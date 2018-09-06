`include "defines.v"

module WB
(
	input  wire            rst,
	input  wire            mtor,
	input  wire [`AluOp]   aluop,
	input  wire [`DataBus] opr2,
	input  wire [`DataBus] wb_ramdata,
	input  wire [`AddrBus] wb_ramaddr,
	input  wire [`DataBus] wb_wrdata,
	
	output wire [`DataBus] rf_wrdata,
	
	output wire            stallreq
);
	
	assign stallreq = `false;
	
	reg [`DataBus] ramdata;
	
	always @(*) begin
		if(rst) begin
			ramdata <= `ZeroWord;
		end
		else begin
			case (aluop)
				`ALU_LB: begin
					case (wb_ramaddr[1:0])
						2'b00: ramdata <= {{24{wb_ramdata[ 7]}}, wb_ramdata[ 7: 0]};
						2'b01: ramdata <= {{24{wb_ramdata[15]}}, wb_ramdata[15: 8]};
						2'b10: ramdata <= {{24{wb_ramdata[23]}}, wb_ramdata[23:16]};
						2'b11: ramdata <= {{24{wb_ramdata[31]}}, wb_ramdata[31:24]};
					endcase
				end
				
				`ALU_LBU: begin
					case (wb_ramaddr[1:0])
						2'b00: ramdata <= {24'b0, wb_ramdata[ 7: 0]};
						2'b01: ramdata <= {24'b0, wb_ramdata[15: 8]};
						2'b10: ramdata <= {24'b0, wb_ramdata[23:16]};
						2'b11: ramdata <= {24'b0, wb_ramdata[31:24]};
					endcase
				end
				
				`ALU_LH: begin
					case (wb_ramaddr[1:0])
						2'b00:   ramdata <= {{16{wb_ramdata[15]}}, wb_ramdata[15: 0]};
						2'b10:   ramdata <= {{16{wb_ramdata[31]}}, wb_ramdata[31:16]};
						default: ramdata <= `ZeroWord;
					endcase
				end
				
				`ALU_LHU: begin
					case (wb_ramaddr[1:0])
						2'b00:   ramdata <= {16'b0, wb_ramdata[15: 0]};
						2'b10:   ramdata <= {16'b0, wb_ramdata[31:16]};
						default: ramdata <= `ZeroWord;
					endcase
				end
				
				`ALU_LW: begin
					ramdata  <= wb_ramdata;
				end
				
				`ALU_LWL: begin
					case (wb_ramaddr[1:0])
						2'b00: ramdata <= {wb_ramdata[ 7:0], opr2[23:0]};
						2'b01: ramdata <= {wb_ramdata[15:0], opr2[15:0]};
						2'b10: ramdata <= {wb_ramdata[23:0], opr2[ 7:0]};
						2'b11: ramdata <=  wb_ramdata[31:0];
					endcase
				end
				
				`ALU_LWR: begin
					case (wb_ramaddr[1:0])
						2'b00: ramdata <=               wb_ramdata[31: 0];
						2'b01: ramdata <= {opr2[31:24], wb_ramdata[31: 8]};
						2'b10: ramdata <= {opr2[31:16], wb_ramdata[31:16]};
						2'b11: ramdata <= {opr2[31: 8], wb_ramdata[31:24]};
					endcase
				end
				
				default: ramdata    <= `ZeroWord;
			endcase
		end
	end
	
	assign rf_wrdata = mtor ? ramdata : wb_wrdata;
	
endmodule