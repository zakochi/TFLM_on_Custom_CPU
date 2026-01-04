module DataMemory
#(parameter I_MEM_DEPTH = 12,
  parameter D_MEM_DEPTH = 16,
  parameter D_INIT_FILE = "",
  parameter I_INIT_FILE = ""
)
(
    input  wire        rst_n,      // active-low asynchronous reset
    input  wire        clk,        // rising-edge clock

	input  wire [31:0] i_addr,
    input  wire        i_rd,
	output wire  [31:0] inst,
    output wire         i_available_o,
    
	input  wire        wr_en,   // 1 = store
    input  wire        rd_en,    // 1 = load
    input  wire [3:0]  ctrl,    // [3]=sign , [2]=word , [1]=half , [0]=byte
    
	input  wire [31:0] address,    // byte address
    input  wire [31:0] data_i,  // store data (little-endian)
    output      [31:0] data_o,    // load data (extended)
	output reg         available_o
);

parameter SIZE = (2**I_MEM_DEPTH);
(* ram_style = "distributed" *)
reg [31:0] i_mem [0:SIZE-1] /* verilator public */;

initial begin
    if (I_INIT_FILE != "") begin
      $readmemh(I_INIT_FILE, i_mem);
    end 
end


assign inst = i_addr[31:2]<SIZE ? i_mem[i_addr[31:2]] : 32'h00000013;
assign i_available_o = 1;


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        available_o <= 0;
    else
        available_o <= 1;
end


sdp_bram #(
    .INIT_FILE(D_INIT_FILE),
    .ADDR_BITS(D_MEM_DEPTH)
) d_mem (
    .clk(clk),
    .en_a(wr_en),
    .we_a(ctrl),
    .addr_a(address[31:2]),
    .din_a(data_i),
    
    .en_b(rd_en),
    .addr_b(address[31:2]),
    .dout_b(data_o)
);

endmodule



module sdp_bram #(
  parameter ADDR_BITS = 16,
  parameter DATA_BITS = 32,  
  parameter COL_WIDTH = 8,
  parameter INIT_FILE = ""   
)(
  input                         clk,

  // ------ Write Port (A) ------
  input                         en_a,
  input      [DATA_BITS/COL_WIDTH-1:0] we_a,  
  input      [ADDR_BITS-1:0]    addr_a,
  input      [DATA_BITS-1:0]    din_a,

  // ------ Read Port (B) ------
  input                         en_b,
  input      [ADDR_BITS-1:0]    addr_b,
  output reg [DATA_BITS-1:0]    dout_b
);

  localparam DEPTH = 2**ADDR_BITS;
  localparam NUM_COL = DATA_BITS / COL_WIDTH; 

  (* cascade_height = 0 *)reg [DATA_BITS-1:0] mem [0:DEPTH-1];

  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end 
  end

  // ------------------------------
  // Write Port (Port A) with Byte Mask
  // ------------------------------
  integer i;
  always @(posedge clk) begin
    if (en_a) begin
      for (i = 0; i < NUM_COL; i = i + 1) begin
        if (we_a[i]) begin
            mem[addr_a][i*COL_WIDTH +: COL_WIDTH] <= din_a[i*COL_WIDTH +: COL_WIDTH];
        end
      end
    end
  end

  // ------------------------------
  // Read Port (Port B)
  // ------------------------------
  always @(posedge clk) begin
    if (en_b) begin
      dout_b <= mem[addr_b];  
    end
  end

endmodule