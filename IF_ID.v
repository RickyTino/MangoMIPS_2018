`include "defines.v"

module IF_ID
(
	input  wire            clk, rst,
	input  wire            flush,
	input  wire            if_stall, id_stall,
	
	input  wire [`AddrBus] if_pc,
	input  wire [`InstBus] if_inst,
	input  wire [`DataBus] if_excp,
	
	output reg  [`AddrBus] id_pc,
	output reg  [`InstBus] id_inst,
	output reg  [`DataBus] id_excp
);
	
	reg clrinst;
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			id_pc   <= `ZeroWord;
			id_excp <= `ZeroWord;
			clrinst <= `false;
		end
		else begin
			casez ({id_stall, if_stall, flush})
				3'b000: begin
					id_pc   <= if_pc;
					id_excp <= if_excp;
				end
				
				3'b010,
				3'b??1: begin
					id_pc   <= `ZeroWord;
					id_excp <= `ZeroWord;
				end
			endcase
			clrinst <= (!id_stall && if_stall) || flush;
		end
	end
	
	always @(*) begin
		if(rst) begin
			id_inst <= `ZeroWord;
		end
		else begin
			id_inst <= clrinst ? `ZeroWord : if_inst;
		end
	end
	
endmodule