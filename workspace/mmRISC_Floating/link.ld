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

MEMORY {
  ROM (rx) : ORIGIN = 0x90000000, LENGTH = 128K
# RAM (rw) : ORIGIN = 0x88000000, LENGTH =  48K 
  RAM (rw) : ORIGIN = 0x80000000, LENGTH =  64M
}

STACK_SIZE = 32K;

SECTIONS {

  .vectors ORIGIN(ROM) : {
    . = ALIGN(0x100);    
    KEEP(*(.vectors));
    FILL(0);
    LONG(0);
  } >ROM

  .trap  : {
    . = ALIGN(0x100);
    KEEP(*(.trap));
    FILL(0);
    LONG(0);
  } >ROM

  .startup  : {
    . = ALIGN(0x100);
    *(.startup*)
    KEEP(*(.startup));
    FILL(0);
    LONG(0);
  } >ROM

  .text : {
    . = ALIGN(0x100);
    PROVIDE(__TEXT_START__ = .);
    *(.text.main)
    *(.text)
    *(.text.*)
     PROVIDE(__TEXT_END__ = .);
  } >ROM

  .rodata : {
    . = ALIGN(0x100);
    *(.rodata)
    *(.rodata.*)
    . = ALIGN(4);
     PROVIDE(__ROM_INIT_BGN__ = .);
  } >ROM
  
  .data : {
    . = ALIGN(0x100);
    PROVIDE(__RAM_INIT_BGN__ = .);
    *(.data)
    *(.data*)
  } >RAM AT> ROM

  .srodata : {
    PROVIDE(__GLOBAL_PTR__ = . + 0x0800);
    *(.srodata)
    *(.srodata*)
  } >RAM AT> ROM

  .sdata : {
    *(.sdata)
    *(.sdata.*)
    PROVIDE(__RAM_INIT_END__ = .);
  } >RAM AT> ROM

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
