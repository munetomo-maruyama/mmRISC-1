/*
 * startrek.c
 *
 * Super Star Trek Classic (v1.1)
 * Retro Star Trek Game
 * C Port Copyright (C) 1996  <Chris Nystrom>
 *
 * This program is free software; you can redistribute it and/or modify
 * in any way that you wish. _Star Trek_ is a trademark of Paramount
 * I think.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * This is a C port of an old BASIC program: the classic Super Star Trek
 * game. It comes from the book _BASIC Computer Games_ edited by David Ahl
 * of Creative Computing fame. It was published in 1978 by Workman Publishing,
 * 1 West 39 Street, New York, New York, and the ISBN is: 0-89489-052-3.
 *
 * See http://www.cactus.org/~nystrom/startrek.html for more info.
 *
 * Contact Author of C port at:
 *
 * Chris Nystrom
 * 1013 Prairie Dove Circle
 * Austin, Texas  78758
 *
 * E-Mail: cnystrom@gmail.com, nystrom@cactus.org
 *
 * BASIC -> Conversion Issues
 *
 *     - String Names changed from A$ to sA
 *     - Arrays changed from G(8,8) to g[9][9] so indexes can
 *       stay the same.
 *
 * Here is the original BASIC header:
 *
 * SUPER STARTREK - MAY 16, 1978 - REQUIRES 24K MEMORY
 *
 ***        **** STAR TREK ****        ****
 *** SIMULATION OF A MISSION OF THE STARSHIP ENTERPRISE,
 *** AS SEEN ON THE STAR TREK TV SHOW.
 *** ORIGINAL PROGRAM BY MIKE MAYFIELD, MODIFIED VERSION
 *** PUBLISHED IN DEC'S "101 BASIC GAMES", BY DAVE AHL.
 *** MODIFICATIONS TO THE LATTER (PLUS DEBUGGING) BY BOB
 *** LEEDOM - APRIL & DECEMBER 1974,
 *** WITH A LITTLE HELP FROM HIS FRIENDS . . .
 *** COMMENTS, EPITHETS, AND SUGGESTIONS SOLICITED --
 *** SEND TO:  R. C. LEEDOM
 ***           WESTINGHOUSE DEFENSE & ELECTRONICS SYSTEMS CNTR.
 ***           BOX 746, M.S. 338
 ***           BALTIMORE, MD  21203
 ***
 *** CONVERTED TO MICROSOFT 8 K BASIC 3/16/78 BY JOHN BORDERS
 *** LINE NUMBERS FROM VERSION STREK7 OF 1/12/75 PRESERVED AS
 *** MUCH AS POSSIBLE WHILE USING MULTIPLE STATMENTS PER LINE
 *
 */

#include <stdint.h>
#include "common.h"
#include "xprintf.h"

void show_document(void)
{
    const uint8_t *doc =
"\n\
1. When you see _Command?_ printed, enter one of the legal commands          \n\
   (nav, srs, lrs, pha, tor, she, dam, com, or xxx).                         \n\
                                                                             \n\
2. If you should type in an illegal command, you'll get a short list of      \n\
   the legal commands printed out.                                           \n\
                                                                             \n\
3. Some commands require you to enter data (for example, the 'nav' command   \n\
   comes back with 'Course(1-9) ?'.) If you type in illegal data (like       \n\
   negative numbers), that command will be aborted.                          \n\
                                                                             \n\
  The galaxy is divided into an 8 X 8 quadrant grid, and each quadrant       \n\
is further divided into an 8 x 8 sector grid.                                \n\
                                                                             \n\
  You will be assigned a starting point somewhere in the galaxy to begin     \n\
a tour of duty as commander of the starship _Enterprise_; your mission:      \n\
to seek out and destroy the fleet of Klingon warships which are menacing     \n\
the United Federation of Planets.                                            \n\
                                                                             \n\
  You have the following commands available to you as Captain of the Starship\n\
Enterprise:                                                                  \n\
                                                                             \n\
\\nav\\ Command = Warp Engine Control --                                     \n\
                                                                             \n\
  Course is in a circular numerical vector            4  3  2                \n\
  arrangement as shown. Integer and real               . . .                 \n\
  values may be used. (Thus course 1.5 is               ...                  \n\
  half-way between 1 and 2.                         5 ---*--- 1              \n\
                                                        ...                  \n\
  Values may approach 9.0, which itself is             . . .                 \n\
  equivalent to 1.0.                                  6  7  8                \n\
                                                                             \n\
  One warp factor is the size of one quadrant.        COURSE                 \n\
  Therefore, to get from quadrant 6,5 to 5,5                                 \n\
  you would use course 3, warp factor 1.                                     \n\
                                                                             \n\
\\srs\\ Command = Short Range Sensor Scan                                    \n\
                                                                             \n\
  Shows you a scan of your present quadrant.                                 \n\
                                                                             \n\
  Symbology on your sensor screen is as follows:                             \n\
    <*> = Your starship's position                                           \n\
    +K+ = Klingon battlecruiser                                              \n\
    >!< = Federation starbase (Refuel/Repair/Re-Arm here)                    \n\
     *  = Star                                                               \n\
                                                                             \n\
  A condensed 'Status Report' will also be presented.                        \n\
                                                                             \n\
\\lrs\\ Command = Long Range Sensor Scan                                     \n\
                                                                             \n\
  Shows conditions in space for one quadrant on each side of the Enterprise  \n\
  (which is in the middle of the scan). The scan is coded in the form \\###\\\n\
  where the units digit is the number of stars, the tens digit is the number \n\
  of starbases, and the hundreds digit is the number of Klingons.            \n\
                                                                             \n\
  Example - 207 = 2 Klingons, No Starbases, & 7 stars.                       \n\
                                                                             \n\
\\pha\\ Command = Phaser Control.                                            \n\
                                                                             \n\
  Allows you to destroy the Klingon Battle Cruisers by zapping them with     \n\
  suitably large units of energy to deplete their shield power. (Remember,   \n\
  Klingons have phasers, too!)                                               \n\
                                                                             \n\
\\tor\\ Command = Photon Torpedo Control                                     \n\
                                                                             \n\
  Torpedo course is the same  as used in warp engine control. If you hit     \n\
  the Klingon vessel, he is destroyed and cannot fire back at you. If you    \n\
  miss, you are subject to the phaser fire of all other Klingons in the      \n\
  quadrant.                                                                  \n\
                                                                             \n\
  The Library-Computer (\\com\\ command) has an option to compute torpedo    \n\
  trajectory for you (option 2).                                             \n\
                                                                             \n\
\\she\\ Command = Shield Control                                             \n\
                                                                             \n\
  Defines the number of energy units to be assigned to the shields. Energy   \n\
  is taken from total ship's energy. Note that the status display total      \n\
  energy includes shield energy.                                             \n\
                                                                             \n\
\\dam\\ Command = Damage Control report                                      \n\
  Gives the state of repair of all devices. Where a negative 'State of Repair'\n\
  shows that the device is temporarily damaged.                              \n\
                                                                             \n\
\\com\\ Command = Library-Computer                                           \n\
  The Library-Computer contains six options:                                 \n\
  Option 0 = Cumulative Galactic Record                                      \n\
    This option shows computer memory of the results of all previous         \n\
    short and long range sensor scans.                                       \n\
  Option 1 = Status Report                                                   \n\
    This option shows the number of Klingons, stardates, and starbases       \n\
    remaining in the game.                                                   \n\
  Option 2 = Photon Torpedo Data                                             \n\
    Which gives directions and distance from Enterprise to all Klingons      \n\
    in your quadrant.                                                        \n\
  Option 3 = Starbase Nav Data                                               \n\
    This option gives direction and distance to any starbase in your         \n\
    quadrant.                                                                \n\
  Option 4 = Direction/Distance Calculator                                   \n\
    This option allows you to enter coordinates for direction/distance       \n\
    calculations.                                                            \n\
  Option 5 = Galactic /Region Name/ Map                                      \n\
    This option prints the names of the sixteen major galactic regions       \n\
    referred to in the game.                                                 \n\
";
    puts(doc);
}

