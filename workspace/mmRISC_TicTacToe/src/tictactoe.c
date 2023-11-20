//===========================================================
// mmRISC Project
//-----------------------------------------------------------
// File Name   : tictactoe.c
// Description : TicTacToe Game Routine
//-----------------------------------------------------------
// History :
// Rev.01 2023.11.18 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2020-2023 M.Maruyama
//===========================================================

#include <stdint.h>
#include "common.h"
#include "tictactoe.h"
#include "touchlcd_tft.h"
#include "touchlcd_res.h"
#include "touchlcd_cap.h"
#include "uart.h"
#include "xprintf.h"

//===========================================================
// Common Routine
//===========================================================
//--------------------
// Winner Check
//--------------------
int8_t Winner_Check(int8_t *board)
{
    if ((board[0]!=0)&&(board[0]==board[1])&&(board[1]==board[2])) return board[0];
    if ((board[3]!=0)&&(board[3]==board[4])&&(board[4]==board[5])) return board[3];
    if ((board[6]!=0)&&(board[6]==board[7])&&(board[7]==board[8])) return board[6];
    if ((board[0]!=0)&&(board[0]==board[3])&&(board[3]==board[6])) return board[0];
    if ((board[1]!=0)&&(board[1]==board[4])&&(board[4]==board[7])) return board[1];
    if ((board[2]!=0)&&(board[2]==board[5])&&(board[5]==board[8])) return board[2];
    if ((board[0]!=0)&&(board[0]==board[4])&&(board[4]==board[8])) return board[0];
    if ((board[2]!=0)&&(board[2]==board[4])&&(board[4]==board[6])) return board[2];
    return 0;
}

//-------------------------------
// MiniMax Method
//-------------------------------
int8_t MiniMax(int8_t *board, int8_t player, int8_t depth)
{
    // Evaluation at Leaf
    int8_t winner = Winner_Check(board);
    if (winner * player > 0) // Player's best
        return +100 - depth;
    else if (winner * player < 0) // Player's worst
        return -100 + depth;
    //
    // Evaluation before Leaf
    int8_t move  = -1;
    int8_t value = -128;
    int8_t value_try;
    int8_t i;
    for(i = 0; i < 9; i = i + 1)
    {
        if(board[i] == 0)
        {
            board[i] = player; // Try
            value_try = -MiniMax(board, player * -1, depth + 1);
            if(value_try > value)
            {
                value = value_try;
                move = i;
            }
            board[i] = 0; // Revert
        }
    }
    value = (move == -1)? 0 : value;
    return value;
}

//===========================================================
// Terminal Version
//===========================================================
//----------------------------
// Get a Character from UART
//----------------------------
uint8_t Get_Char(void)
{
    uint8_t ch;
    ch = UART_RxD();
    return ch;
}

//-------------------------
// Draw Board on Terminal
//-------------------------
void Draw_Board_on_Terminal(int8_t *board)
{
    uint8_t i;
    uint8_t ch;
    //
    for (i = 0; i < 9; i++)
    {
        // Print current Board
        if ((i % 3) == 0) printf("  ");
        ch = (board[i] == +1)? 'O' : (board[i] == -1)? 'X' : '.';
        printf("%c", ch);
        //
        // Print Map Help
        if (i == 2) printf("  (012)\r\n");
        if (i == 5) printf("  (345)\r\n");
        if (i == 8) printf("  (678)\r\n");
    }
}

//-------------------------
// Move by You on Terminal
//-------------------------
void Move_by_YOU_on_Terminal(int8_t *board, int8_t player)
{
    uint8_t ch;
    //
    // Ask Move?
    while(1)
    {
        printf("[You] Move to [0-8] ? ");
        ch = Get_Char();
        printf("%c\r\n", ch);
        if ((ch >= '0') && (ch <= '8'))
        {
            if (board[ch - '0'] == 0) break;
        }
    }
    //
    // Move your selection
    board[ch - '0'] = player;
}

//--------------------------
// Move by CPU on Terminal
//--------------------------
void Move_by_CPU_on_Terminal(int8_t *board, int8_t player)
{
    int8_t value = -128;
    int8_t value_try;
    int8_t move = -1;
    int8_t i;
    //
    for (i = 0; i < 9; i++)
    {
        if (board[i] == 0) // vacant
        {
            board[i] = player; // Try
            value_try = -MiniMax(board, -player, 0);
            // Debug
            // printf("move=%d,value_try=%d\r\n", (int)i, (int)value_try);
            board[i] =  0; // Revert
            if (value_try > value)
            {
                value = value_try;
                move = i;
            }
        }
    }
    board[move] = player;
    printf("[CPU] Move to %d\r\n", move);
}

//------------------------
// TicTacToe on Terminal
//------------------------
void TicTacToe_on_Terminal(void)
{
    uint8_t i;
    uint8_t ch;
    uint8_t turn;
    int8_t  player;
    int8_t  winner;
    int8_t  board[9]; // You=+1, AI=-1, Vacant=0
    //
    // Repeat Games
    while(1)
    {
        // Message
        printf("\r\n=== TictacToe Game ===\r\n");
        //
        // Ask 1st or 2nd?
        while(1)
        {
            printf("1st or 2nd [1-2] ? ");
            ch = Get_Char();
            if ((ch == '1') || (ch == '2'))
            {
                printf("%c\r\n", ch);
                break;
            }
        }
        //
        // Initialize Board
        for (i = 0; i < 9; i = i + 1) board[i] = 0;
        Draw_Board_on_Terminal(board);
        //
        // Play a Game!
        player = (ch == '1')? +1 : -1;
        for (turn = 0; turn < 9; turn++)
        {
            // Check Winner
            winner = Winner_Check(board);
            if (winner != 0) break;
            //
            // Do Move
            if (player == +1) Move_by_YOU_on_Terminal(board, player);
            if (player == -1) Move_by_CPU_on_Terminal(board, player);
            Draw_Board_on_Terminal(board);
            player = -player;
        }
        //
        // Print Result
        printf("-----------------\r\n");
        if (winner == 1)
            printf("--- You  won! ---\r\n");
        else if (winner == -1)
            printf("--- You lose! ---\r\n");
        else
            printf("---   Draw!   ---\r\n");
        printf("-----------------\r\n");
    }
}

//===========================================================
// Touch LCD Version
//===========================================================
//----------------------
// Image to draw
//----------------------
#include "logo.h"

//--------------------------------------------------------
// Touch Panel Control for both Resistive and Capacitive
//--------------------------------------------------------
uint32_t TOUCH_Touched(uint32_t touch_dev)
{
    if (touch_dev == TOUCH_RESISTIVE ) return TOUCH_RES_Touched();
    if (touch_dev == TOUCH_CAPACITIVE) return TOUCH_CAP_Touched();
    return 0;
}
//
uint32_t TOUCH_Buffer_Empty(uint32_t touch_dev)
{
    if (touch_dev == TOUCH_RESISTIVE)  return TOUCH_RES_Buffer_Empty();
    if (touch_dev == TOUCH_CAPACITIVE) return 0;
    return 0;
}
//
void TOUCH_Get_Point(TS_Point *point, uint32_t touch_dev)
{
    if (touch_dev == TOUCH_RESISTIVE ) TOUCH_RES_Get_Point(point);
    if (touch_dev == TOUCH_CAPACITIVE) TOUCH_CAP_Get_Point(point);
}
//
void TOUCH_Buffer_Clear(uint32_t touch_dev)
{
    if (touch_dev == TOUCH_RESISTIVE ) TOUCH_RES_Buffer_Clear();
    if (touch_dev == TOUCH_CAPACITIVE) return;
}

//--------------------------------
// Ask 1st or 2nd on Touch LCD
//--------------------------------
int8_t Ask_1st_or_2nd_on_TouchLCD(uint32_t touch_dev)
{
    char str_1st[] = "1st?";
    char str_or[]  = " or ";
    char str_2nd[] = "2nd?";
    uint32_t touched;
    TS_Point point;
    int8_t   player;
    //
    // Draw Ask Message
    LCD_Fill_Rect(GPOS_1ST_X, GPOS_1ST_Y, GPOS_1ST_W, GPOS_1ST_H,
                  COLOR_1ST_B);
    LCD_Draw_String(str_1st, TPOS_1ST_X,  TPOS_1ST_Y,
                    COLOR_1ST_F, COLOR_1ST_B, FONT_MEDIUM);
    //
    LCD_Draw_String(str_or , TPOS_OR_X,   TPOS_OR_Y,
                    COLOR_WHITE, COLOR_BLACK, FONT_MEDIUM);
    //
    LCD_Fill_Rect(GPOS_2ND_X, GPOS_2ND_Y, GPOS_2ND_W, GPOS_2ND_H,
                  COLOR_2ND_B);
    LCD_Draw_String(str_2nd, TPOS_2ND_X,  TPOS_2ND_Y,
                    COLOR_2ND_F, COLOR_2ND_B, FONT_MEDIUM);
    //
    // Wait for Touch
    TOUCH_Buffer_Clear(touch_dev);
    while(1)
    {
        touched = TOUCH_Touched(touch_dev);
        if (touched)
        {
            point.x = 0; point.y = 0; point.z = 0;
            if (TOUCH_Buffer_Empty(touch_dev) == 0)
            {
                TOUCH_Get_Point(&point, touch_dev);
                TOUCH_Buffer_Clear(touch_dev);
            }
            //
            if ((point.x >= GPOS_1ST_X) && (point.x <= GPOS_1ST_X + GPOS_1ST_W)
             && (point.y >= GPOS_1ST_Y) && (point.y <= GPOS_1ST_Y + GPOS_1ST_H))
            {
                player = +1;
                LCD_Draw_Rect(GPOS_1ST_X-2, GPOS_1ST_Y-2, GPOS_1ST_W, GPOS_1ST_H,
                              COLOR_YELLOW, 4);
                break;
            }
            if ((point.x >= GPOS_2ND_X) && (point.x <= GPOS_2ND_X + GPOS_2ND_W)
             && (point.y >= GPOS_2ND_Y) && (point.y <= GPOS_2ND_Y + GPOS_2ND_H))
            {
                player = -1;
                LCD_Draw_Rect(GPOS_2ND_X-2, GPOS_2ND_Y-2, GPOS_2ND_W, GPOS_2ND_H,
                              COLOR_YELLOW, 4);
                break;
            }
        }
    }
    return player;
}

//------------------------
// Draw a New Board on LCD
//------------------------
void Draw_New_Board_on_LCD(void)
{
    uint16_t x, y;
    //
    LCD_Fill_Rect(0, 0, 320, 240, COLOR_BLACK);
    //
    for (x = 0; x < 4; x = x + 1)
    {
        LCD_Fill_Rect(GPOS_BOARD_ORG_X + GPOS_BOARD_CELL_X * x, GPOS_BOARD_ORG_Y,
                      GPOS_BOARD_LINE_WIDTH, GPOS_BOARD_LINE_WIDTH + GPOS_BOARD_CELL_Y * 3,
                      COLOR_WHITE);
    }
    for (y = 0; y < 4; y = y + 1)
    {
        LCD_Fill_Rect(GPOS_BOARD_ORG_X, GPOS_BOARD_ORG_Y + GPOS_BOARD_CELL_Y * y,
                      GPOS_BOARD_LINE_WIDTH + GPOS_BOARD_CELL_X * 3, GPOS_BOARD_LINE_WIDTH,
                      COLOR_WHITE);
    }
}

//-------------------------
// Draw Mode on TouchLCD
//-------------------------
void Draw_Move_on_TouchLCD(int8_t move, int8_t player, uint8_t turn)
{
    uint16_t x, y;
    uint16_t color;
    //
    x = (uint16_t)move % 3;
    y = (uint16_t)move / 3;
    x = GPOS_BOARD_ORG_X + (GPOS_BOARD_CELL_X / 2) + (GPOS_BOARD_CELL_X * x);
    y = GPOS_BOARD_ORG_Y + (GPOS_BOARD_CELL_Y / 2) + (GPOS_BOARD_CELL_Y * y);
    color = (turn % 2)? COLOR_2ND_B : COLOR_1ST_B;
    //
    // Draw "O"
    if (player > 0)
    {
        LCD_Draw_Circle((int16_t)x, (int16_t)y, GPOS_MOVE_O_RADIUS, color, 2);
    }
    //
    // Draw "X"
    else
    {
        LCD_Draw_Line(x - GPOS_MOVE_X_RADIUS, y - GPOS_MOVE_X_RADIUS,
                      x + GPOS_MOVE_X_RADIUS, y + GPOS_MOVE_X_RADIUS,
                      color, 2);
        LCD_Draw_Line(x + GPOS_MOVE_X_RADIUS, y - GPOS_MOVE_X_RADIUS,
                      x - GPOS_MOVE_X_RADIUS, y + GPOS_MOVE_X_RADIUS,
                      color, 2);
    }
}

//-------------------------
// Move by You on TouchLCD
//-------------------------
void Move_by_YOU_on_TouchLCD(int8_t *board, int8_t player, uint8_t turn, uint32_t touch_dev)
{
    uint32_t touched;
    TS_Point point;
    uint16_t cell_x, cell_y;
    uint16_t color_f, color_b;
    int8_t move;
    //
    // Message
    char str1[] = "Your";
    char str2[] = "Turn";
    color_f = (turn % 2)? COLOR_2ND_F : COLOR_1ST_F;
    color_b = (turn % 2)? COLOR_2ND_B : COLOR_1ST_B;
    LCD_Fill_Rect(GPOS_TURN_X, GPOS_TURN_Y, GPOS_TURN_W, GPOS_TURN_H, color_b);
    LCD_Draw_String(str1, TPOS_TURN_X,  TPOS_TURN_Y    , color_f, color_b, FONT_MEDIUM);
    LCD_Draw_String(str2, TPOS_TURN_X,  TPOS_TURN_Y + 1, color_f, color_b, FONT_MEDIUM);
    //
    TOUCH_Buffer_Clear(touch_dev);
    while(1)
    {
        // Wait for Touch
        while(1)
        {
            touched = TOUCH_Touched(touch_dev);
            if (touched)
            {
                point.x = 0; point.y = 0; point.z = 0;
                if (TOUCH_Buffer_Empty(touch_dev) == 0)
                {
                    TOUCH_Get_Point(&point, touch_dev);
                    TOUCH_Buffer_Clear(touch_dev);
                }
                //
                if ((point.x >= GPOS_BOARD_ORG_X) && (point.y >= GPOS_BOARD_ORG_Y))
                {
                    cell_x = (point.x - GPOS_BOARD_ORG_X) / GPOS_BOARD_CELL_X;
                    cell_y = (point.y - GPOS_BOARD_ORG_Y) / GPOS_BOARD_CELL_Y;
                    if ((cell_x < 3) && (cell_y < 3))
                    {
                        move = (int8_t)(cell_x + cell_y * 3);
                        break;
                    }
                }
            }
        }
        //
        if ((move >= 0) && (move <= 8))
        {
            if (board[move] == 0) break;
        }
    }
    //
    // Move your selection
    Draw_Move_on_TouchLCD(move, player, turn);
    board[move] = player;
}

//--------------------------
// Move by CPU on TouchLCD
//--------------------------
void Move_by_CPU_on_TouchLCD(int8_t *board, int8_t player, int8_t turn)
{
    int8_t value = -128;
    int8_t value_try;
    int8_t move = -1;
    int8_t i;
    uint16_t color_f, color_b;
    //
    // Message
    char str1[] = "CPU ";
    char str2[] = "Turn";
    color_f = (turn % 2)? COLOR_2ND_F : COLOR_1ST_F;
    color_b = (turn % 2)? COLOR_2ND_B : COLOR_1ST_B;
    LCD_Fill_Rect(GPOS_TURN_X, GPOS_TURN_Y, GPOS_TURN_W, GPOS_TURN_H, color_b);
    LCD_Draw_String(str1, TPOS_TURN_X,  TPOS_TURN_Y    , color_f, color_b, FONT_MEDIUM);
    LCD_Draw_String(str2, TPOS_TURN_X,  TPOS_TURN_Y + 1, color_f, color_b, FONT_MEDIUM);
    //
    char str3[] = "CPU Log";
    char str4[] = "POS VAL";
    char str5[20];
    LCD_Draw_String(str3, TPOS_CPULOG_X,  TPOS_CPULOG_Y,
                    COLOR_WHITE, COLOR_BLACK, FONT_SMALL);
    LCD_Draw_String(str4, TPOS_CPULOG_X,  TPOS_CPULOG_Y + 1,
                    COLOR_WHITE, COLOR_BLACK, FONT_SMALL);
    //
    for (i = 0; i < 9; i++)
    {
        if (board[i] == 0) // vacant
        {
            board[i] = player; // Try
            value_try = -MiniMax(board, -player, 0);
            board[i] =  0; // Revert
            if (value_try > value)
            {
                value = value_try;
                move = i;
            }
            xsprintf(str5, "%3d %3d", i, value_try);
            LCD_Draw_String(str5, TPOS_CPULOG_X,  TPOS_CPULOG_Y + 3 + i,
                            COLOR_WHITE, COLOR_BLACK, FONT_SMALL);
        }
        else
        {
            xsprintf(str5, "%3d ---", i);
            LCD_Draw_String(str5, TPOS_CPULOG_X,  TPOS_CPULOG_Y + 3 + i,
                            COLOR_WHITE, COLOR_BLACK, FONT_SMALL);
        }
    }
    //
    // Move CPU selection
    Draw_Move_on_TouchLCD(move, player, turn);
    board[move] = player;
}

//------------------------
// TicTacToe on Touch LCD
//------------------------
void TicTacToe_on_TouchLCD(uint32_t touch_dev)
{
    uint8_t i;
    uint8_t turn;
    int8_t  player;
    int8_t  winner;
    int8_t  board[9]; // You=+1, AI=-1, Vacant=0
    uint16_t color_f, color_b;
    uint32_t touched;
    TS_Point point;
    char str1[] = "Play TicTacToe!";
    //
    // Repeat Games
    while(1)
    {
        // Draw Title
        LCD_Draw_Image(0, 0, logo_BODY, logo_WIDTH, logo_HEIGHT);
        LCD_Fill_Rect(0, 120, 320, 120, COLOR_BLACK);
        LCD_Draw_String(str1, 3,  8, COLOR_YELLOW, COLOR_BLACK, FONT_MEDIUM);
        //
        // Ask 1st or 2nd?
        player = Ask_1st_or_2nd_on_TouchLCD(touch_dev);
        //
        // Initialize Board
        for (i = 0; i < 9; i = i + 1) board[i] = 0;
        Draw_New_Board_on_LCD();
        //
        // Play a Game!
        for (turn = 0; turn < 9; turn++)
        {
            // Check Winner
            winner = Winner_Check(board);
            if (winner != 0) break;
            //
            // Do Move
            if (player == +1) Move_by_YOU_on_TouchLCD(board, player, turn, touch_dev);
            if (player == -1) Move_by_CPU_on_TouchLCD(board, player, turn);
            player = -player;
        }
        //
        // Print Result
        if (winner == +1)
        {
            char str1[] = "You ";
            char str2[] = "Win!";
            //
            LCD_Fill_Rect(GPOS_FIN_X, GPOS_FIN_Y, GPOS_FIN_W, GPOS_FIN_H, COLOR_GREEN);
            LCD_Draw_String(str1, TPOS_FIN_X,  TPOS_FIN_Y    , COLOR_BLUE, COLOR_GREEN, FONT_MEDIUM);
            LCD_Draw_String(str2, TPOS_FIN_X,  TPOS_FIN_Y + 1, COLOR_BLUE, COLOR_GREEN, FONT_MEDIUM);
        }
        else if (winner == -1)
        {
            char str1[] = "You ";
            char str2[] = "Lose";
            //
            LCD_Fill_Rect(GPOS_FIN_X, GPOS_FIN_Y, GPOS_FIN_W, GPOS_FIN_H, COLOR_DARKGRAY);
            LCD_Draw_String(str1, TPOS_FIN_X,  TPOS_FIN_Y    , COLOR_WHITE, COLOR_DARKGRAY, FONT_MEDIUM);
            LCD_Draw_String(str2, TPOS_FIN_X,  TPOS_FIN_Y + 1, COLOR_WHITE, COLOR_DARKGRAY, FONT_MEDIUM);
        }
        else
        {
            char str1[] = "Draw";
            //
            LCD_Draw_String(str1, TPOS_FIN_X,  TPOS_FIN_Y    , COLOR_WHITE, COLOR_BLACK, FONT_MEDIUM);
        }
        //
        // Wait for Touch Release
        TOUCH_Buffer_Clear(touch_dev);
        while(1)
        {
            touched = TOUCH_Touched(touch_dev);
            if (touched == 0) break;
        }
        //
        // Wait for Touch
        while(1)
        {
            touched = TOUCH_Touched(touch_dev);
            if (touched) break;
        }
    }
}


//===========================================================
// End of Program
//===========================================================
