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

//#define MYLIB

#include <stdio.h>
#include <math.h>
#include "common.h"
#include "csr.h"
#include "float.h"
#include "gpio.h"
#include "system.h"
#include "uart.h"
#include "xprintf.h"

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
// Write XRx
//--------------------------------
#define write_xr(xrn, val)                       \
({                                               \
    asm volatile ("c.mv " STRING(xrn) ", %0"  \
        :: "r"(val));                            \
})

#ifdef MYLIB
//---------------------------
// 32bit Format from Float
//---------------------------
int32_t fmt32_float(float fdata)
{
    float   *pfdata;
    int32_t  fmt32;
    int32_t *pfmt32;
    //
    pfdata = &fdata;
    pfmt32 = (int32_t*) pfdata;
    fmt32  = *pfmt32;
    //
    return fmt32;
}

//---------------------------
// Float from 32bit Format
//---------------------------
float float_fmt32(int32_t fmt32)
{
    int32_t *pfmt32;
    float    fdata;
    float   *pfdata;

    pfmt32 = &fmt32;
    pfdata = (float*) pfmt32;
    fdata  = *pfdata;
    //
    return fdata;
}

//-----------------------------
// mm___kernel_sinf
//-----------------------------
/* iy=0 if y is zero */
float mm__kernel_sinf(float x, float y, int iy)
{
    static const float
    half =  5.0000000000e-01,/* 0x3f000000 */
    S1  = -1.6666667163e-01, /* 0xbe2aaaab */
    S2  =  8.3333337680e-03, /* 0x3c088889 */
    S3  = -1.9841270114e-04, /* 0xb9500d01 */
    S4  =  2.7557314297e-06, /* 0x3638ef1b */
    S5  = -2.5050759689e-08, /* 0xb2d72f34 */
    S6  =  1.5896910177e-10; /* 0x2f2ec9d3 */
    //
    float z,r,v;
    int32_t ix;
  //GET_FLOAT_WORD(ix,x);
    ix = fmt32_float(x);
    ix &= 0x7fffffff;                       /* high word of x */
    if(ix<0x32000000)                       /* |x| < 2**-27 */
       {if((int)x==0) return x;}            /* generate inexact */
    z       =  x*x;
    v       =  z*x;
    r       =  S2+z*(S3+z*(S4+z*(S5+z*S6)));
    if(iy==0) return x+v*(S1+z*r);
    else      return x-((z*(half*y-v*r)-y)-v*S1);
}

//-----------------------------
// mm___kernel_cosf
//-----------------------------
float mm__kernel_cosf(float x, float y)
{
    static const float
    one =  1.0000000000e+00, /* 0x3f800000 */
    C1  =  4.1666667908e-02, /* 0x3d2aaaab */
    C2  = -1.3888889225e-03, /* 0xbab60b61 */
    C3  =  2.4801587642e-05, /* 0x37d00d01 */
    C4  = -2.7557314297e-07, /* 0xb493f27c */
    C5  =  2.0875723372e-09, /* 0x310f74f6 */
    C6  = -1.1359647598e-11; /* 0xad47d74e */
    //
    float a,hz,z,r,qx;
    int32_t ix;
    //GET_FLOAT_WORD(ix,x);
      ix = fmt32_float(x);
    ix &= 0x7fffffff;                       /* ix = |x|'s high word*/
    if(ix<0x32000000) {                     /* if x < 2**27 */
        if(((int)x)==0) return one;         /* generate inexact */
    }
    z  = x*x;
    r  = z*(C1+z*(C2+z*(C3+z*(C4+z*(C5+z*C6)))));
    if(ix < 0x3e99999a)                     /* if |x| < 0.3 */
        return one - ((float)0.5*z - (z*r - x*y));
    else {
        if(ix > 0x3f480000) {               /* x > 0.78125 */
            qx = (float)0.28125;
        } else {
          //SET_FLOAT_WORD(qx,ix-0x01000000);       /* x/4 */
            qx = float_fmt32(ix-0x01000000);        /* x/4 */
        }
        hz = (float)0.5*z-qx;
        a  = one-qx;
        return a - (hz - (z*r-x*y));
    }
}

//-------------------------------------------------
// mm__kernel_rem_pio2f
//-------------------------------------------------
// In the float version, the input parameter x contains 8 bit
// integers, not 24 bit integers.  113 bit precision is not sup
// ported.
int mm__kernel_rem_pio2f(float *x, float *y, int e0, int nx, int prec, const int32_t *ipio2)
{
    static const int init_jk[] = {4,7,9}; /* initial value for jk */
    static const float PIo2[] = {
      1.5703125000e+00, /* 0x3fc90000 */
      4.5776367188e-04, /* 0x39f00000 */
      2.5987625122e-05, /* 0x37da0000 */
      7.5437128544e-08, /* 0x33a20000 */
      6.0026650317e-11, /* 0x2e840000 */
      7.3896444519e-13, /* 0x2b500000 */
      5.3845816694e-15, /* 0x27c20000 */
      5.6378512969e-18, /* 0x22d00000 */
      8.3009228831e-20, /* 0x1fc40000 */
      3.2756352257e-22, /* 0x1bc60000 */
      6.3331015649e-25, /* 0x17440000 */
    };
    static const float
    zero   = 0.0,
    one    = 1.0,
    two8   =  2.5600000000e+02, /* 0x43800000 */
    twon8  =  3.9062500000e-03; /* 0x3b800000 */
    //
    int32_t jz,jx,jv,jp,jk,carry,n,iq[20],i,j,k,m,q0,ih;
    float z,fw,f[20],fq[20],q[20];

    /* initialize jk*/
    jk = init_jk[prec];
    jp = jk;

    /* determine jx,jv,q0, note that 3>q0 */
    jx =  nx-1;
    jv = (e0-3)/8; if(jv<0) jv=0;
    q0 =  e0-8*(jv+1);

    /* set up f[0] to f[jx+jk] where f[jx+jk] = ipio2[jv+jk] */
    j = jv-jx; m = jx+jk;
    for(i=0;i<=m;i++,j++) f[i] = (j<0)? zero : (float) ipio2[j];

    /* compute q[0],q[1],...q[jk] */
    for (i=0;i<=jk;i++) {
        for(j=0,fw=0.0;j<=jx;j++) fw += x[j]*f[jx+i-j];
        q[i] = fw;
    }

    jz = jk;
recompute:
    /* distill q[] into iq[] reversingly */
    for(i=0,j=jz,z=q[jz];j>0;i++,j--) {
        fw    =  (float)((int32_t)(twon8* z));
        iq[i] =  (int32_t)(z-two8*fw);
        z     =  q[j-1]+fw;
    }

    /* compute n */
    z  = scalbnf(z,(int)q0);    /* actual value of z */
    z -= (float)8.0*floorf(z*(float)0.125); /* trim off integer >= 8 */
    n  = (int32_t) z;
    z -= (float)n;
    ih = 0;
    if(q0>0) {  /* need iq[jz-1] to determine n */
        i  = (iq[jz-1]>>(8-q0)); n += i;
        iq[jz-1] -= i<<(8-q0);
        ih = iq[jz-1]>>(7-q0);
    }
    else if(q0==0) ih = iq[jz-1]>>7;
    else if(z>=(float)0.5) ih=2;

    if(ih>0) {  /* q > 0.5 */
        n += 1; carry = 0;
        for(i=0;i<jz ;i++) {    /* compute 1-q */
        j = iq[i];
        if(carry==0) {
            if(j!=0) {
            carry = 1; iq[i] = 0x100- j;
            }
        } else  iq[i] = 0xff - j;
        }
        if(q0>0) {      /* rare case: chance is 1 in 12 */
            switch(q0) {
            case 1:
               iq[jz-1] &= 0x7f; break;
            case 2:
               iq[jz-1] &= 0x3f; break;
            }
        }
        if(ih==2) {
        z = one - z;
        if(carry!=0) z -= scalbnf(one,(int)q0);
        }
    }

    /* check if recomputation is needed */
    if(z==zero) {
        j = 0;
        for (i=jz-1;i>=jk;i--) j |= iq[i];
        if(j==0) { /* need recomputation */
        for(k=1;iq[jk-k]==0;k++);   /* k = no. of terms needed */

        for(i=jz+1;i<=jz+k;i++) {   /* add q[jz+1] to q[jz+k] */
            f[jx+i] = (float) ipio2[jv+i];
            for(j=0,fw=0.0;j<=jx;j++) fw += x[j]*f[jx+i-j];
            q[i] = fw;
        }
        jz += k;
        goto recompute;
        }
    }

    /* chop off zero terms */
    if(z==(float)0.0) {
        jz -= 1; q0 -= 8;
        while(iq[jz]==0) { jz--; q0-=8;}
    } else { /* break z into 8-bit if necessary */
        z = scalbnf(z,-(int)q0);
        if(z>=two8) {
        fw = (float)((int32_t)(twon8*z));
        iq[jz] = (int32_t)(z-two8*fw);
        jz += 1; q0 += 8;
        iq[jz] = (int32_t) fw;
        } else iq[jz] = (int32_t) z ;
    }

    /* convert integer "bit" chunk to floating-point value */
    fw = scalbnf(one,(int)q0);
    for(i=jz;i>=0;i--) {
        q[i] = fw*(float)iq[i]; fw*=twon8;
    }

    /* compute PIo2[0,...,jp]*q[jz,...,0] */
    for(i=jz;i>=0;i--) {
        for(fw=0.0,k=0;k<=jp&&k<=jz-i;k++) fw += PIo2[k]*q[i+k];
        fq[jz-i] = fw;
    }

    /* compress fq[] into y[] */
    switch(prec) {
        case 0:
        fw = 0.0;
        for (i=jz;i>=0;i--) fw += fq[i];
        y[0] = (ih==0)? fw: -fw;
        break;
        case 1:
        case 2:
        fw = 0.0;
        for (i=jz;i>=0;i--) fw += fq[i];
        y[0] = (ih==0)? fw: -fw;
        fw = fq[0]-fw;
        for (i=1;i<=jz;i++) fw += fq[i];
        y[1] = (ih==0)? fw: -fw;
        break;
        case 3: /* painful */
        for (i=jz;i>0;i--) {
            fw      = fq[i-1]+fq[i];
            fq[i]  += fq[i-1]-fw;
            fq[i-1] = fw;
        }
        for (i=jz;i>1;i--) {
            fw      = fq[i-1]+fq[i];
            fq[i]  += fq[i-1]-fw;
            fq[i-1] = fw;
        }
        for (fw=0.0,i=jz;i>=2;i--) fw += fq[i];
        if(ih==0) {
            y[0] =  fq[0]; y[1] =  fq[1]; y[2] =  fw;
        } else {
            y[0] = -fq[0]; y[1] = -fq[1]; y[2] = -fw;
        }
    }
    return n&7;
}

//-------------------------------------------------
// mm__ieee754_rem_pio2f(x,y)
// return the remainder of x rem pi/2 in y[0]+y[1]
//-------------------------------------------------
int32_t mm__ieee754_rem_pio2f(float x, float *y)
{
    // Table of constants for 2/pi, 396 Hex digits (476 decimal) of 2/pi
    static const int32_t two_over_pi[] = {
    0xA2, 0xF9, 0x83, 0x6E, 0x4E, 0x44, 0x15, 0x29, 0xFC,
    0x27, 0x57, 0xD1, 0xF5, 0x34, 0xDD, 0xC0, 0xDB, 0x62,
    0x95, 0x99, 0x3C, 0x43, 0x90, 0x41, 0xFE, 0x51, 0x63,
    0xAB, 0xDE, 0xBB, 0xC5, 0x61, 0xB7, 0x24, 0x6E, 0x3A,
    0x42, 0x4D, 0xD2, 0xE0, 0x06, 0x49, 0x2E, 0xEA, 0x09,
    0xD1, 0x92, 0x1C, 0xFE, 0x1D, 0xEB, 0x1C, 0xB1, 0x29,
    0xA7, 0x3E, 0xE8, 0x82, 0x35, 0xF5, 0x2E, 0xBB, 0x44,
    0x84, 0xE9, 0x9C, 0x70, 0x26, 0xB4, 0x5F, 0x7E, 0x41,
    0x39, 0x91, 0xD6, 0x39, 0x83, 0x53, 0x39, 0xF4, 0x9C,
    0x84, 0x5F, 0x8B, 0xBD, 0xF9, 0x28, 0x3B, 0x1F, 0xF8,
    0x97, 0xFF, 0xDE, 0x05, 0x98, 0x0F, 0xEF, 0x2F, 0x11,
    0x8B, 0x5A, 0x0A, 0x6D, 0x1F, 0x6D, 0x36, 0x7E, 0xCF,
    0x27, 0xCB, 0x09, 0xB7, 0x4F, 0x46, 0x3F, 0x66, 0x9E,
    0x5F, 0xEA, 0x2D, 0x75, 0x27, 0xBA, 0xC7, 0xEB, 0xE5,
    0xF1, 0x7B, 0x3D, 0x07, 0x39, 0xF7, 0x8A, 0x52, 0x92,
    0xEA, 0x6B, 0xFB, 0x5F, 0xB1, 0x1F, 0x8D, 0x5D, 0x08,
    0x56, 0x03, 0x30, 0x46, 0xFC, 0x7B, 0x6B, 0xAB, 0xF0,
    0xCF, 0xBC, 0x20, 0x9A, 0xF4, 0x36, 0x1D, 0xA9, 0xE3,
    0x91, 0x61, 0x5E, 0xE6, 0x1B, 0x08, 0x65, 0x99, 0x85,
    0x5F, 0x14, 0xA0, 0x68, 0x40, 0x8D, 0xFF, 0xD8, 0x80,
    0x4D, 0x73, 0x27, 0x31, 0x06, 0x06, 0x15, 0x56, 0xCA,
    0x73, 0xA8, 0xC9, 0x60, 0xE2, 0x7B, 0xC0, 0x8C, 0x6B,
    };
    //
    // This array is like the one in e_rem_pio2.c, but the numbers are
    // single precision and the last 8 bits are forced to 0.
    static const int32_t npio2_hw[] = {
    0x3fc90f00, 0x40490f00, 0x4096cb00, 0x40c90f00, 0x40fb5300, 0x4116cb00,
    0x412fed00, 0x41490f00, 0x41623100, 0x417b5300, 0x418a3a00, 0x4196cb00,
    0x41a35c00, 0x41afed00, 0x41bc7e00, 0x41c90f00, 0x41d5a000, 0x41e23100,
    0x41eec200, 0x41fb5300, 0x4203f200, 0x420a3a00, 0x42108300, 0x4216cb00,
    0x421d1400, 0x42235c00, 0x4229a500, 0x422fed00, 0x42363600, 0x423c7e00,
    0x4242c700, 0x42490f00
    };
    //
    // invpio2:  24 bits of 2/pi
    // pio2_1:   first  17 bit of pi/2
    // pio2_1t:  pi/2 - pio2_1
    // pio2_2:   second 17 bit of pi/2
    // pio2_2t:  pi/2 - (pio2_1+pio2_2)
    // pio2_3:   third  17 bit of pi/2
    // pio2_3t:  pi/2 - (pio2_1+pio2_2+pio2_3)
    static const float
    zero =  0.0000000000e+00, /* 0x00000000 */
    half =  5.0000000000e-01, /* 0x3f000000 */
    two8 =  2.5600000000e+02, /* 0x43800000 */
    invpio2 =  6.3661980629e-01, /* 0x3f22f984 */
    pio2_1  =  1.5707855225e+00, /* 0x3fc90f80 */
    pio2_1t =  1.0804334124e-05, /* 0x37354443 */
    pio2_2  =  1.0804273188e-05, /* 0x37354400 */
    pio2_2t =  6.0770999344e-11, /* 0x2e85a308 */
    pio2_3  =  6.0770943833e-11, /* 0x2e85a300 */
    pio2_3t =  6.1232342629e-17; /* 0x248d3132 */
    //
    float z,w,t,r,fn;
    float tx[3];
    int32_t i,j,n,ix,hx;
    int e0,nx;

    //GET_FLOAT_WORD(hx,x);
    hx = fmt32_float(x);
    ix = hx&0x7fffffff;

  //printf("ix=0x%08x ", ix);

    if(ix<=0x3f490fd8)   /* |x| ~<= pi/4 , no need for reduction */
        {y[0] = x; y[1] = 0; return 0;}
    if(ix<0x4016cbe4) {  /* |x| < 3pi/4, special case with n=+-1 */
        if(hx>0) {
        z = x - pio2_1;
        if((ix&0xfffffff0)!=0x3fc90fd0) { /* 24+24 bit pi OK */
            y[0] = z - pio2_1t;
            y[1] = (z-y[0])-pio2_1t;
        } else {        /* near pi/2, use 24+24+24 bit pi */
            z -= pio2_2;
            y[0] = z - pio2_2t;
            y[1] = (z-y[0])-pio2_2t;
        }
        return 1;
        } else {    /* negative x */
        z = x + pio2_1;
        if((ix&0xfffffff0)!=0x3fc90fd0) { /* 24+24 bit pi OK */
            y[0] = z + pio2_1t;
            y[1] = (z-y[0])+pio2_1t;
        } else {        /* near pi/2, use 24+24+24 bit pi */
            z += pio2_2;
            y[0] = z + pio2_2t;
            y[1] = (z-y[0])+pio2_2t;
        }
        return -1;
        }
    }
    if(ix<=0x43490f80) { /* |x| ~<= 2^7*(pi/2), medium size */
        t  = fabsf(x);
        n  = (int32_t) (t*invpio2+half);
        fn = (float)n;
        r  = t-fn*pio2_1;
        w  = fn*pio2_1t;    /* 1st round good to 40 bit */
        if(n<32&&(ix&0xffffff00)!=npio2_hw[n-1]) {
        y[0] = r-w; /* quick check no cancellation */
        } else {
            uint32_t high;
            j  = ix>>23;
            y[0] = r-w;
      //GET_FLOAT_WORD(high,y[0]);
        high = fmt32_float(y[0]);
            i = j-((high>>23)&0xff);
            if(i>8) {  /* 2nd iteration needed, good to 57 */
            t  = r;
            w  = fn*pio2_2;
            r  = t-w;
            w  = fn*pio2_2t-((t-r)-w);
            y[0] = r-w;
          //GET_FLOAT_WORD(high,y[0]);
            high = fmt32_float(y[0]);
            i = j-((high>>23)&0xff);
            if(i>25)  { /* 3rd iteration need, 74 bits acc */
                t  = r; /* will cover all possible cases */
                w  = fn*pio2_3;
                r  = t-w;
                w  = fn*pio2_3t-((t-r)-w);
                y[0] = r-w;
            }
        }
        }
        y[1] = (r-y[0])-w;
        if(hx<0)    {y[0] = -y[0]; y[1] = -y[1]; return -n;}
        else     return n;
    }
    /*
     * all other (large) arguments
     */
  //if(!FLT_UWORD_IS_FINITE(ix)) {
    if(!((ix)<0x7f800000L)) {
        y[0]=y[1]=x-x; return 0;
    }
    /* set z = scalbn(|x|,ilogb(x)-7) */
    e0  = (int)((ix>>23)-134);  /* e0 = ilogb(z)-7; */
  //SET_FLOAT_WORD(z, ix - ((int32_t)e0<<23));
    z = float_fmt32(ix - ((int32_t)e0<<23));
    for(i=0;i<2;i++) {
        tx[i] = (float)((int32_t)(z));
        z     = (z-tx[i])*two8;
    }
    tx[2] = z;
    nx = 3;
    while(tx[nx-1]==zero) nx--; /* skip zero term */
    n  =  mm__kernel_rem_pio2f(tx,y,e0,nx,2,two_over_pi);
    if(hx<0) {y[0] = -y[0]; y[1] = -y[1]; return -n;}
    return n;
}

//-----------------------
// mm_sinf()
//-----------------------
float mm_sinf(float x)
{
    float y[2], z=0.0;
    int32_t n, ix;

  //GET_FLOAT_WORD(ix,x);
    ix = fmt32_float(x);

/* |x| ~< pi/4 */
    ix &= 0x7fffffff;
    if(ix <= 0x3f490fd8) return mm__kernel_sinf(x,z,0);

/* sin(Inf or NaN) is NaN */
  //else if (!FLT_UWORD_IS_FINITE(ix)) return x-x;
    else if (!((ix)<0x7f800000L)) return x-x;

/* argument reduction needed */
    else {
        n = mm__ieee754_rem_pio2f(x,y);

      //printf("n=%d ", n);

        switch(n&3) {
            case 0: return  mm__kernel_sinf(y[0],y[1],1);
            case 1: return  mm__kernel_cosf(y[0],y[1]);
            case 2: return -mm__kernel_sinf(y[0],y[1],1);
            default:
                    return -mm__kernel_cosf(y[0],y[1]);
        }
    }
}
#endif

//--------------------------
// Floating Main
//--------------------------
void main_floating(void)
{
    uint32_t i;
    uint32_t bcd1000, bcd100, bcd10, bcd1, bcd;
    //
    /*
    uint64_t n;
    float fy0, fy1, fy2, fx1;
    float ff, fT, fa1, fa2, fb;
    n = 0;
    fy1 = 0.0;
    fy2 = 0.0;
    fx1 = 0.0;
    ff  = 1000.0; // Hz
    fT  = 10.0e-6;  // sec
    fa1 = 2 * cosf(2 * M_PI * ff * fT);
    fa2 = -1.0;
    fb  = sinf(2 * M_PI * ff * fT);
    */
    //
    while(1)
    {
        for (i = 0; i < 360; i++)
        {
            /*
            // IIR Sine Wave
            //     x[n] = delta[n] = 1(n=0), 0(n<>0)
            //     y[n] = a1*y[n-1] + a2*y[n-2] + b*x[n-1]
            //       a1 = 2*cos(2*pi*f*T)
            //       a2 = -1.0
            //       b  = sin(2*pi*f*T)
            fx1 = (n == 1)? fb : 0.0;
            fy0 = fa1 * fy1 + fa2 * fy2 + fx1;
          //printf("[%6lld] sin=%9.6f\n", n, fy0);
            fy2 = fy1;
            fy1 = fy0;
            n = n + 1;
            */
            //
            // Sine Function
            float fth  = 2 * M_PI / 360.0 * (float)i;
#ifdef MYLIB
            float fsin = mm_sinf(fth);
#else
            float fsin = sinf(fth);
#endif
            float    fsin_disp = fsin  * 10000.0;
            int32_t  isin_disp = (int32_t) fsin_disp;
            GPIO_SetSEG_SignedDecimal(isin_disp);
            //
            mem_wr32(0xfffffffc, 0xdeaddead); // Simulation Stop
            //
            printf("i=%3d fth=%8.6f fsin=%9.6f\n", i, fth, fsin);
            Wait_mSec(100);
        }
    }
}

//===========================================================
// End of Program
//===========================================================
