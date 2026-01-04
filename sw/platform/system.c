#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <stdint.h>
#include <sys/time.h>

/* Linker symbols */
extern char _heap_start;
extern char _stack_top;

/* UART functions  */
extern void uart_putc(char c);
extern char uart_getc(void);

/* ==========================================
   Timer Hardware Definition
   ========================================== */
#define TIMER_BASE      0x10000000
#define MTIME_LOW_REG   (*(volatile uint32_t *)(TIMER_BASE + 0x00))
#define MTIME_HIGH_REG  (*(volatile uint32_t *)(TIMER_BASE + 0x04))
#define SYSTEM_CLOCK_HZ 20000000  

/* Timer Driver: Safe 64-bit read */
uint64_t get_timer_value() {
    uint32_t high_1, low, high_2;
    do {
        high_1 = MTIME_HIGH_REG;
        low    = MTIME_LOW_REG;
        high_2 = MTIME_HIGH_REG;
    } while (high_1 != high_2);
    return ((uint64_t)high_1 << 32) | low;
}

/* ==========================================
   System Calls (Newlib Stubs)
   ========================================== */

int _write(int file, char *ptr, int len) {
    if (file == STDOUT_FILENO || file == STDERR_FILENO) {
        for (int i = 0; i < len; i++) {
            if (ptr[i] == '\n') uart_putc('\r');
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

int _gettimeofday(struct timeval *tv, void *tz) {
    (void)tz;
    if (tv) {
        uint64_t cycles = get_timer_value();
        tv->tv_sec  = cycles / SYSTEM_CLOCK_HZ;
        tv->tv_usec = ((cycles % SYSTEM_CLOCK_HZ) * 1000000) / SYSTEM_CLOCK_HZ;
    }
    return 0;
}

void *_sbrk(int incr) {
    static char *heap_end = 0;
    char *prev_heap_end;
    char *stack_ptr;

    if (heap_end == 0) heap_end = &_heap_start;
    prev_heap_end = heap_end;

    __asm volatile ("mv %0, sp" : "=r"(stack_ptr));

    if (heap_end + incr > stack_ptr) {
        errno = ENOMEM;
        return (void *) -1;
    }

    heap_end += incr;
    return (void *) prev_heap_end;
}

void _exit(int status) { (void)status; while (1); }
int _close(int file) { (void)file; return -1; }
int _fstat(int file, struct stat *st) { (void)file; st->st_mode = S_IFCHR; return 0; }
int _isatty(int file) { return 1; }
int _lseek(int file, int ptr, int dir) { (void)file; (void)ptr; (void)dir; return 0; }
int _getpid(void) { return 1; }
int _kill(int pid, int sig) { (void)pid; (void)sig; errno = EINVAL; return -1; }