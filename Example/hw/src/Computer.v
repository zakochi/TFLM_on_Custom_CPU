`include "mem_init_path.vh"
`include "parameters.vh"


module Computer(
    input CLK100MHZ,
    input CPU_RESETN,
    input           UART_RX,
    output          UART_TX,
    
    output [3:0] TEST
);

wire i_mem_rd;
wire i_mem_invalidate;
wire i_mem_available;
wire i_mem_exception = 0;
wire [31:0] i_mem_addr;
wire [31:0] inst;

wire d_mem_wr_en;
wire d_mem_rd_en;
wire d_mem_available;
wire d_mem_flush;
wire d_mem_writeback;
wire d_mem_invalidate;
wire d_mem_cacheable;
wire [1:0] d_mem_exception = 2'b0;
wire [3:0] d_mem_ctrl;
wire [31:0] d_mem_addr;
reg [31:0] mem_addr_temp;
wire [31:0] d_mem_wr_data;
wire [31:0] d_mem_rd_data;
wire [31:0]time_data;

 reg [31:0] cp0_d_rd_data;
wire uart_tx_stat;
wire uart_rx_stat;
wire [7:0] uart_rx_data;

reg rst_n;
reg rst_d;
wire clk;

reg [26:0] heartbeat_cnt;
always @(posedge clk) begin
    heartbeat_cnt <= heartbeat_cnt + 1;
end

// LED[0]: clk work
// LED[1]: Reset  
// LED[2]: CPU work(not full light)
// LED[3]: UART TX
assign TEST[0] = heartbeat_cnt[24]; 
assign TEST[1] = rst_n;             
assign TEST[2] = i_mem_addr[2];     
assign TEST[3] = UART_TX;

//`ifdef SIMULATION
//    assign clk = CLK100MHZ;
///`else
    clk_wiz_0 cpu_clock_gen(
        .clk_in1  (CLK100MHZ),
        .clk_out1 (clk)
    );
//`endif



always@(posedge clk)begin
    if(!CPU_RESETN)begin
        rst_n <= 0;
        rst_d <= 0;
    end
    else begin
        rst_n <= rst_d;
        rst_d <= 1;
    end
end


////////////////////////////////////////////

DataMemory #(
.I_MEM_DEPTH(15),
.I_INIT_FILE(`I_INIT_FILE),
.D_MEM_DEPTH(17),
.D_INIT_FILE(`D_INIT_FILE)
)
m_DataMemory(
    .rst_n(rst_n),
    .clk(clk),
    
    .i_addr(i_mem_addr),
    .i_rd(i_mem_rd),
    .inst(inst),
    .i_available_o(i_mem_available),
    
    .wr_en(d_mem_wr_en & (d_mem_addr[31:28] == 4'h0)),
    .rd_en(d_mem_rd_en),
    .ctrl(d_mem_ctrl),
    .address(d_mem_addr),
    .data_i(d_mem_wr_data),
    .data_o(d_mem_rd_data),
    .available_o(d_mem_available)
);

timer64
u_timer(
    .clk(clk),
    .rst_n(rst_n),
    .ren(d_mem_rd_en & (d_mem_addr[31:28] == 4'h1)),
    .addr_ofs(d_mem_addr[3:0]),
    .data_o(time_data)
);

uart_tx
uart_tx_inst(
    .clk       (clk),
    .rst       (~rst_n),
    .wr_valid  (d_mem_wr_en & (d_mem_addr[31:28] == 4'h2) & (d_mem_addr[3:0] == 4'h0)),
    .byte_in   (d_mem_wr_data[7:0]),
    .wr_ready  (uart_tx_stat),
    .tx_serial (UART_TX)
);


uart_rx
uart_rx_inst(
    .clk       (clk),
    .rst       (~rst_n),
    .rd_ready  (uart_rx_stat),
    .rd_valid  (d_mem_wr_en & (d_mem_addr[31:28] == 4'h2) & (d_mem_addr[3:0] == 4'h3)),
    .byte_data (uart_rx_data),
    .uart_rx   (UART_RX)
);


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		mem_addr_temp<=0;
	else
		mem_addr_temp <= d_mem_addr;
end

always @(*) begin
    if (mem_addr_temp[31:28] == 4'h2) begin
        if      (mem_addr_temp[3:0] == 4'h0) cp0_d_rd_data = {31'b0, uart_tx_stat};
        else if (mem_addr_temp[3:0] == 4'h2) cp0_d_rd_data = {31'b0, uart_rx_stat};
        else                              cp0_d_rd_data = {24'h0, uart_rx_data};
    end
    else if(mem_addr_temp[31:28] == 4'h1)    cp0_d_rd_data = time_data;
    else                                  cp0_d_rd_data = d_mem_rd_data;
end


PipelineCPU m_core0(
    .clk(clk),
    .rst_n(rst_n),
    
    .i_mem_rd(i_mem_rd),
    .i_mem_addr(i_mem_addr),
    .i_mem_invalidate(i_mem_invalidate),
    .inst(inst),
    .i_mem_available(i_mem_available),
    .i_mem_exception(i_mem_exception),
    
    .d_mem_ctrl(d_mem_ctrl),
    .d_mem_wr_en(d_mem_wr_en),
    .d_mem_rd_en(d_mem_rd_en),
    .d_mem_addr(d_mem_addr),
    .d_mem_wr_data(d_mem_wr_data),
    .d_mem_rd_data(cp0_d_rd_data),
    .d_mem_writeback(d_mem_writeback),
    .d_mem_invalidate(d_mem_invalidate),
    .d_mem_flush(d_mem_flush),
    .d_mem_cacheable(d_mem_cacheable),
    .d_mem_available(d_mem_available),
    .d_mem_exception(d_mem_exception),
    
    .cdma_data_o(),
    .cdma_addr_o(),
    .cdma_rdy_i(1'b0),
    .cdma_data_i(32'b0),
    .cdma_exception_i(2'b0)
);

endmodule