`include "defines.v"

module Ctrl
(
	input  wire            rst,
	input  wire [4:0]      stallreq, 
	output reg  [4:0]      stall,
	
	input  wire [`DataBus] exctype,
	input  wire [`DataBus] cp0_epc,
	
	output reg             flush,
	output reg  [`AddrBus] new_pc
);
	
	always @(*) begin
		if(rst) begin
			stall  <= 5'b00000;
			flush  <= `false;
			new_pc <= `ZeroWord;
		end
		else begin
			if(exctype != `ZeroWord) begin
				stall <= 5'b00000;
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
					5'b00001: stall <= 5'b00011;
					5'b0001?: stall <= 5'b00011;
					5'b001??: stall <= 5'b00111;
					5'b01???: stall <= 5'b01111;
					5'b1????: stall <= 5'b11111;
					default:  stall <= 5'b00000;
				endcase
			end
		end
	end
	
endmodule