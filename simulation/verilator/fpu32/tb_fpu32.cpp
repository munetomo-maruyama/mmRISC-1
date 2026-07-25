//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : tb_fpu32.cpp
// Description : Verilator unit testbench for CPU_FPU32
//-----------------------------------------------------------
// History :
// Rev.01 2026.07.25 First Release
//-----------------------------------------------------------
// Copyright (C) 2017-2021 M.Maruyama
//===========================================================
//
// CPU_FPU32 is driven standalone here: the debug abstract command port
// reaches the float registers and the CSR port reaches fflags, frm and
// FCONV, so operands can be poked in and results and flags read back
// without a pipeline around it.
//
// The reference is the host's own binary32 arithmetic under fesetround,
// which is correctly rounded for add, subtract, multiply, divide and
// square root, with flags from fetestexcept. Round-to-nearest-max-
// magnitude and the float to integer conversions are modelled in
// software, since neither maps onto host semantics.
//
// Mismatches are attributed to a defect class. Classes listed in
// KNOWN_BUGS are expected to fail and do not fail the run. Anything else
// does. Each RTL fix removes one entry.

#include "VCPU_FPU32.h"
#include "verilated.h"

#include <cfenv>
#pragma STDC FENV_ACCESS ON
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <map>
#include <string>
#include <vector>

//-----------------------------------------------------------
// Encodings, from verilog/common/defines_core.v
//-----------------------------------------------------------
enum : uint8_t {
    CMD_NOP     = 0x00,
    CMD_FADD    = 0x04,
    CMD_FSUB    = 0x0c,
    CMD_FMUL    = 0x14,
    CMD_FDIV    = 0x1c,
    CMD_FSQRT   = 0x5c,
    CMD_FMADD   = 0xf8,
    CMD_FCVTWS  = 0xc0,
    CMD_FCVTWUS = 0xc1,
};

enum : uint8_t {
    RMODE_RNE = 0, RMODE_RTZ = 1, RMODE_RDN = 2, RMODE_RUP = 3, RMODE_RMM = 4,
    RMODE_DYN = 7,
};

enum : uint16_t { ALU_GPR = 0x3000, ALU_FPR = 0x3020 };

enum : uint16_t { CSR_FFLAGS = 0x001, CSR_FRM = 0x002, CSR_FPU32CONV = 0xbe0 };

// fflags bit order
enum : uint8_t { NX = 0x01, UF = 0x02, OF = 0x04, DZ = 0x08, NV = 0x10 };

static const uint32_t CANONICAL_NAN = 0x7fc00000u;

// Long enough for FSQRT at the maximum convergence loop count of 15
static const int SETTLE_CYCLES = 128;

//-----------------------------------------------------------
// Defect classes
//-----------------------------------------------------------
// A mismatch is attributed to exactly one of these. The ones listed in
// KNOWN_BUGS are the defects not yet fixed on this commit.
static const char *KNOWN_BUGS[] = {
    "QNAN_NV",               // NV raised for a quiet NaN operand
    "INF_OF",                // OF raised for an infinite operand
    "OVERFLOW_NX",           // overflow sets OF or NX, never both
    "UNDERFLOW_NX",          // underflow sets UF or NX, never both
    "F2I_NX",                // float to int never raises NX
    "DIV_RESIDUAL",          // Goldschmidt never lands exactly on an exact
                             // quotient, so NX is always raised and directed
                             // rounding is one ulp out. 1.0/2.0 is affected.
    "SQRT_RESIDUAL",         // the same for an exact square root: sqrt(1.0)
                             // is right but raises NX
    "SUBNORMAL_RESULT",      // subnormal operands or results are mishandled
    "INF_OPERAND_UF",        // x/inf is an exact zero but raises UF
    "DIVZERO_OF",            // x/0 raises OF alongside the correct DZ
    "SQRT_NEGZERO_NV",       // sqrt(-0) is -0 with no exception
    nullptr
};

static bool is_known_bug(const std::string &defect_class)
{
    for (int i = 0; KNOWN_BUGS[i] != nullptr; i++)
        if (defect_class == KNOWN_BUGS[i]) return true;
    return false;
}

//-----------------------------------------------------------
// binary32 helpers
//-----------------------------------------------------------
static float bits_to_f32(uint32_t bits) { float f; memcpy(&f, &bits, 4); return f; }
static uint32_t f32_to_bits(float f) { uint32_t bits; memcpy(&bits, &f, 4); return bits; }

static bool is_nan(uint32_t bits)  { return (bits & 0x7f800000u) == 0x7f800000u && (bits & 0x007fffffu) != 0; }
static bool is_snan(uint32_t bits) { return is_nan(bits) && (bits & 0x00400000u) == 0; }
static bool is_qnan(uint32_t bits) { return is_nan(bits) && (bits & 0x00400000u) != 0; }
static bool is_inf(uint32_t bits)  { return (bits & 0x7fffffffu) == 0x7f800000u; }

// Unbiased exponent, used to stratify FSQRT by the parity the RTL tests
static int exponent_of(uint32_t bits) { return (int)((bits >> 23) & 0xff) - 127; }

//-----------------------------------------------------------
// Reference model
//-----------------------------------------------------------
struct Expected {
    uint32_t result;
    uint8_t  flags;
};

static int host_rounding(uint8_t rmode)
{
    switch (rmode) {
        case RMODE_RTZ: return FE_TOWARDZERO;
        case RMODE_RDN: return FE_DOWNWARD;
        case RMODE_RUP: return FE_UPWARD;
        default:        return FE_TONEAREST;  // RNE, and the base for RMM
    }
}

static uint8_t host_flags()
{
    int raised = fetestexcept(FE_ALL_EXCEPT);
    uint8_t flags = 0;
    if (raised & FE_INVALID)   flags |= NV;
    if (raised & FE_DIVBYZERO) flags |= DZ;
    if (raised & FE_OVERFLOW)  flags |= OF;
    if (raised & FE_UNDERFLOW) flags |= UF;
    if (raised & FE_INEXACT)   flags |= NX;
    return flags;
}

// RMM differs from RNE only on an exact tie. Ties are detectable exactly:
// for add, subtract and multiply the operation is exact in long double
// (24 + 24 bits fit in a 64 bit significand), and a square root is either
// exact or irrational so it never ties. Only division needs a residual
// check, which fmal computes exactly here for the same reason.
static bool is_exact_tie(uint8_t cmd, uint32_t a, uint32_t b, uint32_t rne_result)
{
    if (is_nan(rne_result) || is_inf(rne_result)) return false;

    int saved = fegetround();
    fesetround(FE_TONEAREST);

    long double x = (long double)bits_to_f32(a);
    long double y = (long double)bits_to_f32(b);
    long double exact;
    bool have_exact = true;
    switch (cmd) {
        case CMD_FADD: exact = x + y; break;
        case CMD_FSUB: exact = x - y; break;
        case CMD_FMUL: exact = x * y; break;
        case CMD_FDIV: {
            // A tie needs a quotient of exactly 25 significant bits, so it is
            // representable in long double; confirm by exact residual.
            exact = x / y;
            have_exact = (exact != 0.0L) && (fmal(exact, y, -x) == 0.0L);
            break;
        }
        default: exact = 0.0L; have_exact = false; break;  // FSQRT never ties
    }

    bool tie = false;
    if (have_exact && exact != 0.0L) {
        float rounded = (float)exact;
        if ((long double)rounded != exact && !std::isinf(rounded)) {
            // The nearest float may lie on either side of the exact value
            float other = ((long double)rounded < exact)
                        ? nextafterf(rounded,  INFINITY)
                        : nextafterf(rounded, -INFINITY);
            if (!std::isinf(other))
                tie = ((long double)rounded + (long double)other) == exact * 2.0L;
        }
    }
    fesetround(saved);
    return tie;
}

static Expected reference_arith(uint8_t cmd, uint32_t a, uint32_t b, uint8_t rmode)
{
    int saved = fegetround();
    fesetround(host_rounding(rmode));
    feclearexcept(FE_ALL_EXCEPT);

    float x = bits_to_f32(a);
    float y = bits_to_f32(b);
    float r;
    switch (cmd) {
        case CMD_FADD:  r = x + y; break;
        case CMD_FSUB:  r = x - y; break;
        case CMD_FMUL:  r = x * y; break;
        case CMD_FDIV:  r = x / y; break;
        case CMD_FSQRT: r = sqrtf(x); break;
        default:        r = 0.0f; break;
    }

    Expected expected;
    expected.flags = host_flags();
    expected.result = f32_to_bits(r);
    fesetround(saved);

    // RISC-V delivers the canonical NaN rather than a propagated payload
    if (is_nan(expected.result)) expected.result = CANONICAL_NAN;

    if (rmode == RMODE_RMM && is_exact_tie(cmd, a, b, expected.result)) {
        // On a tie, take the candidate of larger magnitude rather than the
        // even one. Rounding towards zero yields the nearer-to-zero candidate,
        // so one step away from zero from there is the answer. The flags are
        // unaffected: a tie is inexact either way, and neither tiny nor huge.
        saved = fegetround();
        fesetround(FE_TOWARDZERO);
        float x2 = bits_to_f32(a);
        float y2 = bits_to_f32(b);
        float toward_zero;
        switch (cmd) {
            case CMD_FADD: toward_zero = x2 + y2; break;
            case CMD_FSUB: toward_zero = x2 - y2; break;
            case CMD_FMUL: toward_zero = x2 * y2; break;
            default:       toward_zero = x2 / y2; break;
        }
        fesetround(saved);
        expected.result = f32_to_bits(nextafterf(
            toward_zero, toward_zero < 0 ? -INFINITY : INFINITY));
    }
    return expected;
}

// FCVT.W.S / FCVT.WU.S, modelled directly: RISC-V saturates rather than
// delivering the host's out-of-range sentinel, and raises NX for a
// discarded fraction.
static Expected reference_f2i(bool is_signed, uint32_t a, uint8_t rmode)
{
    Expected expected = {0, 0};
    float x = bits_to_f32(a);

    if (is_nan(a)) {
        expected.result = is_signed ? 0x7fffffffu : 0xffffffffu;
        expected.flags  = NV;
        return expected;
    }

    // Rounded explicitly rather than through nearbyintf under fesetround,
    // which the optimiser is free to reorder across the mode change.
    float truncated = truncf(x);
    float fraction  = x - truncated;
    float rounded   = truncated;
    if (fraction != 0.0f) {
        bool negative = (fraction < 0.0f);
        float magnitude = negative ? -fraction : fraction;
        bool away;
        switch (rmode) {
            case RMODE_RTZ: away = false; break;
            case RMODE_RDN: away = negative; break;
            case RMODE_RUP: away = !negative; break;
            case RMODE_RMM: away = (magnitude >= 0.5f); break;
            default:  // RNE, ties to even
                away = (magnitude > 0.5f)
                    || (magnitude == 0.5f && fmodf(truncated, 2.0f) != 0.0f);
                break;
        }
        if (away) rounded = truncated + (negative ? -1.0f : 1.0f);
    }

    double limit_lo = is_signed ? -2147483648.0 : 0.0;
    double limit_hi = is_signed ?  2147483647.0 : 4294967295.0;
    if ((double)rounded < limit_lo || (double)rounded > limit_hi) {
        expected.result = (double)rounded < limit_lo
                        ? (is_signed ? 0x80000000u : 0x00000000u)
                        : (is_signed ? 0x7fffffffu : 0xffffffffu);
        expected.flags = NV;
        return expected;
    }

    expected.result = is_signed ? (uint32_t)(int32_t)rounded : (uint32_t)rounded;
    if (rounded != x) expected.flags = NX;
    return expected;
}

//-----------------------------------------------------------
// DUT wrapper
//-----------------------------------------------------------
class Fpu32 {
public:
    Fpu32() : dut(new VCPU_FPU32) { idle(); reset(); }
    ~Fpu32() { dut->final(); delete dut; }

    void tick()
    {
        dut->CLK = 0; dut->eval();
        dut->CLK = 1; dut->eval();
        cycles++;
    }

    void reset()
    {
        dut->RES_CPU = 1;
        for (int i = 0; i < 4; i++) tick();
        dut->RES_CPU = 0;
        tick();
    }

    void write_fpr(int index, uint32_t value)
    {
        dut->DBGABS_FPR_REQ   = 1;
        dut->DBGABS_FPR_WRITE = 1;
        dut->DBGABS_FPR_ADDR  = index;
        dut->DBGABS_FPR_WDATA = value;
        tick();
        dut->DBGABS_FPR_REQ   = 0;
        dut->DBGABS_FPR_WRITE = 0;
    }

    uint32_t read_fpr(int index)
    {
        dut->DBGABS_FPR_REQ   = 1;
        dut->DBGABS_FPR_WRITE = 0;
        dut->DBGABS_FPR_ADDR  = index;
        tick();
        dut->DBGABS_FPR_REQ = 0;
        return dut->DBGABS_FPR_RDATA;
    }

    void write_csr(uint16_t addr, uint32_t value)
    {
        dut->CSR_FPU_CPU_REQ   = 1;
        dut->CSR_FPU_CPU_WRITE = 1;
        dut->CSR_FPU_CPU_ADDR  = addr;
        dut->CSR_FPU_CPU_WDATA = value;
        tick();
        dut->CSR_FPU_CPU_REQ   = 0;
        dut->CSR_FPU_CPU_WRITE = 0;
    }

    uint32_t read_csr(uint16_t addr)
    {
        // The read data path is combinational while REQ is high
        dut->CSR_FPU_CPU_REQ   = 1;
        dut->CSR_FPU_CPU_WRITE = 0;
        dut->CSR_FPU_CPU_ADDR  = addr;
        dut->eval();
        uint32_t value = dut->CSR_FPU_CPU_RDATA;
        dut->CSR_FPU_CPU_REQ = 0;
        dut->eval();
        return value;
    }

    // Issue one instruction and let it retire
    void issue(uint8_t cmd, uint8_t rmode, int src1, int src2, int src3, int dst)
    {
        dut->ID_FPU_CMD   = cmd;
        dut->ID_FPU_RMODE = rmode;
        dut->ID_FPU_SRC1  = src1 >= 0 ? (ALU_FPR | src1) : ALU_GPR;
        dut->ID_FPU_SRC2  = src2 >= 0 ? (ALU_FPR | src2) : ALU_GPR;
        dut->ID_FPU_SRC3  = src3 >= 0 ? (ALU_FPR | src3) : ALU_GPR;
        dut->ID_FPU_DST1  = dst  >= 0 ? (ALU_FPR | dst ) : ALU_GPR;
        // FCVT.W.S delivers its result on EX_FPU_SRCDATA, selected by
        // EX_ALU_SRC1; harmless for the other instructions.
        dut->EX_ALU_SRC1  = src1 >= 0 ? (ALU_FPR | src1) : ALU_GPR;

        // Hold until the FPU accepts it
        for (int guard = 0; guard < 256; guard++) {
            dut->eval();
            if (!dut->ID_FPU_STALL) break;
            tick();
        }
        tick();

        dut->ID_FPU_CMD = CMD_NOP;
        dut->eval();
        for (int i = 0; i < SETTLE_CYCLES; i++) tick();
    }

    uint32_t ex_srcdata() const { return dut->EX_FPU_SRCDATA; }
    uint64_t cycle_count() const { return cycles; }

private:
    void idle()
    {
        dut->CLK = 0;
        dut->RES_CPU = 0;
        dut->CSR_FPU_DBG_REQ = 0; dut->CSR_FPU_DBG_WRITE = 0;
        dut->CSR_FPU_DBG_ADDR = 0; dut->CSR_FPU_DBG_WDATA = 0;
        dut->CSR_FPU_CPU_REQ = 0; dut->CSR_FPU_CPU_WRITE = 0;
        dut->CSR_FPU_CPU_ADDR = 0; dut->CSR_FPU_CPU_WDATA = 0;
        dut->DBGABS_FPR_REQ = 0; dut->DBGABS_FPR_WRITE = 0;
        dut->DBGABS_FPR_ADDR = 0; dut->DBGABS_FPR_WDATA = 0;
        dut->ID_FPU_CMD = CMD_NOP; dut->ID_FPU_RMODE = 0;
        dut->ID_FPU_SRC1 = ALU_GPR; dut->ID_FPU_SRC2 = ALU_GPR;
        dut->ID_FPU_SRC3 = ALU_GPR; dut->ID_FPU_DST1 = ALU_GPR;
        dut->EX_ALU_SRC1 = ALU_GPR; dut->EX_ALU_SRC2 = ALU_GPR;
        dut->EX_ALU_SRC3 = ALU_GPR; dut->EX_ALU_DST1 = ALU_GPR;
        dut->EX_STSRC = ALU_GPR; dut->WB_LOAD_DST = ALU_GPR;
        dut->EX_FPU_DSTDATA = 0; dut->WB_FPU_LD_DATA = 0;
    }

    VCPU_FPU32 *dut;
    uint64_t cycles = 0;
};

//-----------------------------------------------------------
// Checking
//-----------------------------------------------------------
struct Stats {
    uint64_t checked = 0;
    uint64_t matched = 0;
    std::map<std::string, uint64_t> by_class;
    std::map<std::string, std::vector<std::string>> examples;
    size_t examples_per_class = 1;
    int fconv = -1;
};

static const char *op_name(uint8_t cmd)
{
    switch (cmd) {
        case CMD_FADD:    return "fadd.s";
        case CMD_FSUB:    return "fsub.s";
        case CMD_FMUL:    return "fmul.s";
        case CMD_FDIV:    return "fdiv.s";
        case CMD_FSQRT:   return "fsqrt.s";
        case CMD_FCVTWS:  return "fcvt.w.s";
        case CMD_FCVTWUS: return "fcvt.wu.s";
        default:          return "?";
    }
}

// Attribute a mismatch to the defect it is evidence of. Result errors and
// flag errors are distinguished, and the flag cases are keyed on which
// specific bit went the wrong way.
static bool is_subnormal(uint32_t bits)
{
    return (bits & 0x7f800000u) == 0 && (bits & 0x007fffffu) != 0;
}

// Attribute a mismatch to the defect it is evidence of. Result errors and
// flag errors are distinguished, and the flag cases are keyed on which
// specific bit went the wrong way.
static std::string classify(uint8_t cmd, uint32_t a, uint32_t b,
                            const Expected &expected, uint32_t got_result,
                            uint8_t got_flags)
{
    bool subnormal_involved = is_subnormal(a) || is_subnormal(b)
                           || is_subnormal(expected.result)
                           || is_subnormal(got_result);

    if (got_result != expected.result) {
        if (cmd == CMD_FSQRT) {
            // An exact square root has to come back bit-exact no matter how
            // good the seed is, so missing one says the residual never
            // closed, not that the iteration ran short of accurate bits.
            if (!(expected.flags & NX))  return "SQRT_RESIDUAL";
            return (exponent_of(a) % 2 == 0) ? "SQRT_RESULT_EVEN_EXP"
                                             : "SQRT_RESULT_ODD_EXP";
        }
        if (subnormal_involved)  return "SUBNORMAL_RESULT";
        if (cmd == CMD_FDIV)     return "DIV_RESIDUAL";
        return "RESULT";
    }

    uint8_t spurious = got_flags & ~expected.flags;
    uint8_t missing  = expected.flags & ~got_flags;

    if ((spurious & NV) && (is_qnan(a) || is_qnan(b)))   return "QNAN_NV";
    if ((spurious & NV) && cmd == CMD_FSQRT && a == 0x80000000u)
        return "SQRT_NEGZERO_NV";
    if ((spurious & OF) && (is_inf(a) || is_inf(b)))     return "INF_OF";
    if ((spurious & OF) && (expected.flags & DZ))        return "DIVZERO_OF";
    if ((spurious & UF) && (is_inf(a) || is_inf(b)))     return "INF_OPERAND_UF";
    if (expected.flags & OF)                             return "OVERFLOW_NX";
    if (expected.flags & UF)                             return "UNDERFLOW_NX";
    if ((missing & NX) && (cmd == CMD_FCVTWS || cmd == CMD_FCVTWUS))
        return "F2I_NX";
    if (subnormal_involved)                              return "SUBNORMAL_RESULT";
    if ((spurious & NX) && cmd == CMD_FDIV)              return "DIV_RESIDUAL";
    if ((spurious & NX) && cmd == CMD_FSQRT)             return "SQRT_RESIDUAL";
    return "FLAGS";
}

static void check(Stats &stats, Fpu32 &fpu, uint8_t cmd, uint8_t rmode,
                  uint32_t a, uint32_t b)
{
    bool is_conversion = (cmd == CMD_FCVTWS || cmd == CMD_FCVTWUS);
    bool is_unary      = (cmd == CMD_FSQRT) || is_conversion;

    Expected expected = is_conversion
                      ? reference_f2i(cmd == CMD_FCVTWS, a, rmode)
                      : reference_arith(cmd, a, b, rmode);

    fpu.write_fpr(1, a);
    if (!is_unary) fpu.write_fpr(2, b);
    fpu.write_csr(CSR_FFLAGS, 0);

    uint32_t got_result;
    if (is_conversion) {
        fpu.issue(cmd, rmode, 1, -1, -1, -1);
        got_result = fpu.ex_srcdata();
    } else if (is_unary) {
        fpu.issue(cmd, rmode, 1, -1, -1, 3);
        got_result = fpu.read_fpr(3);
    } else {
        fpu.issue(cmd, rmode, 1, 2, -1, 3);
        got_result = fpu.read_fpr(3);
    }
    uint8_t got_flags = fpu.read_csr(CSR_FFLAGS) & 0x1f;

    stats.checked++;
    if (got_result == expected.result && got_flags == expected.flags) {
        stats.matched++;
        return;
    }

    std::string defect_class = classify(cmd, a, b, expected, got_result, got_flags);
    stats.by_class[defect_class]++;
    std::vector<std::string> &examples = stats.examples[defect_class];
    if (examples.size() < stats.examples_per_class) {
        char buffer[256];
        snprintf(buffer, sizeof buffer,
                 "%-9s rm=%d a=%08x b=%08x -> %08x/%02x  expected %08x/%02x",
                 op_name(cmd), rmode, a, b, got_result, got_flags,
                 expected.result, expected.flags);
        examples.push_back(buffer);
    }
}

//-----------------------------------------------------------
// Corpus
//-----------------------------------------------------------
static std::vector<uint32_t> boundary_operands()
{
    return {
        0x00000000, 0x80000000,              // +/- zero
        0x00000001, 0x80000001,              // smallest subnormal
        0x007fffff, 0x807fffff,              // largest subnormal
        0x00800000, 0x80800000,              // smallest normal
        0x7f7fffff, 0xff7fffff,              // largest normal
        0x7f800000, 0xff800000,              // +/- infinity
        0x7fc00000, 0xffc00000,              // quiet NaN
        0x7fa00000, 0x7f800001,              // signalling NaN
        0x7ffe150f,                          // quiet NaN with a payload
        0x3f800000, 0xbf800000,              // +/- 1.0
        0x40000000, 0x40400000, 0x40800000,  // 2.0, 3.0, 4.0
        0x3f000000, 0x3eaaaaab,              // 0.5, 1/3
        0x4079999a, 0x66483307, 0x3c072c85,  // square roots that misround
        0x0203abdb, 0x50937d4d, 0xef50bf89,  // products that overflow
        0x7f7985df, 0x488ac1ab, 0xff47d7e8,
        0xfe61f6e3, 0xb0d51159,
        0x40490fdb, 0x42c80000, 0x461c4000,  // pi, 100.0, 10000.0
        0x432b0000,                          // 171.0, from rv32uf-p-fdiv
    };
}

// xorshift, so the sweep is reproducible from the seed alone
static uint32_t next_random(uint64_t &state)
{
    state ^= state << 13;
    state ^= state >> 7;
    state ^= state << 17;
    return (uint32_t)(state >> 16);
}

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);

    bool strict = false;
    uint64_t seed = 1;
    int random_count = 20000;
    size_t examples_per_class = 1;
    int fconv = -1;
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "--strict") strict = true;
        else if (arg == "--seed" && i + 1 < argc) seed = strtoull(argv[++i], nullptr, 0);
        else if (arg == "-n" && i + 1 < argc) random_count = atoi(argv[++i]);
        else if (arg == "--examples" && i + 1 < argc) examples_per_class = atoi(argv[++i]);
        else if (arg == "--fconv" && i + 1 < argc) fconv = (int)strtoul(argv[++i], nullptr, 0);
    }
    if (seed == 0) seed = 1;

    Fpu32 fpu;
    Stats stats;
    stats.examples_per_class = examples_per_class;
    if (fconv >= 0) {
        fpu.write_csr(CSR_FPU32CONV, (uint32_t)fconv);
        printf("FCONV set to 0x%02x\n", fconv);
    }

    const uint8_t binary_ops[] = {CMD_FADD, CMD_FSUB, CMD_FMUL, CMD_FDIV};
    const uint8_t unary_ops[]  = {CMD_FSQRT, CMD_FCVTWS, CMD_FCVTWUS};
    const uint8_t rmodes[]     = {RMODE_RNE, RMODE_RTZ, RMODE_RDN, RMODE_RUP, RMODE_RMM};

    // Boundary operands, every pair, every rounding mode
    std::vector<uint32_t> boundary = boundary_operands();
    printf("Boundary sweep: %zu operands\n", boundary.size());
    for (uint8_t rmode : rmodes) {
        for (uint32_t a : boundary) {
            for (uint8_t cmd : unary_ops) check(stats, fpu, cmd, rmode, a, 0);
            for (uint32_t b : boundary)
                for (uint8_t cmd : binary_ops) check(stats, fpu, cmd, rmode, a, b);
        }
    }

    // Randomised sweep
    printf("Random sweep:   %d cases per operation per rounding mode\n", random_count);
    uint64_t state = seed;
    for (uint8_t rmode : rmodes) {
        for (int i = 0; i < random_count; i++) {
            uint32_t a = next_random(state);
            uint32_t b = next_random(state);
            for (uint8_t cmd : binary_ops) check(stats, fpu, cmd, rmode, a, b);
            for (uint8_t cmd : unary_ops)  check(stats, fpu, cmd, rmode, a & 0x7fffffff, 0);
        }
    }

    // FSQRT stratified by exponent parity, which is what the existing tests
    // never varied and what the seed defect depends on.
    printf("FSQRT parity sweep\n");
    for (uint8_t rmode : rmodes) {
        for (int exponent = -126; exponent <= 127; exponent++) {
            for (int i = 0; i < 32; i++) {
                uint32_t mantissa = next_random(state) & 0x007fffff;
                uint32_t a = ((uint32_t)(exponent + 127) << 23) | mantissa;
                check(stats, fpu, CMD_FSQRT, rmode, a, 0);
            }
        }
    }

    //-------------------------------------------------------
    // Report
    //-------------------------------------------------------
    printf("\n========================================\n");
    printf("checked %llu, matched %llu, mismatched %llu  (%llu cycles)\n",
           (unsigned long long)stats.checked,
           (unsigned long long)stats.matched,
           (unsigned long long)(stats.checked - stats.matched),
           (unsigned long long)fpu.cycle_count());

    int unexpected = 0;
    for (const auto &entry : stats.by_class) {
        bool known = !strict && is_known_bug(entry.first);
        printf("%-22s %10llu  %s\n", entry.first.c_str(),
               (unsigned long long)entry.second, known ? "(known)" : "UNEXPECTED");
        for (const std::string &example : stats.examples[entry.first])
            printf("    %s\n", example.c_str());
        if (!known) unexpected++;
    }

    if (unexpected == 0) {
        printf("\nPASS%s\n", strict ? " (strict)" : "");
        return 0;
    }
    printf("\nFAIL: %d unexpected defect class(es)\n", unexpected);
    return 1;
}
