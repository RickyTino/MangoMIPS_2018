`include "defines.v"

module mycpu_top
(
	input  wire            clk, resetn, 
	input  wire [5:0]      int,
	
	input  wire [`DataBus] inst_sram_rdata,
	output wire            inst_sram_en,
	output wire [`WriteEn] inst_sram_wen,
	output wire [`AddrBus] inst_sram_addr,
	output wire [`DataBus] inst_sram_wdata,
	
	
	input  wire [`DataBus] data_sram_rdata,
	output wire            data_sram_en,
	output wire [`WriteEn] data_sram_wen,
	output wire [`AddrBus] data_sram_addr,
	output wire [`DataBus] data_sram_wdata,
	
	output wire [`AddrBus] debug_wb_pc,
	output wire [`WriteEn] debug_wb_rf_wen,
	output wire [`RegAddr] debug_wb_rf_wnum,
	output wire [`DataBus] debug_wb_rf_wdata
);
	
	//assign int = 6'b0;
	
	//Address Mapping
	wire [`AddrBus] iram_addr, dram_addr;
	reg  [`AddrBus] iram_mapped_addr, dram_mapped_addr;
	
	assign inst_sram_addr = iram_mapped_addr;
	assign data_sram_addr = dram_mapped_addr;
	
	always @(*) begin
		case (iram_addr[31:28])
			4'h8, 
			4'h9, 
			4'hA,
			4'hB:    iram_mapped_addr <= {3'b000, iram_addr[28:0]};
			default: iram_mapped_addr <= iram_addr;
		endcase
		
		case (dram_addr[31:28])
			4'h8, 
			4'h9, 
			4'hA,
			4'hB:    dram_mapped_addr <= {3'b000, dram_addr[28:0]};
			default: dram_mapped_addr <= dram_addr;
		endcase
		
	end
	
	
	Processor CPU (
		.clk         (clk            ),
		.rst         (!resetn        ),
		.intr        (int            ),
		
		.iram_en     (inst_sram_en   ),
		.iram_wen    (inst_sram_wen  ),
		//.iram_addr   (inst_sram_addr ),
		.iram_addr   (iram_addr      ),
		.iram_wdata  (inst_sram_wdata),
		.iram_rdata  (inst_sram_rdata),
		
		.dram_en     (data_sram_en   ),
		.dram_wen    (data_sram_wen  ),
		//.dram_addr   (data_sram_addr ),
		.dram_addr   (dram_addr      ),
		.dram_wdata  (data_sram_wdata),
		.dram_rdata  (data_sram_rdata),

		//debug
		.debug_wb_pc      (debug_wb_pc      ),
		.debug_wb_rf_wen  (debug_wb_rf_wen  ),
		.debug_wb_rf_wnum (debug_wb_rf_wnum ),
		.debug_wb_rf_wdata(debug_wb_rf_wdata)
	);
	
endmodule