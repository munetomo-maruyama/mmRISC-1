#!/usr/bin/python3
# ===========================================================
#  mmRISC Project
# -----------------------------------------------------------
#  File Name   : do_riscv-arch-test.v
#  Description : Script for RISCV-ARCH-TEST
# -----------------------------------------------------------
#  History :
#  Rev.01 2021.02.23 M.Maruyama First Release
# -----------------------------------------------------------
#  Copyright (C) 2017-2021 M.Maruyama
# ===========================================================
# riscv-arch-test
#    (1) add following line in riscv-arch-test/Makefile.include
#        export RISCV_PREFIX       ?= riscv64-unknown-elf-
#    (2) Install Spike simulator


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

# For each Assemble Source File
isa_elf_file_paths = [                                                  \
                      "./riscv-arch-test/work/rv32i_m/privilege/*.elf", \
                      "./riscv-arch-test/work/rv32i_m/Zifencei/*.elf",  \
                      "./riscv-arch-test/work/rv32i_m/C/*.elf",         \
                      "./riscv-arch-test/work/rv32i_m/M/*.elf",         \
                      "./riscv-arch-test/work/rv32i_m/I/*.elf"          \
                     ]

# Main Routine                     
for bus_intervention in bus_interventions:
    test_count = 1;
    for isa_elf_file_path in isa_elf_file_paths:
        elf_files = glob.glob(isa_elf_file_path);
        for elf_file_name in elf_files:
            #
            # Base File Name
            base_file_name = elf_file_name.replace('.elf', '');
            #
            # Print Test Name
            print('====[Test %d]======[%s]=================' % (test_count, bus_intervention));
            print(elf_file_name);
            #
            # Make objdump File Name
            objdump_file_name = elf_file_name + ".objdump";
            #
            # Open objdump File
            with open(objdump_file_name) as objdump_file:
                objdump_lines = objdump_file.readlines();
            #
            # Extract Parameters
            begin_signature_lines = [line for line in objdump_lines if '<begin_signature>:' in line];
            begin_signature_line = begin_signature_lines[-1];
            dump_bgn = begin_signature_line.replace(' <begin_signature>:\n', '');
            dump_bgn = "32\\'h"+dump_bgn;
            #
            end_signature_lines  = [line for line in objdump_lines if '<end_signature>:' in line];
            begin_regstate_lines = [line for line in objdump_lines if '<begin_regstate>:' in line];
            if (len(end_signature_lines) > 0):
                end_signature_line = end_signature_lines[-1];
                dump_end = end_signature_line.replace(' <end_signature>:\n', '');
                dump_end = "32\\'h"+dump_end;
            else:
                begin_regstate_line = begin_regstate_lines[-1];
                dump_end = begin_regstate_line.replace(' <begin_regstate>:\n', '');
                dump_end = "32\\'h"+dump_end;
            #
            tohost_lines = [line for line in objdump_lines if '<tohost>:' in line];
            tohost_line = tohost_lines[-1];
            tohost = tohost_line.replace(' <tohost>:\n', '');
            tohost = "32\\'h"+tohost;
            #
            print('Dump Begin %s' % dump_bgn);
            print('Dump End   %s' % dump_end);
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
                           " +define+DUMP_BGN="+dump_bgn+\
                           " +define+DUMP_END="+dump_end+\
                           " +define+"+bus_intervention+\
                           " -f flist";
            proc = subprocess.run(cmd_vlog,     \
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
            # Verify Signature
            cmd_diff = 'diff dump.signature ' + base_file_name + '.signature.output';
            proc = subprocess.run(cmd_diff,     \
                                  shell = True,  \
                                  text = True)
            if (proc.returncode != 0):
                print("ERROR: Diff");
                exit();
        
            #
            # Clear List
            objdump_lines.clear();
            begin_signature_lines.clear();
            end_signature_lines.clear();
            begin_regstate_lines.clear();
            tohost_lines.clear();
        
            # Stop Test    
            if (test_count == 100):
                break
            test_count = test_count + 1;

