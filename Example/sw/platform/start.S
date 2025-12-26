/* start.S */

.section .text.init
.global _start
.type _start, @function

_start:
    /* ==========================================
       1. 初始化 Global Pointer (gp)
       ========================================== */
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    /* ==========================================
       2. 初始化 Stack Pointer (sp)
       ========================================== */
    la sp, _stack_top

    /* ==========================================
       3. 清空 BSS (.bss)
       ========================================== */
    la t0, _sbss        
    la t1, _ebss        
    
    bge t0, t1, bss_done

bss_loop:
    sw zero, 0(t0)      
    addi t0, t0, 4      
    blt t0, t1, bss_loop 

bss_done:

    /* ==========================================
       4. 初始化 C++ (TFLM)
       ========================================== */
    call __libc_init_array

    /* ==========================================
       5. 進入 Main
       呼叫 main(0, 0)
       ========================================== */
    li a0, 0            /* argc = 0 */
    li a1, 0            /* argv = NULL */
    call main
	
loop_forever:
    j loop_forever
