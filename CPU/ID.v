`include "defines.v"

module ID
(
	input  wire            rst,
	input  wire [`AddrBus] pc,
	input  wire [`InstBus] inst,
	 
	input  wire [`DataBus] r1data, r2data,
	output reg             r1read, r2read,
	output reg  [`RegAddr] r1addr, r2addr,
	
	output reg  [`AluOp]   aluop,
	output reg  [`AluCtrl] aluctrl,
	output reg  [`DataBus] opr1, opr2,
	output reg         	   wreg,
	output reg  [`RegAddr] wraddr,
	
	input  wire [`AluOp]   ex_aluop,
	input  wire            ex_wreg,
	input  wire [`RegAddr] ex_wraddr,
	input  wire [`DataBus] ex_wrdata,
	
	input  wire [`AluOp]   mem_aluop,
	input  wire            mem_wreg,
	input  wire [`RegAddr] mem_wraddr,
	input  wire [`DataBus] mem_wrdata,
	
	input  wire            i_inslot,
	output reg             nextslot,
	output reg             o_inslot,
	output reg             bflag,
	output reg  [`AddrBus] baddr,
	output reg  [`AddrBus] linkaddr,
	
	input  wire [`DataBus] i_excp,
	output reg  [`DataBus] o_excp,
	
	output reg             stallreq
);
	
	wire [ 5:0] op    = inst[31:26];
	wire [ 4:0] op2   = inst[10: 6];
	wire [ 5:0] op3   = inst[ 5: 0];
	wire [ 4:0] op4   = inst[20:16];
	
	wire [ 4:0] rs    = inst[25:21];
	wire [ 4:0] rt    = inst[20:16];
	wire [ 4:0] rd    = inst[15:11];
	wire [ 4:0] sa    = inst[10: 6];
	
	wire [31:0] zeimm = {16'h0000, inst[15:0]};
	wire [31:0] seimm = {{16{inst[15]}}, inst[15:0]};
	wire [31:0] luimm = {inst[15:0], 16'h0000};
	
	wire [31:0] pcp4   = pc + 32'h4;
	wire [31:0] pcp8   = pc + 32'h8;
	wire [31:0] bofs   = {seimm[29:0], 2'b00};
	
	reg [31:0] imm;
	reg n_valid;
	
	reg exc_sys, exc_bp, exc_eret;
	
	always @(*) begin
		o_excp            <= i_excp;
		o_excp[`EXC_SYS]  <= exc_sys;
		o_excp[`EXC_BP]   <= exc_bp;
		o_excp[`EXC_RI]   <= n_valid;
		o_excp[`EXC_ERET] <= exc_eret;
	end
	
	always @(*) begin
		if(rst) begin
			aluop       <= `ALU_NOP;
			aluctrl     <= `RES_NOP;
			wreg        <= `false;
			wraddr      <= `ZeroReg;
			n_valid     <= `false;
			r1read      <= `false;
			r2read      <= `false;
			r1addr      <= `ZeroReg;
			r2addr      <= `ZeroReg;
			imm         <= `ZeroWord;
			linkaddr    <= `ZeroWord;
			baddr       <= `ZeroWord;
			bflag       <= `false;
			nextslot    <= `false;
			exc_eret    <= `false;
			exc_bp      <= `false;
			exc_sys     <= `false;
		end
		else begin
			aluop       <= `ALU_NOP;
			aluctrl     <= `RES_NOP;
			wreg        <= `false;
			wraddr      <=  rd;
			n_valid     <= `true;
			r1read      <= `false;
			r2read      <= `false;
			r1addr      <=  rs;
			r2addr      <=  rt;
			imm         <=  `ZeroWord;
			linkaddr    <= `ZeroWord;
			baddr       <= `ZeroWord;
			bflag       <= `false;
			nextslot    <= `false;
			exc_eret    <= `false;
			exc_bp      <= `false;
			exc_sys     <= `false;
			
			//todo: 合并case，减少级数
			
			case (op)
				`OP_SPECIAL: begin
					case (op2)
						5'b00000: begin
							case (op3)
								`OP_OR: begin
									wreg    <= `true;
									aluop   <= `ALU_OR;
									aluctrl <= `RES_LOGIC;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_AND: begin
									wreg    <= `true;
									aluop   <= `ALU_AND;
									aluctrl <= `RES_LOGIC;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_XOR: begin
									wreg    <= `true;
									aluop   <= `ALU_XOR;
									aluctrl <= `RES_LOGIC;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_NOR: begin
									wreg    <= `true;
									aluop   <= `ALU_NOR;
									aluctrl <= `RES_LOGIC;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_SLLV: begin
									wreg    <= `true;
									aluop   <= `ALU_SLL;
									aluctrl <= `RES_SHIFT;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_SRLV: begin
									wreg    <= `true;
									aluop   <= `ALU_SRL;
									aluctrl <= `RES_SHIFT;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_SRAV: begin
									wreg    <= `true;
									aluop   <= `ALU_SRA;
									aluctrl <= `RES_SHIFT;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_SYNC: begin
									wreg    <= `true;
									aluop   <= `ALU_NOP;
									aluctrl <= `RES_NOP;
									r1read  <= `false;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_MFHI: begin
									wreg    <= `true;
									aluop   <= `ALU_MFHI;
									aluctrl <= `RES_MOVE;
									r1read  <= `false;
									r2read  <= `false;
									n_valid <= `false;
								end
								
								`OP_MFLO: begin
									wreg    <= `true;
									aluop   <= `ALU_MFLO;
									aluctrl <= `RES_MOVE;
									r1read  <= `false;
									r2read  <= `false;
									n_valid <= `false;
								end
								
								`OP_MTHI: begin
									wreg    <= `false;
									aluop   <= `ALU_MTHI;
									aluctrl <= `RES_MOVE;
									r1read  <= `true;
									r2read  <= `false;
									n_valid <= `false;
								end
								
								`OP_MTLO: begin
									wreg    <= `false;
									aluop   <= `ALU_MTLO;
									aluctrl <= `RES_MOVE;
									r1read  <= `true;
									r2read  <= `false;
									n_valid <= `false;
								end
								
								`OP_MOVN: begin
									wreg    <= (opr2 != `ZeroWord)? `true : `false;
									aluop   <= `ALU_MOVN;
									aluctrl <= `RES_MOVE;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_MOVZ: begin
									wreg    <= (opr2 == `ZeroWord)? `true : `false;
									aluop   <= `ALU_MOVZ;
									aluctrl <= `RES_MOVE;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_SLT: begin
									wreg    <= `true;
									aluop   <= `ALU_SLT;
									aluctrl <= `RES_ARITH;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_SLTU: begin
									wreg    <= `true;
									aluop   <= `ALU_SLTU;
									aluctrl <= `RES_ARITH;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_ADD: begin
									wreg    <= `true;
									aluop   <= `ALU_ADD;
									aluctrl <= `RES_ARITH;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_ADDU: begin
									wreg    <= `true;
									aluop   <= `ALU_ADDU;
									aluctrl <= `RES_ARITH;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_SUB: begin
									wreg    <= `true;
									aluop   <= `ALU_SUB;
									aluctrl <= `RES_ARITH;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_SUBU: begin
									wreg    <= `true;
									aluop   <= `ALU_SUBU;
									aluctrl <= `RES_ARITH;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_MULT: begin
									wreg    <= `false;
									aluop   <= `ALU_MULT;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_MULTU: begin
									wreg    <= `false;
									aluop   <= `ALU_MULTU;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_DIV: begin
									wreg    <= `false;
									aluop   <= `ALU_DIV;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_DIVU: begin
									wreg    <= `false;
									aluop   <= `ALU_DIVU;
									r1read  <= `true;
									r2read  <= `true;
									n_valid <= `false;
								end
								
								`OP_JR: begin
									wreg     <= `false;
									aluop    <= `ALU_JR;
									aluctrl  <= `RES_JB;
									r1read   <= `true;
									r2read   <= `false;
									linkaddr <= `ZeroWord;
									bflag    <= `true;
									baddr    <=  opr1;
									nextslot <= `true;
									n_valid  <= `false;
								end
								
								`OP_JALR: begin
									wreg     <= `true;
									aluop    <= `ALU_JALR;
									aluctrl  <= `RES_JB;
									r1read   <= `true;
									r2read   <= `false;
									wraddr   <=  rd;
									linkaddr <= pcp8;
									bflag    <= `true;
									baddr    <=  opr1;
									nextslot <= `true;
									n_valid  <= `false;
								end
								
								`OP_SYSCALL: begin
									wreg     <= `false;
									aluop    <= `ALU_SYSCALL;
									aluctrl  <= `RES_NOP;
									r1read   <= `false;
									r2read   <= `false;
									n_valid  <= `false;
									exc_sys  <= `true;
								end
								
								`OP_BREAK: begin
									wreg     <= `false;
									aluop    <= `ALU_BREAK;
									aluctrl  <= `RES_NOP;
									r1read   <= `false;
									r2read   <= `false;
									n_valid  <= `false;
									exc_bp   <= `true;
								end
								default: begin
								
								end
							endcase
						end
						default: begin
						
						end
					endcase
				end
				
				`OP_SPECIAL2: begin
					case (op3)
						`OP_CLZ: begin
							wreg    <= `true;
							aluop   <= `ALU_CLZ;
							aluctrl <= `RES_ARITH;
							r1read  <= `true;
							r2read  <= `false;
							n_valid <= `false;
						end
						
						`OP_CLO: begin
							wreg    <= `true;
							aluop   <= `ALU_CLO;
							aluctrl <= `RES_ARITH;
							r1read  <= `true;
							r2read  <= `false;
							n_valid <= `false;
						end
						
						`OP_MUL: begin
							wreg    <= `true;
							aluop   <= `ALU_MUL;
							aluctrl <= `RES_MUL;
							r1read  <= `true;
							r2read  <= `true;
							n_valid <= `false;
						end
						
						`OP_MADD: begin
							wreg    <= `false;
							aluop   <= `ALU_MADD;
							r1read  <= `true;
							r2read  <= `true;
							n_valid <= `false;
						end
						
						`OP_MADDU: begin
							wreg    <= `false;
							aluop   <= `ALU_MADDU;
							r1read  <= `true;
							r2read  <= `true;
							n_valid <= `false;
						end
						
						`OP_MSUB: begin
							wreg    <= `false;
							aluop   <= `ALU_MSUB;
							r1read  <= `true;
							r2read  <= `true;
							n_valid <= `false;
						end
						
						`OP_MSUBU: begin
							wreg    <= `false;
							aluop   <= `ALU_MSUBU;
							r1read  <= `true;
							r2read  <= `true;
							n_valid <= `false;
						end
						
						default: begin
						end
					endcase
				end
				
				`OP_ORI: begin
					wreg    <= `true;
					aluop   <= `ALU_OR;
					aluctrl <= `RES_LOGIC;
					r1read  <= `true;
					r2read  <= `false;
					imm     <=  zeimm;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_ANDI: begin
					wreg    <= `true;
					aluop   <= `ALU_AND;
					aluctrl <= `RES_LOGIC;
					r1read  <= `true;
					r2read  <= `false;
					imm     <=  zeimm;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_XORI: begin
					wreg    <= `true;
					aluop   <= `ALU_XOR;
					aluctrl <= `RES_LOGIC;
					r1read  <= `true;
					r2read  <= `false;
					imm     <=  zeimm;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_LUI: begin
					wreg    <= `true;
					aluop   <= `ALU_OR;
					aluctrl <= `RES_LOGIC;
					r1read  <= `true;
					r2read  <= `false;
					imm     <=  luimm;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_PREF: begin
					wreg    <= `false;
					aluop   <= `ALU_NOP;
					aluctrl <= `RES_NOP;
					r1read  <= `false;
					r2read  <= `false;
					n_valid <= `false;
				end
				
				`OP_SLTI: begin
					wreg    <= `true;
					aluop   <= `ALU_SLT;
					aluctrl <= `RES_ARITH;
					r1read  <= `true;
					r2read  <= `false;
					imm     <=  seimm;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_SLTIU: begin
					wreg    <= `true;
					aluop   <= `ALU_SLTU;
					aluctrl <= `RES_ARITH;
					r1read  <= `true;
					r2read  <= `false;
					imm     <=  seimm;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_ADDI: begin
					wreg    <= `true;
					aluop   <= `ALU_ADD;
					aluctrl <= `RES_ARITH;
					r1read  <= `true;
					r2read  <= `false;
					imm     <=  seimm;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_ADDIU: begin
					wreg    <= `true;
					aluop   <= `ALU_ADDU;
					aluctrl <= `RES_ARITH;
					r1read  <= `true;
					r2read  <= `false;
					imm     <=  seimm;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_J: begin
					wreg     <= `false;
					aluop    <= `ALU_J;
					aluctrl  <= `RES_JB;
					r1read   <= `false;
					r2read   <= `false;
					linkaddr <= `ZeroWord;
					bflag    <= `true;
					baddr    <= {pcp4[31:28], inst[25:0], 2'b00};
					nextslot <= `true;
					n_valid  <= `false;
				end
				
				`OP_JAL: begin
					wreg     <= `true;
					aluop    <= `ALU_JAL;
					aluctrl  <= `RES_JB;
					r1read   <= `false;
					r2read   <= `false;
					wraddr   <=  5'd31;
					linkaddr <=  pcp8;
					bflag    <= `true;
					baddr    <= {pcp4[31:28], inst[25:0], 2'b00};
					nextslot <= `true;
					n_valid  <= `false;
				end
				
				`OP_BEQ: begin
					wreg     <= `false;
					aluop    <= `ALU_BEQ;
					aluctrl  <= `RES_JB;
					r1read   <= `true;
					r2read   <= `true;
					n_valid  <= `false;
					nextslot <= `true;
					if(opr1 == opr2) begin
						baddr    <=  pcp4 + bofs;
						bflag    <= `true;
					end
				end
				
				`OP_BNE: begin
					wreg     <= `false;
					aluop    <= `ALU_BNE;
					aluctrl  <= `RES_JB;
					r1read   <= `true;
					r2read   <= `true;
					n_valid  <= `false;
					nextslot <= `true;
					if(opr1 != opr2) begin
						baddr    <=  pcp4 + bofs;
						bflag    <= `true;
					end
				end
				
				`OP_BGTZ: begin
					wreg     <= `false;
					aluop    <= `ALU_BGTZ;
					aluctrl  <= `RES_JB;
					r1read   <= `true;
					r2read   <= `false;
					n_valid  <= `false;
					nextslot <= `true;
					if(opr1[31] == 1'b0 && opr1 != `ZeroWord) begin
						baddr    <=  pcp4 + bofs;
						bflag    <= `true;
					end
				end
				
				`OP_BLEZ: begin
					wreg     <= `false;
					aluop    <= `ALU_BLEZ;
					aluctrl  <= `RES_JB;
					r1read   <= `true;
					r2read   <= `false;
					n_valid  <= `false;
					nextslot <= `true;
					if(opr1[31] == 1'b1 || opr1 == `ZeroWord) begin
						baddr    <=  pcp4 + bofs;
						bflag    <= `true;
					end
				end
				
				`OP_REGIMM: begin
					case (op4)
						`OP_BGEZ: begin
							wreg     <= `false;
							aluop    <= `ALU_BGEZ;
							aluctrl  <= `RES_JB;
							r1read   <= `true;
							r2read   <= `false;
							n_valid  <= `false;
							nextslot <= `true;
							if(opr1[31] == 1'b0) begin
								baddr    <=  pcp4 + bofs;
								bflag    <= `true;
							end
						end
						
						`OP_BGEZAL: begin
							wreg     <= `true;
							aluop    <= `ALU_BGEZAL;
							aluctrl  <= `RES_JB;
							r1read   <= `true;
							r2read   <= `false;
							linkaddr <=  pcp8;
							wraddr   <=  5'd31;
							n_valid  <= `false;
							nextslot <= `true;
							if(opr1[31] == 1'b0) begin
								baddr    <=  pcp4 + bofs;
								bflag    <= `true;
							end
						end
						
						`OP_BLTZ: begin
							wreg     <= `false;
							aluop    <= `ALU_BLTZ;
							aluctrl  <= `RES_JB;
							r1read   <= `true;
							r2read   <= `false;
							n_valid  <= `false;
							nextslot <= `true;
							if(opr1[31] == 1'b1) begin
								baddr    <=  pcp4 + bofs;
								bflag    <= `true;
							end
						end
						
						`OP_BLTZAL: begin
							wreg     <= `true;
							aluop    <= `ALU_BLTZ;
							aluctrl  <= `RES_JB;
							r1read   <= `true;
							r2read   <= `false;
							linkaddr <=  pcp8;
							wraddr   <=  5'd31;
							n_valid  <= `false;
							nextslot <= `true;
							if(opr1[31] == 1'b1) begin
								baddr    <=  pcp4 + bofs;
								bflag    <= `true;
							end
						end
						default: begin
						end
					endcase
				end
				
				`OP_LB: begin
					wreg    <= `true;
					aluop   <= `ALU_LB;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `false;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_LBU: begin
					wreg    <= `true;
					aluop   <= `ALU_LBU;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `false;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_LH: begin
					wreg    <= `true;
					aluop   <= `ALU_LH;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `false;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_LHU: begin
					wreg    <= `true;
					aluop   <= `ALU_LHU;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `false;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_LW: begin
					wreg    <= `true;
					aluop   <= `ALU_LW;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `false;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_LWL: begin
					wreg    <= `true;
					aluop   <= `ALU_LWL;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `true;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_LWR: begin
					wreg    <= `true;
					aluop   <= `ALU_LWR;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `true;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_SB: begin
					wreg    <= `false;
					aluop   <= `ALU_SB;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `true;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_SH: begin
					wreg    <= `false;
					aluop   <= `ALU_SH;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `true;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_SW: begin
					wreg    <= `false;
					aluop   <= `ALU_SW;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `true;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_SWL: begin
					wreg    <= `false;
					aluop   <= `ALU_SW;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `true;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				`OP_SWR: begin
					wreg    <= `false;
					aluop   <= `ALU_SW;
					aluctrl <= `RES_LS;
					r1read  <= `true;
					r2read  <= `true;
					wraddr  <=  rt;
					n_valid <= `false;
				end
				
				default: begin
				end
			endcase
			
			//sll/srl/sra
			if (inst[31:21] == 11'b0) begin
				case (op3)
					`OP_SLL: begin
						wreg     <= `true;
						aluop    <= `ALU_SLL;
						aluctrl  <= `RES_SHIFT;
						r1read   <= `false;
						r2read   <= `true;
						imm[4:0] <=  sa;
						wraddr   <=  rd;
						n_valid  <= `false;
					end
					
					`OP_SRL: begin
						wreg     <= `true;
						aluop    <= `ALU_SRL;
						aluctrl  <= `RES_SHIFT;
						r1read   <= `false;
						r2read   <= `true;
						imm[4:0] <=  sa;
						wraddr   <=  rd;
						n_valid  <= `false;
					end
					
					`OP_SRA: begin
						wreg     <= `true;
						aluop    <= `ALU_SRA;
						aluctrl  <= `RES_SHIFT;
						r1read   <= `false;
						r2read   <= `true;
						imm[4:0] <=  sa;
						wraddr   <=  rd;
						n_valid  <= `false;
					end
				endcase
			end
			
			//mtc0
			if(inst[31:21] == 11'h200 && inst[10:3] == 8'b0) begin
				aluop   <= `ALU_MFC0;
				aluctrl <= `RES_MOVE;
				wraddr  <= rt;
				wreg    <= `true;
				n_valid <= `false;
				r1read  <= `false;
				r2read  <= `false;
			end
			
			//mfc0
			if(inst[31:21] == 11'h204 && inst[10:3] == 8'b0) begin
				aluop   <= `ALU_MTC0;
				aluctrl <= `RES_NOP;
				wreg    <= `false;
				n_valid <= `false;
				r1read  <= `true;
				r1addr  <= rt;
				r2read  <= `false;
			end
			
			//eret
			if(inst == `OP_ERET) begin
				wreg     <= `false;
				aluop    <= `ALU_ERET;
				aluctrl  <= `RES_NOP;
				r1read   <= `false;
				r2read   <= `false;
				n_valid  <= `false;
				exc_eret <= `true;
			end
		end
	end
	
	always @(*) begin
		if(rst) begin
			opr1 <= `ZeroWord;
			opr2 <= `ZeroWord;
		end
		else begin
			if(r1read) begin
				if(ex_wreg && (ex_wraddr == r1addr))
					opr1 <= ex_wrdata;
				else if(mem_wreg && (mem_wraddr == r1addr))
					opr1 <= mem_wrdata;
				else
					opr1 <= r1data;
			end
			else opr1 <= imm;
			
			if(r2read) begin
				if(ex_wreg && (ex_wraddr == r2addr))
					opr2 <= ex_wrdata;
				else if(mem_wreg && (mem_wraddr == r2addr))
					opr2 <= mem_wrdata;
				else
					opr2 <= r2data;
			end
			else opr2 <= imm;
		end
	end
	
	always @(*) begin
		if(rst) o_inslot <= `false;
		else    o_inslot <= i_inslot;
	end
	
	always @(*) begin
		if(rst) begin
			stallreq <= `false;
		end
		else begin
			stallreq <= `false;
			case (ex_aluop)
				`ALU_LB, `ALU_LBU,
				`ALU_LH, `ALU_LHU,
				`ALU_LW, `ALU_LWL,
				`ALU_LWR:
					if(ex_wraddr == r1addr || ex_wraddr == r2addr)
						stallreq <= `true;
			endcase
			
			case (mem_aluop)
				`ALU_LB, `ALU_LBU,
				`ALU_LH, `ALU_LHU,
				`ALU_LW, `ALU_LWL,
				`ALU_LWR:
					if(mem_wraddr == r1addr || mem_wraddr == r2addr)
						stallreq <= `true;
			endcase
		end
	end
	
endmodule