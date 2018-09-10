`include "defines.v"

module MMU
(
	input  wire [`AddrBus] vrt_addr,
	output reg  [`AddrBus] phy_addr,
	output reg             cached
);

	always @(*) begin
		casez (vrt_addr[31:28])
			//kseg0: unmapped, cached
			4'h8, 4'h9: begin
				phy_addr <= {3'b000, vrt_addr[28:0]};
				cached   <= `true;
			end
			
			//kseg1: unmapped, uncached
			4'hA, 4'hB: begin
				phy_addr <= {3'b000, vrt_addr[28:0]};
				cached   <= `false;
			end
			
			default: begin
				phy_addr <= vrt_addr;
				cached   <= `true;
			end
		endcase
	end
	
endmodule
