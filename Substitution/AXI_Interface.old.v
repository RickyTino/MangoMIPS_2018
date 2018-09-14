module AXI_Interface
(
	//AXI signals
	input  wire        aclk,
	input  wire        aresetn,
	//Read adress channel
	output reg  [ 3:0] arid,
	output reg  [31:0] araddr,
	output reg  [ 3:0] arlen,
	output wire [ 2:0] arsize,
	output wire [ 1:0] arburst,
	output wire [ 1:0] arlock,
	output wire [ 3:0] arcache,
	output wire [ 2:0] arprot,
	output reg         arvalid,
	input  wire        arready,
	//Read data channel
	input  wire [ 3:0] rid,
	input  wire [31:0] rdata,
	input  wire [ 1:0] rresp,
	input  wire        rlast,
	input  wire        rvalid,
	output wire        rready,
	//Write address channel
	output wire [ 3:0] awid,
	output reg  [31:0] awaddr,
	output wire [ 3:0] awlen,
	output wire [ 2:0] awsize,
	output wire [ 1:0] awburst,
	output wire [ 1:0] awlock,
	output wire [ 3:0] awcache,
	output wire [ 2:0] awprot,
	output reg         awvalid,
	input  wire        awready,
	//Write data channel
	output wire [ 3:0] wid,
	output reg  [31:0] wdata,
	output reg  [ 3:0] wstrb,
	output reg         wlast,
	output reg         wvalid,
	input  wire        wready,
	//Write response channel
	input  wire [ 3:0] bid,
	input  wire [ 1:0] bresp,
	input  wire        bvalid,
	output reg         bready,
	
	//Simple AXI read interface
	//input  wire        axir_id,  //0:iram 1:dram
	input  wire        axir_ireq,
	input  wire [31:0] axir_iaddr,
	input  wire [ 3:0] axir_ilen,
	input  wire        axir_dreq,
	input  wire [31:0] axir_daddr,
	output reg         axir_rid,
	output reg         axir_rdy,
	output reg         axir_last,
	output reg  [31:0] axir_data,
	
	//Simple AXI write interface
	input  wire        axiw_req,
	input  wire [31:0] axiw_addr,
	input  wire [31:0] axiw_data,
	input  wire [31:0] axiw_sel,
	output reg         axiw_rdy,
	
	input  wire        flush
);
	//parameters
	parameter AXIR_IDLE = 2'b00;
	parameter AXIR_WAIT = 2'b01;
	parameter AXIR_ADDR = 2'b10;
	parameter AXIR_DATA = 2'b11;
	
	parameter AXIW_IDLE = 2'b00;
	parameter AXIW_ADDR  = 2'b01;
	parameter AXIW_DATA = 2'b10;
	parameter AXIW_RESP = 2'b11;
	
	parameter AR_IDLE = 2'b00;
	parameter AR_INST = 2'b10;
	parameter AR_DATA = 2'b11;
	
	//Unused AXI signals
	assign arsize   = 3'b101;
	assign arburst  = 2'b01;
	assign arlock   = 2'b0;
	assign arcache  = 4'b0;
	assign arprot   = 3'b0;
	
	assign rready   = 1'b1;
	
	assign awid     = 4'b0;
	assign awlen    = 4'b0;
	assign awsize   = 3'b101;
	assign awburst  = 2'b01;
	assign awlock   = 2'b0;
	assign awcache  = 4'b0;
	assign awprot   = 3'b0;
	
	assign wid      = 4'b0;
	
	//DFA state registers
	reg  [ 1:0] irstate, drstate, arstate;
	
	//AR-channel Arbitation
	reg i_ar_req, d_ar_req;
	
	always @(posedge aclk, negedge aresetn) begin
		if(!aresetn)
			arstate <= AR_IDLE;
		else begin
			case (arstate)
				AR_IDLE: arstate <= i_ar_req ? AR_INST : 
					                d_ar_req ? AR_DATA : AR_IDLE;
				AR_INST: arstate <= i_ar_req ? AR_INST : AR_IDLE;
				AR_DATA: arstate <= d_ar_req ? AR_DATA : AR_IDLE;
			endcase
		end
	end
	
	//AXI Read Interface
	reg  [ 3:0] ilock_len;
	reg  [31:0] ilock_raddr, dlock_raddr;
	
	always @(posedge aclk, negedge aresetn) begin
		if(!aresetn) begin
			arid     <=  4'b0;
			araddr   <= 32'b0;
			arlen    <=  4'b0;
			arvalid  <=  1'b0;
			
			axir_rid    <=  1'b0;
			axir_rdy    <=  1'b0;
			axir_last   <=  1'b0;
			axir_data   <= 32'b0;
			
			ilock_len   <= 4'b0;
			ilock_raddr <= 32'b0;
			dlock_raddr <= 32'b0;
			irstate     <= AXIR_IDLE;
			drstate     <= AXIR_IDLE;
			i_ar_req    <= 1'b0;
			d_ar_req    <= 1'b0;
		end
		else begin
			arid     <=  4'b0;
			araddr   <= 32'b0;
			arlen    <=  4'b0;
			arvalid  <=  1'b0;
			
			axir_rdy  <= 1'b0;
			axir_rid  <= 1'b0;
			axir_data <= 32'b0;
			
			case (irstate)
				AXIR_IDLE: begin
					if(axir_ireq && !flush) begin
						ilock_raddr <= axir_iaddr;
						ilock_len   <= axir_ilen;
						i_ar_req    <= 1'b1;
						irstate     <= AXIR_WAIT;
					end
				end
				
				AXIR_WAIT: begin
					if(arstate == AR_INST) begin
						arid    <= 4'b0;
						araddr  <= ilock_raddr;
						arlen   <= ilock_len;
						arvalid <= 1'b1;
						irstate <= AXIR_ADDR;
					end
				end
				
				AXIR_ADDR: begin
					if(arready) begin
						irstate  <= AXIR_DATA;
						i_ar_req <= 1'b0;
					end
					else begin
						arid    <= 4'b0;
						araddr  <= ilock_raddr;
						arlen   <= ilock_len;
						arvalid <= 1'b1;
					end
				end
				
				AXIR_DATA: begin
					if(rvalid && (rid == 4'b0000)) begin
						axir_data <= rdata;
						axir_rdy  <= 1'b1;
						axir_rid  <= 1'b0;
						axir_last <= rlast;
						irstate   <= rlast ? AXIR_IDLE : AXIR_DATA;
					end
				end
			endcase
			
			case (drstate)
				AXIR_IDLE: begin
					if(axir_dreq && !flush) begin
						dlock_raddr <= axir_daddr;
						d_ar_req    <= 1'b1;
						drstate     <= AXIR_WAIT;
					end
				end
				
				AXIR_WAIT: begin
					if(arstate == AR_DATA) begin
						arid    <= 4'b0001;
						araddr  <= dlock_raddr;
						arlen   <= 4'b0;
						arvalid <= 1'b1;
						drstate <= AXIR_ADDR;
					end
				end
				
				AXIR_ADDR: begin
					if(arready) begin
						drstate  <= AXIR_DATA;
						d_ar_req <= 1'b0;
					end
					else begin
						arid    <= 4'b0001;
						araddr  <= dlock_raddr;
						arlen   <= 4'b0;
						arvalid <= 1'b1;
					end
				end
				
				AXIR_DATA: begin
					if(rvalid && (rid == 4'b0001)) begin
						axir_data <= rdata;
						axir_rdy  <= 1'b1;
						axir_rid  <= 1'b1;
						drstate   <= rlast ? AXIR_IDLE : AXIR_DATA;
					end
				end
			endcase
		end
	end
	
	//AXI Write Interface
	reg  [ 3:0] lock_strb;
	reg  [31:0] lock_waddr;
	reg  [31:0] lock_wdata;
	reg  [ 1:0] wstate;
	
	always @(posedge aclk, negedge aresetn) begin
		if(!aresetn) begin
			awaddr  <= 32'b0;
			awvalid <=  1'b0;
			wdata   <= 32'b0;
			wstrb   <=  4'b0;
			wlast   <=  1'b0;
			wvalid  <=  1'b0;
			bready  <=  1'b0;
			
			axiw_rdy   <=  1'b0;
			lock_waddr <= 32'b0;
			lock_wdata <= 32'b0;
			lock_strb  <=  4'b0;
			wstate     <= AXIW_IDLE;
		end
		else begin
			awaddr  <= 32'b0;
			awvalid <=  1'b0;
			wdata   <= 32'b0;
			wstrb   <=  4'b0;
			wlast   <=  1'b0;
			wvalid  <=  1'b0;
			bready  <=  1'b0;
			
			axiw_rdy <= 1'b0;
			
			case (wstate)
				AXIW_IDLE: begin
					if(axiw_req && !flush) begin
						lock_waddr <= axiw_addr;
						lock_wdata <= axiw_data;
						lock_strb  <= axiw_sel;
						wstate     <= AXIW_ADDR;
					end
				end
				
				AXIW_ADDR: begin
					if(!awready) begin
						awaddr  <= lock_waddr;
						awvalid <= 1'b1;
					end
					else begin
						wdata  <= lock_wdata;
						wstrb  <= lock_strb;
						wvalid <= 1'b1;
						wlast  <= 1'b1;
						bready <= 1'b1;
						wstate <= AXIW_DATA;
					end
				end
				
				AXIW_DATA: begin
					if(!wready) begin
						wdata  <= lock_wdata;
						wstrb  <= lock_strb;
						wvalid <= 1'b1;
						wlast  <= 1'b1;
						bready <= 1'b1;
					end
					else begin
						wstate <= AXIW_RESP;
					end
				end
				
				AXIW_RESP: begin
					bready <= 1'b1;
					if(bvalid) begin
						//if(bresp == 2'b00)
						wstate   <= AXIW_IDLE;
						bready   <= 1'b0;
						axiw_rdy <= 1'b1;
					end
				end
			endcase
		end
	end
	
endmodule