#!/usr/bin/python3
# ===========================================================
#  mmRISC Project
# -----------------------------------------------------------
#  File Name   : do_riscv-tests.v
#  Description : Script for RISCV-TESTs
# -----------------------------------------------------------
#  History :
#  Rev.01 2021.06.17 M.Maruyama First Release
# -----------------------------------------------------------
#  Copyright (C) 2017-2021 M.Maruyama
# ===========================================================
# riscv-tests
#    (1) Install Spike simulator


import glob
import subprocess
from subprocess import PIPE

# For configuration of bus intervention
bus_interventions = [                       \
                     "BUS_INTERVENTION_01", \
                     "BUS_INTERVENTION_02", \
                     "BUS_INTERVENTION_03", \
                     "BUS_INTERVENTION_04", \
                    ]

# For each Assemble Source File for RV32IMC
#isa_elf_file_paths = [                                     \
#                      "./riscv-tests/work/isa/RV32IMC/rv32*", \
#                     ]
# For each Assemble Source File for RV32IMAC
#isa_elf_file_paths = [                                     \
#                      "./riscv-tests/work/isa/RV32IMAC/rv32*", \
#                     ]
# For each Assemble Source File for RV32IMFC
isa_elf_file_paths = [                                     \
                      "./riscv-tests/work/isa/RV32IMFC/rv32*", \
                     ]

# Main Routine                     
for bus_intervention in bus_interventions:
    test_count = 1;
    for isa_elf_file_path in isa_elf_file_paths:
        elf_files = glob.glob(isa_elf_file_path);
        for elf_file_name in elf_files:
            # if dump file, skip
            if (".dump" in elf_file_name):
                continue
            if ("consideration" in elf_file_name):
                continue
            if ("not_tested" in elf_file_name):
                continue
            #
            # Base File Name
            base_file_name = elf_file_name.replace('.elf', '');
            #
            # Print Test Name
            print('====[Test %d]======[%s]=================' % (test_count, bus_intervention));
            print(elf_file_name);
            #
            # Make objdump File Name
            objdump_file_name = base_file_name + ".dump";
            #
            # Open objdump File
            with open(objdump_file_name) as objdump_file:
                objdump_lines = objdump_file.readlines();
            #
            # Extract Parameters
            tohost_lines = [line for line in objdump_lines if '<tohost>' in line];
            tohost_line = tohost_lines[0];
            tohost_words = tohost_line.split()
            tohost = "32\\'h"+tohost_words[-2];
            #
            print('To Host    %s' % tohost);
            #
            # Objcopy
            cmd_objcopy = "riscv64-unknown-elf-objcopy -O ihex " \
                        + elf_file_name \
                        + " rom.ihex"
            proc = subprocess.run(cmd_objcopy,   \
                                  shell = True,  \
                                  stdout = PIPE, \
                                  stderr = PIPE, \
                                  text = True)
            if (proc.returncode != 0):
                print("ERROR: Objcopy");
                exit();
            #
            # Convert to Verilog ROM
            cmd_hex2v = "../../../tools/hex2v rom.ihex > rom.memh";
            proc = subprocess.run(cmd_hex2v,     \
                                  shell = True,  \
                                  stdout = PIPE, \
                                  stderr = PIPE, \
                                  text = True)   
            if (proc.returncode != 0):
                print("ERROR: Hex2V");
                exit();
            #
            # Compile Verilog
            cmd_vlog = "vlog +define+TOHOST="+tohost+\
                           " +define+"+bus_intervention+\
                           " -f flist";
            proc = subprocess.run(cmd_vlog,      \
                                  stdout = PIPE, \
                                  shell = True,  \
                                  text = True)
            if (proc.returncode != 0):
                print("ERROR: VLOG");
                exit();
            #
            # Execute Simulation
            cmd_vsim = 'vsim -c -onfinish exit work.tb_TOP -do "run -all"';
            proc = subprocess.run(cmd_vsim,     \
                                  stdout = PIPE, \
                                  shell = True,  \
                                  text = True)
            if (proc.returncode != 0):
                print("ERROR: VSIM");
                exit();
            #
            # Verify Result
            result_file = open('result.txt', 'r')
            result_text = result_file.readlines()            
            result_file.close()
            if ('FAIL' in result_text[0]):
                print("ERROR: Failed");
                exit();
            #
            # Stop Test    
            if (test_count == 100):
                break
            test_count = test_count + 1;

