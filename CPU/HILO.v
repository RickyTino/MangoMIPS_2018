`include "defines.v"

module HILO
(
	input  wire            clk, rst,
	input  wire            we,
	input  wire [`DataBus] i_hi, i_lo,
	output reg  [`DataBus] o_hi, o_lo
);
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			o_hi <= `ZeroWord;
			o_lo <= `ZeroWord;
		end
		else begin
			if(we) begin
				o_hi <= i_hi;
				o_lo <= i_lo;
			end
		end
	end
	
endmodule