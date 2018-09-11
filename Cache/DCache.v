`define State_Idle 0
`define State_Addr 1
`define State_Data 2
`define State_Wait 3

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
	output reg  [ 3:0] axim_awid,
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
	assign axim_awsize   = 3'b010;
	assign axim_awburst  = 2'b01;
	assign axim_awlock   = 2'b0;
	assign axim_awcache  = 4'b0;
	assign axim_awprot   = 3'b0;
	assign axim_wid      = 4'b0;
	assign axim_bready   = 1'b1;
	
	reg         ena  , enb;
	reg  [ 3:0] wea  , web;
	reg  [11:0] addra, addrb;
	reg  [31:0] dina , dinb;
	wire [31:0] douta, doutb;
	
	//Port A: CPU read & write
	//Port B: AXI read & write
	Data_Cache dcache (
	  .clka  (clk),		// input wire clka
	  .ena   (ena),		// input wire ena
	  .wea   (wea),		// input wire [3 : 0] wea
	  .addra (addra),	// input wire [11 : 0] addra
	  .dina  (dina),	// input wire [31 : 0] dina
	  .douta (douta),	// output wire [31 : 0] douta
	  
	  .clkb  (clk),		// input wire clkb
	  .enb   (enb),		// input wire enb
	  .web   (web),		// input wire [3 : 0] web
	  .addrb (addrb),	// input wire [11 : 0] addrb
	  .dinb  (dinb),	// input wire [31 : 0] dinb
	  .doutb (doutb)	// output wire [31 : 0] doutb
	);
	
	wire  dram_wr  = dram_wen != 4'b0000;
	wire  dram_rreq = dram_en && !dram_wr;
	wire  dram_wreq = dram_en &&  dram_wr;
	
	//Cached
	reg  [17:0] cache_haddr [255:0];
	reg         cache_valid [255:0];
	reg         cache_dirty [255:0];
	
	wire [ 3:0] addr_wdsel = dram_addr[ 5: 2];
	wire [ 7:0] addr_lnsel = dram_addr[13: 6];
	wire [17:0] addr_haddr = dram_addr[31:14];
	wire [17:0] line_haddr = cache_haddr[addr_lnsel];
	wire        line_valid = cache_valid[addr_lnsel];
	wire        line_dirty = cache_dirty[addr_lnsel];
	wire        cache_hit  = (line_haddr == addr_haddr) && line_valid;
	wire        cache_wb   = !cache_hit && line_valid && line_dirty;
	
	//Uncached
	reg  [31:0] uncached_data;
	reg  [31:0] uncached_addr;
	reg         uncached_valid;
	reg         uncached_wrdy;
	wire        uncached_hit = (uncached_addr == dram_addr) && uncached_valid;
	
	reg  rd_sreq, wr_sreq;
	assign dram_sreq = rd_sreq || wr_sreq;
	
	always @(*) begin
		if(rst) begin
			rd_sreq <=  1'b0;
			wr_sreq <=  1'b0;
			ena     <=  1'b0;
			wea     <=  4'b0;
			addra   <= 12'b0;
			dina    <= 32'b0;
		end
		else begin
			rd_sreq <= 1'b0;
			wr_sreq <= 1'b0;
			ena     <=  1'b0;
			wea     <=  4'b0;
			addra   <= 12'b0;
			dina    <= 32'b0;
			
			if(dram_en) begin
				if(dram_cached) begin
					if(!cache_hit) begin
						if(line_dirty) begin
							wr_sreq <= cache_wb;
							rd_sreq <= !cache_hit;
						end
						else begin
							rd_sreq <= !cache_hit;
						end
					end
					else begin
						ena       <= !dram_stall;
						wea       <= dram_wen;
						addra     <= dram_addr[13:2];
						dina      <= dram_wdata;
					end
				end
				else begin
					if(dram_wr) begin
						wr_sreq <= !uncached_wrdy;
					end
					else begin
						rd_sreq <= !uncached_hit;
					end
				end
			end
		end
	end
	
	reg [ 1:0] rstate,   wstate;
	reg [31:0] rlk_addr, wlk_addr;
	reg [31:0] wlk_data;
	reg [ 3:0] wlk_strb;
	reg [ 3:0] rcnt,     wcnt;
	
	reg        rlk_cached, wlk_cached;
	
	wire [7:0] rlk_lnsel = rlk_addr[13:6];
	wire [7:0] wlk_lnsel = wlk_addr[13:6];
	integer i;
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			for(i = 0; i < 256; i = i + 1) begin
				cache_haddr[i] <= 18'b0;
				cache_valid[i] <=  1'b0;
			end
			rstate       <= `State_Idle;
			wstate       <= `State_Idle;
			
			axim_arid    <=  4'b0;
			axim_araddr  <= 32'b0;
			axim_arlen   <=  4'b0;
			axim_arvalid <=  1'b0;
			axim_awid    <=  4'b0;
			axim_awaddr  <= 32'b0;
			axim_awlen   <=  4'b0;
			axim_awvalid <=  1'b0;
			axim_wdata   <= 32'b0;
			axim_wstrb   <=  4'b0;
			axim_wlast   <=  1'b0;
			axim_wvalid  <=  1'b0;
			
			enb   <=  1'b0;
			web   <=  4'h0;
			addrb <= 12'b0;
			dinb  <= 32'b0;
			
			uncached_data  <= 32'b0;
			uncachde_addr  <= 32'b0;
			uncached_valid <=  1'b0;
			uncached_wrdy  <=  1'b0;
			
			rcnt       <=  4'b0;
			wcnt       <=  4'b0;
			rlk_addr   <= 32'b0;
			wlk_addr   <= 32'b0;
			wlk_data   <= 32'b0;
			wlk_strb   <=  4'b0;
			rlk_cached <=  1'b0;
			wlk_cached <=  1'b0;
			
		end
		else begin
			axim_arid    <=  4'b0;
			axim_araddr  <= 32'b0;
			axim_arlen   <=  4'b0;
			axim_arvalid <=  1'b0;
			
			axim_awid    <=  4'b0;
			axim_awaddr  <= 32'b0;
			axim_awlen   <=  4'b0;
			axim_awvalid <=  1'b0;
			axim_wdata   <= 32'b0;
			axim_wstrb   <=  4'b0;
			axim_wlast   <=  1'b0;
			axim_wvalid  <=  1'b0;
			
			enb   <=  1'b0;
			web   <=  4'h0;
			addrb <= 12'b0;
			dinb  <= 32'b0;
			
			uncached_valid <=  1'b0;
			uncached_wrdy  <=  1'b0;
			
			case(rstate)
				`State_Idle: begin
					if(dram_rreq) begin
						rlk_cached <= dram_cached;
						if(dram_cached) begin
							if(!cache_hit && !cache_wb) begin
								rlk_addr <= {dram_addr[31:6], 6'b0};
								rcnt     <= 4'b0;
								rstate   <= `State_Addr;
								cache_haddr[addr_lnsel] <= dram_addr[31:14];
								cache_valid[addr_lnsel] <= 1'b0;
							end
						end
						else begin
							rlk_addr <= dram_addr;
							rstate   <= `State_Addr;
						end
					end
				end
				
				`State_Addr: begin
					if(axim_arvalid && axim_arready) begin
						rstate <= `State_Data;
					end
					else begin
						if(rlk_cached) begin
							axim_arid    <= 4'b0001;
							axim_araddr  <= rlk_addr;
							axim_arlen   <= 4'hF;
						end
						else begin
							axim_arid    <= 4'b0010;
							axim_araddr  <= rlk_addr;
							axim_arlen   <= 4'h0;
						end
						axim_arvalid <= 1'b1;
					end
				end
				
				`State_Data: begin
					if(axim_rvalid) begin
						if(rlk_cached) begin
							enb   <= 1'b1;
							web   <= 4'hF;
							addrb <= {rlk_lnsel, cnt};
							dinb  <= axim_rdata;
							rcnt  <= rcnt + 4'h1;
						end
						else begin
							uncached_data <= axim_rdata;
							uncached_addr <= rlk_addr;
						end
						if(axim_rlast) begin
							rstate <= `State_Wait;
						end
					end
				end
				
				`State_Wait: begin
					//cache_haddr[rlk_lnsel] <= rlk_addr[31:14];
					if(rlk_cached) begin
						cache_valid[rlk_lnsel] <= 1'b1;
					end
					else begin
						uncached_valid <= 1'b1;
					end
					if(iram_stall == rd_sreq) rstate <= `State_Idle;
				end
				
			endcase
			
			case(wstate)
				`State_Idle: begin
					if(dram_cached) begin
						if(cache_wb) begin
							wlk_addr   <= {iram_addr[31:6], 6'b0};
							wcnt       <= 4'b0;
							wlk_cached <= dram_cached;
							wstate     <= `State_Addr;
						end
					end
					else begin
						if(dram_wreq && !uncached_wrdy) begin
							wlk_addr   <= dram_addr;
							wlk_data   <= dram_wdata;
							wlk_strb   <= dram_wen;
							wlk_cached <= dram_cached;
							wstate     <= `State_Addr;
						end
					end
				end
				
				`State_Addr: begin
					if(axim_awvalid && axim_awready) begin
						state <= `State_Data;
						if(wlk_cached) begin
							enb   <= 1'b1;
							addrb <= {wlk_lnsel, wcnt};
						end
					end
					else begin
						if(wlk_cached) begin
							axim_awaddr  <= wlk_addr;
							axim_awlen   <= 4'hF;
							axim_awvalid <= 1'b1;
						end
						else begin
							axim_awaddr  <= wlk_addr;
							axim_awlen   <= 4'h0;
							axim_awvalid <= 1'b1;
						end
					end
				end
				
				`State_Data: begin
					
					if(axim_wvalid && axim_wready) begin
						if(wlk_cached) begin
							if(wcnt == 4'hF) begin
								state <= `State_Wait;
							end
							else begin
								wcnt  <= wcnt + 4'h1;
								enb   <= 1'b1;
								addrb <= {wlk_lnsel, wcnt};
							end
						end
						else wstate <= `State_Wait;
					end
					else begin
						if(wlk_cached) begin
							axim_wdata  <= doutb;
							axim_wstrb  <= 4'hF;
							axim_wvalid <= 1'b1;
							if(wcnt == 4'hF) axim_wlast <= 1'b1;
						end
						else begin
							axim_wdata  <= wlk_data;
							axim_wstrb  <= wlk_strb;
							axim_wvalid <= 1'b1;
							axim_wlast  <= 1'b1;
						end
					end
				end
				
				`State_Wait: begin
					if(axim_bvalid) begin
						wstate <= `State_Idle;
						if(wlk_cached) begin
							cache_dirty[wlk_lnsel] <= 1'b0;
						end
						else begin
							uncached_wrdy <= 1'b1;
						end
					end
				end
				
			endcase
		end
	end
	
	reg [31:0] temp_rdata;
	reg lk_flush;
	reg res_cached;
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			temp_rdata <= 32'b0;
			lk_flush <= 1'b0;
			res_cached <= 1'b0;
		end
		else begin
			if(!dram_stall) begin 
				temp_rdata <= uncached_data;
				lk_flush   <= flush;
				if(dram_rreq)
					res_cached <= dram_cached;
			end
		end
	end
	
	assign dram_rdata = lk_flush ? 32'b0 : res_cached ? douta : temp_rdata;
	
endmodule