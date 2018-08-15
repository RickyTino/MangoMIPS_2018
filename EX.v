`include "defines.v"

module EX
(
	input wire             rst,
	
	input  wire [`InstBus] inst,
	input  wire [`AluOp]   aluop,
	input  wire [`AluCtrl] aluctrl,
	input  wire [`DataBus] opr1, opr2,
	
	input  wire            i_wreg,
	input  wire [`RegAddr] i_wraddr,
	output reg             o_wreg,
	output reg  [`RegAddr] o_wraddr,
	output reg  [`DataBus] wrdata,
	
	input  wire [`DataBus] i_hi, i_lo,
	input  wire            mem_whilo,
	input  wire [`DataBus] mem_hi, mem_lo,
	input  wire            wb_whilo,
	input  wire [`DataBus] wb_hi, wb_lo,
	output reg             whilo,
	output reg  [`DataBus] o_hi, o_lo,
	
	input  wire [`DataBus] cp0_rdata,
	output reg  [`RegAddr] cp0_raddr,
	output reg             cp0_we,
	output reg  [`RegAddr] cp0_waddr,
	output reg  [`DataBus] cp0_wdata,
	input  wire            mem_cp0_we,
	input  wire [`RegAddr] mem_cp0_waddr,
	input  wire [`DataBus] mem_cp0_wdata,
	input  wire            wb_cp0_we,
	input  wire [`RegAddr] wb_cp0_waddr,
	input  wire [`DataBus] wb_cp0_wdata,
	
	input  wire [`DblData] div_res,
	input  wire            div_ready,
	output reg  [`DataBus] div_opr1, div_opr2,
	output reg             div_start, div_signed,
	
	input  wire [`AddrBus] linkaddr,
	input  wire            inslot,
	
	output wire [`AddrBus] ramaddr,
	
	input  wire [`DataBus] i_excp,
	output reg  [`DataBus] o_excp,
	
	output reg             stallreq
);
	
	reg [`DataBus] logicRes, shiftRes, moveRes, arithRes;
	reg [`DataBus] hi, lo;
	reg            overflow;
	
	wire [31:0] ofsimm = {{16{inst[15]}}, inst[15:0]};
	wire [ 4:0] rd     = inst[15:11];
	
	wire mem_cp0_clash = mem_cp0_we && (mem_cp0_waddr == rd);
	wire  wb_cp0_clash =  wb_cp0_we && ( wb_cp0_waddr == rd);
	
	assign ramaddr = opr1 + ofsimm;
	
	always @(*) begin
		o_excp          <= i_excp;
		o_excp[`EXC_OV] <= overflow;
	end
	
	wire sign1 = opr1[31];
	wire sign2 = opr2[31];
	wire rsign = arithRes[31];
	
	//multiplier
	reg  [`DataBus] mulopr1, mulopr2;
	wire [`DblData] multemp = mulopr1 * mulopr2;
	reg  [`DblData] mulRes;
	
	always @(*) begin
		case (aluop)
			`ALU_MULTU,
			`ALU_MADDU,
			`ALU_MSUBU: begin
				mulopr1 <= opr1;
				mulopr2 <= opr2;
				mulRes  <= multemp;
			end
			
			`ALU_MUL,
			`ALU_MULT,
			`ALU_MADD,
			`ALU_MSUB: begin
				mulopr1 <= sign1 ? ~opr1 + 1 : opr1;
				mulopr2 <= sign2 ? ~opr2 + 1 : opr2;
				mulRes <= (sign1 ^ sign2) ? ~multemp + 1 : multemp;
			end
			default: begin
				mulopr1 <= `ZeroWord;
				mulopr2 <= `ZeroWord;
				mulRes  <= `ZeroDblWord;
		    end
		endcase
	end
	
	//Multiply-Accumulate
	reg [`DblData] macRes;
	
	always @(*) begin
		if(rst) begin
			macRes <= `ZeroDblWord;
		end
		else begin
			case (aluop)
				`ALU_MADD,
				`ALU_MADDU: macRes <= {hi, lo} + mulRes;
				`ALU_MSUB,
				`ALU_MSUBU: macRes <= {hi, lo} - mulRes;
				default:    macRes <= `ZeroDblWord;
			endcase
		end
	end
	
	//Divider
	reg div_sreq;
	
	always @(*) begin
		if(rst) begin
			div_sreq   <= `false;
			div_opr1   <= `ZeroWord;
			div_opr2   <= `ZeroWord;
			div_start  <= `false;
			div_signed <= `false;
		end
		else begin
			case (aluop)   //case ({aluop, div_ready})
				`ALU_DIV: begin   // {`ALU_DIV, `true}: begin
					div_opr1   <= opr1;
					div_opr2   <= opr2;
					div_signed <= `true;
					div_start  <= !div_ready;
					div_sreq   <= !div_ready;
				end
				
				`ALU_DIVU: begin
					div_opr1   <= opr1;
					div_opr2   <= opr2;
					div_signed <= `false;
					div_start  <= !div_ready;
					div_sreq   <= !div_ready;
				end
				
				default: begin
					div_sreq   <= `false;
					div_opr1   <= `ZeroWord;
					div_opr2   <= `ZeroWord;
					div_start  <= `false;
					div_signed <= `false;
				end
			endcase
		end
	end
	
	//Stall Requirement
	always @(*) begin
		stallreq  = div_sreq;
	end			
	
	//CLO & CLZ
	wire [`DataBus] clzres, clores;
	assign clzres = opr1[31] ?  0 : opr1[30] ?  1 :
                    opr1[29] ?  2 : opr1[28] ?  3 :
                    opr1[27] ?  4 : opr1[26] ?  5 :
                    opr1[25] ?  6 : opr1[24] ?  7 :
                    opr1[23] ?  8 : opr1[22] ?  9 :
                    opr1[21] ? 10 : opr1[20] ? 11 :
                    opr1[19] ? 12 : opr1[18] ? 13 :
                    opr1[17] ? 14 : opr1[16] ? 15 :
                    opr1[15] ? 16 : opr1[14] ? 17 :
                    opr1[13] ? 18 : opr1[12] ? 19 :
                    opr1[11] ? 20 : opr1[10] ? 21 :
                    opr1[ 9] ? 22 : opr1[ 8] ? 23 :
                    opr1[ 7] ? 24 : opr1[ 6] ? 25 :
                    opr1[ 5] ? 26 : opr1[ 4] ? 27 :
                    opr1[ 3] ? 28 : opr1[ 2] ? 29 :
                    opr1[ 1] ? 30 : opr1[ 0] ? 31 : 32 ;
					
	assign clores = ~opr1[31] ?  0 : ~opr1[30] ?  1 :
                    ~opr1[29] ?  2 : ~opr1[28] ?  3 :
                    ~opr1[27] ?  4 : ~opr1[26] ?  5 :
                    ~opr1[25] ?  6 : ~opr1[24] ?  7 :
                    ~opr1[23] ?  8 : ~opr1[22] ?  9 :
                    ~opr1[21] ? 10 : ~opr1[20] ? 11 :
                    ~opr1[19] ? 12 : ~opr1[18] ? 13 :
                    ~opr1[17] ? 14 : ~opr1[16] ? 15 :
                    ~opr1[15] ? 16 : ~opr1[14] ? 17 :
                    ~opr1[13] ? 18 : ~opr1[12] ? 19 :
                    ~opr1[11] ? 20 : ~opr1[10] ? 21 :
                    ~opr1[ 9] ? 22 : ~opr1[ 8] ? 23 :
                    ~opr1[ 7] ? 24 : ~opr1[ 6] ? 25 :
                    ~opr1[ 5] ? 26 : ~opr1[ 4] ? 27 :
                    ~opr1[ 3] ? 28 : ~opr1[ 2] ? 29 :
                    ~opr1[ 1] ? 30 : ~opr1[ 0] ? 31 : 32 ;
	
	//Results
	always @(*) begin
		if(rst) begin
			logicRes <= `ZeroWord;
			shiftRes <= `ZeroWord;
			moveRes  <= `ZeroWord;
			arithRes <= `ZeroWord;
			overflow <= `false;
			cp0_raddr <= `ZeroReg;
		end
		else begin
			//Logic Result
			case (aluop)
				`ALU_OR:  logicRes <= opr1 | opr2;
				`ALU_AND: logicRes <= opr1 & opr2;
				`ALU_NOR: logicRes <= ~(opr1 | opr2);
				`ALU_XOR: logicRes <= opr1 ^ opr2;
				default:  logicRes <= `ZeroWord;
			endcase
			
		    //Shift Result
			case (aluop)
				`ALU_SLL: shiftRes <= opr2 << opr1[4:0];
				`ALU_SRL: shiftRes <= opr2 >> opr1[4:0];
				`ALU_SRA: shiftRes <= ($signed(opr2)) >>> opr1[4:0];
				          //shiftres <= ({32{reg2_i[31]}}<<(6'd32-{1'b0,reg1_i[4:0]}))
                          //| reg2_i >> reg1_i[4:0];
				default:  shiftRes <= `ZeroWord;
			endcase
			
			//Move Result
			cp0_raddr <= `ZeroReg;
			case (aluop)
				`ALU_MFHI: moveRes <= hi;
				`ALU_MFLO: moveRes <= lo;
				`ALU_MOVZ: moveRes <= opr1;
				`ALU_MOVN: moveRes <= opr1;
				`ALU_MFC0: begin
					cp0_raddr <= inst[15:11];
					case ({mem_cp0_clash, wb_cp0_clash})
						2'b00: moveRes <=     cp0_rdata;
						2'b01: moveRes <=  wb_cp0_wdata;
						2'b10,
						2'b11: moveRes <= mem_cp0_wdata;
					endcase
				end
				default:   moveRes <= `ZeroWord;
			endcase
			
			//Arithmetic Result
			case (aluop)
				`ALU_SLT:  arithRes <= $signed(opr1) < $signed(opr2);
				`ALU_SLTU: arithRes <= opr1 < opr2;
				`ALU_ADD,//:  arithRes <= opr1 + opr2;
				`ALU_ADDU: arithRes <= opr1 + opr2;
				`ALU_SUB,//:  arithRes <= opr1 - opr2;
				`ALU_SUBU: arithRes <= opr1 - opr2;
				`ALU_CLZ:  arithRes <= clzres;
				`ALU_CLO:  arithRes <= clores;
				default:   arithRes <= `ZeroWord;
			endcase
			
			//Overflow
			case (aluop)
				`ALU_ADD: overflow <= ( sign1 &&  sign2 && !rsign) || 
				                      (!sign1 && !sign2 &&  rsign);
				`ALU_SUB: overflow <= ( sign1 && !sign2 && !rsign) || 
				                      (!sign1 &&  sign2 &&  rsign);
				default:  overflow <= `false;
			endcase
		end
	end
	
	//Select results
	always @(*) begin
		o_wraddr <= i_wraddr;
		
		if(overflow) o_wreg <= `false;
		else         o_wreg <= i_wreg;
		
		case (aluctrl)
			`RES_LOGIC: wrdata <= logicRes;
			`RES_SHIFT: wrdata <= shiftRes;
			`RES_MOVE:  wrdata <= moveRes;
			`RES_ARITH: wrdata <= arithRes;
			`RES_MUL:   wrdata <= mulRes[31:0];
			`RES_JB:    wrdata <= linkaddr;
			default:    wrdata <= `ZeroWord;
		endcase
	end
	
	//input hi/lo
	always @(*) begin
		if(rst) begin
			{hi, lo} <= `ZeroDblWord;
		end
		else begin
			case ({mem_whilo, wb_whilo})
				2'b00: {hi, lo} <= {  i_hi,   i_lo};
				2'b01: {hi, lo} <= { wb_hi,  wb_lo};
				2'b10, 
				2'b11: {hi, lo} <= {mem_hi, mem_lo};
			endcase
		end
	end
	
	//output hi/lo
	always @(*) begin
		if(rst) begin
			whilo <= `false;
			o_hi  <= `ZeroWord;
			o_lo  <= `ZeroWord;
		end
		else begin
			case (aluop)
				`ALU_MULT,
				`ALU_MULTU: begin
					whilo <= `true;
					o_hi  <= mulRes[63:32];
					o_lo  <= mulRes[31: 0];
				end
				
				`ALU_MADD,
				`ALU_MADDU,
				`ALU_MSUB,
				`ALU_MSUBU: begin
					whilo <= `true;
					o_hi  <= macRes[63:32];
					o_lo  <= macRes[31: 0];
				end
				
				`ALU_MTHI: begin
					whilo <= `true;
					o_hi  <= opr1;
					o_lo  <= lo;
				end
				
				`ALU_MTLO: begin
					whilo <= `true;
					o_hi  <= hi;
					o_lo  <= opr1;
				end
				
				`ALU_DIV,
				`ALU_DIVU: begin
					whilo <= `true;
					o_hi  <= div_res[63:32];
					o_lo  <= div_res[31: 0];
				end
				
				default: begin
					whilo <= `false;
					o_hi  <= `ZeroWord;
					o_lo  <= `ZeroWord;
				end
			endcase
		end
	end
	
	//output CP0
	always @(*) begin
		if(rst) begin
			cp0_waddr <= `ZeroReg;
			cp0_we    <= `false;
			cp0_wdata <= `ZeroWord;
		end
		else begin
			if(aluop == `ALU_MTC0) begin
				cp0_waddr <= rd;
				cp0_we    <= `true;
				cp0_wdata <= opr1;
			end
			else begin
				cp0_waddr <= `ZeroReg;
				cp0_we    <= `false;
				cp0_wdata <= `ZeroWord;
			end
		end
	end
endmodule
