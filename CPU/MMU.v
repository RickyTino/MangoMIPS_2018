`include "defines.v"

module MMU
(
	input  wire [`AddrBus] vrt_addr,
	output reg  [`AddrBus] phy_addr
);

	always @(*) begin
		case (vrt_addr[31:28])
			4'h8, 
			4'h9, 
			4'hA,
			4'hB:    phy_addr <= {3'b000, vrt_addr[28:0]};
			default: phy_addr <= vrt_addr;
		endcase
	end
	
endmodule
