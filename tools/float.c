#include <stdio.h>
#include <math.h>

void print_double(double fX)
{
    unsigned char  *pfX;
    int    i;
    
    printf("fX=%lf\n", fX);
    
    pfX = (unsigned char*)(&fX);
    printf("fX=0x");
    for (i = 0; i < 8; i++)
    {
        printf("%02x", pfX[7-i]);
    }
    printf("\n");
}


void main(void)
{
    double fX;
    
    print_double(M_PI/180);
    print_double(sin(M_PI/180));
}
