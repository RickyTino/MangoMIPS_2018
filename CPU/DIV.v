`include "defines.v"

module DIV 
(
	input  wire            clk, rst,
	input  wire            divsigned, start, abandon,
	input  wire [`DataBus] opr1, opr2,
	output reg             ready,
	output reg  [`DblData] res
);
	
	wire        aresetn = !(rst || abandon);
    reg         opr_valid;
    reg  [31:0] divisor,    dividend;
    wire        sres_valid, ures_valid;
    wire [63:0] sres,       ures;
	
	wire        res_valid = divsigned ? sres_valid : ures_valid;
	wire [63:0] tempres   = divsigned ? sres       : ures;
	
	Divider_Signed divS(
		.aclk                    (clk),
		.aresetn                 (aresetn),
		.s_axis_divisor_tvalid   (opr_valid),
		.s_axis_divisor_tdata    (divisor),
		.s_axis_dividend_tvalid  (opr_valid),
		.s_axis_dividend_tdata   (dividend),
		.m_axis_dout_tvalid      (sres_valid),
		.m_axis_dout_tdata       (sres)
    );     
	
	Divider_Unsigned divU(
		.aclk                    (clk),
		.aresetn                 (aresetn),
		.s_axis_divisor_tvalid   (opr_valid),
		.s_axis_divisor_tdata    (divisor),
		.s_axis_dividend_tvalid  (opr_valid),
		.s_axis_dividend_tdata   (dividend),
		.m_axis_dout_tvalid      (ures_valid),
		.m_axis_dout_tdata       (ures)
    );
	
	wire [31:0] topr1, topr2;
	reg  [ 1:0] state;
	
	parameter DIVIDLE = 2'b00;
	parameter DIVON   = 2'b01;
	parameter DIVBYZ  = 2'b10;
	parameter DIVEND  = 2'b11;
	
	//assign topr1 = divsigned && opr1[31] ? ~opr1 + 1 : opr1;
	//assign topr2 = divsigned && opr2[31] ? ~opr2 + 1 : opr2;
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			state      <= DIVIDLE;
			ready      <= `false;
			res        <= `ZeroDWord;
			dividend   <= `ZeroWord;
			divisor    <= `ZeroWord;
			opr_valid <= `false;
		end
		else begin
			opr_valid <= `false;
			
			case(state)
				DIVIDLE: begin
					if(start && !abandon) begin
						if(opr2 == `ZeroWord) begin
							state <= DIVBYZ;
						end
						else begin
							state      <= DIVON;
							dividend   <= opr1;
							divisor    <= opr2;
							opr_valid  <= `true;
						end
					end
					else begin
						ready <= `false;
						res   <= `ZeroDWord;
					end
				end
				
				DIVON: begin
					if(!abandon) begin
						if(res_valid) begin
							res[63:32] <= tempres[31: 0];
							res[31: 0] <= tempres[63:32];
							ready <= `true;
							state <= DIVEND;
						end
					end
					else begin
						state <= DIVIDLE;
					end
				end
				
				DIVBYZ: begin
					res      <= `ZeroDWord;
					ready    <= `true;
					state    <= DIVEND;
				end
				
				DIVEND: begin
					if(!start) begin
						state <= DIVIDLE;
						ready <= `false;
						res   <= `ZeroDWord;
					end
				end				
			endcase
		end
	end

endmodule