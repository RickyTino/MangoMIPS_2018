`include "defines.v"

module EX_MEM
(
	input  wire            clk, rst,
	input  wire            flush,
	input  wire            ex_stall, mem_stall,
	
	input  wire            ex_wreg,	
	input  wire [`RegAddr] ex_wraddr,
	input  wire [`DataBus] ex_wrdata,
	input  wire            ex_whilo,
	input  wire [`DataBus] ex_hi, ex_lo,
	input  wire [`AluOp]   ex_aluop,
	input  wire [`AddrBus] ex_ramaddr,
	input  wire [`DataBus] ex_opr2,
	input  wire            ex_cp0_we,
	input  wire [`RegAddr] ex_cp0_waddr,
	input  wire [`DataBus] ex_cp0_wdata,
	input  wire [`DataBus] ex_excp,
	input  wire            ex_inslot,
	input  wire [`AddrBus] ex_pc,
	
	output reg             mem_wreg,
	output reg  [`RegAddr] mem_wraddr,
	output reg  [`DataBus] mem_wrdata,
	output reg             mem_whilo,
	output reg  [`DataBus] mem_hi, mem_lo,
	output reg  [`AluOp]   mem_aluop,
	output reg  [`AddrBus] mem_ramaddr,
	output reg  [`DataBus] mem_opr2,
	output reg             mem_cp0_we,
	output reg  [`RegAddr] mem_cp0_waddr,
	output reg  [`DataBus] mem_cp0_wdata,
	output reg  [`DataBus] mem_excp,
	output reg             mem_inslot,
	output reg  [`AddrBus] mem_pc
);

	always @(posedge clk, posedge rst) begin
		if(rst) begin
			mem_wreg      <= `false;
			mem_wraddr    <= `ZeroReg;
			mem_wrdata    <= `ZeroWord;
			mem_whilo     <= `false;
			mem_hi        <= `ZeroWord;
			mem_lo        <= `ZeroWord;
			mem_pc        <= `ZeroWord;
			mem_aluop     <= `ALU_NOP;
			mem_ramaddr   <= `ZeroWord;
			mem_opr2      <= `ZeroWord;
			mem_cp0_we    <= `false;
			mem_cp0_waddr <= `ZeroReg;
			mem_cp0_wdata <= `ZeroWord;
			mem_excp      <= `ZeroWord;
			mem_inslot    <= `false;
			mem_pc        <= `ZeroWord;
		end
		else begin
			casez ({mem_stall, ex_stall, flush})
				3'b000: begin
					mem_wreg      <= ex_wreg;
					mem_wraddr    <= ex_wraddr;
					mem_wrdata    <= ex_wrdata;
					mem_whilo     <= ex_whilo;
					mem_hi        <= ex_hi;
					mem_lo        <= ex_lo;
					mem_aluop     <= ex_aluop;
					mem_ramaddr   <= ex_ramaddr;
					mem_opr2      <= ex_opr2;
					mem_cp0_we    <= ex_cp0_we;
					mem_cp0_waddr <= ex_cp0_waddr;
					mem_cp0_wdata <= ex_cp0_wdata;
					mem_excp      <= ex_excp;
					mem_inslot    <= ex_inslot;
					mem_pc        <= ex_pc;
				end
				
				3'b010,
				3'b??1: begin
					mem_wreg      <= `false;
					mem_wraddr    <= `ZeroReg;
					mem_wrdata    <= `ZeroWord;
					mem_whilo     <= `false;
					mem_hi        <= `ZeroWord;
					mem_lo        <= `ZeroWord;
					mem_aluop     <= `ALU_NOP;
					mem_ramaddr   <= `ZeroWord;
					mem_opr2      <= `ZeroWord;
					mem_cp0_we    <= `false;
					mem_cp0_waddr <= `ZeroReg;
					mem_cp0_wdata <= `ZeroWord;
					mem_excp      <= `ZeroWord;
					mem_inslot    <= `false;
					mem_pc        <= `ZeroWord;
				end
			endcase
			/*
			if(!ex_stall) begin
				mem_wreg      <= ex_wreg;
				mem_wraddr    <= ex_wraddr;
				mem_wrdata    <= ex_wrdata;
				mem_whilo     <= ex_whilo;
				mem_hi        <= ex_hi;
				mem_lo        <= ex_lo;
				mem_aluop     <= ex_aluop;
				mem_ramaddr   <= ex_ramaddr;
				mem_opr2      <= ex_opr2;
				mem_cp0_we    <= ex_cp0_we;
				mem_cp0_waddr <= ex_cp0_waddr;
				mem_cp0_wdata <= ex_cp0_wdata;
				mem_excp   <= ex_excp;
				mem_inslot    <= ex_inslot;
				mem_pc        <= ex_pc;
			end
			else if(!mem_stall) begin
				mem_wreg      <= `false;
				mem_wraddr    <= `ZeroReg;
				mem_wrdata    <= `ZeroWord;
				mem_whilo     <= `false;
				mem_hi        <= `ZeroWord;
				mem_lo        <= `ZeroWord;
				mem_aluop     <= `ALU_NOP;
				mem_ramaddr   <= `ZeroWord;
				mem_opr2      <= `ZeroWord;
				mem_cp0_we    <= `false;
				mem_cp0_waddr <= `ZeroReg;
				mem_cp0_wdata <= `ZeroWord;
				mem_excp   <= `ZeroWord;
				mem_inslot    <= `false;
				mem_pc        <= `ZeroWord;
			end
			*/
		end
	end

endmodule