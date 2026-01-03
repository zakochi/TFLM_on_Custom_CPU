`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2026 07:06:11 PM
// Design Name: 
// Module Name: timer64
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module timer64(
    input clk,
    input rst_n,
    input ren,
    input [3:0]addr_ofs,
    output reg [31:0]data_o
);
    reg [63:0] time_cnt;
    always@(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            time_cnt <= 0;
        end
        else begin 
            time_cnt <= time_cnt + 1;
        end
    end
    
    always @(posedge clk)begin
        if(ren)begin
            case(addr_ofs)
                4'h0 : data_o <= time_cnt[31:0];
                4'h4 : data_o <= time_cnt[63:32];
                default : data_o = 0;
            endcase
        end
        else
            data_o <= 0;
    end
    
endmodule
