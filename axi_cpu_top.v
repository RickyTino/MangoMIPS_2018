module mycpu_top
(
	input  wire [ 5:0] int,
	
	input  wire        aclk,
	input  wire        aresetn,
	output wire [ 3:0] arid,
	output wire [31:0] araddr,
	output wire [ 3:0] arlen,
	output wire [ 2:0] arsize,
	output wire [ 1:0] arburst,
	output wire [ 1:0] arlock,
	output wire [ 3:0] arcache,
	output wire [ 2:0] arprot,
	output wire        arvalid,
	input  wire        arready,
	input  wire [ 3:0] rid,
	input  wire [31:0] rdata,
	input  wire [ 1:0] rresp,
	input  wire        rlast,
	input  wire        rvalid,
	output wire        rready,
	output wire [ 3:0] awid,
	output wire [31:0] awaddr,
	output wire [ 3:0] awlen,
	output wire [ 2:0] awsize,
	output wire [ 1:0] awburst,
	output wire [ 1:0] awlock,
	output wire [ 3:0] awcache,
	output wire [ 2:0] awprot,
	output wire        awvalid,
	input  wire        awready,
	output wire [ 3:0] wid,
	output wire [31:0] wdata,
	output wire [ 3:0] wstrb,
	output wire        wlast,
	output wire        wvalid,
	input  wire        wready,
	input  wire [ 3:0] bid,
	input  wire [ 1:0] bresp,
	input  wire        bvalid,
	output wire        bready,
	
	output wire [31:0] debug_wb_pc,
	output wire [ 3:0] debug_wb_rf_wen,
	output wire [ 4:0] debug_wb_rf_wnum,
	output wire [31:0] debug_wb_rf_wdata
);

	wire        flush;
	
	wire        iram_en;
	wire [31:0] iram_addr;
	wire [31:0] iram_rdata;
	wire        iram_sreq;
	wire        iram_stall;
	
	wire        dram_en;
	wire [ 3:0] dram_wen;
	wire [31:0] dram_addr;
	wire [31:0] dram_wdata;
	wire [31:0] dram_rdata;
	wire        dram_sreq;
	wire        dram_stall;
	
	MangoMIPS CPU (
		.clk         (aclk      ),
		.rst         (!aresetn  ),
		.intr        (int       ),
		.flush       (flush     ),
		
		.iram_en     (iram_en   ),
		.iram_addr   (iram_addr ),
		.iram_rdata  (iram_rdata),
		.iram_sreq   (iram_sreq ),
		.iram_stall  (iram_stall),
		
		.dram_en     (dram_en   ),
		.dram_wen    (dram_wen  ),
		.dram_addr   (dram_addr ),
		.dram_wdata  (dram_wdata),
		.dram_rdata  (dram_rdata),
		.dram_sreq   (dram_sreq ),
		.dram_stall  (dram_stall),
		
		.debug_wb_pc      (debug_wb_pc      ),
		.debug_wb_rf_wen  (debug_wb_rf_wen  ),
		.debug_wb_rf_wnum (debug_wb_rf_wnum ),
		.debug_wb_rf_wdata(debug_wb_rf_wdata)
	);
	
	wire [ 3:0] ibus_arid;
	wire [31:0] ibus_araddr;
	wire [ 3:0] ibus_arlen;
	wire [ 2:0] ibus_arsize;
	wire [ 1:0] ibus_arburst;
	wire [ 1:0] ibus_arlock;
	wire [ 3:0] ibus_arcache;
	wire [ 2:0] ibus_arprot;
	wire        ibus_arvalid;
	wire        ibus_arready;
	wire [ 3:0] ibus_rid;
	wire [31:0] ibus_rdata;
	wire [ 1:0] ibus_rresp;
	wire        ibus_rlast;
	wire        ibus_rvalid;
	wire        ibus_rready;
	wire [ 3:0] ibus_awid;
	wire [31:0] ibus_awaddr;
	wire [ 3:0] ibus_awlen;
	wire [ 2:0] ibus_awsize;
	wire [ 1:0] ibus_awburst;
	wire [ 1:0] ibus_awlock;
	wire [ 3:0] ibus_awcache;
	wire [ 2:0] ibus_awprot;
	wire        ibus_awvalid;
	wire        ibus_awready;
	wire [ 3:0] ibus_wid;
	wire [31:0] ibus_wdata;
	wire [ 3:0] ibus_wstrb;
	wire        ibus_wlast;
	wire        ibus_wvalid;
	wire        ibus_wready;
	wire [ 3:0] ibus_bid;
	wire [ 1:0] ibus_bresp;
	wire        ibus_bvalid;
	wire        ibus_bready;
	
	wire [ 3:0] dbus_arid;
	wire [31:0] dbus_araddr;
	wire [ 3:0] dbus_arlen;
	wire [ 2:0] dbus_arsize;
	wire [ 1:0] dbus_arburst;
	wire [ 1:0] dbus_arlock;
	wire [ 3:0] dbus_arcache;
	wire [ 2:0] dbus_arprot;
	wire        dbus_arvalid;
	wire        dbus_arready;
	wire [ 3:0] dbus_rid;
	wire [31:0] dbus_rdata;
	wire [ 1:0] dbus_rresp;
	wire        dbus_rlast;
	wire        dbus_rvalid;
	wire        dbus_rready;
	wire [ 3:0] dbus_awid;
	wire [31:0] dbus_awaddr;
	wire [ 3:0] dbus_awlen;
	wire [ 2:0] dbus_awsize;
	wire [ 1:0] dbus_awburst;
	wire [ 1:0] dbus_awlock;
	wire [ 3:0] dbus_awcache;
	wire [ 2:0] dbus_awprot;
	wire        dbus_awvalid;
	wire        dbus_awready;
	wire [ 3:0] dbus_wid;
	wire [31:0] dbus_wdata;
	wire [ 3:0] dbus_wstrb;
	wire        dbus_wlast;
	wire        dbus_wvalid;
	wire        dbus_wready;
	wire [ 3:0] dbus_bid;
	wire [ 1:0] dbus_bresp;
	wire        dbus_bvalid;
	wire        dbus_bready;
	
	ICache Inst_Cache (
		.clk            (aclk           ),
		.rst            (!aresetn       ),
		.flush          (flush          ),
		.axim_arid      (ibus_arid      ),
		.axim_araddr    (ibus_araddr    ),
		.axim_arlen     (ibus_arlen     ),
		.axim_arsize    (ibus_arsize    ),
		.axim_arburst   (ibus_arburst   ),
		.axim_arlock    (ibus_arlock    ),
		.axim_arcache   (ibus_arcache   ),
		.axim_arprot    (ibus_arprot    ),
		.axim_arvalid   (ibus_arvalid   ),
		.axim_arready   (ibus_arready   ),		
		.axim_rid       (ibus_rid       ),
		.axim_rdata     (ibus_rdata     ),
		.axim_rresp     (ibus_rresp     ),
		.axim_rlast     (ibus_rlast     ),
		.axim_rvalid    (ibus_rvalid    ),
		.axim_rready    (ibus_rready    ),
		.axim_awid      (ibus_awid      ),
		.axim_awaddr    (ibus_awaddr    ),
		.axim_awlen     (ibus_awlen     ),
		.axim_awsize    (ibus_awsize    ),
		.axim_awburst   (ibus_awburst   ),
		.axim_awlock    (ibus_awlock    ),
		.axim_awcache   (ibus_awcache   ),
		.axim_awprot    (ibus_awprot    ),
		.axim_awvalid   (ibus_awvalid   ),
		.axim_awready   (ibus_awready   ),
		.axim_wid       (ibus_wid       ),
		.axim_wdata     (ibus_wdata     ),
		.axim_wstrb     (ibus_wstrb     ),
		.axim_wlast     (ibus_wlast     ),
		.axim_wvalid    (ibus_wvalid    ),
		.axim_wready    (ibus_wready    ),
		.axim_bid       (ibus_bid       ),
		.axim_bresp     (ibus_bresp     ),
		.axim_bvalid    (ibus_bvalid    ),
		.axim_bready    (ibus_bready    ),
		
		.iram_en        (iram_en        ),
		.iram_addr      (iram_addr      ),
		.iram_rdata     (iram_rdata     ),
		.iram_sreq      (iram_sreq      ),
		.iram_stall     (iram_stall     ),
		.iram_hitiv     (1'b0           ),
		.iram_ivaddr    (32'b0          )
	);
	
	axi_crossbar_cpu cpu_axi_1x2 (
		.aclk             ( aclk        ),                 
		.aresetn          ( aresetn     ),
		
		.s_axi_arid       ( {ibus_arid   ,dbus_arid   } ),
		.s_axi_araddr     ( {ibus_araddr ,dbus_araddr } ),
		.s_axi_arlen      ( {ibus_arlen  ,dbus_arlen  } ),
		.s_axi_arsize     ( {ibus_arsize ,dbus_arsize } ),
		.s_axi_arburst    ( {ibus_arburst,dbus_arburst} ),
		.s_axi_arlock     ( {ibus_arlock ,dbus_arlock } ),
		.s_axi_arcache    ( {ibus_arcache,dbus_arcache} ),
		.s_axi_arprot     ( {ibus_arprot ,dbus_arprot } ),
		.s_axi_arqos      ( 8'b0                        ),
		.s_axi_arvalid    ( {ibus_arvalid,dbus_arvalid} ),
		.s_axi_arready    ( {ibus_arready,dbus_arready} ),
		.s_axi_rid        ( {ibus_rid    ,dbus_rid    } ),
		.s_axi_rdata      ( {ibus_rdata  ,dbus_rdata  } ),
		.s_axi_rresp      ( {ibus_rresp  ,dbus_rresp  } ),
		.s_axi_rlast      ( {ibus_rlast  ,dbus_rlast  } ),
		.s_axi_rvalid     ( {ibus_rvalid ,dbus_rvalid } ),
		.s_axi_rready     ( {ibus_rready ,dbus_rready } ),
		.s_axi_awid       ( {ibus_awid   ,dbus_awid   } ),
		.s_axi_awaddr     ( {ibus_awaddr ,dbus_awaddr } ),
		.s_axi_awlen      ( {ibus_awlen  ,dbus_awlen  } ),
		.s_axi_awsize     ( {ibus_awsize ,dbus_awsize } ),
		.s_axi_awburst    ( {ibus_awburst,dbus_awburst} ),
		.s_axi_awlock     ( {ibus_awlock ,dbus_awlock } ),
		.s_axi_awcache    ( {ibus_awcache,dbus_awcache} ),
		.s_axi_awprot     ( {ibus_awprot ,dbus_awprot } ),
		.s_axi_awqos      ( 8'b0                        ),
		.s_axi_awvalid    ( {ibus_awvalid,dbus_awvalid} ),
		.s_axi_awready    ( {ibus_awready,dbus_awready} ),
		.s_axi_wid        ( {ibus_wid    ,dbus_wid    } ),
		.s_axi_wdata      ( {ibus_wdata  ,dbus_wdata  } ),
		.s_axi_wstrb      ( {ibus_wstrb  ,dbus_wstrb  } ),
		.s_axi_wlast      ( {ibus_wlast  ,dbus_wlast  } ),
		.s_axi_wvalid     ( {ibus_wvalid ,dbus_wvalid } ),
		.s_axi_wready     ( {ibus_wready ,dbus_wready } ),
		.s_axi_bid        ( {ibus_bid    ,dbus_bid    } ),
		.s_axi_bresp      ( {ibus_bresp  ,dbus_bresp  } ),
		.s_axi_bvalid     ( {ibus_bvalid ,dbus_bvalid } ),
		.s_axi_bready     ( {ibus_bready ,dbus_bready } ),
		
		.m_axi_arid       ( arid        ),
		.m_axi_araddr     ( araddr      ),
		.m_axi_arlen      ( arlen[3:0]  ),
		.m_axi_arsize     ( arsize      ),
		.m_axi_arburst    ( arburst     ),
		.m_axi_arlock     ( arlock      ),
		.m_axi_arcache    ( arcache     ),
		.m_axi_arprot     ( arprot      ),
		.m_axi_arqos      (             ),
		.m_axi_arvalid    ( arvalid     ),
		.m_axi_arready    ( arready     ),
		.m_axi_rid        ( rid         ),
		.m_axi_rdata      ( rdata       ),
		.m_axi_rresp      ( rresp       ),
		.m_axi_rlast      ( rlast       ),
		.m_axi_rvalid     ( rvalid      ),
		.m_axi_rready     ( rready      ),
		.m_axi_awid       ( awid        ),
		.m_axi_awaddr     ( awaddr      ),
		.m_axi_awlen      ( awlen[3:0]  ),
		.m_axi_awsize     ( awsize      ),
		.m_axi_awburst    ( awburst     ),
		.m_axi_awlock     ( awlock      ),
		.m_axi_awcache    ( awcache     ),
		.m_axi_awprot     ( awprot      ),
		.m_axi_awqos      (             ),
		.m_axi_awvalid    ( awvalid     ),
		.m_axi_awready    ( awready     ),
		.m_axi_wid        ( wid         ),
		.m_axi_wdata      ( wdata       ),
		.m_axi_wstrb      ( wstrb       ),
		.m_axi_wlast      ( wlast       ),
		.m_axi_wvalid     ( wvalid      ),
		.m_axi_wready     ( wready      ),
		.m_axi_bid        ( bid         ),
		.m_axi_bresp      ( bresp       ),
		.m_axi_bvalid     ( bvalid      ),
		.m_axi_bready     ( bready      )
	);
	
	
	//------------------test---------------------
	
	wire        axir_ireq;
	wire [31:0] axir_iaddr;
	wire [ 3:0] axir_ilen;
	wire        axir_dreq;
	wire [31:0] axir_daddr;
	wire        axir_rid;
	wire        axir_rdy;
	wire [31:0] axir_data;
	wire        axir_last;
	
	wire        axiw_req;
	wire [31:0] axiw_addr;
	wire [31:0] axiw_data;
	wire [31:0] axiw_sel;
	wire        axiw_rdy;
	
	SRAM_Interface sram_intf (
		.clk         (aclk      ),
		.rst         (!aresetn || flush),
		.flush       (1'b0),
		
//		.iram_en     (iram_en   ),
//		.iram_wen    (iram_wen  ),
//		.iram_addr   (iram_maddr),
//		.iram_wdata  (iram_wdata),
//		.iram_rdata  (iram_rdata),
//		.iram_sreq   (iram_sreq ),
//		.iram_stall  (iram_stall),
		.iram_en     (1'b0      ),
		.iram_wen    (4'b0      ),
		.iram_addr   (32'b0     ),
		.iram_wdata  (32'b0     ),
		.iram_rdata  (          ),
		.iram_wait   (          ),
		.iram_stall  (1'b0      ),
		
		.dram_en     (dram_en   ),
		.dram_wen    (dram_wen  ),
		.dram_addr   (dram_addr ),
		.dram_wdata  (dram_wdata),
		.dram_rdata  (dram_rdata),
		.dram_wait   (dram_sreq ),
		.dram_stall  (dram_stall),
		
		
		.axir_ireq  (axir_ireq ),
		.axir_iaddr (axir_iaddr),
		.axir_ilen  (axir_ilen ),
		.axir_dreq  (axir_dreq ),
		.axir_daddr (axir_daddr),
		.axir_rid   (axir_rid  ),
		.axir_rdy   (axir_rdy  ),
		.axir_last  (axir_last ),
		.axir_data  (axir_data ),
	
		.axiw_req  (axiw_req  ),
		.axiw_addr (axiw_addr ),
		.axiw_data (axiw_data ),
		.axiw_sel  (axiw_sel  ),
		.axiw_rdy  (axiw_rdy  )
	);
	
	AXI_Interface axi_intf (
		.aclk      (aclk      ),
		.aresetn   (aresetn && !flush),

		.arid      (dbus_arid      ),
		.araddr    (dbus_araddr    ),
		.arlen     (dbus_arlen     ),
		.arsize    (dbus_arsize    ),
		.arburst   (dbus_arburst   ),
		.arlock    (dbus_arlock    ),
		.arcache   (dbus_arcache   ),
		.arprot    (dbus_arprot    ),
		.arvalid   (dbus_arvalid   ),
		.arready   (dbus_arready   ),
					
		.rid       (dbus_rid       ),
		.rdata     (dbus_rdata     ),
		.rresp     (dbus_rresp     ),
		.rlast     (dbus_rlast     ),
		.rvalid    (dbus_rvalid    ),
		.rready    (dbus_rready    ),
				   
		.awid      (dbus_awid      ),
		.awaddr    (dbus_awaddr    ),
		.awlen     (dbus_awlen     ),
		.awsize    (dbus_awsize    ),
		.awburst   (dbus_awburst   ),
		.awlock    (dbus_awlock    ),
		.awcache   (dbus_awcache   ),
		.awprot    (dbus_awprot    ),
		.awvalid   (dbus_awvalid   ),
		.awready   (dbus_awready   ),
		
		.wid       (dbus_wid       ),
		.wdata     (dbus_wdata     ),
		.wstrb     (dbus_wstrb     ),
		.wlast     (dbus_wlast     ),
		.wvalid    (dbus_wvalid    ),
		.wready    (dbus_wready    ),
		
		.bid       (dbus_bid       ),
		.bresp     (dbus_bresp     ),
		.bvalid    (dbus_bvalid    ),
		.bready    (dbus_bready    ),
		
		.axir_ireq  (axir_ireq ),
		.axir_iaddr (axir_iaddr),
		.axir_ilen  (axir_ilen ),
		.axir_dreq  (axir_dreq ),
		.axir_daddr (axir_daddr),
		.axir_rid   (axir_rid  ),
		.axir_rdy   (axir_rdy  ),
		.axir_last  (axir_last ),
		.axir_data  (axir_data ),
	
	
		.axiw_req  (axiw_req  ),
		.axiw_addr (axiw_addr ),
		.axiw_data (axiw_data ),
		.axiw_sel  (axiw_sel  ),
		.axiw_rdy  (axiw_rdy  ),
		.flush     (1'b0) 
	);
/*
	
	AXI_master axim (
		.aclk      (aclk      ),
		.aresetn   (aresetn   ),
		.arid      (arid      ),
		.araddr    (araddr    ),
		.arlen     (arlen     ),
		.arsize    (arsize    ),
		.arburst   (arburst   ),
		.arlock    (arlock    ),
		.arcache   (arcache   ),
		.arprot    (arprot    ),
		.arvalid   (arvalid   ),
		.arready   (arready   ),		
		.rid       (rid       ),
		.rdata     (rdata     ),
		.rresp     (rresp     ),
		.rlast     (rlast     ),
		.rvalid    (rvalid    ),
		.rready    (rready    ),	   
		.awid      (awid      ),
		.awaddr    (awaddr    ),
		.awlen     (awlen     ),
		.awsize    (awsize    ),
		.awburst   (awburst   ),
		.awlock    (awlock    ),
		.awcache   (awcache   ),
		.awprot    (awprot    ),
		.awvalid   (awvalid   ),
		.awready   (awready   ),
		.wid       (wid       ),
		.wdata     (wdata     ),
		.wstrb     (wstrb     ),
		.wlast     (wlast     ),
		.wvalid    (wvalid    ),
		.wready    (wready    ),
		.bid       (bid       ),
		.bresp     (bresp     ),
		.bvalid    (bvalid    ),
		.bready    (bready    ),
		
		.iram_en     (iram_en   ),
		.iram_wen    (iram_wen  ),
		.iram_addr   (iram_maddr),
		.iram_wdata  (iram_wdata),
		.iram_rdata  (iram_rdata),
		.iram_sreq   (iram_sreq ),
		.iram_stall  (iram_stall),
		.dram_en     (dram_en   ),
		.dram_wen    (dram_wen  ),
		.dram_addr   (dram_maddr),
		.dram_wdata  (dram_wdata),
		.dram_rdata  (dram_rdata),
		.dram_sreq   (dram_sreq ),
		.dram_stall  (dram_stall),
		
		.flush       (flush)
	);
	
*/
endmodule