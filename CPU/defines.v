/*---------------Bus Width---------------*/
`define AddrBus				31:0
`define DataBus				31:0
`define DblData             63:0
`define InstBus				31:0
`define AluOp				 7:0
`define AluCtrl				 3:0
`define HardInt				 5:0
`define RegAddr				 4:0
`define WriteEn              3:0

/*---------------Zero---------------*/
`define ZeroWord			32'h0
`define ZeroDWord         64'h0
`define ZeroReg				 5'h0
`define WrDisable            4'h0
`define false				 1'b0
`define true				 1'b1

/*---------------Stall---------------*/
`define STALL_IF				0
`define STALL_ID				1
`define STALL_EX				2
`define STALL_MEM				3
`define STALL_WB				4

`define SREQ_IF					0
`define SREQ_ID					1
`define SREQ_EX					2
`define SREQ_MEM				3
`define SREQ_WB					4
/*---------------OpCode---------------*/
//OP0:Specials
`define OP_SPECIAL			6'b000000
`define OP_SPECIAL2			6'b011100
`define OP_REGIMM			6'b000001

//OP0:I-Type
`define OP_ADDI				6'b001000
`define OP_ADDIU			6'b001001
`define OP_SLTI  			6'b001010
`define OP_SLTIU			6'b001011

`define OP_ANDI             6'b001100
`define OP_ORI				6'b001101
`define OP_XORI             6'b001110
`define OP_LUI              6'b001111

//OP0: Load / Store
`define OP_LB				6'b100000
`define OP_LBU				6'b100100
`define OP_LH				6'b100001
`define OP_LHU				6'b100101
`define OP_LW				6'b100011
`define OP_LWL				6'b100010
`define OP_LWR				6'b100110
`define OP_SB				6'b101000
`define OP_SH				6'b101001
`define OP_SW				6'b101011
`define OP_SWL				6'b101010
`define OP_SWR				6'b101110

//OP3:Shift
`define OP_SLL				6'b000000
`define OP_SRL				6'b000010
`define OP_SRA				6'b000011
`define OP_SLLV				6'b000100
`define OP_SRLV				6'b000110
`define OP_SRAV				6'b000111

//OP3:Move
`define OP_MOVZ				6'b001010
`define OP_MOVN				6'b001011
`define OP_MFHI				6'b010000
`define OP_MTHI				6'b010001
`define OP_MFLO				6'b010010
`define OP_MTLO				6'b010011

//OP3:Multiply
`define OP_MULT  			6'b011000
`define OP_MULTU 			6'b011001

//OP3:Divide
`define OP_DIV				6'b011010
`define OP_DIVU				6'b011011

//OP3:R-Type
`define OP_ADD				6'b100000
`define OP_ADDU				6'b100001
`define OP_SUB				6'b100010
`define OP_SUBU				6'b100011

`define OP_AND              6'b100100
`define OP_OR               6'b100101
`define OP_XOR              6'b100110
`define OP_NOR              6'b100111
`define OP_SLT				6'b101010
`define OP_SLTU				6'b101011

//OP3 (Special 2):
`define OP_MADD				6'b000000
`define OP_MADDU            6'b000001
`define OP_MSUB             6'b000100
`define OP_MSUBU            6'b000101

`define OP_CLZ   			6'b100000
`define OP_CLO   			6'b100001
`define OP_MUL   			6'b000010

//Other
`define OP_NOP				6'b000000
`define OP_SYNC				6'b001111
`define OP_PREF				6'b110011

//Branch
`define OP_J				6'b000010
`define OP_JAL				6'b000011
`define OP_JALR				6'b001001
`define OP_JR				6'b001000

`define OP_BEQ				6'b000100
`define OP_BNE				6'b000101
`define OP_BGTZ				6'b000111
`define OP_BLEZ				6'b000110

`define OP_BGEZ				5'b00001
`define OP_BGEZAL			5'b10001
`define OP_BLTZ				5'b00000
`define OP_BLTZAL			5'b10000

`define OP_SYSCALL			6'b001100
`define OP_BREAK			6'b001101
`define OP_ERET				32'h42000018

/*---------------AluOp---------------*/
`define ALU_NOP				8'h00

`define ALU_AND				8'h01
`define ALU_OR				8'h02
`define ALU_XOR				8'h03
`define ALU_NOR				8'h04

`define ALU_SLL				8'h05
`define ALU_SRL				8'h06
`define ALU_SRA				8'h07

`define ALU_MOVZ			8'h08
`define ALU_MOVN			8'h09
`define ALU_MFHI			8'h0A
`define ALU_MTHI			8'h0B
`define ALU_MFLO			8'h0C
`define ALU_MTLO			8'h0D

`define ALU_SLT				8'h0E
`define ALU_SLTU			8'h0F
`define ALU_ADD				8'h10
`define ALU_ADDU			8'h11
`define ALU_SUB				8'h12
`define ALU_SUBU			8'h13
`define ALU_MULT			8'h14
`define ALU_MULTU			8'h15
`define ALU_MUL				8'h16
`define ALU_CLZ				8'h17
`define ALU_CLO				8'h18

`define ALU_MADD			8'h19
`define ALU_MADDU			8'h1A
`define ALU_MSUB			8'h1B
`define ALU_MSUBU			8'h1C

`define ALU_DIV				8'h1D
`define ALU_DIVU			8'h1E

`define ALU_JR				8'h1F
`define ALU_JALR			8'h20
`define ALU_J				8'h21
`define ALU_JAL				8'h22
`define ALU_BEQ				8'h23
`define ALU_BNE				8'h24
`define ALU_BGTZ			8'h25
`define ALU_BLEZ			8'h26
`define ALU_BGEZ			8'h27
`define ALU_BGEZAL			8'h28
`define ALU_BLTZ			8'h29
`define ALU_BLTZAL			8'h2A

`define ALU_LB				8'h2B
`define ALU_LBU				8'h2C
`define ALU_LH				8'h2D
`define ALU_LHU				8'h2E
`define ALU_LW				8'h2F
`define ALU_LWL				8'h30
`define ALU_LWR				8'h31
`define ALU_SB				8'h32
`define ALU_SH				8'h33
`define ALU_SW				8'h34
`define ALU_SWL				8'h35
`define ALU_SWR				8'h36

`define ALU_MFC0			8'h37
`define ALU_MTC0			8'h38
`define ALU_SYSCALL         8'h39
`define ALU_BREAK			8'h3A 
`define ALU_ERET            8'h3B

/*---------------AluCtrl---------------*/
`define RES_NOP				4'h0
`define RES_LOGIC			4'h1
`define RES_SHIFT			4'h2
`define RES_MOVE			4'h3
`define RES_ARITH			4'h4
`define RES_MUL				4'h5
`define RES_DIV             4'h6
`define RES_JB				4'h7
`define RES_LS				4'h8

/*---------------CP0---------------*/
`define CP0_BADVADDR		5'd8
`define CP0_COUNT			5'd9
`define CP0_COMPARE			5'd11
`define CP0_STATUS			5'd12
`define CP0_CAUSE			5'd13
`define CP0_EPC				5'd14
`define CP0_PRID			5'd15
`define CP0_CONFIG			5'd16

/*---------------Exceptions---------------*/
`define EXC_SINT0			0
`define EXC_SINT1			1
`define EXC_HINT0			2
`define EXC_HINT1			3
`define EXC_HINT2			4
`define EXC_HINT3			5
`define EXC_HINT4			6
`define EXC_HINT5           7
`define EXC_IADEL			8
`define EXC_SYS				9
`define EXC_BP				10
`define EXC_RI       		11
`define EXC_OV				12
`define EXC_DADEL			13
`define EXC_DADES			14
`define EXC_ERET			15

`define EXCT_INT			32'h1
`define EXCT_SYS			32'h2
`define EXCT_BP				32'h3
`define EXCT_RI				32'h4
`define EXCT_OV				32'h5
`define EXCT_ADEL			32'h6
`define EXCT_ADES			32'h7
`define EXCT_ERET			32'h8

`define ECOD_INT			5'h00;
`define ECOD_ADEL			5'h04;
`define ECOD_ADES			5'h05;
`define ECOD_SYS			5'h08;
`define ECOD_BP				5'h09;
`define ECOD_RI				5'h0A;
`define ECOD_OV				5'h0C;

/*---------------ENTRANCE---------------*/
`define ENT_START			32'hBFC00000
`define ENT_EXCP			32'hBFC00380
