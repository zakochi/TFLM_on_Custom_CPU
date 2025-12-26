#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <stdint.h>
#include <sys/time.h>

extern char _heap_start; /* Heap BA */
extern char _stack_top;  /* Stack BA */

void *_sbrk(int incr) {
    static char *heap_end = 0;
    char *prev_heap_end;
    char *stack_ptr;

    if (heap_end == 0) {
        heap_end = &_heap_start;
    }

    prev_heap_end = heap_end;

    __asm volatile ("mv %0, sp" : "=r"(stack_ptr));

    if (heap_end + incr > stack_ptr) {
        errno = ENOMEM;
        return (void *) -1;
    }

    heap_end += incr;
    return (void *) prev_heap_end;
}

void _exit(int status) {
    (void)status; //
    while (1) {
    }
}

/* _fstat: 查詢檔案狀態 */
int _fstat(int file, struct stat *st) {
    (void)file;
    st->st_mode = S_IFCHR; 
    return 0;
}

/* _isatty: 查詢是否為終端機 */
int _isatty(int file) {
    return 1; 
}

/* _lseek: 檔案定位 */
int _lseek(int file, int ptr, int dir) {
    (void)file;
    (void)ptr;
    (void)dir;
    return 0;
}

/* _close: 關閉檔案 */
int _close(int file) {
    (void)file;
    return -1; 
}

/* _getpid: 取得 Process ID */
int _getpid(void) {
    return 1;
}

/* _kill */
int _kill(int pid, int sig) {
    (void)pid;
    (void)sig;
    errno = EINVAL;
    return -1;
}


int _gettimeofday(struct timeval *tv, void *tz) {
    (void)tz;
    if (tv) {
        uint32_t cycles;
        __asm volatile ("csrr %0, mcycle" : "=r"(cycles));
        
        tv->tv_sec = cycles / 100000000;
        tv->tv_usec = (cycles % 100000000) / 100;
    }
    return 0;
}
