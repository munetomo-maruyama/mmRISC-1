//=========================================================
// PSoC5LP Project
//=========================================================
// File Name : utility.c
// Function  : Utility Routine
//---------------------------------------------------------
// Rev.01 2012.09.01 Munetomo Maruyama
//---------------------------------------------------------
// Copyright (C) 2012-2013 Munetomo Maruyama
//=========================================================
// ---- License Information -------------------------------
// Anyone can FREELY use this code fully or partially
// under conditions shown below.
// 1. You may use this code only for individual purpose,
//    and educational purpose.
//    Do not use this code for business even if partially.
// 2. You can copy, modify and distribute this code.
// 3. You should remain this header text in your codes
//   including Copyright credit and License Information.
// 4. Your codes should inherit this license information.
//=========================================================
// ---- Patent Notice -------------------------------------
// I have not cared whether this system (hw + sw) causes
// infringement on the patent, copyright, trademark,
// or trade secret rights of others. You have all
// responsibilities for determining if your designs
// and products infringe on the intellectual property
// rights of others, when you use technical information
// included in this system for your business.
//=========================================================
// ---- Disclaimers ---------------------------------------
// The function and reliability of this system are not
// guaranteed. They may cause any damages to loss of
// properties, data, money, profits, life, or business.
// By adopting this system even partially, you assume
// all responsibility for its use.
//=========================================================

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "fixedpoint.h"
#include "utility.h"

#define MAX_WORKBUF 64

//========================
// Calculate x^n
//========================
int32 power(int32 x, int32 n)
{
    uint32 i;
    int32  y;

    y = 1;
    for (i = 0; i < n; i++)
    {
        y = y * x;
    }
    return y;
}

//=====================
// BCD from Integer
//=====================
uint8 BCD_INT(uint8 num)
{
    return ((num / 10) << 4) + (num % 10);
}

//=====================
// Integer from BCD
//=====================
uint8 INT_BCD(uint8 bcd)
{
    return (((bcd >> 4) * 10) + (bcd & 0x0f));
}

//=================================
// Extended atoi String to Integer
//=================================
//  str : Pointer to pointer to source string
//    "0xff800" hexadecimal
//    "1250000" decimal
//    "-25000" decimal
//  data : Pointer to return value
uint32 xatoi(uint8 **str, int32 *data)
{
    uint8 *pS, *pE;
    int32 result;
    uint32 judge;

    pS = *str;

    result = (int32) strtol((const char*) pS, (char**) &pE, 0);
    judge = (pS == pE)? 0 : (result == LONG_MAX)? 0 : (result == LONG_MIN)? 0 : 1;
    *data = result;
    *str = pE;
    return judge;
}

//====================================
// Extended itoa output to String
//====================================
//      value  radix  width   output
//        100     10      6   "   100"
//        100     10     -6   "000100"
//        100     10      0   "100"
// 4294967295     10      0   "4294967295"
// 4294967295    -10      0   "-1"
//     655360     16     -8   "000A0000"
//       1024     16      0   "400"
//       0x55      2     -8   "01010101"
uint8 *xitoa(uint8 *str, uint32 *pLength, int32 value, int8 radix, int8 width)
{
    uint32 i, j, n;
    uint8  ch;
    int8   radix_abs;
    uint32 radix_unsigned;
    int8   width_abs;
    uint32 width_unsigned;
    int32  value_abs;
    uint32 value_unsigned;
    uint8  workbuf[MAX_WORKBUF];
    //
    // Check Radix
    //
    radix_abs = (radix >= 0)? radix : -radix;
    radix_unsigned = (uint32) radix_abs;
    if ((radix_abs < 2) || (radix_abs > 36))
    {
        if (str != NULL) *str = '\0';
        return str;
    }
    //
    // Check Width
    //
    width_abs = (width >= 0)? width : -width;
    width_unsigned = (uint32) width_abs;
    //
    // Check Value
    //
    value_abs = (value >= 0)? value : -value;
    if (radix >= 0)
    {
        value_unsigned = (value >= 0)? (uint32) value_abs : (uint32) value;
    }
    else
    {
        value_unsigned = (value >= 0)? (uint32) value_abs : (uint32) value_abs;
    }
    //
    // Make Positive Number String
    //
    i = 0;
    do
    {
        n = value_unsigned % radix_unsigned;
        workbuf[i++] = (n < 10 ? (uint8) n + '0' : (uint8) n - 10 + 'a');
        value_unsigned = value_unsigned / radix_unsigned;
        //
        if (i >= MAX_WORKBUF)
        {
            if (str != NULL) *str = '\0';
            return str;
        }
    }
    while (value_unsigned != 0);
    //
    // Formatting
    //
    j = i;
    if ((*pLength > 0) && (value < 0) && (radix < 0))
    {
        if (width < 0)
        {
            ch = '-';
            *str++ = ch;
            (*pLength)--;
        }
        j = i + 1;
    }
    //
    while ((*pLength > 0) & (width_unsigned > j))
    {
        ch = (width >= 0)? ' ' : '0';
        *str++ = ch;
        (*pLength)--;
        width_unsigned--;
    }
    //
    if ((*pLength > 0) && (value < 0) && (radix < 0) && (width >= 0))
    {
        ch = '-';
        *str++ = ch;
        (*pLength)--;
    }
    //
    while ((*pLength > 0) && (i > 0))
    {
        ch = workbuf[--i];
        *str++ = ch;
        (*pLength)--;
    }
    //
    // Finish
    //
    if (str != NULL) *str = '\0';
    return str;
}

//====================================
// Extended snprintf() for Small MCU
//====================================
uint8 *xsnprintf(uint8 *str, uint32 length, const char *format, ...)
{
    va_list ap;

    va_start(ap, format);
    str = xvsnprintf(str, length, format, ap);
    va_end(ap);
    return str;
}

//====================================
// Extended vsnprintf() for Small MCU
//====================================
/* Format string is placed in the ROM. The format flags is similar to printf().

   %[flag][width][size]type

   flag
     A '0' means filled with '0' when output is shorter than width.
     ' ' is used in default. This is effective only numeral type.
   width
     Minimum width in decimal number. This is effective only numeral type.
     Default width is zero.
   size (In this program, this is ignored. Always treaded as long.)
     A 'l' means the argument is long(32bit). Default is short(16bit).
     This is effective only numeral type.
   type
     'c' : Character, argument is the value
     's' : String placed on memory, argument is the pointer
     'd' : Signed decimal, argument is the value
     'u' : Unsigned decimal, argument is the value
     'x' : Hex decimal, argument is the value
     'b' : Binary, argument is the value
     '%' : '%'
*/
uint8 *xvsnprintf(uint8 *str, uint32 length, const char *format, va_list ap)
{
    uint8 *ptr;
    int32 data;
    int8 zero;
    int8 width;

    ptr = (uint8*) format;
    while(*ptr != '\0')
    {
        if (*ptr == '%')
        {
            ptr++;
            zero = 1;
            if (*ptr == '0')
            {
                zero = -1;
                ptr++;
            }
            width = 0;
            if (xatoi(&ptr, &data))
            {
                width = (int8) data;
            }
            if (*ptr == 'l')
            {
                // ignore
                ptr++;
            }
            switch (*ptr)
            {
                case 'c':
                {
                    uint8 ch = (uint8) va_arg(ap, int);
                    if (length > 0) {*str++ = ch; length--;}
                    break;
                }
                case 's':
                {
                    uint8 ch;
                    uint8 *string = (uint8*) va_arg(ap, char*);
                    while((length > 0) && ((ch = *string++) != '\0')) {*str++ = ch; length--;}
                    break;
                }
                case 'd':
                {
                    int32 value32;
                    value32 = (int32) va_arg(ap, int);
                    str = xitoa(str, &length, (int32) value32, -10, width * zero);
                    break;
                }
                case 'u':
                {
                    int32 value32;
                    value32 = (int32) va_arg(ap, int);
                    str = xitoa(str, &length, (int32) value32, +10, width * zero);
                    break;
                }
                case 'x':
                {
                    int32 value32;
                    value32 = (int32) va_arg(ap, int);
                    str = xitoa(str, &length, (int32) value32, +16, width * zero);
                    break;
                }
                case 'b':
                {
                    int32 value32;
                    value32 = (int32) va_arg(ap, int);
                    str = xitoa(str, &length, (int32) value32, +2, width * zero);
                    break;
                }
                case '%':
                {
                    if (length > 0) {*str++ = '%'; length--;}
                    break;
                }
                default:
                {
                    if (length > 0) {*str++ = *ptr; length--;}
                    break;
                }
            }
            ptr++;
        }
        else
        {
            if (length > 0) {*str++ = *ptr; length--;}
            ptr++;
        }
    }
    //
    if (str != NULL) *str = '\0';
    return str;
}

//======================================================
// Append String UI32
//======================================================
uint8* Append_String_UI32(uint32 value, uint8 *string, uint32 radix, uint32 length)
{
    uint8 *dst;
    uint8 digits[32];
    uint32 i, n;

    dst = string;
    if ((radix < 2) || (radix > 36))
    {
        *dst = 0;
        return string;
    }
    i = 0;
    do
    {
        n = value % radix;
        digits[i++] = (n < 10 ? (uint8) n + '0' : (uint8) n - 10 + 'a');
        value = value / radix;
    } while (value != 0);
    //
    while (length > i)
    {
        *dst++ = '0';
        length--;
    }
    while (i > 0)
    {
        *dst++ = digits[--i];
    }

  //*dst++ = '\0';
  //return string;
    return dst;
}

//======================================================
// Append String SI32
//======================================================
uint8* Append_String_SI32(int32 value, uint8 *string, uint32 radix, uint32 length)
{
    uint8 *dst;

    dst = string;

    if (value == 0)
    {
        *dst++ = ' ';
    }
    else if (value > 0)
    {
        *dst++ = '+';
    }
    else
    {
        *dst++ = '-';
        value = 0 - value;
    }
    dst = Append_String_UI32((uint32) value, dst, radix, length);
  //return string;
    return dst;
}

//======================================================
// Append String Fixed
//======================================================
// [example]
// 0111.1100000000000000
//      c000 = 49152 --> 49152/65536=0.75
//      49125*1000/65536=749, (749+5)/10=75
// 0111.1101000000000000
//      d000 = 53248 --> 53248/65536=0.8125
//      53248*100000/65536=81250, (81250+5)/10=8125
uint8* Append_String_Fixed(fix32 fvalue, uint8 *string, uint32 format)
{
    uint32 ivalue_int;
    uint32 ivalue_dec;
    uint8  *dst;

    dst = string;

    if (fvalue == 0)
    {
        *dst++ = ' ';
    }
    else if (fvalue > 0)
    {
        *dst++ = '+';
    }
    else
    {
        *dst++ = '-';
        fvalue = FIX_Abs(fvalue);
    }
    //
    if (format == 0)
    {
        fvalue = fvalue + (1 << (FIXQ - 1));
    }
    ivalue_int = fvalue >> FIXQ;
    dst = Append_String_UI32(ivalue_int, dst, 10, 0);
    //
    if (format > 0)
    {
        *dst++ = '.';
        ivalue_dec = fvalue & 0x0ffff;
        ivalue_dec = ivalue_dec * (10 ^ (format + 1)) / (1 << FIXQ);
        ivalue_dec = (ivalue_dec + 5) / 10; // rounding
        dst = Append_String_UI32(ivalue_dec, dst, 10, 0);
    }
    return dst;
}

//======================================================
// Append String UI32 in N-digit
//======================================================
uint8* Append_String_UI08_Ndigit(uint32 value, uint8 *string, uint32 digit)
{
    uint32 i;
    uint8  *dst;
    uint32 exp;

    exp = 1;
    for (i = 0; i < digit; i++) // digit=3
    {
        exp = exp * 10;
    }
    value = value % exp;        // exp = 1000
    dst = string;
    //
    for (i = 0; i < digit; i++) // digit=3
    {
        *dst++ = '0' + (value % exp) / (exp / 10);
        exp = exp / 10;
    }
  //*dst++ = '\0';
  //return string;
    return dst;
}

//======================================================
// Append String SI32 in N-digit
//======================================================
uint8* Append_String_SI08_Ndigit(uint32 value, uint8 *string, uint32 digit)
{
    uint8  *dst;
    uint32 abs;

    dst = string;
    if (value >= 0)
    {
        *dst++ = '+';
        abs = (uint32) ( value);
    }
    else
    {
        *dst++ = '-';
        abs = (uint32) (-value);
    }
    dst = Append_String_UI08_Ndigit(abs, dst, digit);
  //return string;
    return dst;
}

//======================================================
// Append String
//======================================================
uint8* Append_String(uint8 *pDst, uint8 *pSrc)
{
    uint8 ch;

    while ((ch = *pSrc++) != '\0')
    {
        *pDst++ = ch;
    }
    return pDst;
}

//=========================================================
// End of Program
//=========================================================
