//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : float.c
// Description : Floating Point Arithmetic Routine
//-----------------------------------------------------------
// History :
// Rev.01 2021.07.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#include <stdio.h>
#include <math.h>
#include "common.h"
#include "csr.h"
#include "float.h"
#include "gpio.h"
#include "uart.h"
#include "xprintf.h"

#define FPGA
//#define FLOAT_SOFT
//#define FLOAT_HARD

#define STRING(frn) #frn

//--------------------------------
// Read FRx
//--------------------------------
#define read_fr(frn)                         \
({                                           \
    unsigned long __tmp;                     \
    asm volatile ("fmv.x.w %0, " STRING(frn) \
        : "=r"(__tmp));                      \
    __tmp;                                   \
})

//--------------------------------
// Write FRx
//--------------------------------
#define write_fr(frn, val)                       \
({                                               \
    asm volatile ("fmv.w.x " STRING(frn) ", %0"  \
        :: "r"(val));                            \
})

//--------------------------------
// Read XRx
//--------------------------------
#define read_xr(xrn)                         \
({                                           \
    unsigned long __tmp;                     \
    asm volatile ("c.mv %0, " STRING(xrn)    \
        : "=r"(__tmp));                      \
    __tmp;                                   \
})

//--------------------------------
// Write XRx
//--------------------------------
#define write_xr(xrn, val)                       \
({                                               \
    asm volatile ("c.mv " STRING(xrn) ", %0"  \
        :: "r"(val));                            \
})

//-------------------------
// Check Float Number Type
//-------------------------
FTYPE check_ftype(float fdata)
{
    uint32_t fmt32 = fmt32_float(fdata);
    uint32_t sign = SIGN(fmt32);
    uint32_t expo = EXPO(fmt32);
    uint32_t frac = FRAC(fmt32);
    uint32_t fmsb = FMSB(fmt32);
    FTYPE result;
    //
         if ((sign == 0) && (expo == 0x00) && (frac == 0)) result = FT_POSZRO;
    else if ((sign == 1) && (expo == 0x00) && (frac == 0)) result = FT_NEGZRO;
    else if ((sign == 0) && (expo == 0xff) && (frac == 0)) result = FT_POSINF;
    else if ((sign == 1) && (expo == 0xff) && (frac == 0)) result = FT_NEGINF;
    else if ((sign == 0) && (expo == 0xff) && (frac != 0) && (fmsb == 1)) result = FT_POSQNA;
    else if ((sign == 1) && (expo == 0xff) && (frac != 0) && (fmsb == 1)) result = FT_NEGQNA;
    else if ((sign == 0) && (expo == 0xff) && (frac != 0) && (fmsb == 0)) result = FT_POSSNA;
    else if ((sign == 1) && (expo == 0xff) && (frac != 0) && (fmsb == 0)) result = FT_NEGSNA;
    else if ((sign == 0) && (expo == 0)) result = FT_POSSUB;
    else if ((sign == 1) && (expo == 0)) result = FT_NEGSUB;
    else if ((sign == 0)) result = FT_POSNOR;
    else if ((sign == 1)) result = FT_NEGNOR;
    else
    {
        printf("ERROR\n");
        exit(1);
    }
    return result;
}

//---------------------------
// 32bit Format from Float
//---------------------------
uint32_t fmt32_float(float fdata)
{
    float    *pfdata;
    uint32_t  fmt32;
    uint32_t *pfmt32;
    //
    pfdata = &fdata;
    pfmt32 = (uint32_t*) pfdata;
    fmt32  = *pfmt32;
    //
    return fmt32;
}

//--------------------------------------
// 32bit Format from Elements
//--------------------------------------
uint32_t fmt32_element(uint32_t sign, uint32_t expo, uint32_t frac)
{
    uint32_t  fmt32;
    //
    sign = sign & 0x01;
    expo = expo & 0x0ff;
    frac = frac & 0x007fffff;
    fmt32 = (sign << 31) + (expo << 23) + (frac << 0);
    //
    return fmt32;
}

//---------------------------
// Float from 32bit Format
//---------------------------
float float_fmt32(uint32_t fmt32)
{
    uint32_t *pfmt32;
    float     fdata;
    float    *pfdata;

    pfmt32 = &fmt32;
    pfdata = (float*) pfmt32;
    fdata  = *pfdata;
    //
    return fdata;
}

//----------------------------------
// Print Floating Point Format
//----------------------------------
void print_fmt(float fdata)
{
    uint32_t  fmt32;
    uint32_t  sign;
    uint32_t  exponent;
    uint32_t  fraction;

    fmt32 = fmt32_float(fdata);
    //
    sign = fmt32 >> 31;
    exponent = (fmt32 & 0x7fffffff) >> 23;
    fraction = fmt32 & 0x007fffff;
    //
    printf("----------------\n");
    printf("%f\n", fdata);
    printf("%08x\n", fmt32);
    printf("s=%01x\n", sign);
    printf("e=%02x=%d=%d\n", exponent, exponent, exponent-127);
    printf("f=%06x=%f\n", fraction, (float)(fraction+0x0800000)/(float)(0x0800000));
    printf("\n");
}

//----------------------------------
// Print Floating Point Data
//----------------------------------
void print_float(float fdata)
{
    FTYPE type = check_ftype(fdata);
    //
    if (type == FT_POSZRO)
        printf("PosZro");
    else if (type == FT_NEGZRO)
        printf("NegZro");
    else if (type == FT_POSINF)
        printf("PosInf");
    else if (type == FT_NEGINF)
        printf("NegInf");
    else if (type == FT_POSQNA)
        printf("PosQna");
    else if (type == FT_NEGQNA)
        printf("NegQna");
    else if (type == FT_POSSNA)
        printf("PosSna");
    else if (type == FT_NEGSNA)
        printf("NegSna");
    else if (type == FT_POSSUB)
        printf("PosSub(%f)", fdata);
    else if (type == FT_NEGSUB)
        printf("NegSub(%f)", fdata);
    else if (type == FT_POSNOR)
        printf("PosNor(%f)", fdata);
    else if (type == FT_NEGNOR)
        printf("NegNor(%f)", fdata);
    else
    {
        printf("ERROR\n");
        exit(1);
    }
}

//----------------------------
// Convert qNAN from sNAN
//----------------------------
float qnan_snan(float snan)
{
    uint32_t snan_fmt32;
    uint32_t qnan_fmt32;
    float    qnan;
    snan_fmt32 = fmt32_float(snan);
    qnan_fmt32 = snan_fmt32 | (1 << 22);
    qnan = float_fmt32(qnan_fmt32);
    return qnan;
}

//----------------------------
// Test Float
//----------------------------
// Format of Input Text File
// (1) Configuration Line
//     #<operation><round>
//        <operation> S: F32(1) to SI32(e)
//                    U: F32(1) to UI32(e)
//                    s: SI32(1) to F32(e)
//                    u: UI32(1) to F32(e)
//                    A: F32(e) = F32(1) + F32(2)
//                    B: F32(e) = F32(1) - F32(2)
//                    M: F32(e) = F32(1) * F32(2)
//                    D: F32(e) = F32(1) / F32(2)
//                    Q: F32(e) = sqrt(F32(1))
//                    N: F32(e) = F32(1) * F32(2) + F32(3)
//         <round> N:RNE Round to Nearest, tied to even
//                 Z:RTZ Round to Zero
//                 D:RDN Round Down towards minus infinite
//                 U:RUP Round Up towards plus infinite
//                 M:RMM Round to Nearest, ties to Max Magnitude
// (2) Input Data Line
//        1 operand : 11111111 eeeeeeee ff
//        2 operand : 11111111 22222222 eeeeeeee ff
//        3 operand : 11111111 22222222 33333333 eeeeeeee ff
//            nnnnnnnn:Input n
//            eeeeeeee:Output Data Expected
//            ff      :Output Flag Expected
//                bit 0   inexact exception
//                bit 1   underflow exception
//                bit 2   overflow exception
//                bit 3   infinite exception (“divide by zero”)
//                bit 4   invalid exception
// (3) Output Data Line
//        RRRRRRRR OK FF OK
//        RRRRRRRR NG FF OK
//        RRRRRRRR OK FF NG
//        RRRRRRRR NG FF NG
//            RRRRRRRR:Result Data
//            FF      :Result Flag
//
//
uint8_t Conv_Ascii2Hex4(uint8_t ch)
{
    ch = ((ch>='a') && (ch<='z'))? ch - 0x20 : ch;
    if ((ch >= '0') & (ch <= '9'))
        ch = ch - '0';
    else if ((ch >= 'A') & (ch <= 'F'))
        ch = ch - 'A' + 10;
    else
        ch = 0;
    return ch;
}
//
uint32_t Get_Hex(uint32_t bitlen, uint8_t first_ch)
{
    uint32_t i;
    uint32_t hex = 0;
    uint8_t  ch;
    //
    hex = (uint32_t) Conv_Ascii2Hex4(first_ch);
    for (i = 0; i < (bitlen / 4) -1; i++)
    {
        hex = hex << 4;
        while(Get_UART_RxD_Buffer_DC() == 0);
        ch = Get_UART_RxD_BUffer_Data();
        hex = hex + (uint32_t) Conv_Ascii2Hex4(ch);
    }
    return hex;
}
//
void Test_Float(void)
{
    uint8_t ch;
    uint8_t mode_round = 'N';
    uint8_t mode_operation = 'S';
    uint32_t input_count = 0;
    uint32_t input_data1 = 0;
    uint32_t input_data2 = 0;
    uint32_t input_data3 = 0;
    uint32_t input_expected_data = 0;
    uint32_t input_expected_flag = 0;
    uint32_t input_completed = 0;
    //
    // Forever Loop
    while(1)
    {
        // Parse Input Data
        while(1)
        {
            // Get a Character
            while(Get_UART_RxD_Buffer_DC() == 0);
            ch = Get_UART_RxD_BUffer_Data();
            //
            // Skip Delimiter
            if ((ch == ' ') || (ch == '\t') || (ch == '\r') || (ch == '\n'))
            {
                continue;
            }
            //
            // Configuration?
            else if (ch == '#')
            {
                while(Get_UART_RxD_Buffer_DC() == 0);
                ch = Get_UART_RxD_BUffer_Data();
                mode_operation = ch;
                while(Get_UART_RxD_Buffer_DC() == 0);
                ch = Get_UART_RxD_BUffer_Data();
                mode_round = ch;
                //
                printf("\n");
            }
            //
            // Dispatched by Operation
            else
            {
                switch(mode_operation)
                {
                    case 'S':
                    case 'U':
                    case 's':
                    case 'u':
                    case 'Q':
                    {
                        if (input_count == 0)
                        {
                            input_data1 = Get_Hex(32, ch);
                            input_count = input_count + 1;
                        }
                        else if (input_count == 1)
                        {
                            input_expected_data = Get_Hex(32, ch);
                            input_count = input_count + 1;
                        }
                        else
                        {
                            input_expected_flag = Get_Hex(8, ch);
                            input_count = 0;
                            input_completed = 1;
                        }
                        break;
                    }
                    //
                    case 'A':
                    case 'B':
                    case 'M':
                    case 'D':
                    {
                        if (input_count == 0)
                        {
                            input_data1 = Get_Hex(32, ch);
                            input_count = input_count + 1;
                        }
                        else if (input_count == 1)
                        {
                            input_data2 = Get_Hex(32, ch);
                            input_count = input_count + 1;
                        }
                        else if (input_count == 2)
                        {
                            input_expected_data = Get_Hex(32, ch);
                            input_count = input_count + 1;
                        }
                        else
                        {
                            input_expected_flag = Get_Hex(8, ch);
                            input_count = 0;
                            input_completed = 1;
                        }
                        break;
                    }
                    case 'N':
                    {
                        if (input_count == 0)
                        {
                            input_data1 = Get_Hex(32, ch);
                            input_count = input_count + 1;
                        }
                        else if (input_count == 1)
                        {
                            input_data2 = Get_Hex(32, ch);
                            input_count = input_count + 1;
                        }
                        else if (input_count == 2)
                        {
                            input_data3 = Get_Hex(32, ch);
                            input_count = input_count + 1;
                        }
                        else if (input_count == 3)
                        {
                            input_expected_data = Get_Hex(32, ch);
                            input_count = input_count + 1;
                        }
                        else
                        {
                            input_expected_flag = Get_Hex(8, ch);
                            input_count = 0;
                            input_completed = 1;
                        }
                        break;
                    }
                    default:
                    {
                        break;
                    }
                }
            }
            if (input_completed)
            {
                input_completed = 0;
                break;
            }
        }
        //
        // Set Rounding Mode
        uint32_t rmode;
        rmode = (mode_round == 'N')? 0x00
              : (mode_round == 'Z')? 0x01
              : (mode_round == 'D')? 0x02
              : (mode_round == 'U')? 0x03
              : (mode_round == 'M')? 0x04
              :                      0x00;
        write_csr(frm, rmode);
        //
        // Clear fflags
        write_csr(fflags, 0);
        //
        // Verify Floating
        switch(mode_operation)
        {
            case 'S':
            {
                float fin = float_fmt32(input_data1);
                write_fr(f20, input_data1);
                asm volatile ("fcvt.w.s x20, f20");
                uint32_t iout = read_xr(x20);
                uint32_t flag = read_csr(fflags);
                printf(" %08X ", iout);
                if (input_expected_data == iout) printf("OK"); else printf("NG");
                printf(" %02X ", flag);
                if (input_expected_flag == flag) printf("ok"); else printf("ng");
                break;
            }
            case 'U':
            {
                float fin = float_fmt32(input_data1);
                write_fr(f20, input_data1);
                asm volatile ("fcvt.wu.s x20, f20");
                uint32_t iout = read_xr(x20);
                uint32_t flag = read_csr(fflags);
                printf(" %08X ", iout);
                if (input_expected_data == iout) printf("OK"); else printf("NG");
                printf(" %02X ", flag);
                if (input_expected_flag == flag) printf("ok"); else printf("ng");
                break;
            }
            case 's':
            {
                float iin = float_fmt32(input_data1);
                write_xr(x20, input_data1);
                asm volatile ("fcvt.s.w f20, x20");
                uint32_t fout = read_fr(f20);
                uint32_t flag = read_csr(fflags);
                printf(" %08X ", fout);
                if (input_expected_data == fout) printf("OK"); else printf("NG");
                printf(" %02X ", flag);
                if (input_expected_flag == flag) printf("ok"); else printf("ng");
                break;
            }
            case 'u':
            {
                float iin = float_fmt32(input_data1);
                write_xr(x20, input_data1);
                asm volatile ("fcvt.s.wu f20, x20");
                uint32_t fout = read_fr(f20);
                uint32_t flag = read_csr(fflags);
                printf(" %08X ", fout);
                if (input_expected_data == fout) printf("OK"); else printf("NG");
                printf(" %02X ", flag);
                if (input_expected_flag == flag) printf("ok"); else printf("ng");
                break;
            }
            case 'A':
            {
                float fin1 = float_fmt32(input_data1);
                float fin2 = float_fmt32(input_data2);
                write_fr(f20, input_data1);
                write_fr(f21, input_data2);
                asm volatile ("fadd.s f22, f20, f21");
                uint32_t fout = read_fr(f22);
                uint32_t flag = read_csr(fflags);
                printf(" %08X ", fout);
                if (input_expected_data == fout) printf("OK"); else printf("NG");
                printf(" %02X ", flag);
                if (input_expected_flag == flag) printf("ok"); else printf("ng");
                break;
            }
            case 'B':
            {
                float fin1 = float_fmt32(input_data1);
                float fin2 = float_fmt32(input_data2);
                write_fr(f20, input_data1);
                write_fr(f21, input_data2);
                asm volatile ("fsub.s f22, f20, f21");
                uint32_t fout = read_fr(f22);
                uint32_t flag = read_csr(fflags);
                printf(" %08X ", fout);
                if (input_expected_data == fout) printf("OK"); else printf("NG");
                printf(" %02X ", flag);
                if (input_expected_flag == flag) printf("ok"); else printf("ng");
                break;
            }
            case 'M':
            {
                float fin1 = float_fmt32(input_data1);
                float fin2 = float_fmt32(input_data2);
                write_xr(x20, input_data1);
                write_xr(x21, input_data2);
                asm volatile ("fmv.w.x f20, x20");
                asm volatile ("fmv.w.x f21, x21");
                asm volatile ("fmul.s  f22, f20, f21");
                asm volatile ("fmv.x.w x22, f22");
                uint32_t fout = read_xr(x22);
                uint32_t flag = read_csr(fflags);
                printf(" %08X ", fout);
                if (input_expected_data == fout) printf("OK"); else printf("NG");
                printf(" %02X ", flag);
                if (input_expected_flag == flag) printf("ok"); else printf("ng");
                break;
            }
            case 'D':
            {
                write_csr(0xbe0, 0x0f); // FCONV
                float fin1 = float_fmt32(input_data1);
                float fin2 = float_fmt32(input_data2);
                write_xr(x20, input_data1);
                write_xr(x21, input_data2);
                asm volatile ("fmv.w.x f20, x20");
                asm volatile ("fmv.w.x f21, x21");
                asm volatile ("fdiv.s  f22, f20, f21");
                asm volatile ("fmv.x.w x22, f22");
                uint32_t fout = read_xr(x22);
                uint32_t flag = read_csr(fflags);
                printf(" %08X ", fout);
                if (input_expected_data == fout) printf("OK"); else printf("NG");
                printf(" %02X ", flag);
                if (input_expected_flag == flag) printf("ok"); else printf("ng");
                break;
            }
            case 'Q':
            {
                write_csr(0xbe0, 0x0f); // FCONV
                float fin1 = float_fmt32(input_data1);
                write_xr(x20, input_data1);
                asm volatile ("fmv.w.x f20, x20");
                asm volatile ("fsqrt.s f21, f20");
                asm volatile ("fmv.x.w x21, f21");
                uint32_t fout = read_xr(x21);
                uint32_t flag = read_csr(fflags);
                printf(" %08X ", fout);
                if (input_expected_data == fout) printf("OK"); else printf("NG");
                printf(" %02X ", flag);
                if (input_expected_flag == flag) printf("ok"); else printf("ng");
                break;
            }
            case 'N':
            {
                float fin1 = float_fmt32(input_data1);
                float fin2 = float_fmt32(input_data2);
                float fin3 = float_fmt32(input_data3);
                write_xr(x20, input_data1);
                write_xr(x21, input_data2);
                write_xr(x22, input_data3);
                asm volatile ("fmv.w.x f20, x20");
                asm volatile ("fmv.w.x f21, x21");
                asm volatile ("fmv.w.x f22, x22");
                asm volatile ("fmadd.s f23, f20, f21, f22");
                asm volatile ("fmv.x.w x23, f23");
                uint32_t fout = read_xr(x23);
                uint32_t flag = read_csr(fflags);
                printf(" %08X ", fout);
                if (input_expected_data == fout) printf("OK"); else printf("NG");
                printf(" %02X ", flag);
                if (input_expected_flag == flag) printf("ok"); else printf("ng");
                break;
            }
            default:
            {
                break;
            }
        }
        printf("\n");
        //        <operation> S: F32(1) to SI32(e)
        //                    U: F32(1) to UI32(e)
        //                    s: SI32(1) to F32(e)
        //                    u: UI32(1) to F32(e)
        //                    A: F32(e) = F32(1) + F32(2)
        //                    B: F32(e) = F32(1) - F32(2)
        //                    M: F32(e) = F32(1) * F32(2)
        //                    D: F32(e) = F32(1) / F32(2)
        //                    Q: F32(e) = sqrt(F32(1))
        //                    N: F32(e) = F32(1) * F32(2) + F32(3)
    }
}

//-------------------------
// Test Loop Float
//-------------------------
void Test_Loop_Float(void)
{
    int as, ae, af;
    int bs, be, bf;
    uint32_t aexpo, bexpo;
    uint32_t afrac, bfrac;
    uint32_t fa_fmt32, fb_fmt32;
    int quit = 0;
    uint32_t count = 0;
    const uint32_t expo_data[8] =
    {
        0, 1, 2, 126, 127, 128, 254, 255
    };
    const uint32_t frac_data[16] =
    {
        0x00000000, 0x00000001, 0x00000004, 0x00000010,
        0x00020000, 0x00040000, 0x00100000, 0x00400000,
        0xffffffff, 0xfffffffe, 0xfffffff8, 0xffffffe0,
        0xfffff800, 0xffffe000, 0xffff8000, 0xffe00000
    };
    //
    for (as = 0; as < 2; as++)
    {
        for (ae = 0; ae < 8; ae++)
        {
            aexpo = expo_data[ae];
            //
            for (af = 0; af < 16; af++)
            {
                afrac = frac_data[af];
                //
                fa_fmt32 = fmt32_element(as, aexpo, afrac);
                //
                for (bs = 0; bs < 2; bs++)
                {
                    for (be = 0; be < 8; be++)
                    {
                        bexpo = expo_data[be];
                        //
                        for (bf = 0; bf < 16; bf++)
                        {
                            bfrac = frac_data[bf];
                            //
                            fb_fmt32 = fmt32_element(bs, bexpo, bfrac);
#ifdef FLOAT_SOFT
                            float fa = float_fmt32(fa_fmt32);
                            float fb = float_fmt32(fb_fmt32);
                          //float fc = fa + fb;
                          //float fc = fa - fb;
                          //float fc = fa * fb;
                            float fc = fa / fb;
                            uint32_t fc_fmt32 = fmt32_float(fc);
#endif
#ifdef FLOAT_HARD
                            write_fr(f1, fa_fmt32);
                            write_fr(f2, fb_fmt32);
                          //asm volatile ("fadd.s f3, f1, f2");
                          //asm volatile ("fsub.s f3, f1, f2");
                          //asm volatile ("fmul.s f3, f1, f2");
                            asm volatile ("fdiv.s f3, f1, f2");
                            uint32_t fc_fmt32 = read_fr(f3);
#endif
                            mem_wr32(0xffffffe0, count);
                            mem_wr32(0xffffffe4, fa_fmt32);
                            mem_wr32(0xffffffe8, fb_fmt32);
                            mem_wr32(0xffffffec, fc_fmt32);
                            #ifdef FPGA
                            printf("%08x " , count);
                            printf("%08x " , fa_fmt32);
                            printf("%08x " , fb_fmt32);
                            printf("%08x\n", fc_fmt32);
                            #endif
                            //
                            GPIO_SetSEG(count);
                            count++;
                        }
                    }
                }
            }
        }
    }
}

//-------------------------
// Test Loop FSQRT
//-------------------------
void Test_Loop_FSQRT(void)
{
    int bs, be, bf;
    uint32_t bexpo;
    uint32_t bfrac;
    uint32_t fb_fmt32;
    int quit = 0;
    uint32_t count = 0;
    const uint32_t expo_data[8] =
    {
        0, 1, 2, 126, 127, 128, 254, 255
    };
    const uint32_t frac_data[16] =
    {
        0x00000000, 0x00000001, 0x00000004, 0x00000010,
        0x00020000, 0x00040000, 0x00100000, 0x00400000,
        0xffffffff, 0xfffffffe, 0xfffffff8, 0xffffffe0,
        0xfffff800, 0xffffe000, 0xffff8000, 0xffe00000
    };
    //
    for (bs = 0; bs < 2; bs++)
    {
        for (be = 0; be < 8; be++)
        {
            bexpo = expo_data[be];
            //
            for (bf = 0; bf < 16; bf++)
            {
                bfrac = frac_data[bf];
                //
                fb_fmt32 = fmt32_element(bs, bexpo, bfrac);
#ifdef FLOAT_SOFT
                float fb = float_fmt32(fb_fmt32);
                float fc = sqrtf(fb);
                uint32_t fc_fmt32 = fmt32_float(fc);
#endif
#ifdef FLOAT_HARD
                write_fr(f2, fb_fmt32);
                asm volatile ("fsqrt.s f3, f2");
                uint32_t fc_fmt32 = read_fr(f3);
#endif
                mem_wr32(0xffffffe0, count);
                mem_wr32(0xffffffe4, fb_fmt32);
                mem_wr32(0xffffffe8, fb_fmt32);
                mem_wr32(0xffffffec, fc_fmt32);
#ifdef FPGA
                printf("%08x " , count);
                printf("%08x " , fb_fmt32);
                printf("%08x " , fb_fmt32);
                printf("%08x\n", fc_fmt32);
#endif
                //
                GPIO_SetSEG(count);
                count++;
            }
        }
    }
}

//----------------------------
// Test Floating Operation
//----------------------------
void Test_Floating_Operation(uint32_t rmode)
{
    uint32_t i;

    // Set Round Mode
    write_csr(frm, rmode);
    //
    // Set Test Data
    const uint32_t fmt32_in[] =
    {
         0x8683F7FF, // -4.96411206955e-35
         0x3D9B6F91, // 0.075896389782428741455078125
         0xCE7C0007, // -1056965056
         0x4f000000, //  2147483648
         0xcf000000, // -2147483648
         //
         0xbe804000, // -0.25048828125
         0xbe804080, // -0.250492095947
         0xbe000000, // -0.125
         0xbc800000, // -0.015625
         0xbd800000, // -0.0625
         0xbd000000, // -0.03125
         //
         0x3e620010, // 0.220703363419
         0x0f000000, // 6.31088724177e-30
         0x0f800000, // 1.26217744835e-29
         0x3e800000, // 0.25
         0x03800000, // 7.52316384526e-37
         0x3d2daba0, // 0.0424000024796
         //
         0x3effffff, // 0.499999970198
         0x3f000000, // 0.5
         0x3f000001, // 0.500000059605
         0xbeffffff, // -0.499999970198
         0xbf000000, // -0.5
         0xbf000001  // -0.500000059605
    };
    //
    // Convert to Integer
  //printf("\n\n");
    //
    for (i = 0; i < sizeof(fmt32_in)/4; i++)
    {
        float fin = float_fmt32(fmt32_in[i]);
        //
        write_fr(f20, fmt32_in[i]);
      //asm volatile ("fcvt.w.s x20, f20");
        asm volatile ("fcvt.wu.s x20, f20");
        uint32_t iout = read_xr(x20);
        //
      //printf("Input=0x%08x, %f; Output=0x%08x\n", fmt32_in, fin, iout);
    }
    //
  //printf("\n\n");
}



//--------------------------
// Floating Main
//--------------------------
void main_floating(void)
{
#if 1
    Test_Float();
#endif

#if 0
    Test_Floating_Operation(RMODE_RNE);
    Test_Floating_Operation(RMODE_RTZ);
    Test_Floating_Operation(RMODE_RDN);
    Test_Floating_Operation(RMODE_RUP);
    Test_Floating_Operation(RMODE_RMM);
#endif

#if 0
    Test_Loop_Float();
#endif
#if 0
    write_csr(0xbe0, 0x00000004); // fpu32conv
    Test_Loop_FSQRT();
#endif

#if 0
    uint32_t i;
    uint32_t fdata_fmt32[16];
    fdata_fmt32[0] = fmt32_element(0, 0x7f, 0x000000); // +1.0
    fdata_fmt32[1] = fmt32_element(1, 0x7f, 0x000000); // -1.0
    fdata_fmt32[2] = fmt32_element(0, 0x01, 0x000001); // Normal
    fdata_fmt32[3] = fmt32_element(0, 0xfe, 0x7fffff); // Normal
    fdata_fmt32[4] = fmt32_element(0, 0x10, 0x7edcba); // Normal
    fdata_fmt32[5] = fmt32_element(0, 0xe0, 0x012345); // Normal
    fdata_fmt32[6] = fmt32_element(0, 0x00, 0x7fffff); // Subnormal
    fdata_fmt32[7] = fmt32_element(0, 0x00, 0x000001); // Subnormal
    //
  //uint32_t fdata1_fmt32 = 0x3f800000; // 1.0
  //uint32_t fdata2_fmt32 = 0x42f60000; // 123.0
  //uint32_t fdata1_fmt32 = 0x00000001; // subnormal
  //uint32_t fdata2_fmt32 = 0x80000001; // subnormal
  //uint32_t fdata1_fmt32 = 0x7f7fffff; // Max
  //uint32_t fdata2_fmt32 = 0xff7ffffe; // 1.0
    //
    uint32_t fdata1_fmt32 = 0x3f800000; // 1.0
    uint32_t fdata2_fmt32 = 0x40000000; // 2.0
    uint32_t fdata3_fmt32 = 0x42f60000; // 123.0
    write_fr(f1, fdata1_fmt32);
    write_fr(f2, fdata2_fmt32);
    write_fr(f3, fdata3_fmt32);
    //
    uint32_t mstatus_val = read_csr(mstatus);
    mstatus_val = (mstatus_val & ~0x00006000) | 0x00004000;
    write_csr(mstatus, mstatus_val); // clear FS to intial
    //
    asm volatile ("fadd.s f4, f3, f2"); // 125 = 0x42fa0000
    asm volatile ("fsub.s f5, f3, f2"); // 121 = 0x42f20000
    asm volatile ("fmul.s f6, f3, f2"); // 246 = 0x43760000
    asm volatile ("fmadd.s f7, f3, f2, f1"); // 247 = 0x43770000
    asm volatile ("fmsub.s f8, f3, f2, f1"); // 245 = 0x43750000
    asm volatile ("fnmadd.s f9, f3, f2, f1"); // -247 = 0xc3770000
    asm volatile ("fnmsub.s f10, f3, f2, f1"); // -245 = 0xc3750000
    asm volatile ("fadd.s f11, f2, f1"); // 3.0 = 0x40400000
    volatile uint32_t fdataA_fmt32 = read_fr(f11);
    //
    asm volatile ("fadd.s f4, f2, f1"); // 3.0 = 0x40400000
    asm volatile ("fsub.s f5, f4, f3"); // -120 = 0xc2f00000
    asm volatile ("fmul.s f6, f5, f4"); // -360 = 0xc3b40000
    asm volatile ("fmadd.s f7, f6, f5, f4"); // 43203 = 0x4728c300
    asm volatile ("fmsub.s f8, f7, f6, f5"); // -15552960 = 0xcb6d51c0
    asm volatile ("fnmadd.s f9, f8, f7, f6"); // 671934530520 = 0x531c726b
    asm volatile ("fnmsub.s f10, f9, f8, f7"); // 1.045057088E+19 = 0x5f1107e3
    asm volatile ("fadd.s f11, f10, f9"); // 1.045057155E+19 = 0x5f1107e4
    volatile uint32_t fdataB_fmt32 = read_fr(f11);
    //
    uint32_t fdata12_fmt32 = 0x00000000; // ZERO
    uint32_t fdata13_fmt32 = 0x7fc00000; // QNAN
    uint32_t fdata14_fmt32 = 0x7f800001; // SNAN
    uint32_t fdata15_fmt32 = 0x7f800000; // INF
    write_fr(f12, fdata12_fmt32);
    write_fr(f13, fdata13_fmt32);
    write_fr(f14, fdata14_fmt32);
    write_fr(f15, fdata15_fmt32);
    asm volatile ("fadd.s f16, f12, f1 "); // +1.0
    asm volatile ("fsub.s f17, f12, f1 "); // -1.0
    asm volatile ("fadd.s f18, f12, f13"); // +QNAN
    asm volatile ("fsub.s f19, f12, f14"); // -QNAN
    asm volatile ("fmul.s f20, f15, f17"); // -INF
    asm volatile ("fmadd.s f21, f3, f2, f12"); // +246
    asm volatile ("fmsub.s f22, f3, f2, f15"); // -INF
    asm volatile ("fnmadd.s f23, f15, f2, f12"); // -INF
    asm volatile ("fnmsub.s f24, f15, f2, f1 "); // -INF
    volatile uint32_t fdataC_fmt32 = read_fr(f24);
    //
    uint32_t fdata25_fmt32 = 0x3f800000; // 1.0
    uint32_t fdata26_fmt32 = 0x40000000; // 2.0
    uint32_t fdata27_fmt32 = 0x40490fdb; // 3.1415926536
    uint32_t fdata28_fmt32 = 0x439d1463; // 314.15926536
    write_fr(f25, fdata25_fmt32);
    write_fr(f26, fdata26_fmt32);
    write_fr(f27, fdata27_fmt32);
    write_fr(f28, fdata28_fmt32);
    asm volatile ("fdiv.s f29, f25, f27 "); // 0.318309886 0x3ea2f983
    asm volatile ("fdiv.s f30, f26, f28 "); // 0.006366198 0x3bd09b8a
    volatile uint32_t fdataD_fmt32 = read_fr(f30);
    //
    asm volatile ("fdiv.s f29, f13, f14"); // QNAN
    asm volatile ("fdiv.s f30, f25, f12"); // DIVZRO
    volatile uint32_t fdataE_fmt32 = read_fr(f30);
    //
    asm volatile ("fadd.s f18, f12, f14"); // +QNAN = ZERO+SNAN
    //
    write_csr(0xbe0, 0x00000044); // fpu32conv
    uint32_t fdataX1_fmt32 = 0x007fffff; // 1.17549421069e-38
    uint32_t fdataX2_fmt32 = 0x40000000; // 2.0
    write_fr(f1, fdataX1_fmt32);
    write_fr(f2, fdataX2_fmt32);
    asm volatile ("fdiv.s f3, f1, f2"); // 5.87747175411e-39 0x00400000
    volatile uint32_t fdataX3_fmt32 = read_fr(f3);
    //
    uint32_t fdataS1_fmt32 = 0x3f800000; // 1.0
    uint32_t fdataS3_fmt32 = 0x40000000; // 2.0
    uint32_t fdataS5_fmt32 = 0x42c80000; // 100.0
    write_fr(f1, fdataS1_fmt32);
    write_fr(f3, fdataS3_fmt32);
    write_fr(f5, fdataS5_fmt32);
    asm volatile ("fsqrt.s f2, f1");
    asm volatile ("fsqrt.s f4, f3");
    asm volatile ("fsqrt.s f6, f5");
    volatile uint32_t fdataS2_fmt32 = read_fr(f2);
    volatile uint32_t fdataS4_fmt32 = read_fr(f4);
    volatile uint32_t fdataS6_fmt32 = read_fr(f6);
    //
    uint32_t fdataA1_fmt32 = 0x3f800000; // 1.0
    uint32_t fdataA2_fmt32 = 0x40000000; // 2.0
    uint32_t fdataA3_fmt32 = 0x40400000; // 3.0
    uint32_t fdataA4_fmt32 = 0x40800000; // 4.0
    uint32_t fdataA5_fmt32 = 0x40a00000; // 5.0
    uint32_t fdataA6_fmt32 = 0x40c00000; // 6.0
    uint32_t fdataA7_fmt32 = 0x40e00000; // 7.0
    uint32_t fdataA8_fmt32 = 0x41000000; // 8.0
    write_fr(f1, fdataA1_fmt32);
    write_fr(f2, fdataA2_fmt32);
    write_fr(f3, fdataA3_fmt32);
    write_fr(f4, fdataA4_fmt32);
    write_fr(f5, fdataA5_fmt32);
    write_fr(f6, fdataA6_fmt32);
    write_fr(f7, fdataA7_fmt32);
    write_fr(f8, fdataA8_fmt32);
    asm volatile ("fadd.s f10, f1, f2");
    asm volatile ("fmul.s f11, f3, f4");
    asm volatile ("fadd.s f12, f5, f6");
    asm volatile ("fmul.s f13, f7, f8");
    //
    asm volatile ("fadd.s f10, f1, f13");
    asm volatile ("fmul.s f11, f3, f10");
    asm volatile ("fadd.s f12, f5, f11");
    asm volatile ("fmul.s f13, f7, f12");
    //
    asm volatile ("fadd.s f14, f1, f2");
    asm volatile ("fdiv.s f15, f1, f2");
    asm volatile ("fmul.s f16, f1, f2");
    //
    asm volatile ("fmul.s f17, f1 , f2");
    asm volatile ("fdiv.s f18, f17, f2");
    asm volatile ("fadd.s f19, f18, f2");
    //
    asm volatile ("fadd.s  f20, f1, f2");
    asm volatile ("fsqrt.s f21, f2");
    asm volatile ("fmul.s  f22, f1, f2");
    //
    asm volatile ("fmul.s  f23, f1 , f2");
    asm volatile ("fsqrt.s f24, f23");
    asm volatile ("fadd.s  f25, f24, f2");
    //
    asm volatile ("fadd.s  f26, f1, f2");
    asm volatile ("fmadd.s f27, f1, f2, f3");
    asm volatile ("fsub.s  f28, f4, f5");
    //
    asm volatile ("fadd.s  f26, f6,  f7");
    asm volatile ("fmadd.s f27, f26, f1, f2");
    asm volatile ("fmul.s  f28, f3,  f27");
    //
    asm volatile ("fmadd.s f10, f1, f2, f3");
    asm volatile ("fdiv.s  f11, f4, f5");
    asm volatile ("fmsub.s f12, f6, f7, f8");
    //
    asm volatile ("fmadd.s f13, f1,  f2, f3");
    asm volatile ("fdiv.s  f14, f13, f5");
    asm volatile ("fmsub.s f15, f14, f7, f8");
    //
    uint32_t iA, *piA;
    float    fA, *pfA;
    iA  = 0x3f800000;
    piA = &iA;
    pfA = (float*) piA;
    fA  = *pfA;
    //
    uint32_t iB, *piB;
    float    fB, *pfB;
    iB  = 0x40000000;
    piB = &iB;
    pfB = (float*) piB;
    fB  = *pfB;
    //
    float fC;
    fC = fA + fB;
    //
    write_csr(fcsr, 0x000000000);
    uint32_t fdataM1_fmt32 = 0x3f800000; // +1.0
    uint32_t fdataM2_fmt32 = 0x40000000; // +2.0
    uint32_t fdataM3_fmt32 = 0xbf800000; // -1.0
    uint32_t fdataM4_fmt32 = 0xc0000000; // -2.0
    uint32_t fdataM5_fmt32 = 0x00000000; // +0.0
    uint32_t fdataM6_fmt32 = 0x80000000; // -0.0
    uint32_t fdataM7_fmt32 = 0x7fc00000; // qnan
    uint32_t fdataM8_fmt32 = 0x7f800001; // snan
    write_fr(f1, fdataM1_fmt32);
    write_fr(f2, fdataM2_fmt32);
    write_fr(f3, fdataM3_fmt32);
    write_fr(f4, fdataM4_fmt32);
    write_fr(f5, fdataM5_fmt32);
    write_fr(f6, fdataM6_fmt32);
    write_fr(f7, fdataM7_fmt32);
    write_fr(f8, fdataM8_fmt32);
    asm volatile ("fmax.s f9, f1, f2"); // 0x40000000
    asm volatile ("fmin.s f9, f1, f2"); // 0x3f800000
    asm volatile ("fmax.s f9, f2, f3"); // 0x40000000
    asm volatile ("fmin.s f9, f2, f3"); // 0xbf800000
    asm volatile ("fmin.s f9, f3, f4"); // 0xc0000000
    asm volatile ("fmax.s f9, f3, f4"); // 0xbf800000
    asm volatile ("fmax.s f9, f1, f7"); // 0x3f800000
    asm volatile ("fmin.s f9, f2, f7"); // 0x40000000
    asm volatile ("fmax.s f9, f7, f7"); // 0x7fc00000
    asm volatile ("fmax.s f9, f4, f8"); // 0xc0000000
    asm volatile ("fmin.s f9, f7, f7"); // 0x7fc00000
    asm volatile ("fmin.s f9, f4, f8"); // 0xc0000000
    //
    asm volatile ("fcvt.w.s x1, f1");
    asm volatile ("fcvt.w.s x1, f2");
    asm volatile ("fcvt.w.s x1, f3");
    asm volatile ("fcvt.w.s x1, f4");
    asm volatile ("fcvt.w.s x1, f5");
    asm volatile ("fcvt.w.s x1, f6");
    uint32_t fdataC1_fmt32 = fmt32_element(0, 127, 0); //+1.0
    uint32_t fdataC2_fmt32 = fmt32_element(1, 127, 0); //-1.0
    uint32_t fdataC3_fmt32 = fmt32_element(0, 157, 0x7fffff); //0x7fffffff
    uint32_t fdataC4_fmt32 = fmt32_element(1, 157, 0x7fffff); //0x7fffffff
    write_fr(f11, fdataC1_fmt32);
    write_fr(f12, fdataC2_fmt32);
    write_fr(f13, fdataC3_fmt32);
    write_fr(f14, fdataC4_fmt32);
    asm volatile ("fcvt.w.s x11, f11");
    asm volatile ("fcvt.w.s x12, f12");
    asm volatile ("fcvt.w.s x13, f13");
    asm volatile ("fcvt.w.s x14, f14");
    asm volatile ("fcvt.wu.s x11, f11");
    asm volatile ("fcvt.wu.s x12, f12");
    asm volatile ("fcvt.wu.s x13, f13");
    asm volatile ("fcvt.wu.s x14, f14");
    int32_t intA1 = 0x00000000;
    int32_t intA2 = 0x00000001;
    int32_t intA3 = 0xffffffff;
    int32_t intA4 = 0x7fffffff;
    int32_t intA5 = 0x80000000;
    float floatA1 = (float)intA1;
    float floatA2 = (float)intA2;
    float floatA3 = (float)intA3;
    float floatA4 = (float)intA4;
    float floatA5 = (float)intA5;
    //
    uint32_t fdataJ0_fmt32 = 0xc2f60000; // -123.0
    uint32_t fdataJ1_fmt32 = fmt32_element(0, 127, 0); //+1.0
    uint32_t fdataJ2_fmt32 = fmt32_element(1, 127, 0); //-1.0
    write_fr(f0, fdataJ0_fmt32);
    write_fr(f1, fdataJ1_fmt32);
    write_fr(f2, fdataJ2_fmt32);
    asm volatile ("fsgnj.s  f3, f0, f1"); // 42f60000
    asm volatile ("fsgnj.s  f4, f0, f2"); // c2f60000
    asm volatile ("fsgnjn.s f5, f0, f1"); // c2f60000
    asm volatile ("fsgnjn.s f6, f0, f2"); // 42f60000
    asm volatile ("fsgnjx.s f7, f0, f1"); // c2f60000
    asm volatile ("fsgnjx.s f8, f0, f2"); // 42f60000
    //
    uint32_t fdataP0_fmt32 = 0xc0000000; // -2.0
    uint32_t fdataP1_fmt32 = 0xbf800000; // -1.0
    uint32_t fdataP2_fmt32 = 0x3f800000; // +1.0
    uint32_t fdataP3_fmt32 = 0x40000000; // +2.0
    write_fr(f0, fdataP0_fmt32);
    write_fr(f1, fdataP1_fmt32);
    write_fr(f2, fdataP2_fmt32);
    write_fr(f3, fdataP3_fmt32);
    asm volatile ("feq.s  x1, f0, f0"); // 1
    asm volatile ("feq.s  x1, f0, f1"); // 0
    asm volatile ("flt.s  x1, f0, f1"); // 1
    asm volatile ("flt.s  x1, f3, f2"); // 0
    asm volatile ("fle.s  x1, f2, f3"); // 1
    asm volatile ("fle.s  x1, f1, f0"); // 0
    asm volatile ("fle.s  x1, f1, f1"); // 1
    asm volatile ("fle.s  x1, f3, f0"); // 0
    //
    uint32_t fdataT0_fmt32 = 0xff800000; // NEGINF
    uint32_t fdataT1_fmt32 = 0xc0490fdb; // NEGNOR
    uint32_t fdataT2_fmt32 = 0x8000ffff; // NEGSUB
    uint32_t fdataT3_fmt32 = 0x80000000; // NEGZRO
    uint32_t fdataT4_fmt32 = 0x00000000; // POSZRO
    uint32_t fdataT5_fmt32 = 0x0000ffff; // POSSUB
    uint32_t fdataT6_fmt32 = 0x40490fdb; // POSNOR
    uint32_t fdataT7_fmt32 = 0x7f800000; // POSINF
    uint32_t fdataT8_fmt32 = 0x7f800001; // POSSNA
    uint32_t fdataT9_fmt32 = 0x7fc00000; // POSQNA
    uint32_t fdataTA_fmt32 = 0xff800001; // NEGSNA
    uint32_t fdataTB_fmt32 = 0xffc00000; // NEGQNA
    write_fr(f0 , fdataT0_fmt32);
    write_fr(f1 , fdataT1_fmt32);
    write_fr(f2 , fdataT2_fmt32);
    write_fr(f3 , fdataT3_fmt32);
    write_fr(f4 , fdataT4_fmt32);
    write_fr(f5 , fdataT5_fmt32);
    write_fr(f6 , fdataT6_fmt32);
    write_fr(f7 , fdataT7_fmt32);
    write_fr(f8 , fdataT8_fmt32);
    write_fr(f9 , fdataT9_fmt32);
    write_fr(f10, fdataTA_fmt32);
    write_fr(f11, fdataTB_fmt32);
    asm volatile ("fclass.s  x31, f0 ");
    asm volatile ("fclass.s  x31, f1 ");
    asm volatile ("fclass.s  x31, f2 ");
    asm volatile ("fclass.s  x31, f3 ");
    asm volatile ("fclass.s  x31, f4 ");
    asm volatile ("fclass.s  x31, f5 ");
    asm volatile ("fclass.s  x31, f6 ");
    asm volatile ("fclass.s  x31, f7 ");
    asm volatile ("fclass.s  x31, f8 ");
    asm volatile ("fclass.s  x31, f9 ");
    asm volatile ("fclass.s  x31, f10");
    asm volatile ("fclass.s  x31, f11");
    //
    #endif

#if 0
    uint32_t fflags;
    float f1, f2, f3;
    //
    f1 = 3.14159265;
    f2 = 2.71828182;
    f3 = f1 / f2; // 1.1557273520668288
    fflags = read_csr(fflags);
    write_csr(fflags, 0);
    //
    f1 = -1234.0;
    f2 = 1235.1;
    f3 = f1 / f2; // -0.9991093838555584
    fflags = read_csr(fflags);
    write_csr(fflags, 0);
    //
    f1 = 3.14159265;
    f2 = 1.0 ;
    f3 = f1 / f2; // 3.14159265
    fflags = read_csr(fflags);
    write_csr(fflags, 0);
    //
    f1 = 3.14159265;
    f2 = sqrtf(f1); // 1.7724538498928541
    fflags = read_csr(fflags);
    write_csr(fflags, 0);
    //
    f1 = 10000.0;
    f2 = sqrtf(f1); // 100
    fflags = read_csr(fflags);
    write_csr(fflags, 0);
    //
    f1 = -1.0;
    f2 = sqrtf(f1); // 0x7FC00000
    fflags = read_csr(fflags);
    write_csr(fflags, 0);
    //
    f1 = 171.0;
    f2 = sqrtf(f1); // 13.076696
    fflags = read_csr(fflags);
    write_csr(fflags, 0);
#endif

#if 0
    uint32_t i;
    uint32_t bcd1000, bcd100, bcd10, bcd1, bcd;
    uint64_t cyclel, cycleh, cycle_prev, cycle_now;
    printf("======== Calculate SIN() ========\n");
    while(1)
    {
        for (i = 0; i < 360; i++)
        {
            float fth  = 2 * M_PI / 360.0 * (float)i;
            float fsin = sinf(fth);
            float    fsin_disp = fsin  * 10000.0;
            int32_t  isin_disp = (int32_t) fsin_disp;
            GPIO_SetSEG_SignedDecimal(isin_disp);
            //
            cyclel = (uint64_t) read_csr(mcycle);
            cycleh = (uint64_t) read_csr(mcycleh);
            cycle_prev = (cycleh << 32) + (cyclel);
            while (1)
            {
                cyclel = (uint64_t) read_csr(mcycle);
                cycleh = (uint64_t) read_csr(mcycleh);
                cycle_now = (cycleh << 32) + (cyclel);
                if (cycle_now >= cycle_prev + 1666666) break;
            }
        }
    }
#endif
}

//===========================================================
// End of Program
//===========================================================
