//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : tictactoe.h
// Description : TicTacToe Game Header
//-----------------------------------------------------------
// History :
// Rev.01 2023.11.18 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2023 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"
#include "touchlcd_tft.h"

//----------------------------
// Macro for Draw Coordinates
//----------------------------
#define COLOR_1ST_B COLOR_RED
#define COLOR_1ST_F COLOR_WHITE
#define COLOR_2ND_B COLOR_GREEN
#define COLOR_2ND_F COLOR_BLACK
//
#define GPOS_BOARD_ORG_X     15
#define GPOS_BOARD_ORG_Y     15
#define GPOS_BOARD_CELL_X    70
#define GPOS_BOARD_CELL_Y    GPOS_BOARD_CELL_X
#define GPOS_BOARD_LINE_WIDTH 4
#define GPOS_MOVE_O_RADIUS (GPOS_BOARD_CELL_X / 2 - 5)
#define GPOS_MOVE_X_RADIUS (GPOS_BOARD_CELL_X / 2 - 5)
//
#define TPOS_1ST_X   3
#define TPOS_1ST_Y  11
#define TPOS_OR_X    8
#define TPOS_OR_Y   11
#define TPOS_2ND_X  13
#define TPOS_2ND_Y  11
#define GPOS_1ST_X (TPOS_1ST_X * 16 - 8)
#define GPOS_1ST_Y (TPOS_1ST_Y * 16 - 8)
#define GPOS_1ST_W (64 + 16)
#define GPOS_1ST_H (16 + 16)
#define GPOS_2ND_X (TPOS_2ND_X * 16 - 8)
#define GPOS_2ND_Y (TPOS_2ND_Y * 16 - 8)
#define GPOS_2ND_W (64 + 16)
#define GPOS_2ND_H (16 + 16)
//
#define TPOS_TURN_X 15
#define TPOS_TURN_Y  2
#define GPOS_TURN_X (TPOS_TURN_X * 16 - 8)
#define GPOS_TURN_Y (TPOS_TURN_Y * 16 - 8)
#define GPOS_TURN_W (64 + 16)
#define GPOS_TURN_H (32 + 16)
//
#define TPOS_CPULOG_X 31
#define TPOS_CPULOG_Y 11
//
#define TPOS_FIN_X 15
#define TPOS_FIN_Y 12
#define GPOS_FIN_X (TPOS_FIN_X * 16 - 8)
#define GPOS_FIN_Y (TPOS_FIN_Y * 16 - 8)
#define GPOS_FIN_W (64 + 16)
#define GPOS_FIN_H (32 + 16)




//--------------------------------------------------------
// Touch Panel Control for both Resistive and Capacitive
//--------------------------------------------------------
enum TOUCH_DEVICE {TOUCH_NONE, TOUCH_RESISTIVE, TOUCH_CAPACITIVE};

//---------------------------------
// Prototype
//---------------------------------
void TicTacToe_on_Terminal(void);
void TicTacToe_on_TouchLCD(uint32_t touch_dev);

//===========================================================
// End of Program
//===========================================================
