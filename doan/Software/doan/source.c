#include "system.h"
#include "altera_avalon_pio_regs.h"
#include "io.h"
#include <stdio.h>

static void print_mode(unsigned int sw_val) {
    switch (sw_val & 0x3) {
        case 0: printf("[MODE] SW[1:0]=00 -> RGB goc\n"); break;
        case 1: printf("[MODE] SW[1:0]=01 -> Grayscale\n"); break;
        case 2: printf("[MODE] SW[1:0]=10 -> Sobel Edge Detection\n"); break;
        case 3: printf("[MODE] SW[1:0]=11 -> Sharpen (Unsharp Mask)\n"); break;
    }
}

int main(void) {
    unsigned int sw_prev, sw_now;

    printf("\n=============================================\n");
    printf("   DE1-SoC IMAGE DISPLAY CONTROLLER (UART)  \n");
    printf("=============================================\n");

    printf("[SYSTEM] You can now load image by TCL at 0x02000000.\n");

    printf("\n=== KEYBOARD CONTROL INSTRUCTIONS ===\n");
    printf(" -> Press '1' + Enter: ENABLE  VGA display\n");
    printf(" -> Press '0' + Enter: DISABLE VGA (safe for JTAG re-download)\n");
    printf("---------------------------------------------\n");
    printf("  SW[1:0] chon mode xu ly anh:\n");
    printf("    00 : RGB goc\n");
    printf("    01 : Grayscale\n");
    printf("    10 : Sobel Edge Detection\n");
    printf("    11 : Sharpen (Unsharp Mask)\n");
    printf("---------------------------------------------\n");

    IOWR_ALTERA_AVALON_PIO_DATA(PIO_IMG_LOAD_BASE, 0);

    sw_prev = IORD_ALTERA_AVALON_PIO_DATA(PIO_SW_BASE) & 0x3;
    print_mode(sw_prev);

    while (1) {
        unsigned int jtag_reg = IORD(JTAG_UART_0_BASE, 0);

        if (jtag_reg & 0x00008000) {
            char key = (char)(jtag_reg & 0x000000FF);

            if (key == '1') {
                IOWR_ALTERA_AVALON_PIO_DATA(PIO_IMG_LOAD_BASE, 1);
                printf("[MENU] VGA ENABLED  (SW[1:0]: 00=RGB | 01=Grayscale | 10=Sobel | 11=Sharpen)\n");
            }
            else if (key == '0') {
                IOWR_ALTERA_AVALON_PIO_DATA(PIO_IMG_LOAD_BASE, 0);
                printf("[MENU] VGA DISABLED. SDRAM bus free for JTAG.\n");
            }
        }

        sw_now = IORD_ALTERA_AVALON_PIO_DATA(PIO_SW_BASE) & 0x3;
        if (sw_now != sw_prev) {
            printf("[SWITCH] SW[1:0] = %u%u\n",
                   (sw_now >> 1) & 0x1, sw_now & 0x1);
            print_mode(sw_now);
            sw_prev = sw_now;
        }
    }

    return 0;
}
