#!/usr/bin/perl -w

#########################################################################
# bmp2c
#========================================================================
# Convert BMP24 to C data of RGB Image Data(RGB=565)
#------------------------------------------------------------------------
# Rev.01 2009.10.07 Munetomo Maruyama  1st Release
#########################################################################

use Getopt::Long;

#======================================
#--------------------------------------
# Main Routine
#--------------------------------------
#======================================
#-----------------------------
# Check Command Line Arguments
#-----------------------------
sub error_msg()
{
    printf("----------------------------------------------------------\n"); 
    printf("[Usage] Convert BMP24 to RGB Image Data(RGB=565). (Rev.01)\n"); 
    printf("bmp2c inputBMP24.bmp [-o outputrgb.c]\n"); 
    printf("----------------------------------------------------------\n"); 
    printf("bmp2rgb input.bmp             ... Generate input.c\n");
    printf("bmp2rgb input.bmp -o output.c ... Generate output.c\n");
    printf("----------------------------------------------------------\n"); 
    die "\n"; 
}

#---------------------------
# Parse Command Options
#---------------------------
if ($#ARGV == -1)
{
    &error_msg();
}
$opt_o = '';
$result_option = GetOptions('out=s'   => \$opt_o);  ## -o or --out with mandatory argument
if ($result_option == 0)
{
    &error_msg();
}
#---------------------------
# Check Option Parameters
#---------------------------
$fname_bmp24 = $ARGV[$#ARGV];
$image_name = $fname_bmp24;
$image_name =~ s/\..*//g;
#
if ($opt_o eq '')
{
    $fname_rgb = $image_name.".h";
}
else
{
    $fname_rgb = $opt_o;
}
#
if ($fname_bmp24 eq $fname_rgb) {&error_msg();}

#---------------------------
# Open Input Files
#---------------------------
if (! -f $fname_bmp24)
{
  die "$fname_bmp24 does not exist. \n";
}
open (IN_bmp24 , "< $fname_bmp24");
binmode(IN_bmp24);

#--------------------------
# Read BMP Header and Copy
#--------------------------
$ptrbmp = 0;

read (IN_bmp24, $buf, 2); #BM         ## 2
$ptrbmp = $ptrbmp + 2;
#
read (IN_bmp24, $buf, 4); #fileSize   ## 6
$ptrbmp = $ptrbmp + 4;
$fileSize = unpack("L1", $buf);
#
read (IN_bmp24, $buf, 4); #zero       ## 10
$ptrbmp = $ptrbmp + 4;
#
read (IN_bmp24, $buf, 4); #bodyOffset ## 14
$ptrbmp = $ptrbmp + 4;
$bodyOffset = unpack("L1", $buf);
#
read (IN_bmp24, $buf, 4); #infosize   ## 18
$ptrbmp = $ptrbmp + 4;
$infoSize = unpack("L1", $buf);
#
read (IN_bmp24, $buf, 4); #width      ## 22
$ptrbmp = $ptrbmp + 4;
$width = unpack("L1", $buf);
#
read (IN_bmp24, $buf, 4); #height     ## 26
$ptrbmp = $ptrbmp + 4;
$height = unpack("L1", $buf);
#
read (IN_bmp24, $buf, 2); #planeCount ## 28
$ptrbmp = $ptrbmp + 2;
$planeCount = unpack("S1", $buf);
#
read (IN_bmp24, $buf, 2); #pixelDepth ## 30
$ptrbmp = $ptrbmp + 2;
$pixelDepth = unpack("S1", $buf);
#
if ($pixelDepth != 24)
{
    die ("Unsupported Format: pixelDepth=%d\n", $pixelDepth);
}
#
read (IN_bmp24, $buf, 4); #zero       ## 34
$ptrbmp = $ptrbmp + 4;
$compression = unpack("L1", $buf);
#
if ($compression != 0)
{
    die ("Unsupported Format: compression=%d\n", $compression);
}
#
read (IN_bmp24, $buf, 4); #bodySize   ## 38
$ptrbmp = $ptrbmp + 4;
$bodySize = unpack("L1", $buf);
#
read (IN_bmp24, $buf, 4); #skip       ## 42
$ptrbmp = $ptrbmp + 4;
#
read (IN_bmp24, $buf, 4); #skip       ## 46
$ptrbmp = $ptrbmp + 4;
#
read (IN_bmp24, $buf, 4); #cpUsed     ## 50
$ptrbmp = $ptrbmp + 4;
$cpUsed = unpack("L1", $buf);
#
read (IN_bmp24, $buf, 4); #cpPrimary  ## 54(0x36)
$ptrbmp = $ptrbmp + 4;
$cpPrimary = unpack("L1", $buf);

printf("fileSize   = %d\n"  , $fileSize);
printf("bodyOffset = 0x%x\n", $bodyOffset);
printf("infoSize   = %d\n"  , $infoSize);
printf("width      = %d\n"  , $width);
printf("height     = %d\n"  , $height);
printf("planeCount = %d\n"  , $planeCount);
printf("pixelDepth = %d\n"  , $pixelDepth);
printf("bodySize   = %d\n"  , $bodySize);
printf("colorPalletUsed       = %d\n", $cpUsed);
printf("colorPalletImportant  = %d\n", $cpPrimary);

#---------------------------
# Read Color Pallet, if have
#---------------------------
if ($cpUsed != 0)
{
    for ($i = 0; $i < $cpUsed; $i++)
    {
        read (IN_bmp24, $buf, 4); #zero
        $ptrbmp = $ptrbmp + 4;
      ##$cp = unpack("L1", $buf);
      ##$cpRGBA[$i] = $cp;
    }
    for ($i = 0; $i < ($bodyOffset - 0x36 - $cpUsed * 4); $i++)
    {
        read (IN_bmp24, $buf, 1); # skip
        $ptrbmp = $ptrbmp + 1;
    }
}
else
{
    for ($i = 0; $i < ($bodyOffset - 0x36); $i++)
    {
        read (IN_bmp24, $buf, 1); # skip
        $ptrbmp = $ptrbmp + 1;
    }
}

#---------------------------
# Read BMP Body (only 24bit)
#---------------------------
for ($y = 0; $y < $height; $y++)
{
    for ($x = 0; $x < $width; $x++)
    {
        read (IN_bmp24, $buf, 1);
        $blu[$height - 1 - $y][$x] = unpack("C1", $buf);
        read (IN_bmp24, $buf, 1);
        $grn[$height - 1 - $y][$x] = unpack("C1", $buf);
        read (IN_bmp24, $buf, 1);
        $red[$height - 1 - $y][$x] = unpack("C1", $buf);
    }
    if ((($width * 3) % 4) != 0) # padding
    {
        for ($x = 0; $x < (4 - (($width * 3) % 4)); $x++)
        {
            read (IN_bmp24, $buf, 1); # skip
        } 
    }
}

#---------------------
# Close Input files
#---------------------
close (IN_bmp24);

#---------------------------
# Open Output Files
#---------------------------
open (OUT_rgb, "> $fname_rgb");


#----------------------
# Print Out Header
#----------------------
printf(OUT_rgb "//-------------------------------------------------------------\n");
printf(OUT_rgb "// Image data for $fname_bmp24 ; height=$height, width=$width\n");
printf(OUT_rgb "//-------------------------------------------------------------\n");
printf(OUT_rgb "#define %s_WIDTH  %d\n", $image_name, $width );
printf(OUT_rgb "#define %s_HEIGHT %d\n", $image_name, $height);

#----------------------
# Print Out Body
#----------------------
printf(OUT_rgb "static const uint16_t %s_BODY[%3d] = {\n", $image_name, $width * $height);
for ($y = 0; $y < $height; $y++)
{
    for ($x = 0; $x < $width; $x++)
    {
        $pixel = (($red[$y][$x] >> 3) << 11)
               + (($grn[$y][$x] >> 2) <<  5)
               + (($blu[$y][$x] >> 3) <<  0);
        printf(OUT_rgb "%5d", $pixel);
        if (($x == ($width - 1)) && ($y == ($height - 1)))
        {
            printf(OUT_rgb "\n");
        }
        elsif ($x == ($width - 1))
        {
            printf(OUT_rgb ",\n");
        }
        else
        {
            printf(OUT_rgb ", ");
        }
    }
}
printf(OUT_rgb "};\n");

#---------------------
# Close Output files
#---------------------
close (OUT_rgb);

#--------------------
# End of Main Routine
#--------------------
exit(0);

#====================
# End of the Program.
#====================



