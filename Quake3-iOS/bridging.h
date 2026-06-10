//
//  bridging.h
//  Quake3-iOS
//
//  Created by Tom Kidd on 7/21/18.
//  Copyright © 2018 Tom Kidd. All rights reserved.
//

#ifndef bridging_h
#define bridging_h

#include "q_shared.h"
#include "keycodes.h"
//#import "AppDelegate.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "SDL_uikitviewcontroller.h"
#include "SDL_uikitappdelegate.h"
#pragma clang diagnostic pop
#include "UIImage-Targa.h"
#import "IOSGameController.h"

void Sys_Startup( int argc, char **argv );

// Wraps setjmp + Sys_Startup; returns normally after game exits
void Sys_StartupWithExitCallback( int argc, char **argv );

// CADisplayLink mode: call before Sys_StartupWithExitCallback so that
// Sys_Startup returns after init instead of entering the blocking loop.
void Sys_UseDisplayLink( void );

// Call once per display refresh (from CADisplayLink).
// Returns 0 to keep running, 1 when the game has requested exit.
int  Sys_TickFrame( void );

void Com_Frame(void);

void CL_KeyEvent(int key, qboolean down, unsigned time);

void CL_AddReliableCommand(const char *cmd, qboolean isDisconnectCmd);

int Sys_Milliseconds (void);

typedef struct {
    int            down[2];        // key nums holding it down
    unsigned    downtime;        // msec timestamp
    unsigned    msec;            // msec down this frame if both a down and up happened
    qboolean    active;            // current state
    qboolean    wasPressed;        // set when down, not cleared when up
} kbutton_t;

int cl_joyscale_x[2];
int cl_joyscale_y[2];

void CL_MouseEvent( int dx, int dy, int time, qboolean absolute );

kbutton_t    in_strafe;

void Sys_SetHomeDir( const char *newHomeDir );

int Key_GetCatcher( void );

// Voice command bridge
void iOS_RegisterVoiceFunctions(void (*startFn)(void), void (*stopFn)(void));
void iOS_EnqueueVoiceCommand(const char *command);

#endif /* bridging_h */
