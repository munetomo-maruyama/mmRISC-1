#===========================================================
# mmRISC Project
#-----------------------------------------------------------
# File Name   : Makefile
# Description : Verilator unit testbench for CPU_FPU32
#-----------------------------------------------------------
# History :
# Rev.01 2026.07.25 First Release
#-----------------------------------------------------------
# Copyright (C) 2017-2021 M.Maruyama
#===========================================================

ROOT    := ../../..
RTL     := $(ROOT)/verilog/cpu/cpu_fpu32.v
INCDIR  := $(ROOT)/verilog/common

# RISCV_ISA_RV32F is defined unconditionally in defines_core.v, so the
# only thing the build needs is the include path.
VFLAGS  := --cc --exe --build -j 0 -sv --top-module CPU_FPU32 \
           +incdir+$(INCDIR) \
           -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-WIDTHCONCAT \
           -Wno-CASEOVERLAP -Wno-UNOPTFLAT -Wno-LATCH

# -ffp-contract=off keeps the host reference from fusing multiply-add,
# and -frounding-math keeps it from folding under the wrong mode.
CXXFLAGS := -O2 -ffp-contract=off -frounding-math

TARGET  := obj_dir/VCPU_FPU32

all: $(TARGET)

$(TARGET): tb_fpu32.cpp $(RTL)
	verilator $(VFLAGS) -CFLAGS "$(CXXFLAGS)" $(RTL) tb_fpu32.cpp

run: $(TARGET)
	$(TARGET)

clean:
	rm -rf obj_dir

.PHONY: all run clean
