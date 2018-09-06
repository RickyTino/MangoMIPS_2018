`include "defines.v"

module CP0
(
	input  wire            clk, rst,
	
	input  wire            we,
	input  wire [`RegAddr] waddr, raddr,
	input  wire [`DataBus] wdata,
	output reg  [`DataBus] rdata,
	
	input  wire [`HardInt] intr,
	input  wire [`DataBus] exctype,
	input  wire [`DataBus] i_badvaddr,
	input  wire [`AddrBus] mem_pc,
	input  wire            inslot,
	
	//output reg  [`DataBus] count,
	//output reg  [`DataBus] compare,
	output reg  [`DataBus] badvaddr,
	output reg  [`DataBus] status,
	output reg  [`DataBus] cause,
	output reg  [`DataBus] epc
	//output reg  [`DataBus] conf,  //config
	//output reg  [`DataBus] prid,
	
	//output reg             timer_int
);

	always @(posedge clk, posedge rst) begin
		if(rst) begin
			badvaddr <= `ZeroWord;
			status   <= 32'h1000;
			cause    <= `ZeroWord;
			epc      <= `ZeroWord;
		end
		else begin
			cause [15:10] <= intr;
			if(we) begin
				case (waddr)
					`CP0_BADVADDR: badvaddr <= wdata;
					`CP0_STATUS:   status   <= wdata;
					`CP0_CAUSE:    cause    <= wdata;
					`CP0_EPC:      epc      <= wdata;
				endcase
			end
			
			case (exctype)
				`EXCT_INT: begin
					epc        <= inslot ? mem_pc - 32'h4 : mem_pc;
					cause[31]  <= inslot ? 1'b1 : 1'b0;
					status[1]  <= 1'b1;
					cause[6:2] <= `ECOD_INT;
				end
				
				`EXCT_SYS: begin
					epc        <= inslot ? mem_pc - 32'h4 : mem_pc;
					cause[31]  <= inslot ? 1'b1 : 1'b0;
					status[1]  <= 1'b1;
					cause[6:2] <= `ECOD_SYS;
				end
				
				`EXCT_BP: begin
					epc        <= inslot ? mem_pc - 32'h4 : mem_pc;
					cause[31]  <= inslot ? 1'b1 : 1'b0;
					status[1]  <= 1'b1;
					cause[6:2] <= `ECOD_BP;
				end
				
				`EXCT_RI: begin
					epc        <= inslot ? mem_pc - 32'h4 : mem_pc;
					cause[31]  <= inslot ? 1'b1 : 1'b0;
					status[1]  <= 1'b1;
					cause[6:2] <= `ECOD_RI;
				end
				
				`EXCT_OV: begin
					epc        <= inslot ? mem_pc - 32'h4 : mem_pc;
					cause[31]  <= inslot ? 1'b1 : 1'b0;
					status[1]  <= 1'b1;
					cause[6:2] <= `ECOD_OV;
				end
				
				`EXCT_ADEL: begin
					epc        <= inslot ? mem_pc - 32'h4 : mem_pc;
					cause[31]  <= inslot ? 1'b1 : 1'b0;
					status[1]  <= 1'b1;
					cause[6:2] <= `ECOD_ADEL;
					badvaddr   <= i_badvaddr;
				end
				
				`EXCT_ADES: begin
					epc        <= inslot ? mem_pc - 32'h4 : mem_pc;
					cause[31]  <= inslot ? 1'b1 : 1'b0;
					status[1]  <= 1'b1;
					cause[6:2] <= `ECOD_ADES;
					badvaddr   <= i_badvaddr;
				end
				
				`EXCT_ERET: begin
					status[1]  <= 1'b0;
				end
			endcase
		end
	end
	
	always @(*) begin
		if(rst) begin
			rdata <= `ZeroWord;
		end
		else begin
			case (raddr)
				`CP0_BADVADDR: rdata <= badvaddr;
				`CP0_STATUS:   rdata <= status;
				`CP0_CAUSE:    rdata <= cause;
				`CP0_EPC:      rdata <= epc;
				default:       rdata <= `ZeroWord;
			endcase
		end
	end

endmodule
	