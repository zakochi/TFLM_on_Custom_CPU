`timescale 1ns / 1ps
`include "parameters.vh"

//////////////////////////////////////////////////////////////////////////////////
// Company: CAS lab
// Create Date: 02/08/2024 02:59:36 PM
// Module Name: cpu_top
//////////////////////////////////////////////////////////////////////////////////

module cpu_top
(
    input           CLK100MHZ,
    input           CPU_RESETN,

    input           UART_RX,
    output          UART_TX,    
    output [7:0]    seg,
    output [3:0]    AN,
    output [3:0]    BN
);

wire        cp0_clk;
reg         rst;
reg  [5 :0] sync_rst_sr;

wire [3 :0] cp0_d_rd_mode;
wire        cp0_d_wr_valid;
wire        cp0_d_rd_en;
wire [31:0] cp0_d_addr;
wire [31:0] cp0_d_wr_data;
reg  [31:0] cp0_d_rd_data;
wire [31:0] cp0_i_addr;
wire [31:0] cp0_i_data;

wire [31:0] tcm_d_rd_data;
wire        uart_tx_stat;

wire [7 :0] uart_rx_data;
wire        uart_rx_stat;


clk_wiz_0 
cpu_clock_gen(
    .clk_in1  (CLK100MHZ),
    .clk_out1 (cp0_clk)
);


// ====================================================================
// |                         YOUR CPU CORE HERE                       |
// ====================================================================

PipelineCPU 
CPU_core(
    .clk       (cp0_clk),
    .rst_n     (~rst),

    .memRdMode (cp0_d_rd_mode),
    .memWrite  (cp0_d_wr_valid),
    .memRead   (cp0_d_rd_en),
    .address   (cp0_d_addr),
    .writeData (cp0_d_wr_data),
    .readData  (cp0_d_rd_data),

    .readAddr  (cp0_i_addr),
    .inst      (cp0_i_data)
);

// ====================================================================


TCM_wrapper
TCM_inst(
    .clk            (cp0_clk),

    // Data memory ports
    .d_rd_mode      (cp0_d_rd_mode),
    .d_wr_valid     (cp0_d_wr_valid & (cp0_d_addr[31:28] == 4'h0)),
    .d_rd_en        (cp0_d_rd_en),
    .d_addr         (cp0_d_addr),
    .d_wr_data      (cp0_d_wr_data),
    .d_rd_data      (tcm_d_rd_data),

    // Instruction memory ports
    .i_addr         (cp0_i_addr),
    .i_data         (cp0_i_data)
);


uart_tx
uart_tx_inst(
    .clk       (cp0_clk),
    .rst       (rst),
    .wr_valid  (cp0_d_wr_valid & (cp0_d_addr[31:28] == 4'hA) & (cp0_d_addr[3:0] == 4'h0)),
    .byte_in   (cp0_d_wr_data[7:0]),
    .wr_ready  (uart_tx_stat),
    .tx_serial (UART_TX)
);


uart_rx
uart_rx_inst(
    .clk       (cp0_clk),
    .rst       (rst),
    .rd_ready  (uart_rx_stat),
    .rd_valid  (cp0_d_wr_valid & (cp0_d_addr[31:28] == 4'hA) & (cp0_d_addr[3:0] == 4'h3)),
    .byte_data (uart_rx_data),
    .uart_rx   (UART_RX)
);


always @(*) begin
    if (cp0_d_addr[31:28] == 4'hA) begin
        if      (cp0_d_addr[3:0] == 4'h0) cp0_d_rd_data = {31'b0, uart_tx_stat};
        else if (cp0_d_addr[3:0] == 4'h2) cp0_d_rd_data = {31'b0, uart_rx_stat};
        else                              cp0_d_rd_data = {24'h0, uart_rx_data};
    end
    else if (cp0_d_addr[31:28] == 4'hB)   cp0_d_rd_data = 32'b0;
    else                                  cp0_d_rd_data = tcm_d_rd_data;
end


// ====================================================================
// |        "DebugSevenSegment", "RunningSevenSegment" and            |
// |        "SevenSegMux" are modules for debugging on FPGA.          |
// |        You may comment out them for faster synthesis.            |
// ====================================================================

wire [7:0] seg_digit_0;
wire [7:0] seg_digit_1;
wire [7:0] seg_digit_2;
wire [7:0] seg_digit_3;


//        a         a            a               a    
//      ____       ____        ____            ____
//   f |    | b f |    | b  f |    | b      f |    | b
//     |_g__|     |_g__|      |_g__|          |_g__| 
//   e |    | c e |    | c  e |    | c      e |    | c
//     |____|     |____|      |____|          |____|
//       d          d           d                d
//
//    digit0      digit1      digit2           digit3
//    |=========  ERROR CODE =======|  |== running light ==|


//                         ( CPU CLK  / refresh rate (in Hz) )
SevenSegMux #(.REFRESH_RATE(`CPU_CLK / `SEVEN_SEG_MUX_REFRESH_RATE))
seg_mux(
    .clk         (cp0_clk),
    .rst         (rst),
    .seg_digit_0 (seg_digit_0),
    .seg_digit_1 (seg_digit_1),
    .seg_digit_2 (seg_digit_2),
    .seg_digit_3 (seg_digit_3),
    
    .seg_out     (seg),
    .seg_enable  (AN)
);


SevenSegmentErrorCode 
debug_digit_012(
    .clk         (cp0_clk),
    .rst         (rst),
    .data_in     (cp0_d_wr_data),
    .addr_in     (cp0_d_addr),
    .wr_valid    (cp0_d_wr_valid & (cp0_d_addr[31:28] == 4'hB)),
    .seg_digit_0 (seg_digit_0),
    .seg_digit_1 (seg_digit_1),
    .seg_digit_2 (seg_digit_2)
);

// Cool running 7-segment for your own use.
// assert "Disable" for 1 cycle to stop it from running.
RunningSevenSegment 
debug_digit_3(
    .Clk          (cp0_clk),
    .Reset        (rst),
    .Disable      (0),
    .SevenSegment (seg_digit_3)  
);


always @(posedge cp0_clk) begin
    if (!CPU_RESETN) begin
        sync_rst_sr <= 6'b111_111;
    end
    else begin
        sync_rst_sr <= (sync_rst_sr << 1);
    end
end

always @(posedge cp0_clk) begin
    rst <= sync_rst_sr[5];
end

assign BN = 4'b1111;



endmodule
