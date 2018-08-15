`include "defines.v"

module RF
(
	input  wire            clk, rst, 
	//Write Port
	input  wire            we,
	input  wire [`RegAddr] waddr, 
	input  wire [`DataBus] wdata,
	//Read Port 1
	input  wire            re1, 
	input  wire [`RegAddr] r1addr,
	output reg  [`DataBus] r1data,
	//Read Port 2
	input  wire            re2,
	input  wire [`RegAddr] r2addr,
	output reg  [`DataBus] r2data
);

	reg[`DataBus] regs [0:31];
	integer i;
	
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			for(i = 0; i < 32; i = i + 1) begin
				regs[i] <= `ZeroWord;
			end
		end
		else begin
			if((we == `true) && (waddr != `ZeroReg))
				regs[waddr] <= wdata;
		end
	end
	
	always @(*) begin
		if(rst) begin
			r1data <= `ZeroWord;
			r2data <= `ZeroWord;
		end
		else begin
			//Read Port 1
			if(r1addr == `ZeroReg)
				r1data <= `ZeroWord;
			else if((r1addr == waddr) && (we == `true) && (re1 == `true))
				r1data <= wdata;
			else if(re1 == `true)
				r1data <= regs[r1addr];
			else
				r1data <= `ZeroWord;
			
			//Read Port 2
			if(r2addr == `ZeroReg)
				r2data <= `ZeroWord;
			else if((r2addr == waddr) && (we == `true) && (re2 == `true))
				r2data <= wdata;
			else if(re2 == `true)
				r2data <= regs[r2addr];
			else
				r2data <= `ZeroWord;
		end
	end
	
endmodule

	