#include "uart.h"
#include <unistd.h> 

/* ==============================================
   BA: 0x20000000
   ============================================== */
#define UART_BASE 0x20000000
#define UART_TX_REG   (*(volatile uint8_t *)(UART_BASE + 0x00)) 
#define UART_TX_STAT  (*(volatile uint8_t *)(UART_BASE + 0x00)) 
#define UART_RX_STAT  (*(volatile uint8_t *)(UART_BASE + 0x02)) 
#define UART_RX_DATA  (*(volatile uint8_t *)(UART_BASE + 0x03)) 

void uart_init(void) {}

void uart_putc(char c) {
    /* ============================================================
       Polling
       ============================================================ */
    while ((UART_TX_STAT & 0x01) == 0);
    UART_TX_REG = c;
}

int uart_available(void) {
    return (UART_RX_STAT & 0x01);
}

char uart_getc(void) {
    while (uart_available() == 0);
    return (char)UART_RX_DATA;
}

/* ==============================================
   printf
   ============================================= */
int _write(int file, char *ptr, int len) {
    if (file == STDOUT_FILENO || file == STDERR_FILENO) {
        for (int i = 0; i < len; i++) {
            if (ptr[i] == '\n') {
                uart_putc('\r');
            }
            uart_putc(ptr[i]);
        }
        return len;
    }
    return -1;
}

int _read(int file, char *ptr, int len) {
    if (file == STDIN_FILENO) {
        int read_count = 0;
        while (read_count < len) {
            ptr[read_count] = uart_getc();
            read_count++;
            break; 
        }
        return read_count;
    }
    return 0;
}