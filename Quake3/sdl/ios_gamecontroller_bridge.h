//
//  sys_ios.h
//  Quake3-iOS
//
//  Created by rebelancap on 6/6/25.
//  Copyright © 2025 Tom Kidd. All rights reserved.
//

#ifndef IOS_GAMECONTROLLER_BRIDGE_H
#define IOS_GAMECONTROLLER_BRIDGE_H

#include <SDL.h>

#ifdef __cplusplus
extern "C" {
#endif

// Initialize the controller system
void iOS_InitGameController(void);

// Set SDL window reference
void iOS_SetSDLWindow(SDL_Window *window);

// Check if a controller is connected
int iOS_IsControllerConnected(void);

// Get analog stick values (-1.0 to 1.0)
float iOS_GetLeftStickX(void);
float iOS_GetLeftStickY(void);
float iOS_GetRightStickX(void);
float iOS_GetRightStickY(void);

// Get trigger values (0.0 to 1.0)
float iOS_GetLeftTrigger(void);
float iOS_GetRightTrigger(void);

// Get button states (0 or 1)
int iOS_GetButtonA(void);
int iOS_GetButtonB(void);
int iOS_GetButtonX(void);
int iOS_GetButtonY(void);
int iOS_GetLeftShoulder(void);
int iOS_GetRightShoulder(void);
int iOS_GetDpadUp(void);
int iOS_GetDpadDown(void);
int iOS_GetDpadLeft(void);
int iOS_GetDpadRight(void);
int iOS_GetButtonMenu(void);
int iOS_GetButtonOptions(void);
int iOS_GetButtonShare(void);
int iOS_GetLeftThumbstickButton(void);
int iOS_GetRightThumbstickButton(void);

// Haptic feedback
void iOS_TriggerHaptic(float intensity, int durationMs);

// Voice command — called from Swift speech recognizer, polled by game loop
void iOS_EnqueueVoiceCommand(const char *command);
// Returns 1 and fills buf if a command is waiting; returns 0 if queue is empty.
int  iOS_DequeuePendingVoiceCommand(char *buf, int bufSize);

// Start / stop microphone recording (called from game input loop)
void iOS_StartVoiceRecognition(void);
void iOS_StopVoiceRecognition(void);
// Register Swift callbacks so the C layer can invoke them
void iOS_RegisterVoiceFunctions(void (*startFn)(void), void (*stopFn)(void));

// Process any pending main-queue work (speech recognition callbacks etc.)
// Must be called from the main thread once per frame.
void iOS_PumpMainRunLoop(void);

#ifdef __cplusplus
}
#endif

#endif
