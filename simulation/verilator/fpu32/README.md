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
make strict                     # same, but ignore KNOWN_BUGS

./obj_dir/VCPU_FPU32 -n 50000            # deeper random sweep
./obj_dir/VCPU_FPU32 --seed 7            # different random operands
./obj_dir/VCPU_FPU32 --examples 10       # more example mismatches per class
./obj_dir/VCPU_FPU32 --fconv 0xff        # override the FCONV convergence loop counts
```

Exit status is non-zero if a mismatch appears that is not in `KNOWN_BUGS`.

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

Every mismatch is attributed to exactly one class. `KNOWN_BUGS` lists the classes that are expected
to fail on the current commit. A mismatch outside that list fails the run. Each fix removes one
entry, so the list is both the regression gate and the running inventory of what is still wrong.

Counts from the default sweep on the tree as of this commit, 143240 cases checked:

| class | count | defect |
|---|---:|---|
| `SQRT_RESULT_ODD_EXP` | 21772 | FSQRT seed is a minimax fit of `1/sqrt(b)` over `[1,2)`, but an odd exponent puts `b` in `[2,4)` |
| `F2I_NX` | 11766 | `FCVT.W.S`/`FCVT.WU.S` never raise inexact |
| `QNAN_NV` | 4571 | invalid raised for a quiet NaN operand, not only a signalling one |
| `OVERFLOW_NX` | 3932 | overflow sets OF or NX, never both |
| `UNDERFLOW_NX` | 3776 | underflow sets UF or NX, never both |
| `INF_OF` | 2315 | overflow raised because an operand is already infinite |
| `DIV_RESIDUAL` | 781 | Goldschmidt never lands exactly on an exact quotient, so NX is always raised and directed rounding is one ulp out. `1.0/2.0` is affected |
| `INF_OPERAND_UF` | 330 | `x/inf` is an exact zero but raises underflow |
| `DIVZERO_OF` | 310 | `x/0` raises overflow alongside the correct divide-by-zero |
| `SUBNORMAL_RESULT` | 210 | subnormal operands or results are mishandled |
| `SQRT_RESIDUAL` | 15 | as `DIV_RESIDUAL`, for an exact square root: `sqrt(1.0)` is right but raises NX |
| `SQRT_RESULT_EVEN_EXP` | 9 | FSQRT reads its result one refinement early, so a loop count of n delivers n-1 |
| `SQRT_NEGZERO_NV` | 5 | `sqrt(-0)` is `-0` with no exception |

Counts are not severity. `SQRT_RESULT_EVEN_EXP` is only 9 because the even-exponent seed is good
enough that the shortfall shows up on few operands, while `SQRT_RESULT_ODD_EXP` is enormous because
the odd-exponent seed is wrong by up to 79 percent.
