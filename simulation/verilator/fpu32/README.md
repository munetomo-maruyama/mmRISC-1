# CPU_FPU32 unit testbench

A Verilator testbench that drives the RV32F unit on its own, checking every result and every
exception flag against a reference.

It complements `../riscv-tests/`, which runs whole programs on the whole chip but carries very few
floating point vectors. `rv32uf-p-fdiv` contains three `fsqrt.s` cases in total, all with odd
exponents, and none of the tests vary the rounding mode.

## Requirements

- `verilator` (developed against 5.050)
- a C++ compiler on a host with IEEE binary32 arithmetic and a working `<cfenv>`

`RISCV_ISA_RV32F` is defined unconditionally in `verilog/common/defines_core.v`, so the build needs
only that include path.

## Usage

```sh
make                            # build
make run                        # default sweep, about 15 s

./obj_dir/VCPU_FPU32 -n 50000            # deeper random sweep
./obj_dir/VCPU_FPU32 --seed 7            # different random operands
./obj_dir/VCPU_FPU32 --examples 10       # more example mismatches per class
./obj_dir/VCPU_FPU32 --fconv 0xff        # override the FCONV convergence loop counts
```

Exit status is non-zero if any mismatch appears.

## How the DUT is driven

`CPU_FPU32` is plain Verilog-2001 with a flat port list, and its debug abstract command port gives
direct access to the float registers, so no pipeline is needed around it:

| purpose | ports |
|---|---|
| poke and peek a float register | `DBGABS_FPR_REQ/WRITE/ADDR/WDATA/RDATA` |
| `fflags`, `frm`, FCONV | `CSR_FPU_CPU_REQ/WRITE/ADDR/WDATA/RDATA` |
| issue an instruction | `ID_FPU_CMD`, `ID_FPU_RMODE`, `ID_FPU_SRC1..3`, `ID_FPU_DST1`, held until `ID_FPU_STALL` drops |
| float to integer result | `EX_FPU_SRCDATA`, selected by `EX_ALU_SRC1` |

Each case writes its operands, clears `fflags`, issues one instruction, waits a fixed settling
period long enough for FSQRT at the maximum convergence count, then reads back the result and the
accumulated flags.

## The reference

Host binary32 arithmetic under `fesetround`, which is correctly rounded for add, subtract, multiply,
divide and square root, with flags from `fetestexcept` remapped to the RISC-V bit order. Two things
do not map onto host semantics and are modelled explicitly:

- Round-to-nearest-max-magnitude has no `fesetround` equivalent. It differs from
  round-to-nearest-even only on an exact tie, and then takes the candidate of larger magnitude. Ties
  are detected exactly: add, subtract and multiply are exact in `long double`, division is confirmed
  by an exact `fmal` residual, and a square root is either exact or irrational so it never ties.
- `FCVT.W.S` / `FCVT.WU.S` saturate in RISC-V rather than delivering the host's out-of-range
  sentinel, and the rounding is done arithmetically rather than through `nearbyintf`, which the
  optimiser is free to reorder across a rounding mode change.

NaN results are compared against the canonical `0x7fc00000` that RISC-V requires.

## Defect classes

Every mismatch is attributed to exactly one class, named for the defect rather than for the
instruction, so that a failure report says what is wrong and not merely where. Any mismatch fails
the run.

