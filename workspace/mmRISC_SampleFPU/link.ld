/*
//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : link.ld
// Description : Linker Script
//-----------------------------------------------------------
// History :
// Rev.01 2020.09.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================
*/

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*
// FAST RAM in FPGA : ORIGIN = 0x90000000, LENGTH =   128K
// FAST RAM in FPGA : ORIGIN = 0x88000000, LENGTH =    48K
// SLOW SDRAM       : ORIGIN = 0x80000000, LENGTH = 65536K
*/

MEMORY {
  ROM_BOOT (rx) : ORIGIN = 0x90000000, LENGTH =     2K
  ROM_MAIN (rx) : ORIGIN = 0x90000800, LENGTH =   126K
  RAM      (rw) : ORIGIN = 0x88000000, LENGTH =    48K
}
STACK_SIZE = 40K;

SECTIONS {

  .vectors ORIGIN(ROM_BOOT) : {
    . = ALIGN(0x100);    
    KEEP(*(.vectors));
    FILL(0);
    LONG(0);
  } >ROM_BOOT

  .trap  : {
    . = ALIGN(0x100);
    KEEP(*(.trap));
    FILL(0);
    LONG(0);
  } >ROM_BOOT

  .startup  : {
    . = ALIGN(0x100);
    *(.startup*)
    KEEP(*(.startup));
    FILL(0);
    LONG(0);
  } >ROM_BOOT

  .text : {
    . = ALIGN(0x100);
    PROVIDE(__TEXT_START__ = .);
    *(.text.main)
    *(.text)
    *(.text.*)
     PROVIDE(__TEXT_END__ = .);
  } >ROM_MAIN

  .rodata : {
    . = ALIGN(0x100);
    *(.rodata)
    *(.rodata.*)
    . = ALIGN(4);
     PROVIDE(__ROM_INIT_BGN__ = .);
  } >ROM_MAIN
  
  .data : {
    . = ALIGN(0x100);
    PROVIDE(__RAM_INIT_BGN__ = .);
    *(.data)
    *(.data*)
  } >RAM AT> ROM_MAIN

  .srodata : {
    PROVIDE(__GLOBAL_PTR__ = . + 0x0800);
    *(.srodata)
    *(.srodata*)
  } >RAM AT> ROM_MAIN

  .sdata : {
    *(.sdata)
    *(.sdata.*)
    PROVIDE(__RAM_INIT_END__ = .);
  } >RAM AT> ROM_MAIN

  .sbss : {
    PROVIDE(__BSS_BGN__ = .);
    *(.sbss)
    *(.sbss.*)
    *(.scommon)
  } >RAM

  .bss : {
    *(.bss)
    *(.bss.*)
    . = ALIGN(4);
    PROVIDE(__BSS_END__ = .);
  } >RAM

  .stack ORIGIN(RAM) + LENGTH(RAM) - STACK_SIZE : {
    PROVIDE(__STACK_START__ = .);
    . += STACK_SIZE;
    PROVIDE(__STACK_TOP__ = .);
    PROVIDE(__STACK_END__ = .);
  } >RAM

  /DISCARD/ : {
    *(.eh_frame .eh_frame.*)
  }
}

/*
//===========================================================
// End of Program
//===========================================================
*/
