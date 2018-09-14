module SRAM_Interface
(
	input  wire        clk, rst,
	input  wire        flush,
	//Inst_ram interface
	output reg  [31:0] iram_rdata,
	output reg         iram_wait,
	input  wire        iram_en,
	input  wire [ 3:0] iram_wen,
	input  wire [31:0] iram_addr,
	input  wire [31:0] iram_wdata,
	input  wire        iram_stall,
	
	//Data_ram interface
	output reg  [31:0] dram_rdata,
	output reg         dram_wait,
	input  wire        dram_en,
	input  wire [ 3:0] dram_wen,
	input  wire [31:0] dram_addr,
	input  wire [31:0] dram_wdata,
	input  wire        dram_stall,
	
	//Intermediate interface
	//output reg         axir_id,  //0:iram 1:dram
	output reg         axir_ireq,
	output reg  [31:0] axir_iaddr,
	output reg  [ 3:0] axir_ilen,
	
	output reg         axir_dreq,
	output reg  [31:0] axir_daddr,
	
	input  wire        axir_rid,
	input  wire        axir_rdy,
	input  wire        axir_last,
	input  wire [31:0] axir_data,

	output reg         axiw_req,
	output reg  [31:0] axiw_addr,
	output reg  [31:0] axiw_data,
	output reg  [31:0] axiw_sel,
	input  wire        axiw_rdy
);
	/*
	reg [31:0] irbuf_addr;
	reg [31:0] irbuf_data;
	wire       irbuf_vld = iram_addr == irbuf_addr;
	
	reg [31:0] drbuf_addr;
	reg [31:0] drbuf_data;
	wire       drbuf_vld = dram_addr == drbuf_addr;
	*/
	wire  inst_req = iram_en;
	wire  dram_wr  = dram_wen != 4'b0000;
	wire rdata_req = dram_en && !dram_wr;
	wire wdata_req = dram_en &&  dram_wr;
	
	wire axir_irdy  = axir_rdy && axir_rid == 1'b0;
	wire axir_drdy = axir_rdy && axir_rid == 1'b1;
	
	reg         inst_rdy,    rdata_rdy;
	reg  [31:0] temp_irdata, temp_drdata;
	
	
	reg [1:0] istate, dstate, axir_state;
	
	parameter I_IDLE = 2'b00;
	parameter I_BUSY = 2'b10;
	parameter I_WAIT = 2'b11;
	
	parameter D_IDLE  = 2'b00;
	parameter D_RBUSY = 2'b01;
	parameter D_WBUSY = 2'b10;
	parameter D_WAIT  = 2'b11;
	
	/*
	parameter R_IDLE  = 2'b00;
	parameter R_IBUSY = 2'b01;
	parameter R_DBUSY = 2'b10;
	
	reg i_axireq, d_axireq;
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			axir_state <= R_IDLE;
		end
		else begin
			case(axir_state)
				R_IDLE: begin
					if(i_axireq)
						axir_state <= R_IBUSY;
					else if(d_axireq)
						axir_state <= R_DBUSY;
				end
				R_IBUSY: axir_state <= R_IDLE;
				R_DBUSY: axir_state <= R_IDLE;
			endcase
		end
	end
	*/
	always @(*) begin
		if(rst) begin
			iram_wait <= 1'b0;
			dram_wait <= 1'b0;
		end
		else begin
			iram_wait <= 1'b0;
			dram_wait <= 1'b0;
			
			case (istate)
				I_IDLE: iram_wait  <= flush ? 1'b0 : inst_req;
				I_BUSY,
				I_WAIT: iram_wait  <= !inst_rdy;
			endcase
			
			case (dstate)
				D_IDLE:  dram_wait <= flush ? 1'b0 : rdata_req || wdata_req;
				D_RBUSY,
				D_WAIT:  dram_wait <= !rdata_rdy;
				D_WBUSY: dram_wait <= !axiw_rdy;
			endcase
		end
	end
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			//axir_id   <= 1'b0;
			axir_ireq  <= 1'b0;
			axir_iaddr <= 32'b0;
			axir_ilen  <= 4'b0;
			axir_dreq  <= 1'b0;
			axir_daddr <= 32'b0;
			axiw_req   <= 1'b0;
			axiw_addr  <= 32'b0;
			axiw_data  <= 32'b0;
			axiw_sel   <= 32'b0;
			
			istate      <= I_IDLE;
			dstate      <= D_IDLE;
			temp_irdata <= 32'b0;
			temp_drdata <= 32'b0;
			inst_rdy    <= 1'b0;
			rdata_rdy   <= 1'b0;
		end
		else begin
			axir_ireq  <= 1'b0;
			axir_iaddr <= 32'b0;
			axir_ilen  <= 4'b0;
			axir_dreq  <= 1'b0;
			axir_daddr <= 32'b0;
			axiw_req   <= 1'b0;
			axiw_addr  <= 32'b0;
			axiw_data  <= 32'b0;
			axiw_sel   <= 32'b0;
			
			case(istate)
				I_IDLE: begin
					if(inst_req && !flush) begin
						axir_ireq  <= 1'b1;
						axir_iaddr <= iram_addr;
						axir_ilen  <= 4'b0;
						inst_rdy   <= 1'b0;
						istate     <= I_BUSY;
					end
				end
	
				I_BUSY: begin
					if(axir_irdy) begin
						temp_irdata <= axir_data;
						inst_rdy    <= 1'b1;
						istate      <= I_WAIT;
					end
					if(flush) istate <= I_IDLE;
				end
				
				I_WAIT: begin
					if(!iram_stall) istate <= I_IDLE;
				end
			endcase
			
			case(dstate)
				D_IDLE: begin
					if(rdata_req && !flush) begin
						axir_dreq  <= 1'b1;
						axir_daddr <= dram_addr;
						rdata_rdy  <= 1'b0;
						dstate     <= D_RBUSY;
					end
					else if(wdata_req && !flush) begin
						axiw_req  <= 1'b1;
						axiw_addr <= dram_addr;
						axiw_data <= dram_wdata;
						axiw_sel  <= dram_wen;
						dstate    <= D_WBUSY;
					end
				end
				
				D_RBUSY: begin
					if(axir_drdy) begin
						temp_drdata <= axir_data;
						rdata_rdy   <= 1'b1;
						dstate      <= D_WAIT;
					end
					if(flush) dstate <= D_IDLE;
				end
				
				D_WBUSY: begin
					if(axiw_rdy) dstate <= D_IDLE;
					if(flush)    dstate <= D_IDLE;					
				end
				
				D_WAIT: begin
					if(!dram_stall) dstate <= D_IDLE;
				end
			endcase
			
		end
	end
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			iram_rdata <= 32'b0;
			dram_rdata <= 32'b0;
		end
		else begin
			if(!iram_stall && inst_rdy)  iram_rdata <= temp_irdata;
			if(!dram_stall && rdata_rdy) dram_rdata <= temp_drdata;
		end
	end
	
endmodule