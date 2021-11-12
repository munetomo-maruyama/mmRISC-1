//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : main.c
// Description : Main Routine
//-----------------------------------------------------------
// History :
// Rev.01 2021.05.08 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2021 M.Maruyama
//===========================================================
// This program is based on following program.
/*
 * FreeRTOS V202104.00
 * Copyright (C) 2020 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * https://www.FreeRTOS.org
 * https://www.github.com/FreeRTOS
 *
 * 1 tab == 4 spaces!
 */

// FreeRTOS kernel includes
#include "FreeRTOS.h"
#include "task.h"

// mmRISC includes
#include "common.h"
#include "gpio.h"
#include "interrupt.h"
#include "uart.h"
#include "xprintf.h"

// Prototypes
void vApplicationMallocFailedHook( void );
void vApplicationIdleHook( void );
void vApplicationStackOverflowHook( TaskHandle_t pxTask, char *pcTaskName );
void vApplicationTickHook( void );
int main_blinky( void );

//-------------------------------------------
// Run a simple demo just prints 'Blink'
//-------------------------------------------
int main( void )
{
    int ret;
    //
    // Initialize Hardware
    GPIO_Init();
    UART_Init();
    INT_Init();
    //
    // Demo
    ret = main_blinky();
    return ret;
}

//-----------------------------------------------------------------------------
// vApplicationMallocFailedHook
// vApplicationMallocFailedHook() will only be called if
// configUSE_MALLOC_FAILED_HOOK is set to 1 in FreeRTOSConfig.h.  It is a hook
// function that will get called if a call to pvPortMalloc() fails.
// pvPortMalloc() is called internally by the kernel whenever a task, queue,
// timer or semaphore is created.  It is also called by various parts of the
// demo application.  If heap_1.c or heap_2.c are used, then the size of the
// heap available to pvPortMalloc() is defined by configTOTAL_HEAP_SIZE in
// FreeRTOSConfig.h, and the xPortGetFreeHeapSize() API function can be used
// to query the size of free heap space that remains (although it does not
// provide information on how the remaining heap might be fragmented).
//-----------------------------------------------------------------------------
void vApplicationMallocFailedHook( void )
{
    taskDISABLE_INTERRUPTS();
    for( ;; );
}

//-----------------------------------------------------------------------------
// vApplicationIdleHook
// vApplicationIdleHook() will only be called if configUSE_IDLE_HOOK is set
// to 1 in FreeRTOSConfig.h.  It will be called on each iteration of the idle
// task.  It is essential that code added to this hook function never attempts
// to block in any way (for example, call xQueueReceive() with a block time
// specified, or call vTaskDelay()).  If the application makes use of the
// vTaskDelete() API function (as this demo application does) then it is also
// important that vApplicationIdleHook() is permitted to return to its calling
// function, because it is the responsibility of the idle task to clean up
// memory allocated by the kernel to any task that has since been deleted.
//-----------------------------------------------------------------------------
void vApplicationIdleHook( void )
{
}

//-----------------------------------------------------------------------------
// vApplicationStackOverflowHook
// Run time stack overflow checking is performed if
// configCHECK_FOR_STACK_OVERFLOW is defined to 1 or 2.  This hook
// function is called if a stack overflow is detected.
//-----------------------------------------------------------------------------
void vApplicationStackOverflowHook( TaskHandle_t pxTask, char *pcTaskName )
{
    ( void ) pcTaskName;
    ( void ) pxTask;

    taskDISABLE_INTERRUPTS();
    for( ;; );
}
//-----------------------------------------------------------------------------
// vApplicationTickHook
//-----------------------------------------------------------------------------
void vApplicationTickHook( void )
{
}
//-----------------------------------------------------------------------------
// vAssertCalled
//-----------------------------------------------------------------------------
void vAssertCalled( void )
{
    volatile uint32_t ulSetTo1ToExitFunction = 0;
    taskDISABLE_INTERRUPTS();
    while( ulSetTo1ToExitFunction != 1 )
    {
        __asm volatile( "NOP" );
    }
}

//===========================================================
// End of Program
//===========================================================
