module DInterface (
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
	input  wire [ 3:0] dram_wen,
	input  wire [31:0] dram_addr,
	output wire [31:0] dram_rdata,
	input  wire [31:0] dram_wdata,
	output wire        dram_sreq,
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
	assign axim_awsize   = 3'b010;
	assign axim_awburst  = 2'b01;
	assign axim_awlock   = 2'b0;
	assign axim_awcache  = 4'b0;
	assign axim_awprot   = 3'b0;
	assign axim_wid      = 4'b0;
	assign axim_bready   = 1'b1;
	
	wire  dram_wr  = dram_wen != 4'b0000;
	wire  dram_rreq = dram_en && !dram_wr;
	wire  dram_wreq = dram_en &&  dram_wr;
	
	reg [31:0] uncached_data;
	reg [31:0] uncached_addr;
	reg        uncached_valid;
	wire       uncached_hit = (uncached_addr == dram_addr) && uncached_valid;
	reg        wr_finish;
	
	reg rd_sreq, wr_sreq;
	
	assign dram_sreq = rd_sreq || wr_sreq;
	
	always @(*) begin
		if(rst) begin
			rd_sreq <= 1'b0;
			wr_sreq <= 1'b0;
		end
		else begin
			rd_sreq <= 1'b0;
			wr_sreq <= 1'b0;
			
			if(dram_en) begin
				if(dram_wr) begin
					wr_sreq <= !wr_finish;
				end
				else begin
					rd_sreq <= !uncached_hit;
				end
			end
		end
	end
	
	reg [31:0] rlk_addr;
	reg [31:0] wlk_addr;
	reg [31:0] wlk_data;
	reg [ 3:0] wlk_strb;
	
	reg [ 1:0] rstate, wstate;
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			rstate       <= 0;
			wstate       <= 0;
			
			axim_arid    <=  4'b0;
			axim_araddr  <= 32'b0;
			axim_arlen   <=  4'b0;
			axim_arvalid <=  1'b0;
			axim_awaddr  <= 32'b0;
			axim_awlen   <=  4'b0;
			axim_awvalid <=  1'b0;
			axim_wdata   <= 32'b0;
			axim_wstrb   <=  4'b0;
			axim_wlast   <=  1'b0;
			axim_wvalid  <=  1'b0;
			
			uncached_valid <= 1'b0;
			wr_finish      <= 1'b0;
			rlk_addr       <= 32'b0;
			wlk_addr       <= 32'b0;	
			wlk_data       <= 32'b0;
			wlk_strb       <=  4'b0;
		end
		else begin
			axim_arid    <=  4'b0;
			axim_araddr  <= 32'b0;
			axim_arlen   <=  4'b0;
			axim_arvalid <=  1'b0;
			axim_awaddr  <= 32'b0;
			axim_awlen   <=  4'b0;
			axim_awvalid <=  1'b0;
			axim_wdata   <= 32'b0;
			axim_wstrb   <=  4'b0;
			axim_wlast   <=  1'b0;
			axim_wvalid  <=  1'b0;
			
			uncached_valid <= 1'b0;
			wr_finish      <= 1'b0;
			
			case(rstate)
				0: begin
					if(dram_rreq && !uncached_hit) begin
						rlk_addr <= dram_addr;
						rstate   <= 1;
					end
				end
				
				1: begin
					if(axim_arvalid && axim_arready) begin
						rstate <= 2;
					end
					else begin
						axim_arid    <= 4'b0010;
						axim_araddr  <= rlk_addr;
						axim_arlen   <= 4'h0;
						axim_arvalid <= 1'b1;
					end
				end
				
				2: begin
					if(axim_rvalid) begin
						uncached_data <= axim_rdata;
						uncached_addr <= rlk_addr;
						if(axim_rlast) begin
							rstate <= 3;
						end
					end
				end
				
				3: begin
					uncached_valid <= 1'b1;
					if(dram_stall == rd_sreq) rstate <= 0;
				end
			endcase
			
			case(wstate)
				0: begin
					if(dram_wreq && !wr_finish) begin
						wlk_addr <= dram_addr;
						wlk_data <= dram_wdata;
						wlk_strb <= dram_wen;
						wstate   <= 1;
					end
				end
				
				1: begin
					if(axim_awvalid && axim_awready) begin
						wstate <= 2;
					end
					else begin
						axim_awaddr  <= wlk_addr;
						axim_awlen   <= 4'h0;
						axim_awvalid <= 1'b1;
					end
				end
				
				2: begin
					if(axim_wvalid && axim_wready) begin
						wstate      <= 3;
					end
					else begin
						axim_wdata  <= wlk_data;
						axim_wstrb  <= wlk_strb;
						axim_wvalid <= 1'b1;
						axim_wlast  <= 1'b1;
					end
				end
				
				3: begin
					if(axim_bvalid) begin
						wstate    <= 0;
						wr_finish <= 1'b1;
					end
				end				
			endcase
		end
	end
	
	reg [31:0] temp_rdata;
	reg lk_flush;
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			temp_rdata <= 32'b0;
			lk_flush <= 1'b0;
		end
		else begin
			if(!dram_stall) begin 
				temp_rdata <= uncached_data;
				lk_flush   <= flush;
			end
		end
	end
	
	assign dram_rdata = lk_flush ? 32'b0 : temp_rdata;
	
endmodule
	
	