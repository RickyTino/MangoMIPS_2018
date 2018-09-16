`include "defines.v"

module DIV 
(
	input  wire            clk, rst,
	
	input  wire            divsigned, start, abandon,
	input  wire [`DataBus] opr1, opr2,

	output reg             ready,
	output reg  [`DblData] res
);
	
	wire [32:0] temp;
	reg  [ 5:0] cnt;
	reg  [64:0] dividend;
	reg  [ 1:0] state;
	reg  [31:0] divisor;
	wire [31:0] topr1, topr2;
	
	parameter DIVFREE = 2'b00;
	parameter DIVBYZ  = 2'b01;
	parameter DIVON   = 2'b10;
	parameter DIVEND  = 2'b11;
	
	assign temp = {1'b0, dividend[63:32]} - {1'b0, divisor};
	
	assign topr1 = divsigned && opr1[31] ? ~opr1 + 1 : opr1;
	assign topr2 = divsigned && opr2[31] ? ~opr2 + 1 : opr2;
	
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			state    <= DIVFREE;
			ready    <= `false;
			res      <= `ZeroDWord;
			dividend <= 65'b0;
			divisor  <= `ZeroWord;
			cnt      <= 6'd0;
		end
		else begin
			case(state)
				DIVFREE: begin
					if(start && !abandon) begin
						if(opr2 == `ZeroWord) begin
							state <= DIVBYZ;
						end
						else begin
							state    <= DIVON;
							cnt      <= 6'd0;
							//topr1    <= divsigned && opr1[31] ? ~opr1 + 1 : opr1;
							//topr2    <= divsigned && opr2[31] ? ~opr2 + 1 : opr2;
							dividend <= {31'b0, topr1, 1'b0};
							divisor  <= topr2;
						end
					end
					else begin
						ready <= `false;
						res   <= `ZeroDWord;
					end
				end
				
				DIVBYZ: begin
					dividend <= `ZeroDWord;
					state    <= DIVEND;
				end
				
				DIVON: begin
					if(!abandon) begin
						if(cnt != 6'd32) begin
							if(temp[32] == 1'b1)
								dividend <= {dividend[63:0], 1'b0};
							else
								dividend <= {temp[31:0], dividend[31:0], 1'b1};
							cnt <= cnt + 1;
						end
						else begin
							if(divsigned && (opr1[31] ^ opr2[31]))
								dividend[31:0] <= ~dividend[31:0] + 1;
							if(divsigned && (opr1[31] ^ dividend[64]))
								dividend[64:33] <= ~dividend[64:33] + 1;
							state <= DIVEND;
							cnt   <= 6'd0;
						end
					end
					else begin
						state <= DIVFREE;
					end
				end
				
				DIVEND: begin
					res <= {dividend[64:33], dividend[31:0]};
					ready <= `true;
					if(!start) begin
						state <= DIVFREE;
						ready <= `false;
						res   <= `ZeroDWord;
					end
				end				
			endcase
		end
	end

endmodule