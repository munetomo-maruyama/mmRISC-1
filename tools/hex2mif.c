//===========================================================
// mmRISC-0 Support Program
//-----------------------------------------------------------
// File Name   : hex2mif.c
// Description : Convert Intel Hex to Memory Init File
//-----------------------------------------------------------
// History :
// Rev.01 2021.12.26 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2021-2022 M.Maruyama
//===========================================================

#include <getopt.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAXLEN_LINE 1024
#define MAXLEN_WORD 256
#define MAX_ROM (128*1024)
#define ROM_BASE 0x90000000

//=====================
// Globals
//=====================
uint8_t ROM[MAX_ROM];
uint32_t addr_min = 0xffffffff;
uint32_t addr_max = 0;

//======================
// Read Hex Format
//======================
uint32_t Read_Hex_Format(FILE *fp)
{
    uint32_t error = 0;
    uint8_t  hexline[MAXLEN_LINE];
    uint8_t *pline;
    size_t   len;
    uint8_t  str[MAXLEN_WORD];
    uint32_t bytecount;
    uint32_t addr_base = 0;
    uint32_t addr_bgn;
    uint32_t addr;
    uint32_t data;
    uint32_t checksum, checksum2;
    uint32_t line;

    while(1)
    {
        // Get a Line
        if (fgets(hexline, MAXLEN_LINE, fp) == NULL) return error;
        pline = hexline;
        // Start Code
        if (*pline++ != ':') {error = 1; break;}
        // Byte Count
        str[0] = *pline++;
        str[1] = *pline++;
        str[2] = '\0';
        if (sscanf(str, "%02X", (int*)&bytecount) == EOF) {error = 2; break;}
        checksum = bytecount;
        // Address
        str[0] = *pline++;
        str[1] = *pline++;
        str[2] = *pline++;
        str[3] = *pline++;
        str[4] = '\0';
        if (sscanf(str, "%04X", (int*)&addr_bgn) == EOF) {error = 3; break;}
        checksum = checksum + (addr_bgn >> 8) + (addr_bgn & 0x00ff);
        // Record Type
        str[0] = *pline++;
        str[1] = *pline++;
        str[2] = '\0';
        // Record Type = End of File 
        if (strcmp(str, "01") == 0) break;
        // Record Type = Extended Segment Address
        if (strcmp(str, "02") == 0)
        {
            str[0] = *pline++;
            str[1] = *pline++;
            str[2] = *pline++;
            str[3] = *pline++;
            str[4] = '\0';
            if (sscanf(str, "%04X", (int*)&addr_base) == EOF) {error = 4; break;}
            addr_base = addr_base << 4;
          //printf("RecordType=02 addr_base = %08x\n", addr_base);
            continue;
        }
        // Record Type = Extended Linear Address
        if (strcmp(str, "04") == 0)
        {
            str[0] = *pline++;
            str[1] = *pline++;
            str[2] = *pline++;
            str[3] = *pline++;
            str[4] = '\0';
            if (sscanf(str, "%04X", (int*)&addr_base) == EOF) {error = 5; break;}
            addr_base = addr_base << 16;
          //printf("RecordType=04 addr_base = %08x\n", addr_base);
            continue;
        }
        // Record Type = Start Linear Address
        if (strcmp(str, "05") == 0)
        {
            str[0] = *pline++;
            str[1] = *pline++;
            str[2] = *pline++;
            str[3] = *pline++;
            str[4] = *pline++;
            str[5] = *pline++;
            str[6] = *pline++;
            str[7] = *pline++;
            str[8] = '\0';
            if (sscanf(str, "%08X", (int*)&addr_base) == EOF) {error = 6; break;}
          //printf("RecordType=05 addr_base = %08x\n", addr_base);
            continue;
        }
        // Record Type = Unsupported
        if (strcmp(str, "00") != 0) {error = 7; break;}
        // Record Type = Data Record
        for (addr = addr_bgn; addr < (addr_bgn + bytecount); addr++)
        {
            str[0] = *pline++;
            str[1] = *pline++;
            str[2] = '\0';
            if (sscanf(str, "%02X", (int*)&data) == EOF) {error = 8; break;}
            //
            if (addr >= MAX_ROM) {error = 9; break;}
            addr_min = ((addr_base + addr) < addr_min)? addr_base + addr : addr_min;
            addr_max = ((addr_base + addr) > addr_max)? addr_base + addr : addr_max;
            ROM[addr + addr_base - ROM_BASE] = data;
            //
            checksum = checksum + data;
        }        
        if (error) break;
        // Checksum
        str[0] = *pline++;
        str[1] = *pline++;
        str[2] = '\0';
        if (sscanf(str, "%02X", (int*)&checksum2) == EOF) {error = 10; break;}
        checksum = (0 - checksum) & 0x00ff;
        if (checksum != checksum2) {error = 11; break;}
    }
    return error;
}

//======================
// Print ASCII Dump
//======================
void Print_ASCII_Dump(void)
{
    uint32_t addr;
    //
    printf("WIDTH=32;\n");
    printf("DEPTH=32768;\n");
    printf("ADDRESS_RADIX=HEX;\n");
    printf("DATA_RADIX=HEX;\n");
    printf("CONTENT\n");
    printf("BEGIN\n");
    printf("\n");
    //
    for (addr = addr_min; addr <= addr_max; addr = addr + 4)
    {
        printf ("%08X : ", (addr - addr_min)/4);
        printf ("%02X%02X%02X%02X;\n", 
            ROM[addr - addr_min + 3],
            ROM[addr - addr_min + 2],
            ROM[addr - addr_min + 1],
            ROM[addr - addr_min + 0]);
    }
    //
    printf("\n");
    printf("END;\n");    
}

//=======================
// Main Routine
//=======================
int main (int argc, char **argv)
{
    FILE *fp;
    uint32_t error;
    
    fp = fopen(argv[1], "r");
    if (fp == NULL)
    {
        fprintf(stderr, "Can't open \"%s\".\n", argv[1]);
        exit(EXIT_FAILURE);
    }
    //
    error = Read_Hex_Format(fp);
    if (error)
    {
        fprintf(stderr, "Format Error (%d) in \"%s\".\n", error, argv[1]);
        exit(EXIT_FAILURE);
    }
    Print_ASCII_Dump();
    
    exit(EXIT_SUCCESS);
}

//===========================================================
// End of Program
//===========================================================

