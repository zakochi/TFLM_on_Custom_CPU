`timescale 1ns / 1ps
`include "parameters.vh"

//////////////////////////////////////////////////////////////////////////////////
// Company: CAS lab
// Create Date: 01/21/2025 01:53:47 AM
// Module Name: uart_rx_0
//////////////////////////////////////////////////////////////////////////////////

module uart_rx
(
    input        clk,
    input        rst,
    output       rd_ready,
    input        rd_valid,
    output [7:0] byte_data,
    input        uart_rx
);

parameter CLKS_PER_HALF_BIT = 87;//`CPU_CLK / (`UART_BAUD_RATE * 2);

parameter S_IDLE      = 3'b101;
parameter S_START_BIT = 3'b001;
parameter S_READ_BIT  = 3'b010;
parameter S_END_BIT   = 3'b011;
parameter S_CLEAN_UP  = 3'b100;

// FSM
//                      read bit
// IDLE -> start bit -> 12345678 -> end bit -> clean up
//   ^---------|                       |           |
//   |---------------------------------|           |
//   |---------------------------------------------|
 

// FFs
reg [2:0] state_r;
reg [7:0] bits_r;
reg [2:0] bits_remain_r;
reg       div_ov_r;    // div_of_r ^ 1 when clk_count is 0
reg       rx_in_pre_r; // double FF for metastability
reg       rx_in_r;     // double FF for metastability
reg [$clog2(CLKS_PER_HALF_BIT)-1:0] clk_count;

reg [2:0] next_state;

wire   sample_bit;
assign sample_bit = (div_ov_r == 1'b0 && clk_count == 0);

always @(posedge clk) begin
    if (rst) state_r <= S_IDLE;
    else     state_r <= next_state;
end

always @(*) begin
    case (state_r)
    S_IDLE: begin
    	if (rx_in_r == 1'b0) next_state = S_START_BIT;
	    else                 next_state = S_IDLE;
    end
    S_START_BIT: begin
    	if (sample_bit) begin
	    	if (rx_in_r == 1'b0) next_state = S_READ_BIT;
	    	else                 next_state = S_IDLE;
	    end
	    else                     next_state = S_START_BIT;
    end
    S_READ_BIT: begin
    	if (bits_remain_r == 3'd0 && sample_bit) next_state = S_END_BIT;
	    else                                     next_state = S_READ_BIT;
    end
    S_END_BIT: begin
    	if (sample_bit) begin
	    	if (rx_in_r == 1'b0) next_state = S_IDLE;
	    	else                 next_state = S_CLEAN_UP;
	    end
	    else                     next_state = S_END_BIT;
    end
    S_CLEAN_UP: begin
    	if (rd_valid) next_state = S_IDLE;
	    else          next_state = S_CLEAN_UP;
    end
    default: begin
    	next_state = state_r;
    end
    endcase
end

always @(posedge clk) begin
    if (state_r[2] == 1'b1) begin // state IDLE & CLEAN_UP
        clk_count <= CLKS_PER_HALF_BIT;
        div_ov_r  <= 1'b0;
    end
    else if (state_r[2] == 1'b0) begin // state START_BIT, READ_BIT & END_BIT
        if (clk_count == 0) begin
            clk_count <= CLKS_PER_HALF_BIT;
	        div_ov_r  <= div_ov_r ^ 1'b1;
        end
        else begin
            clk_count <= clk_count - 1'b1;
        end
    end
end

always @(posedge clk) begin
    if (state_r == S_READ_BIT && sample_bit) begin
	    bits_r <= {rx_in_r, bits_r[7:1]};
    end
end

always @(posedge clk) begin
    if (state_r[2] == 1'b1) begin
        bits_remain_r <= 3'd7;
    end
    else if (state_r == S_READ_BIT && sample_bit) begin
        bits_remain_r <= bits_remain_r - 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        rx_in_r     <= 1'b1;
	    rx_in_pre_r <= 1'b1;
    end
    else begin
        {rx_in_r, rx_in_pre_r} <= {rx_in_pre_r, uart_rx};
    end
end

assign rd_ready  = (state_r == S_CLEAN_UP);
assign byte_data = bits_r;

endmodule
