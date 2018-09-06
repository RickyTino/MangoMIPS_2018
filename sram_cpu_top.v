module mycpu_top
(
	input  wire        clk, resetn, 
	input  wire [ 5:0] int,
	
	input  wire [31:0] inst_sram_rdata,
	output wire        inst_sram_en,
	output wire [ 3:0] inst_sram_wen,
	output wire [31:0] inst_sram_addr,
	output wire [31:0] inst_sram_wdata,
	
	input  wire [31:0] data_sram_rdata,
	output wire        data_sram_en,
	output wire [ 3:0] data_sram_wen,
	output wire [31:0] data_sram_addr,
	output wire [31:0] data_sram_wdata,
	
	output wire [31:0] debug_wb_pc,
	output wire [ 3:0] debug_wb_rf_wen,
	output wire [ 4:0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata
);
	
	wire iram_en,    dram_en;
	wire iram_stall, dram_stall;
	
	assign inst_sram_en = iram_en && !iram_stall;
	assign data_sram_en = dram_en && !dram_stall;
	
	MangoMIPS CPU (
		.clk         (clk            ),
		.rst         (!resetn        ),
		.intr        (int            ),
		
		.iram_en     (iram_en        ),
		.iram_wen    (inst_sram_wen  ),
		.iram_addr   (inst_sram_addr ),
		.iram_wdata  (inst_sram_wdata),
		.iram_rdata  (inst_sram_rdata),
		.iram_sreq   (1'b0           ),
		.iram_stall  (iram_stall     ),
		
		.dram_en     (dram_en        ),
		.dram_wen    (data_sram_wen  ),
		.dram_addr   (data_sram_addr ),
		.dram_wdata  (data_sram_wdata),
		.dram_rdata  (data_sram_rdata),
		.dram_sreq   (1'b0           ),
		.dram_stall  (dram_stall     ),
		
		//debug
		.debug_wb_pc      (debug_wb_pc      ),
		.debug_wb_rf_wen  (debug_wb_rf_wen  ),
		.debug_wb_rf_wnum (debug_wb_rf_wnum ),
		.debug_wb_rf_wdata(debug_wb_rf_wdata)
	);
	
endmodule