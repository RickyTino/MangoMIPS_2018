`include "defines.v"

module MEM_WB
(
	input wire             clk, rst,
	input wire             flush,
	input wire             mem_stall, wb_stall,
	
	input  wire [`AluOp]   mem_aluop,
	input  wire            mem_wreg,
	input  wire [`RegAddr] mem_wraddr,
	input  wire [`DataBus] mem_wrdata,
	input  wire [`DataBus] mem_ramdata,
	input  wire [`AddrBus] mem_ramaddr,
	input  wire [`DataBus] mem_opr2,
	input  wire            mem_mtor,
	input  wire            mem_whilo,
	input  wire [`DataBus] mem_hi, mem_lo,
	input  wire            mem_cp0_we,
	input  wire [`RegAddr] mem_cp0_waddr,
	input  wire [`DataBus] mem_cp0_wdata,
	input  wire [`AddrBus] mem_pc,
	
	output reg  [`AluOp]   wb_aluop,
	output reg             wb_wreg,
	output reg  [`RegAddr] wb_wraddr,
	output reg  [`DataBus] wb_wrdata,
	output reg  [`DataBus] wb_ramdata,
	output reg  [`AddrBus] wb_ramaddr,
	output reg  [`DataBus] wb_opr2,
	output reg             wb_mtor,
	output reg             wb_whilo,
	output reg  [`DataBus] wb_hi, wb_lo,
	output reg             wb_cp0_we,
	output reg  [`RegAddr] wb_cp0_waddr,
	output reg  [`DataBus] wb_cp0_wdata,
	output reg  [`AddrBus] wb_pc
	
);
	
	reg clrdata;
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			wb_aluop     <= `ALU_NOP;
			wb_wreg      <= `false;
			wb_wraddr    <= `ZeroReg;
			wb_wrdata    <= `ZeroWord;
			wb_ramaddr   <= `ZeroWord;
			wb_opr2      <= `ZeroWord;
			wb_mtor      <= `false;
			wb_whilo     <= `false;
			wb_hi        <= `ZeroWord;
			wb_lo        <= `ZeroWord;
			wb_cp0_we    <= `false;
			wb_cp0_waddr <= `ZeroReg;
			wb_cp0_wdata <= `ZeroWord;
			wb_pc        <= `ZeroWord;
			clrdata      <= `true;
		end
		else begin
			casez ({wb_stall, mem_stall, flush})
				3'b000: begin
					wb_aluop     <= mem_aluop;
					wb_wreg      <= mem_wreg;
					wb_wraddr    <= mem_wraddr;
					wb_wrdata    <= mem_wrdata;
					wb_ramaddr   <= mem_ramaddr;
					wb_opr2      <= mem_opr2;
					wb_mtor      <= mem_mtor;
					wb_whilo     <= mem_whilo;
					wb_hi        <= mem_hi;
					wb_lo        <= mem_lo;
					wb_cp0_we    <= mem_cp0_we;
					wb_cp0_waddr <= mem_cp0_waddr;
					wb_cp0_wdata <= mem_cp0_wdata;
					wb_pc        <= mem_pc;
					clrdata      <= `false;
				end
				
				3'b010,
				3'b??1: begin
					wb_aluop     <= `ALU_NOP;
					wb_wreg      <= `false;
					wb_wraddr    <= `ZeroReg;
					wb_wrdata    <= `ZeroWord;
					wb_ramaddr   <= `ZeroWord;
					wb_opr2      <= `ZeroWord;
					wb_mtor      <= `false;
					wb_whilo     <= `false;
					wb_hi        <= `ZeroWord;
					wb_lo        <= `ZeroWord;
					wb_cp0_we    <= `false;
					wb_cp0_waddr <= `ZeroReg;
					wb_cp0_wdata <= `ZeroWord;
					wb_pc        <= `ZeroWord;
					clrdata      <= `true;
				end
			endcase
			/*
			if(!mem_stall) begin
				wb_aluop     <= mem_aluop;
				wb_wreg      <= mem_wreg;
				wb_wraddr    <= mem_wraddr;
				wb_wrdata    <= mem_wrdata;
				wb_ramaddr   <= mem_ramaddr;
				wb_opr2      <= mem_opr2;
				wb_mtor      <= mem_mtor;
				wb_whilo     <= mem_whilo;
				wb_hi        <= mem_hi;
				wb_lo        <= mem_lo;
				wb_cp0_we    <= mem_cp0_we;
				wb_cp0_waddr <= mem_cp0_waddr;
				wb_cp0_wdata <= mem_cp0_wdata;
				wb_pc        <= mem_pc;
				clrdata      <= `false;
			end
			else if(!wb_stall) begin
				wb_aluop     <= `ALU_NOP;
				wb_wreg      <= `false;
				wb_wraddr    <= `ZeroReg;
				wb_wrdata    <= `ZeroWord;
				wb_ramaddr   <= `ZeroWord;
				wb_opr2      <= `ZeroWord;
				wb_mtor      <= `false;
				wb_whilo     <= `false;
				wb_hi        <= `ZeroWord;
				wb_lo        <= `ZeroWord;
				wb_cp0_we    <= `false;
				wb_cp0_waddr <= `ZeroReg;
				wb_cp0_wdata <= `ZeroWord;
				wb_pc        <= `ZeroWord;
				clrdata      <= `true;
			end
			*/
		end
	end
	
	always @(*) begin
		if(rst) wb_ramdata <= `ZeroWord;
		else    wb_ramdata <= clrdata ? `ZeroWord : mem_ramdata;
	end
	
endmodule