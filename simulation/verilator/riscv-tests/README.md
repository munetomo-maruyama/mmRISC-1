# riscv-tests on Verilator

The Verilator counterpart of `simulation/modelsim/riscv-tests/`.

It exists because the ModelSim flow needs `vsim` and, to rebuild anything, a RISC-V C toolchain.
This flow needs neither: the test ELFs under `riscv-tests/work/isa/` are prebuilt and committed, and
converting them needs only `objcopy`. That makes the suite runnable on a plain Linux box and
potentially enabled a GitHub Actions based CI.

## Requirements

- `verilator` (developed against 5.050)
- a C++ compiler
- any RISC-V `objcopy`. The script looks for `riscv64-unknown-elf-`, `riscv32-unknown-elf-`,
  `riscv32-elf-`, `riscv64-elf-` and `llvm-objcopy`, in that order
- `tools/hex2v` (committed. Rebuild with `cc -o tools/hex2v tools/hex2v.c` if needed)

## Usage

```sh
./do-verilator-tests.py                            # RV32IMFC, all four bus interventions
./do-verilator-tests.py --bus BUS_INTERVENTION_01  # one configuration
./do-verilator-tests.py --isa RV32IMC RV32IMAC     # other ISA subdirectories
./do-verilator-tests.py --include-not-tested       # also run the quarantined ELFs
```

Exit status is non-zero if any test fails, and a summary of failures is printed at the end. Unlike
the ModelSim script, a failure does not abort the run.

## Two-state caveat

Verilator is a two-state simulator: it initialises to 0 where ModelSim would produce X. Any
testbench signal that is read before it is driven can therefore behave differently here.

One such signal used to matter. `tb_reset_halt_n` drives the active-low halt-on-reset input and was
never assigned, so ModelSim read X, treated as "do not halt", while Verilator read 0 and halted
every hart at reset, with no instruction ever fetched. It is now assigned explicitly, along with
`tb_debug_secure`.

## Known failures

These tests fail here. Recorded so that a regression is distinguishable from a pre-existing
failure. Full sweep over `RV32IMFC RV32IMAC RV32IMC` with `--include-not-tested`: 296 pass, 12 fail.
Every floating point test passes, `rv32uf-p-fdiv` included, though that one still sits in
`not_tested/` where only `--include-not-tested` reaches it.

| test | configurations | status |
|----|----|---|
| `rv32mi-p-csr` | all four | Not triaged. |
| seven `rv32ua-p-amo*_w` | `BUS_INTERVENTION_02` only | Not triaged. The atomics pass in the single-hart configurations and in `_04`, which is also two harts but with RAM wait states. Note that `do-riscv-tests.py` only ever selects one ISA directory at a time and ships with `RV32IMFC` selected, so `RV32IMAC` against two harts is a combination the ModelSim flow does not appear to have been run with either. |
| `rv32uc-p-rvc` | `BUS_INTERVENTION_04` only | Not triaged. |
