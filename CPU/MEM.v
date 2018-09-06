`include "defines.v"

module MEM
(
	input wire             rst,
	
	input  wire [`AluOp]   aluop,
	input  wire [`DataBus] opr2,
	input  wire [`AddrBus] ramaddr,
	
	output wire [`DataBus] ramdata,
	output wire            mtor,
	
	//RAM interface
	input  wire [`DataBus] dram_rdata,
	input  wire            dram_sreq,
	output reg  [`AddrBus] dram_addr,
	output reg  [`WriteEn] dram_wen,
	output reg  [`DataBus] dram_wdata,
	output wire            dram_en,
	
	//Exceptions
	input  wire [`DataBus] i_excp,
	input  wire [`AddrBus] nowpc,
//	input  wire            inslot,
	input  wire [`DataBus] cp0_status,
	input  wire [`DataBus] cp0_cause,
	input  wire [`DataBus] cp0_epc,
	
	input  wire            wb_cp0_we,
	input  wire [`RegAddr] wb_cp0_waddr,
	input  wire [`DataBus] wb_cp0_wdata,
	
	output reg  [`DataBus] exctype,
	output wire [`DataBus] o_cp0_epc,
	output reg  [`DataBus] badvaddr,
	
	output wire            stallreq
);
	
	//Memory accessing
	//assign stallreq = dram_sreq && dram_en;
	assign stallreq = dram_sreq;
	assign mtor = dram_en && !dram_wen;
	assign ramdata = dram_rdata;
	
	reg exc_dadel, exc_dades;
	reg dram_en_t;
	
	reg [`DataBus] excp;
	
	always @(*) begin
		if(rst) begin
			dram_en_t  <= `false;
			dram_addr  <= `ZeroWord;
			dram_wen   <= `WrDisable;
			dram_wdata <= `ZeroWord;
			exc_dadel  <= `false;
			exc_dades  <= `false;
		end
		else begin
			dram_wdata <= `ZeroWord;
			exc_dadel  <= `false;
			exc_dades  <= `false;
			
			case (aluop)
				`ALU_LB,
				`ALU_LBU: begin
					dram_en_t <= `true;
					dram_addr <= ramaddr;
					dram_wen  <= `WrDisable;
				end
				
				`ALU_LH,
				`ALU_LHU: begin
					dram_en_t <= `true;
					dram_addr <= ramaddr;
					dram_wen  <= `WrDisable;
					exc_dadel <= ramaddr[0] != 1'b0;
					if(ramaddr[0] != 1'b0) begin
						exc_dadel <= `true;
						//dram_en_t   <= `false;
					end
				end
				
				`ALU_LW: begin
					dram_en_t <= `true;
					dram_addr <= ramaddr;
					dram_wen  <= `WrDisable;
					if(ramaddr[1:0] != 2'b0) begin
						exc_dadel <= `true;
						//dram_en_t   <= `false;
					end
				end
				
				`ALU_LWL: begin
					dram_en_t <= `true;
					dram_addr <= {ramaddr[31:2], 2'b00};
					dram_wen  <= `WrDisable;
				end
				
				`ALU_LWR: begin
					dram_en_t <= `true;
					dram_addr <= {ramaddr[31:2], 2'b00};
					dram_wen  <= `WrDisable;
				end
				
				`ALU_SB: begin
					dram_en_t  <= `true;
					dram_addr  <= ramaddr;
					dram_wdata <= {4{opr2[7:0]}};
					case (ramaddr[1:0])
						2'b00: dram_wen <= 4'b0001;
						2'b01: dram_wen <= 4'b0010;
						2'b10: dram_wen <= 4'b0100;
						2'b11: dram_wen <= 4'b1000;
					endcase
				end
				
				`ALU_SH: begin
					dram_en_t  <= `true;
					dram_addr  <= ramaddr;
					dram_wdata <= {2{opr2[15:0]}};
					case (ramaddr[1:0])
						2'b00:   dram_wen <= 4'b0011;
						2'b10:   dram_wen <= 4'b1100;
						default: dram_wen <= `WrDisable;
					endcase
					if(ramaddr[0] != 1'b0) begin
						exc_dades <= `true;
						//dram_en_t   <= `false;
					end
				end
				
				`ALU_SW: begin
					dram_en_t  <= `true;
					dram_addr  <= ramaddr;
					dram_wdata <= opr2;
					dram_wen   <= 4'b1111;
					if(ramaddr[1:0] != 2'b0) begin
						exc_dades <= `true;
						//dram_en_t   <= `false;
					end
				end
				
				`ALU_SWL: begin
					dram_en_t  <= `true;
					dram_addr  <= {ramaddr[31:2], 2'b00};
					case (ramaddr[1:0])
						2'b00: begin
							dram_wen   <= 4'b0001;
							dram_wdata <= {24'b0, opr2[31:24]};
						end
						
						2'b01: begin
							dram_wen   <= 4'b0011;
							dram_wdata <= {16'b0, opr2[31:16]};
						end
						
						2'b10: begin
							dram_wen   <= 4'b0111;
							dram_wdata <= { 8'b0, opr2[31: 8]};
						end
						
						2'b11: begin
							dram_wen   <= 4'b1111;
							dram_wdata <= opr2;
						end
					endcase
				end
				
				`ALU_SWR: begin
					dram_en_t  <= `true;
					dram_addr  <= {ramaddr[31:2], 2'b00};
					case (ramaddr[1:0])
						2'b00: begin
							dram_wen   <= 4'b1111;
							dram_wdata <= opr2;
						end
						
						2'b01: begin
							dram_wen   <= 4'b1110;
							dram_wdata <= {opr2[23:0],  8'b0};
						end
						
						2'b10: begin
							dram_wen   <= 4'b1100;
							dram_wdata <= {opr2[15:0], 16'b0};
						end
						
						2'b11: begin
							dram_wen   <= 4'b1000;
							dram_wdata <= {opr2[7:0], 24'b0};
						end
					endcase
				end
				
				default: begin
					dram_en_t  <= `false;
					dram_addr  <= `ZeroWord;
					dram_wen   <= `WrDisable;
					dram_wdata <= `ZeroWord;
					exc_dadel  <= `false;
					exc_dades  <= `false;
				end
			endcase
		end
	end
	
	assign dram_en = excp == `ZeroWord ? dram_en_t : `false;
	
	//CP0
	reg [`DataBus] status, cause, epc;
	
	wire wb_status_clash = wb_cp0_we && wb_cp0_waddr == `CP0_STATUS;
	wire wb_epc_clash    = wb_cp0_we && wb_cp0_waddr == `CP0_EPC;
	wire wb_cause_clash  = wb_cp0_we && wb_cp0_waddr == `CP0_CAUSE;
	
	always @(*) begin
		if(rst) begin
			status <= `ZeroWord;
			epc    <= `ZeroWord;
			cause  <= `ZeroWord;
		end
		else begin
			status       <= wb_status_clash ? wb_cp0_wdata      : cp0_status;
			epc          <= wb_epc_clash    ? wb_cp0_wdata      : cp0_epc;
			cause[ 9: 8] <= wb_cause_clash  ? wb_cp0_wdata[9:8] : cp0_cause[9:8];
			cause[31:10] <= cp0_cause[31:10];
			cause[ 7: 0] <= cp0_cause[ 7: 0];
		end
	end
	
	assign o_cp0_epc = epc;
	
	//Exceptions
	
	always @(*) begin
		excp <= i_excp;
		excp[`EXC_DADEL] <= exc_dadel;
		excp[`EXC_DADES] <= exc_dades;
	end
	
	wire exc_intr = (cause[15:8] & status[15:8]) != 8'h00 && !status[1] && status[0];
	wire exc_iade = excp[`EXC_IADEL];
	wire exc_sys  = excp[`EXC_SYS];
	wire exc_bp   = excp[`EXC_BP];
	wire exc_ri   = excp[`EXC_RI];
	wire exc_ov   = excp[`EXC_OV];
	wire exc_eret = excp[`EXC_ERET];
	
	wire [8:0] exccase = {
		exc_intr,
		exc_iade,
		exc_sys,
		exc_bp,
		exc_ri,
		exc_ov,
		exc_dadel,
		exc_dades,
		exc_eret
	};
	
	always @(*) begin
		if(rst) begin
			exctype <= `ZeroWord;
		end
		else begin
			exctype <= `ZeroWord;
			if(nowpc != `ZeroWord) begin
				casez (exccase)
					9'b1????????: exctype <= `EXCT_INT;
					9'b01???????: exctype <= `EXCT_ADEL;
					9'b001??????: exctype <= `EXCT_SYS;
					9'b0001?????: exctype <= `EXCT_BP;
					9'b00001????: exctype <= `EXCT_RI;
					9'b000001???: exctype <= `EXCT_OV;
					9'b0000001??: exctype <= `EXCT_ADEL;
					9'b00000001?: exctype <= `EXCT_ADES;
					9'b000000001: exctype <= `EXCT_ERET;
					default:      exctype <= `ZeroWord;
				endcase
			end
		end
	end
	
	always @(*) begin
		casez ({exc_iade, exc_dadel, exc_dades})
			3'b000: badvaddr <= `ZeroWord;
			3'b001,
			3'b010,
			3'b011: badvaddr <= ramaddr;
			3'b1??: badvaddr <= nowpc;
		endcase
	end
	
endmodule