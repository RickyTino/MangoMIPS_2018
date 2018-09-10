module DCache (
	input  wire        clk,
	input  wire        rst,
	input  wire        flush,
	//AXI signals
	output reg  [ 3:0] axim_arid,
	output reg  [31:0] axim_araddr,
	output reg  [ 3:0] axim_arlen,
	output wire [ 2:0] axim_arsize,
	output wire [ 1:0] axim_arburst,
	output wire [ 1:0] axim_arlock,
	output wire [ 3:0] axim_arcache,
	output wire [ 2:0] axim_arprot,
	output reg         axim_arvalid,
	input  wire        axim_arready,
	input  wire [ 3:0] axim_rid,
	input  wire [31:0] axim_rdata,
	input  wire [ 1:0] axim_rresp,
	input  wire        axim_rlast,
	input  wire        axim_rvalid,
	output wire        axim_rready,
	output wire [ 3:0] axim_awid,
	output reg  [31:0] axim_awaddr,
	output reg  [ 3:0] axim_awlen,
	output wire [ 2:0] axim_awsize,
	output wire [ 1:0] axim_awburst,
	output wire [ 1:0] axim_awlock,
	output wire [ 3:0] axim_awcache,
	output wire [ 2:0] axim_awprot,
	output reg         axim_awvalid,
	input  wire        axim_awready,
	output wire [ 3:0] axim_wid,
	output reg  [31:0] axim_wdata,
	output reg  [ 3:0] axim_wstrb,
	output reg         axim_wlast,
	output reg         axim_wvalid,
	input  wire        axim_wready,
	input  wire [ 3:0] axim_bid,
	input  wire [ 1:0] axim_bresp,
	input  wire        axim_bvalid,
	output wire        axim_bready,
	//SRAM signals
	input  wire        dram_en,
	input  wire [31:0] dram_addr,
	output reg  [31:0] dram_rdata,
	output reg         dram_sreq,
	input  wire        dram_stall,
	input  wire        dram_cached,
	input  wire        dram_hitiv,
	input  wire        dram_hitwb
);

	//Fixed AXI signals
	assign axim_arsize   = 3'b010;
	assign axim_arburst  = 2'b01;
	assign axim_arlock   = 2'b0;
	assign axim_arcache  = 4'b0;
	assign axim_arprot   = 3'b0;
	assign axim_rready   = 1'b1;
	assign axim_awid     = 4'b0;
//	assign axim_awlen    = 4'b0;
	assign axim_awsize   = 3'b010;
	assign axim_awburst  = 2'b01;
	assign axim_awlock   = 2'b0;
	assign axim_awcache  = 4'b0;
	assign axim_awprot   = 3'b0;
	assign axim_wid      = 4'b0;
	assign axim_bready   = 1'b1;
	
	wire  dram_wr  = dram_wen != 4'b0000;
	
	wire [ 3:0] addr_wdsel = dram_addr[ 5: 2];
	wire [ 7:0] addr_lnsel = dram_addr[13: 6];
	wire [17:0] addr_haddr = dram_addr[31:14];
	
	//Cached
	reg  [19:0] cache_table [255:0]; //19-Valid 18-dirty 17:0-High address
	wire [17:0] line_haddr = cache_table[addr_lnsel][17:0];
	wire        line_valid = cache_table[addr_lnsel][18];
	wire        line_dirty = cache_table[addr_lnsel][19];
	wire        cache_hit  = (line_haddr == addr_haddr) && line_valid;
	
	//Uncached
	reg  [31:0] uncached_data;
	reg  [31:0] uncached_addr;
	reg  [31:0] uncached_valid;
	
	
	always @(*) begin
		if(rst) begin
			dram_sreq <= 1'b0;
		end
		else begin
			if(dram_en) begin
				/*if(dram_cached) begin*/
					if(!cache_hit) begin
						if(line_dirty) begin
							//Wait for writeback and read finished
						end
						else begin
							//Only wait for read finished
						end
					end
					else begin
						dram_sreq <= 1'b0;
						ena       <= dram_en;
						wea       <= dram_wen;
						addra     <= dram_addr[13:2];
						dina      <= dram_wdata;
					end
				end
				/*else begin
					//Wait till uncached visiting finished
				end*/
			end
			else begin
				dram_sreq <= 1'b0;
			end
		end
	end
	
	//Synchronized cached signal, used to determine output mux
	reg  res_cached;
	
	//Synchronized module used to deal with non-stalling issues
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			res_cached <= 1'b0;
		end
		else begin
			if(!dram_stall) begin
				if(dram_en) begin
					if(!dram_wr) res_cached <= dram_cached;
				end
			end
		end
	end
	
	assign dram_rdata = res_cached ? douta : uncached_data;
endmodule