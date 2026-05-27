#include <stdio.h>
#include <unistd.h>
#include <io.h>
#include "system.h"
#include "alt_types.h"

// ------------------------------------------------------------------------
// Framebuffer configuration (Standard VGA 640x480 RGB565)
// ------------------------------------------------------------------------
#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480
#define FRAME_SIZE    (SCREEN_WIDTH * SCREEN_HEIGHT) // 307,200 Pixels (614,400 Bytes)

// SDRAM Base address automatically generated in system.h by Qsys
// NOTE: If your Qsys component has a different name, change this macro to match system.h
#define SDRAM_BASE    NEW_SDRAM_CONTROLLER_0_BASE

// 16-bit color definitions for RGB565 format (5-bit Red, 6-bit Green, 5-bit Blue)
#define COLOR_BLACK   0x0000
#define COLOR_BLUE    0x001F
#define COLOR_RED     0xF800
#define COLOR_GREEN   0x07E0
#define COLOR_YELLOW  0xFFE0
#define COLOR_WHITE   0xFFFF
#define COLOR_CYAN    0x07FF
#define COLOR_MAGENTA 0xF81F

// ------------------------------------------------------------------------
// Screen clear function (Fills the entire framebuffer memory with a constant color)
// ------------------------------------------------------------------------
void clear_screen(alt_u16 color) {
    printf("[Nios II] Clearing screen with color code: 0x%04X...\n", color);

    int i;
    // Use IOWR_16DIRECT to write directly to SDRAM, bypassing the Data Cache (if enabled).
    // This ensures the VGA hardware instantly reads the updated data without coherence delays.
    for (i = 0; i < FRAME_SIZE; i++) {
        IOWR_16DIRECT(SDRAM_BASE, i * 2, color); // i * 2 because each pixel occupies 2 bytes
    }

    printf("[Nios II] Screen clear complete!\n");
}

// ------------------------------------------------------------------------
// Function to draw test color bars to verify the VGA read path independently
// ------------------------------------------------------------------------
void draw_test_pattern(void) {
    printf("[Nios II] Generating test color bars pattern...\n");

    int x, y;
    alt_u16 color;
    int bar_width = SCREEN_WIDTH / 8; // Divide into 8 vertical color bars

    for (y = 0; y < SCREEN_HEIGHT; y++) {
        for (x = 0; x < SCREEN_WIDTH; x++) {
            // Determine color based on X coordinate column
            if (x < bar_width)          color = COLOR_WHITE;
            else if (x < bar_width * 2) color = COLOR_YELLOW;
            else if (x < bar_width * 3) color = COLOR_CYAN;
            else if (x < bar_width * 4) color = COLOR_GREEN;
            else if (x < bar_width * 5) color = COLOR_MAGENTA;
            else if (x < bar_width * 6) color = COLOR_RED;
            else if (x < bar_width * 7) color = COLOR_BLUE;
            else                        color = COLOR_BLACK;

            // Write pixel data into SDRAM
            IOWR_16DIRECT(SDRAM_BASE, (y * SCREEN_WIDTH + x) * 2, color);
        }
    }
    printf("[Nios II] Test pattern displayed on VGA successfully.\n");
}

// ------------------------------------------------------------------------
// Main function controlling the system
// ------------------------------------------------------------------------
int main() {
    printf("\n======================================================\n");
    printf("   OV7670 Camera & VGA SoC System - DE1-SoC Board   \n");
    printf("======================================================\n");
    printf("[Nios II] SDRAM Base Address: 0x%08X\n", (unsigned int)SDRAM_BASE);

    // Step 1: Clear the initial framebuffer to Blue (or Black)
    // This confirms Nios II booted successfully and clears random startup noise in SDRAM
    clear_screen(COLOR_BLUE);
    usleep(1000000); // Wait 1 second

    // Step 2: Draw the test color bars pattern
    // Debug tip: If these color bars display perfectly on the VGA monitor,
    // it means your SDRAM -> FIFO -> VGA Controller read path is 100% correct.
    // If there are issues later, the root cause lies solely within the Camera write path.
    draw_test_pattern();
    usleep(2000000); // Hold the test pattern for 2 seconds before giving control to the hardware

    printf("[Nios II] Switching to hardware autopilot mode.\n");
    printf("[Nios II] Camera Master Writer is writing to SDRAM and VGA Master Reader is reading out...\n");

    // Infinite loop to keep the CPU running
    while (1) {
        // System heartbeat - Periodically prints to the console for monitoring
        printf("[Status] System is alive... Camera & VGA are running in background.\n");
        usleep(5);

        // You can expand the code here, for example:
        // - Read the onboard KEY buttons to switch image effects.
        // - Process images directly inside SDRAM via software (e.g., color filtering, object detection).
    }

    return 0;
}
