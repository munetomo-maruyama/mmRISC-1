//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : float.h
// Description : Floating Point Arithmetic Header
//-----------------------------------------------------------
// History :
// Rev.01 2021.07.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================

#ifndef FLOAT_H_
#define FLOAT_H_

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "common.h"

//-------------------------
// Special Numbers
//-------------------------
typedef enum FTYPE
{
    FT_POSNOR, // Positive Normal
    FT_NEGNOR, // Negative Normal
    FT_POSSUB, // Positive Subnormal
    FT_NEGSUB, // Negative Subnormal
    FT_POSINF, // Positive Infinite
    FT_NEGINF, // Negative Infinite
    FT_POSZRO, // Positive Zero
    FT_NEGZRO, // Negative Zero
    FT_POSQNA, // Positive Quiet NaN (Canonical NaN)
    FT_NEGQNA, // Negative Quiet NaN
    FT_POSSNA, // Positive Signal Nan
    FT_NEGSNA  // Negative Signal Nan
} FTYPE;

//-------------------------
// Rounding Mode
//-------------------------
typedef enum RMODE
{
    RMODE_RNE, // Round to Nearest, ties to Even
    RMODE_RTZ, // Round towards Zero
    RMODE_RDN, // Round Down (towards -infinite)
    RMODE_RUP, // Round Up   (towards +infinite)
    RMODE_RMM  // Round to Nearest, ties to Max Magitude
} RMODE;

//-------------------
// Exception Flags
//-------------------
#define FLAG_OK 0x00 //FLAG_OK
#define FLAG_NV 0x10 //Invalid Operation
#define FLAG_DZ 0x08 //Divide by Zero
#define FLAG_OF 0x04 //Overflow
#define FLAG_UF 0x02 //Underflow
#define FLAG_NX 0x01 //Inexact (rounding happened)
typedef uint32_t FLAG;

//-------------------------
// Utility Macro
//-------------------------
#define SIGN(x) ((x) >> 31)
#define EXPO(x) (((x) & 0x7fffffff) >> 23)
#define FRAC(x) ((x) & 0x007fffff)
#define FMSB(x) (FRAC(x) >> 22)
#define BNEG(x) ((~x) & 0x01)
#define BPOS(x) (( x) & 0x01)

//--------------------
// Prototypes
//--------------------
FTYPE    check_ftype(float f);
float    qnan_snan(float snan);
//
int32_t  fmt32_float(float fdata);
uint32_t fmt32_element(uint32_t sign, uint32_t expo, uint32_t frac);
float    float_fmt32(int32_t fmt32);
void     print_fmt(float fdata);
void     print_float(float fdata);
//
void main_floating(void);

#endif
//===========================================================
// End of Program
//===========================================================
