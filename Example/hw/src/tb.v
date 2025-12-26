`timescale 1ns / 1ps
`define SIMULATION
module tb;

    // 1. Inputs to DUT (Device Under Test)
    reg CLK100MHZ;
    reg CPU_RESETN;
    reg UART_RX;

    // 2. Outputs from DUT
    wire UART_TX;
    
    // 如果你有加 debug ports，記得在這裡也加上 wire 並連線
    // wire [31:0] debug_pc;
    // wire [31:0] debug_inst;

    // 3. Instantiate the Unit Under Test (UUT)
    Computer uut (
        .CLK100MHZ(CLK100MHZ), 
        .CPU_RESETN(CPU_RESETN), 
        .UART_RX(UART_RX), 
        .UART_TX(UART_TX)
        // .debug_pc(debug_pc),    // 如果有的話
        // .debug_inst(debug_inst) // 如果有的話
    );

    // 4. Clock Generation (100MHz -> Period = 10ns)
    initial begin
        CLK100MHZ = 0;
        forever #5 CLK100MHZ = ~CLK100MHZ; // 每 5ns 翻轉一次
    end

    // 5. Reset Logic & Initial State
    initial begin
        // --- 初始化輸入 ---
        CPU_RESETN = 1; // 壓住 Reset (Active Low)
        UART_RX = 1;    // UART RX 線閒置時必須是 High (1)，否則會被誤判為 Start Bit

        // --- 等待重置 ---
        #100;           // 等待 100ns (10個 clock cycle)
        
        CPU_RESETN = 0; 
        
        # 100
        CPU_RESETN = 1;
        #100000;           // 等待 100ns (10個 clock cycle)
        
        CPU_RESETN = 0; 
        #100000;           // 等待 100ns (10個 clock cycle)
        
        CPU_RESETN = 1; 
    end

endmodule