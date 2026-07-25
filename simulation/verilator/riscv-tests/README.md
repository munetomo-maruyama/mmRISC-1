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
./do-verilator-tests.py --include-not-tested       # also run any ELF quarantined in not_tested/
```

Nothing is quarantined under `RV32IMFC`, `RV32IMAC` or `RV32IMC` at present, so `--include-not-tested`
currently changes nothing. The `not_tested/` directory beside them holds RV64, virtual memory and
supervisor tests, which no ISA subdirectory reaches.

Exit status is non-zero if any test fails, and a summary of failures is printed at the end. Unlike
the ModelSim script, a failure does not abort the run.

## Two-state caveat

Verilator is a two-state simulator: it initialises to 0 where ModelSim would produce X. Any
testbench signal that is read before it is driven can therefore behave differently here.

One such signal used to matter. `tb_reset_halt_n` drives the active-low halt-on-reset input and was
never assigned, so ModelSim read X, treated as "do not halt", while Verilator read 0 and halted
every hart at reset, with no instruction ever fetched. It is now assigned explicitly, along with
`tb_debug_secure`.

## Tests that are not upstream

Two tests under `riscv-tests/isa/rv32uf/` were written for this core, covering behaviour that
upstream riscv-tests does not reach anywhere.

| test | covers |
|----|----|
| `rv32uf-p-frm` | The reserved rounding modes: the static encodings 5 and 6, the dynamic encoding while `frm` holds 5, 6 or 7, and the instructions whose `funct3` selects an operation rather than a rounding mode, which must keep working whatever `frm` holds. |
| `rv32uf-p-fs` | `mstatus.FS` set to Off disabling the FPU, across all of RV32F and RV32FC and the floating point CSRs. `rv32mi-p-csr` checks one store this way; this checks the rest, and that everything works again once `FS` is restored. |

Their ELFs sit with the others under `riscv-tests/work/isa/RV32IMFC/`, so both this flow and the
ModelSim one pick them up automatically. They were built without `riscv64-unknown-elf-gcc`, which
the `isa/Makefile` expects and which is not needed for a test written entirely in assembly:

```sh
cd simulation/modelsim/riscv-tests/riscv-tests/isa
cpp -nostdinc -undef -D__riscv -D__riscv_xlen=32 -I../env/p -Imacros/scalar \
    -x assembler-with-cpp rv32uf/frm.S -o frm.s
sed -i 's/\bsptbr\b/satp/g' frm.s     # see below
riscv32-elf-as -march=rv32imfc_zicsr -mabi=ilp32f frm.s -o frm.o
riscv32-elf-ld -T ../env/p/link.ld frm.o -o ../work/isa/RV32IMFC/rv32uf-p-frm
riscv32-elf-objdump --disassemble-all --disassemble-zeroes \
    --section=.text --section=.text.startup --section=.text.init --section=.data \
    ../work/isa/RV32IMFC/rv32uf-p-frm > ../work/isa/RV32IMFC/rv32uf-p-frm.dump
```

`env/p/riscv_test.h` writes `sptbr`, the pre-1.10 name for `satp`, which current binutils rejects,
hence the `sed`. Older toolchains do not need it.

## Known failures

These tests fail here. Recorded so that a regression is distinguishable from a pre-existing
failure. Full sweep over `RV32IMFC RV32IMAC RV32IMC`: 308 pass, 8 fail. Every floating point test
passes, and every remaining failure depends on the bus configuration rather than on the
instruction.

| test | configurations | status |
|----|----|---|
| seven `rv32ua-p-amo*_w` | `BUS_INTERVENTION_02` only | Not triaged. The atomics pass in the single-hart configurations and in `_04`, which is also two harts but with RAM wait states. Note that `do-riscv-tests.py` only ever selects one ISA directory at a time and ships with `RV32IMFC` selected, so `RV32IMAC` against two harts is a combination the ModelSim flow does not appear to have been run with either. |
| `rv32uc-p-rvc` | `BUS_INTERVENTION_04` only | Not triaged. |

Run only one sweep at a time. Every invocation uses the same `run/` directory for `rom.memh` and
`result.txt`, so two at once corrupt each other and report failures that are not real.
