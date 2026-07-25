#!/usr/bin/python3
# ===========================================================
#  mmRISC Project
# -----------------------------------------------------------
#  File Name   : do-verilator-tests.py
#  Description : Script for RISCV-TESTs on Verilator
# -----------------------------------------------------------
#  History :
#  Rev.01 2026.07.25 Verilator port of do-riscv-tests.py
# -----------------------------------------------------------
#  Copyright (C) 2017-2021 M.Maruyama
# ===========================================================
# This is the Verilator counterpart of
# simulation/modelsim/riscv-tests/do-riscv-tests.py. It needs
# verilator and a riscv objcopy. The test ELFs under
# riscv-tests/work/isa are prebuilt and committed.
#
# Usage:
#   ./do-verilator-tests.py # RV32IMFC, all bus interventions
#   ./do-verilator-tests.py --isa RV32IMC RV32IMFC
#   ./do-verilator-tests.py --bus BUS_INTERVENTION_01
#   ./do-verilator-tests.py --include-not-tested

import argparse
import glob
import os
import shutil
import subprocess
import sys

# Locations, all relative to this script
SCRIPT_DIR   = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT    = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "..", ".."))
MODELSIM_DIR = os.path.join(REPO_ROOT, "simulation", "modelsim", "riscv-tests")
ISA_DIR      = os.path.join(MODELSIM_DIR, "riscv-tests", "work", "isa")
HEX2V        = os.path.join(REPO_ROOT, "tools", "hex2v")

# The RTL file list already lives in four places. Read the ModelSim one rather than making it five.
FLIST = os.path.join(MODELSIM_DIR, "flist")

# For configuration of bus intervention
BUS_INTERVENTIONS = [
    "BUS_INTERVENTION_01",
    "BUS_INTERVENTION_02",
    "BUS_INTERVENTION_03",
    "BUS_INTERVENTION_04",
]

# Warnings the existing RTL and testbenches already produce. Listed one by one
# rather than using -Wno-fatal, so that a newly introduced warning still stops
# the build.
WARNING_WAIVERS = [
    "CASEOVERLAP", "COMBDLY", "DEFOVERRIDE", "IMPLICIT", "LATCH",
    "MULTIDRIVEN", "PINMISSING", "REALCVT", "SPECIFYIGN", "TIMESCALEMOD",
    "WIDTHCONCAT", "WIDTHEXPAND", "WIDTHTRUNC", "ZERODLY",
]

INCDIRS = [
    os.path.join(REPO_ROOT, "verilog", "common"),
    os.path.join(REPO_ROOT, "verilog", "ahb_sdram", "model"),
    os.path.join(REPO_ROOT, "verilog", "i2c", "i2c", "trunk", "rtl", "verilog"),
]

# The Micron SDRAM model needs these, exactly as the ModelSim flist sets them
SDRAM_DEFINES = ["den512mb", "sg75", "x16"]


def find_objcopy():
    candidates = [
        "riscv64-unknown-elf-objcopy",
        "riscv32-unknown-elf-objcopy",
        "riscv32-elf-objcopy",
        "riscv64-elf-objcopy",
        "llvm-objcopy",
    ]
    for name in candidates:
        if shutil.which(name):
            return name
    sys.exit("ERROR: no riscv objcopy found (tried: %s)" % ", ".join(candidates))


def read_flist():
    # The file has CRLF line endings and backslash continuations, and its
    # relative paths are anchored at the ModelSim directory.
    sources = []
    with open(FLIST) as flist_file:
        for line in flist_file:
            line = line.replace("\\", "").strip()
            if not line.startswith(("../", "./")):
                continue
            path = os.path.normpath(os.path.join(MODELSIM_DIR, line))
            if not os.path.isfile(path):
                sys.exit("ERROR: file listed in flist does not exist: %s" % path)
            sources.append(path)
    return sources


def read_tohost(dump_file_name):
    with open(dump_file_name) as dump_file:
        for line in dump_file:
            if "<tohost>" in line:
                return "32'h" + line.split()[-2]
    sys.exit("ERROR: no <tohost> in %s" % dump_file_name)


def build(sources, bus_intervention, tohost, cache):
    key = (bus_intervention, tohost)
    if key in cache:
        return cache[key]

    # TOHOST is a compile-time define, so it has to be part of the directory
    # name as well as of the cache key. Most tests share one address but not
    # all of them do, and a shared directory would silently clobber the build.
    obj_dir = os.path.join(SCRIPT_DIR, "obj_dir_%s_%s"
                           % (bus_intervention, tohost.replace("32'h", "")))
    binary  = os.path.join(obj_dir, "sim_tb_TOP")

    cmd = ["verilator", "--binary", "-j", "0", "--timing", "-sv",
           "--top-module", "tb_TOP", "--Mdir", obj_dir, "-o", binary]
    cmd += ["-Wno-" + warning for warning in WARNING_WAIVERS]
    cmd += ["+incdir+" + incdir for incdir in INCDIRS]
    cmd += ["+define+RISCV_TESTS", "+define+SIMULATION",
            "+define+" + bus_intervention,
            "+define+TOHOST=" + tohost]
    cmd += ["+define+" + define for define in SDRAM_DEFINES]
    cmd += sources

    print("Building   %s TOHOST=%s" % (bus_intervention, tohost))
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          text=True)
    if proc.returncode != 0:
        print(proc.stdout)
        sys.exit("ERROR: Verilator build failed")

    cache[key] = binary
    return binary


def run_test(binary, elf_file_name, objcopy, run_dir):
    ihex = os.path.join(run_dir, "rom.ihex")
    memh = os.path.join(run_dir, "rom.memh")
    result_file_name = os.path.join(run_dir, "result.txt")

    if os.path.exists(result_file_name):
        os.remove(result_file_name)

    proc = subprocess.run([objcopy, "-O", "ihex", elf_file_name, ihex],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          text=True)
    if proc.returncode != 0:
        print(proc.stderr)
        sys.exit("ERROR: Objcopy")

    with open(memh, "w") as memh_file:
        proc = subprocess.run([HEX2V, ihex], stdout=memh_file,
                              stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        print(proc.stderr)
        sys.exit("ERROR: Hex2V")

    # The testbench $readmemh's rom.memh and $fopen's result.txt relative to
    # the working directory, so it has to run there.
    subprocess.run([binary], cwd=run_dir, stdout=subprocess.PIPE,
                   stderr=subprocess.STDOUT, text=True)

    if not os.path.exists(result_file_name):
        return "TIMEOUT"
    with open(result_file_name) as result_file:
        return "FAIL" if "FAIL" in result_file.readline() else "PASS"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--isa", nargs="+", default=["RV32IMFC"],
                        help="ISA subdirectories under riscv-tests/work/isa")
    parser.add_argument("--bus", nargs="+", default=BUS_INTERVENTIONS,
                        help="bus intervention configurations to sweep")
    parser.add_argument("--include-not-tested", action="store_true",
                        help="also run the ELFs quarantined in not_tested/")
    args = parser.parse_args()

    objcopy = find_objcopy()
    sources = read_flist()
    run_dir = os.path.join(SCRIPT_DIR, "run")
    os.makedirs(run_dir, exist_ok=True)

    cache = {}
    failures = []
    passed = 0

    for bus_intervention in args.bus:
        test_count = 1
        for isa in args.isa:
            patterns = [os.path.join(ISA_DIR, isa, "rv32*")]
            if args.include_not_tested:
                patterns.append(os.path.join(ISA_DIR, isa, "not_tested", "rv32*"))
            for elf_file_name in sorted(sum([glob.glob(p) for p in patterns], [])):
                # if dump file, skip
                if ".dump" in elf_file_name:
                    continue
                if "consideration" in elf_file_name:
                    continue
                if "not_tested" in elf_file_name and not args.include_not_tested:
                    continue

                tohost = read_tohost(elf_file_name + ".dump")
                binary = build(sources, bus_intervention, tohost, cache)

                print("====[Test %d]======[%s]=================" % (test_count, bus_intervention))
                print(elf_file_name)
                print("To Host    %s" % tohost)

                result = run_test(binary, elf_file_name, objcopy, run_dir)
                print("Result     %s" % result)
                if result == "PASS":
                    passed = passed + 1
                else:
                    failures.append("%s %s %s" % (bus_intervention,
                                                  os.path.basename(elf_file_name),
                                                  result))
                test_count = test_count + 1

    print()
    print("========================================")
    print("PASS %d, FAIL %d" % (passed, len(failures)))
    for failure in failures:
        print("  %s" % failure)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
