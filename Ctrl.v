`include "defines.v"

module Ctrl
(
	input  wire            rst,
	input  wire [4:0]      stallreq, 
	output reg  [5:0]      stall,
	
	input  wire [`DataBus] exctype,
	input  wire [`DataBus] cp0_epc,
	
	output reg             flush,
	output reg  [`AddrBus] new_pc
);
	
	always @(*) begin
		if(rst) begin
			stall  <= 6'b000000;
			flush  <= `false;
			new_pc <= `ZeroWord;
		end
		else begin
			if(exctype != `ZeroWord) begin
				stall <= 6'b000000;
				case (exctype)
					`EXCT_INT,
					`EXCT_SYS,
					`EXCT_BP,
					`EXCT_RI,
					`EXCT_OV,
					`EXCT_ADEL,
					`EXCT_ADES: begin
						flush  <= `true;
						new_pc <= `ENT_EXCP;
					end
					
					`EXCT_ERET: begin
						flush  <= `true;
						new_pc <= cp0_epc;
					end
					
					default: begin
						flush  <= `false;
						new_pc <= `ZeroWord;
					end
				endcase
			end
			else begin
				flush  <= `false;
				new_pc <= `ZeroWord;
				casez (stallreq)
					5'b00001: stall <= 6'b000111;
					5'b0001?: stall <= 6'b000111;
					5'b001??: stall <= 6'b001111;
					5'b01???: stall <= 6'b011111;
					5'b1????: stall <= 6'b111111;
					default:  stall <= 6'b000000;
				endcase
			end
		end
	end
	
endmodule