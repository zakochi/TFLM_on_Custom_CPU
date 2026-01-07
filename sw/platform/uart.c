#include "uart.h"
#include <stdint.h> 

/* ==============================================
   BA: 0x20000000
   ============================================== */
#define UART_BASE 0x20000000
#define UART_TX_REG   (*(volatile uint8_t *)(UART_BASE + 0x00)) 
#define UART_TX_STAT  (*(volatile uint8_t *)(UART_BASE + 0x00)) 
#define UART_RX_STAT  (*(volatile uint8_t *)(UART_BASE + 0x02)) 
#define UART_RX_DATA  (*(volatile uint8_t *)(UART_BASE + 0x03)) 

void uart_init(void) {
}

void uart_putc(char c) {
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
