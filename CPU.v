`include "defines.v"

module Processor
(
	input  wire            clk, rst,
	input  wire [`HardInt] intr,
	
	input  wire [`DataBus] iram_rdata,
	output wire            iram_en,
	output wire [`WriteEn] iram_wen,
	output wire [`AddrBus] iram_addr,
	output wire [`DataBus] iram_wdata,
	
	input  wire [`DataBus] dram_rdata,
	output wire            dram_en,
	output wire [`WriteEn] dram_wen,
	output wire [`AddrBus] dram_addr,
	output wire [`DataBus] dram_wdata,
	
	output wire [`AddrBus] debug_wb_pc,
	output wire [`WriteEn] debug_wb_rf_wen,
	output wire [`RegAddr] debug_wb_rf_wnum,
	output wire [`DataBus] debug_wb_rf_wdata
	
);
	
	wire [`AddrBus] if_pc;
	wire [`InstBus] if_inst;
	wire [`AddrBus] if_excp;
	wire [`AddrBus] baddr;
	wire            bflag;
	wire [`AddrBus] new_pc;
	
	wire [`AddrBus] id_pc;
	wire [`DataBus] id_inst;
	wire [`AluOp]   id_aluop;
	wire [`AluCtrl] id_aluctrl;
	wire [`DataBus] id_opr1, id_opr2;
	wire            id_wreg;
	wire [`RegAddr] id_wraddr;
	wire [`AddrBus] id_linkaddr;
	wire            id_i_inslot, id_o_inslot;
	wire            id_nextslot;
	wire [`DataBus] id_i_excp, id_o_excp;
	
	wire            r1read, r2read;
	wire [`DataBus] r1data, r2data;
	wire [`RegAddr] r1addr, r2addr;
	
	wire [`InstBus] ex_inst;
	wire [`AluOp]   ex_aluop;
	wire [`AluCtrl] ex_aluctrl;
	wire [`DataBus] ex_opr1, ex_opr2;
	wire            ex_i_wreg;
	wire [`RegAddr] ex_i_wraddr;
	wire [`AddrBus] ex_linkaddr;
	wire            ex_inslot;
	wire [`DataBus] ex_i_excp, ex_o_excp;
	wire [`AddrBus] ex_pc;
	
	wire [`DblData] div_res;
	wire            div_ready;
	wire [`DataBus] div_opr1, div_opr2;
	wire            div_start, div_signed;
	
	wire            ex_o_wreg;
	wire [`RegAddr] ex_o_wraddr;
	wire [`DataBus] ex_wrdata;
	wire            ex_whilo;
	wire [`DataBus] ex_o_hi, ex_o_lo;
	wire            ex_cp0_we;
	wire [`RegAddr] ex_cp0_waddr;
	wire [`DataBus] ex_cp0_wdata;
	wire [`AddrBus] ex_ramaddr;
	
	wire            mem_wreg;
	wire [`RegAddr] mem_wraddr;
	wire [`DataBus] mem_wrdata;
	wire [`DataBus] mem_ramdata;
	wire            mem_mtor;
	wire            mem_whilo;
	wire [`DataBus] mem_hi, mem_lo;
	wire [`AluOp]   mem_aluop;
	wire [`AddrBus] mem_ramaddr;
	wire [`DataBus] mem_opr2;
	wire            mem_cp0_we;
	wire [`RegAddr] mem_cp0_waddr;
	wire [`DataBus] mem_cp0_wdata;
	wire [`DataBus] mem_excp;
	wire            mem_inslot;
	wire [`AddrBus] mem_pc;
	
	wire [`DataBus] exctype;
	wire [`DataBus] mem_cp0_epc;
	wire [`DataBus] mem_badvaddr;
	
	wire [`AluOp]   wb_aluop;
	wire            wb_wreg;
	wire [`RegAddr] wb_wraddr;
	wire [`DataBus] wb_wrdata;
	wire [`DataBus] wb_ramdata;
	wire [`AddrBus] wb_ramaddr;
	wire [`DataBus] wb_opr2;
	wire            wb_mtor;
	wire            wb_whilo;
	wire [`DataBus] wb_hi, wb_lo;
	wire            wb_cp0_we;
	wire [`RegAddr] wb_cp0_waddr;
	wire [`DataBus] wb_cp0_wdata;
	wire [`AddrBus] wb_pc;
	
	wire [`DataBus] rf_wrdata;
	wire [`DataBus] hi, lo;
	wire [`DataBus] cp0_rdata;
	wire [`RegAddr] cp0_raddr;
	wire [`DataBus] cp0_badvaddr;
	wire [`DataBus] cp0_status;
	wire [`DataBus] cp0_cause;
	wire [`DataBus] cp0_epc;
	
	
	wire       flush;
	wire [4:0] stallreq;
	wire [5:0] stall;

	
	assign iram_addr  = if_pc;
	assign iram_wen   = 4'b0000;
	assign iram_wdata = `ZeroWord;
	
	PC pc (
		.clk     (clk),
		.rst     (rst),
		.stall   (stall[`STALL_PC]),
		.pc      (if_pc),
		.iram_en (iram_en),
		.bflag   (bflag),
		.baddr   (baddr),
		.flush   (flush),
		.excp    (if_excp),
		.new_pc  (new_pc)
	);
	
	assign if_inst = iram_rdata;
	assign stallreq[`SREQ_IF] = `false;
	
	IF_ID if_id (
		.clk      (clk),
		.rst      (rst),
		.flush    (flush),
		.if_stall (stall[`STALL_IF]),
		.id_stall (stall[`STALL_ID]),
		
		.if_pc    (if_pc),
		.if_inst  (if_inst),
		.if_excp  (if_excp),
		
		.id_pc    (id_pc),
		.id_inst  (id_inst),
		.id_excp  (id_i_excp)
	);
	
	ID id (
		.rst        (rst),
		.pc         (id_pc),
		.inst       (id_inst),
		
		.r1data     (r1data),
		.r2data     (r2data),
		.r1read     (r1read),
		.r2read     (r2read),
		.r1addr     (r1addr),
		.r2addr     (r2addr),
		
		.aluop      (id_aluop),
		.aluctrl    (id_aluctrl),
		.opr1       (id_opr1),
		.opr2       (id_opr2),
		.wreg       (id_wreg),
		.wraddr     (id_wraddr),
		
		.ex_aluop   (ex_aluop),
		.ex_wreg    (ex_o_wreg),
		.ex_wraddr  (ex_o_wraddr),
		.ex_wrdata  (ex_wrdata),
		.mem_aluop  (mem_aluop),
		.mem_wreg   (mem_wreg),
		.mem_wraddr (mem_wraddr),
		.mem_wrdata (mem_wrdata),
		
		.i_inslot   (id_i_inslot),
		.o_inslot   (id_o_inslot),
		.nextslot   (id_nextslot),
		.bflag      (bflag),
		.baddr      (baddr),
		.linkaddr   (id_linkaddr),
		
		.i_excp     (id_i_excp),
		.o_excp     (id_o_excp),
		
		.stallreq   (stallreq[`SREQ_ID])
	);
	
	RF regfile (
		.clk    (clk),
		.rst    (rst),
		.we     (wb_wreg),
		.waddr  (wb_wraddr),
		.wdata  (rf_wrdata),
		.re1    (r1read),
		.r1addr (r1addr),
		.r1data (r1data),
		.re2    (r2read),
		.r2addr (r2addr),
		.r2data (r2data)
	);
	
	ID_EX id_ex (
		.clk         (clk),
		.rst         (rst),
		.flush       (flush),
		.id_stall    (stall[`STALL_ID]),
		.ex_stall    (stall[`STALL_EX]),
		.id_inst     (id_inst),
		.id_aluop    (id_aluop),
		.id_aluctrl  (id_aluctrl),
		.id_opr1     (id_opr1),
		.id_opr2     (id_opr2),
		.id_wreg     (id_wreg),
		.id_wraddr   (id_wraddr),
		.id_inslot   (id_o_inslot),
		.id_nextslot (id_nextslot),
		.id_linkaddr (id_linkaddr),
		.id_excp     (id_o_excp),
		.id_pc       (id_pc),
		
		.ex_inst     (ex_inst),
		.ex_aluop    (ex_aluop),
		.ex_aluctrl  (ex_aluctrl),
		.ex_opr1     (ex_opr1),
		.ex_opr2     (ex_opr2),
		.ex_wreg     (ex_i_wreg),
		.ex_wraddr   (ex_i_wraddr),
		.ex_inslot   (ex_inslot),
		.ex_linkaddr (ex_linkaddr),
		.o_inslot    (id_i_inslot),
		.ex_excp     (ex_i_excp),
		.ex_pc       (ex_pc)
	);
	
	EX ex (
		.rst(rst),
		.inst      (ex_inst),
		.aluop     (ex_aluop),
		.aluctrl   (ex_aluctrl),
		.opr1      (ex_opr1),
		.opr2      (ex_opr2),
		.i_wreg    (ex_i_wreg),
		.i_wraddr  (ex_i_wraddr),
		.o_wreg    (ex_o_wreg),
		.o_wraddr  (ex_o_wraddr),
		.wrdata    (ex_wrdata),
		
		.i_hi      (hi),
		.i_lo      (lo),
		.mem_whilo (mem_whilo),
		.mem_hi    (mem_hi),
		.mem_lo    (mem_lo),
		.wb_whilo  (wb_whilo),
		.wb_hi     (wb_hi),
		.wb_lo     (wb_lo),
		.whilo     (ex_whilo),
		.o_hi      (ex_o_hi),
		.o_lo      (ex_o_lo),
		
		.cp0_raddr     (cp0_raddr),
		.cp0_rdata     (cp0_rdata),
		.cp0_we        (ex_cp0_we),
		.cp0_waddr     (ex_cp0_waddr),
		.cp0_wdata     (ex_cp0_wdata),
		.mem_cp0_we    (mem_cp0_we),
		.mem_cp0_waddr (mem_cp0_waddr),
		.mem_cp0_wdata (mem_cp0_wdata),
		.wb_cp0_we     (wb_cp0_we),
		.wb_cp0_waddr  (wb_cp0_waddr),
		.wb_cp0_wdata  (wb_cp0_wdata),
		
		.div_res    (div_res),
		.div_ready  (div_ready),
		.div_opr1   (div_opr1),
		.div_opr2   (div_opr2),
		.div_start  (div_start),
		.div_signed (div_signed),
		
		.linkaddr   (ex_linkaddr),
		.inslot     (ex_inslot),
		.ramaddr    (ex_ramaddr),
		
		.i_excp     (ex_i_excp),
		.o_excp     (ex_o_excp),
		
		.stallreq   (stallreq[`SREQ_EX])
	);
	
	DIV div (
		.clk       (clk),
		.rst       (rst),
		.res       (div_res),
		.ready     (div_ready),
		.opr1      (div_opr1),
		.opr2      (div_opr2),
		.start     (div_start),
		.divsigned (div_signed),
		.abandon   (`false)
	);
	
	EX_MEM ex_mem (
		.clk           (clk),
		.rst           (rst),
		.flush         (flush),
		.ex_stall      (stall[`STALL_EX]),
		.mem_stall     (stall[`STALL_MEM]),
		.ex_wreg       (ex_o_wreg),
		.ex_wraddr     (ex_o_wraddr),
		.ex_wrdata     (ex_wrdata),
		.ex_whilo      (ex_whilo),
		.ex_hi         (ex_o_hi),
		.ex_lo         (ex_o_lo),
		.ex_aluop      (ex_aluop),
		.ex_ramaddr    (ex_ramaddr),
		.ex_opr2       (ex_opr2),
		.ex_cp0_we     (ex_cp0_we),
		.ex_cp0_waddr  (ex_cp0_waddr),
		.ex_cp0_wdata  (ex_cp0_wdata),
		.ex_excp       (ex_o_excp),
		.ex_inslot     (ex_inslot),
		.ex_pc         (ex_pc),

		.mem_wreg      (mem_wreg),
		.mem_wraddr    (mem_wraddr),
		.mem_wrdata    (mem_wrdata),
		.mem_whilo     (mem_whilo),
		.mem_hi        (mem_hi),
		.mem_lo        (mem_lo),
		.mem_aluop     (mem_aluop),
		.mem_ramaddr   (mem_ramaddr),
		.mem_opr2      (mem_opr2),
		.mem_cp0_we    (mem_cp0_we),
		.mem_cp0_waddr (mem_cp0_waddr),
		.mem_cp0_wdata (mem_cp0_wdata),
		.mem_excp      (mem_excp),
		.mem_inslot    (mem_inslot),
		.mem_pc        (mem_pc)
	);
	
	MEM mem (
		.rst        (rst),
		
		.aluop        (mem_aluop),
		.opr2         (mem_opr2),
		.ramaddr      (mem_ramaddr),
		.ramdata      (mem_ramdata),
		.mtor         (mem_mtor),
		
		.dram_rdata   (dram_rdata),
		.dram_addr    (dram_addr),
		.dram_wen     (dram_wen),
		.dram_wdata   (dram_wdata),
		.dram_en      (dram_en),
		
		.i_excp       (mem_excp),
		.nowpc        (mem_pc),
		.cp0_status   (cp0_status),
		.cp0_cause    (cp0_cause),
		.cp0_epc      (cp0_epc),
		
		.wb_cp0_we    (wb_cp0_we),
		.wb_cp0_waddr (wb_cp0_waddr),
		.wb_cp0_wdata (wb_cp0_wdata),
		
		.exctype      (exctype),
		.o_cp0_epc    (mem_cp0_epc),
		.badvaddr     (mem_badvaddr),
		
		.stallreq   (stallreq[`SREQ_MEM])
	);
	
	MEM_WB mem_wb (
		.clk           (clk),
		.rst           (rst),
		.flush         (flush),
		.mem_stall     (stall[`STALL_MEM]),
		.wb_stall      (stall[`STALL_WB]),
		.mem_aluop     (mem_aluop),
		.mem_wreg      (mem_wreg),
		.mem_wraddr    (mem_wraddr),
		.mem_wrdata    (mem_wrdata),
		.mem_ramdata   (mem_ramdata),
		.mem_ramaddr   (dram_addr),
		.mem_opr2      (mem_opr2),
		.mem_mtor      (mem_mtor),
		.mem_whilo     (mem_whilo),
		.mem_hi        (mem_hi),
		.mem_lo        (mem_lo),
		.mem_cp0_we    (mem_cp0_we),
		.mem_cp0_waddr (mem_cp0_waddr),
		.mem_cp0_wdata (mem_cp0_wdata),
		.mem_pc        (mem_pc),
		
		.wb_aluop      (wb_aluop),
		.wb_wreg       (wb_wreg),
		.wb_wraddr     (wb_wraddr),
		.wb_wrdata     (wb_wrdata),
		.wb_ramdata    (wb_ramdata),
		.wb_ramaddr    (wb_ramaddr),
		.wb_opr2       (wb_opr2),
		.wb_mtor       (wb_mtor),
		.wb_whilo      (wb_whilo),
		.wb_hi         (wb_hi),
		.wb_lo         (wb_lo),
		.wb_cp0_we     (wb_cp0_we),
		.wb_cp0_waddr  (wb_cp0_waddr),
		.wb_cp0_wdata  (wb_cp0_wdata),
		.wb_pc         (wb_pc)
	);
	
	WB wb (
		.rst        (rst),
		.mtor       (wb_mtor),
		.aluop      (wb_aluop),
		.opr2       (wb_opr2),
		.wb_ramdata (wb_ramdata),
		.wb_ramaddr (wb_ramaddr),
		.wb_wrdata  (wb_wrdata),
		.rf_wrdata  (rf_wrdata),
		.stallreq   (stallreq[`SREQ_WB])
	);
	
	HILO hilo (
		.clk  (clk),
		.rst  (rst),
		.we   (wb_whilo),
		.i_hi (wb_hi),
		.i_lo (wb_lo),
		.o_hi (hi),
		.o_lo (lo)
	);
	
	CP0 cp0 (
		.clk        (clk),
		.rst        (rst),
		.we         (wb_cp0_we),
		.waddr      (wb_cp0_waddr),
		.wdata      (wb_cp0_wdata),
		.raddr      (cp0_raddr),
		.rdata      (cp0_rdata),
		
		.intr       (intr),
		.exctype    (exctype),
		.i_badvaddr (mem_badvaddr),
		.mem_pc     (mem_pc),
		.inslot     (mem_inslot),
		
		.badvaddr   (cp0_badvaddr),
		.status     (cp0_status),
		.cause      (cp0_cause),
		.epc        (cp0_epc)
	);
	
	Ctrl ctrl (
		.rst      (rst),
		.stallreq (stallreq),
		.stall    (stall),
		
		.exctype  (exctype),
		.cp0_epc  (mem_cp0_epc),
		.flush    (flush),
		.new_pc   (new_pc)
	);
	
	assign debug_wb_pc       = wb_pc;
	assign debug_wb_rf_wen   = {4{wb_wreg}};
	assign debug_wb_rf_wnum  = wb_wraddr;
	assign debug_wb_rf_wdata = rf_wrdata;
	
endmodule
	
	
	
	
	