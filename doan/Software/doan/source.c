#include "system.h"
#include "altera_avalon_pio_regs.h"
#include "io.h"
#include <stdio.h>

<<<<<<< Updated upstream
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
=======
int main(void) {
    printf("\n=============================================\n");
    printf("   DE1-SoC IMAGE DISPLAY CONTROLLER (UART)  \n");
    printf("=============================================\n");


    printf("[SYSTEM] You can now load image by TCL at 0x02000000.\n");

    printf("\n=== KEYBOARD CONTROL INSTRUCTIONS ===\n");
    printf(" -> Press '1' + Enter: ENABLE  VGA display\n");
    printf(" -> Press '0' + Enter: DISABLE VGA (safe for JTAG re-download)\n");
    printf("---------------------------------------------\n");

    IOWR_ALTERA_AVALON_PIO_DATA(PIO_IMG_LOAD_BASE, 0);

>>>>>>> Stashed changes
    while (1) {
        unsigned int jtag_reg = IORD(JTAG_UART_0_BASE, 0);

        if (jtag_reg & 0x00008000) {
            char key = (char)(jtag_reg & 0x000000FF);

            if (key == '1') {
                IOWR_ALTERA_AVALON_PIO_DATA(PIO_IMG_LOAD_BASE, 1);
                printf("[MENU] VGA ENABLED  (SW0=0: RGB | SW0=1: Grayscale)\n");
            }
            else if (key == '0') {
                IOWR_ALTERA_AVALON_PIO_DATA(PIO_IMG_LOAD_BASE, 0);
                printf("[MENU] VGA DISABLED. SDRAM bus free for JTAG.\n");
            }
        }
    }

    return 0;
}
