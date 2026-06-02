#include <stdio.h>
#include <stdint.h>
#include <unistd.h>                 // Library for usleep() function
#include "system.h"                 // Hardware configuration generated from Qsys
#include "altera_avalon_pio_regs.h" // PIO read/write library

// ====================================================================
// MACRO ADDRESS DECLARATIONS (Mapped from system.h)
// ====================================================================
#ifndef PIO_MODE_BASE
#define PIO_MODE_BASE           PIO_MODE_BASE
#endif

#ifndef PIO_SCCB_START_BASE
#define PIO_SCCB_START_BASE     PIO_SCCB_START_BASE
#endif

#ifndef PIO_SCCB_DONE_BASE
#define PIO_SCCB_DONE_BASE      PIO_SCCB_DONE_BASE
#endif

// Declare PIO_SW_BASE (Need to create a PIO Input in Qsys to read Switches)
#ifndef PIO_SW_BASE
#define PIO_SW_BASE             PIO_SW_BASE // Change if your system.h uses a different name
#endif

// ====================================================================
// OV7670 CAMERA INITIALIZATION FUNCTION
// ====================================================================
void Camera_Initialize() {
    printf("==========================================\n");
    printf("   OV7670 CAMERA TO VGA PROCESSING SYSTEM \n");
    printf("==========================================\n");
    printf("[INFO] Initializing OV7670 Camera...\n");

    // 1. Ensure the START signal is at logic 0
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_SCCB_START_BASE, 0);
    usleep(1000); // Wait for 1ms

    // 2. Trigger a pulse to notify the hardware SCCB module to start running
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_SCCB_START_BASE, 1);
    usleep(1000);
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_SCCB_START_BASE, 0);

    // 3. Wait for the hardware to finish configuring ~160 registers
    while (IORD_ALTERA_AVALON_PIO_DATA(PIO_SCCB_DONE_BASE) == 0) {
        printf(".");
        usleep(100000); // Wait 100ms per check
    }

    printf("\n[SUCCESS] Camera configuration successful!\n");
    printf("OV7670 Camera is ready to output to VGA.\n");
    printf("==========================================\n\n");
}

// ====================================================================
// MAIN PROGRAM
// ====================================================================
int main() {
    uint32_t current_sw = 0;
    uint32_t last_sw = 0xFFFFFFFF; // Dummy initial value to force the loop to print on the first iteration

    // Initialize Camera
    Camera_Initialize();

    printf("[INFO] System is running. Waiting for Switch toggles...\n\n");

    // Infinite loop for automatic processing
    while (1) {
        // Read the current value of the switches (SW)
        current_sw = IORD_ALTERA_AVALON_PIO_DATA(PIO_SW_BASE);

        // Only print to console and update when the user actually toggles a switch
        if (current_sw != last_sw) {

            // Write the SW value to the image processing hardware
            IOWR_ALTERA_AVALON_PIO_DATA(PIO_MODE_BASE, current_sw);

            // Print the current status to the Console
            printf("------------------------------------------\n");
            printf(">> Switch Changed! SW Value: %lu\n", current_sw);

            switch (current_sw) {
                case 0:
                    printf(">> Current Mode: NORMAL DISPLAY (RGB)\n");
                    break;
                case 1:
                    printf(">> Current Mode: GRAYSCALE FILTER\n");
                    break;
                case 2:
                    printf(">> Current Mode: EDGE DETECTION\n");
                    break;
                case 3:
                    printf(">> Current Mode: COLOR INVERSION\n");
                    break;
                default:
                    printf(">> Current Mode: UNKNOWN / EXPERIMENTAL (Mode %lu)\n", current_sw);
                    break;
            }

            // Save the switch value to compare in the next scan
            last_sw = current_sw;
        }

        // Pause for 100ms to prevent Nios II from hanging due to scanning too fast
        usleep(100000);
    }

    return 0;
}
