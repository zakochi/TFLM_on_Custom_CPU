OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
  /* IMEM: 128KB */
  IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 128K
  
  /* DMEM: 512KB */
  DMEM (rwx) : ORIGIN = 0x00200000, LENGTH = 512K
}

SECTIONS
{
  /* 1. 程式碼 -> IMEM */
  .text : {
    KEEP(*(.text.init))
    *(.text)
    *(.text.*)
    . = ALIGN(4);
  } > IMEM

  /* 2. 模型權重 -> DMEM */
  .rodata : {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata.*)
    *(.srodata.*)
    . = ALIGN(4);
  } > DMEM

  /* 3. 變數 -> DMEM */
  .data : {
    . = ALIGN(4);
    _sdata = .;
    PROVIDE( __global_pointer$ = . + 0x800 );
    *(.data)
    *(.data.*)
    *(.sdata)
    *(.sdata.*)
    . = ALIGN(8);
    __init_array_start = .;
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array))
    __init_array_end = .;
    . = ALIGN(4);
    _edata = .;
  } > DMEM

  /* 4. BSS -> DMEM */
  .bss : {
    . = ALIGN(4);
    _sbss = .;
    *(.bss)
    *(.bss.*)
    *(.sbss)
    *(.sbss.*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } > DMEM

  /* 5. Heap & Stack -> DMEM */
  .heap : {
    . = ALIGN(16);
    _heap_start = .;
    end = .;
  } > DMEM

  . = ALIGN(16);
  _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
}