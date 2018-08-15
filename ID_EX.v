`include "defines.v"

module ID_EX
(
	input wire             clk, rst,
	input wire             flush,
	input wire             id_stall, ex_stall,
	
	input  wire [`InstBus] id_inst,
	input  wire [`AluOp]   id_aluop,
	input  wire [`AluCtrl] id_aluctrl,
	input  wire [`DataBus] id_opr1, id_opr2,
	input  wire            id_wreg,
	input  wire [`RegAddr] id_wraddr,
	input  wire [`AddrBus] id_linkaddr,
	input  wire            id_inslot,
	input  wire            id_nextslot,
//	input  wire [`AddrBus] id_ofsimm,
	input  wire [`DataBus] id_excp,
	input  wire [`AddrBus] id_pc,
	
	output reg  [`InstBus] ex_inst,
	output reg  [`AluOp]   ex_aluop,
	output reg  [`AluCtrl] ex_aluctrl,
	output reg  [`DataBus] ex_opr1, ex_opr2,
	output reg             ex_wreg,
	output reg  [`RegAddr] ex_wraddr,
	output reg  [`AddrBus] ex_linkaddr,
	output reg             ex_inslot,
	output reg             o_inslot,
//	output reg  [`AddrBus] ex_ofsimm,
	output reg  [`DataBus] ex_excp,
	output reg  [`AddrBus] ex_pc
);

	always @(posedge clk, posedge rst) begin
		if(rst) begin
			ex_inst     <= `ZeroWord;
			ex_aluop    <= `ALU_NOP;
			ex_aluctrl  <= `RES_NOP;
			ex_opr1     <= `ZeroWord;
			ex_opr2     <= `ZeroWord;
			ex_wreg     <= `false;
			ex_wraddr   <= `ZeroReg;
			ex_linkaddr <= `ZeroWord;
			ex_inslot   <= `false;
			o_inslot    <= `false;
//			ex_ofsimm   <= `ZeroWord;
			ex_excp     <= `ZeroWord;
			ex_pc	    <= `ZeroWord;
		end
		else begin
			casez ({ex_stall, id_stall, flush})
				3'b000: begin
					ex_inst     <= id_inst;
					ex_aluop    <= id_aluop;
					ex_aluctrl  <= id_aluctrl;
					ex_opr1     <= id_opr1;
					ex_opr2     <= id_opr2;
					ex_wreg     <= id_wreg;
					ex_wraddr   <= id_wraddr;
					ex_linkaddr <= id_linkaddr;
					ex_inslot   <= id_inslot;
					o_inslot    <= id_nextslot;
	//				ex_ofsimm   <= id_ofsimm;
					ex_excp     <= id_excp;
					ex_pc       <= id_pc;
				end
				
				3'b010,
				3'b??1: begin
					ex_inst     <= `ZeroWord;
					ex_aluop    <= `ALU_NOP;
					ex_aluctrl  <= `RES_NOP;
					ex_opr1     <= `ZeroWord;
					ex_opr2     <= `ZeroWord;
					ex_wreg     <= `false;
					ex_wraddr   <= `ZeroReg;
					ex_linkaddr <= `ZeroWord;
					ex_inslot   <= `false;
	//				ex_ofsimm   <= `ZeroWord;
					ex_excp     <= `ZeroWord;
					ex_pc	    <= `ZeroWord;
				end
			/*
			 if(!id_stall) begin
				ex_inst     <= id_inst;
				ex_aluop    <= id_aluop;
				ex_aluctrl  <= id_aluctrl;
				ex_opr1     <= id_opr1;
				ex_opr2     <= id_opr2;
				ex_wreg     <= id_wreg;
				ex_wraddr   <= id_wraddr;
				ex_linkaddr <= id_linkaddr;
				ex_inslot   <= id_inslot;
				o_inslot    <= id_nextslot;
//				ex_ofsimm   <= id_ofsimm;
				ex_excp  <= id_excp;
				ex_pc       <= id_pc;
			end
			else if(!ex_stall) begin
				ex_inst     <= `ZeroWord;
				ex_aluop    <= `ALU_NOP;
				ex_aluctrl  <= `RES_NOP;
				ex_opr1     <= `ZeroWord;
				ex_opr2     <= `ZeroWord;
				ex_wreg     <= `false;
				ex_wraddr   <= `ZeroReg;
				ex_linkaddr <= `ZeroWord;
				ex_inslot   <= `false;
//				ex_ofsimm   <= `ZeroWord;
				ex_excp  <= `ZeroWord;
				ex_pc	   <= `ZeroWord;
			end
			*/
			endcase
		end
	end
	
endmodule
