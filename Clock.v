`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:16:01 03/10/2016 
// Design Name: 
// Module Name:    Clock 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Clock(
	input clock,                     //输入50M时钟
	input FPGA_RST,
	
	output rst,
	output clk,clk_48M,clk_96M,
	output reg clk6M,clk12M,clk1_5M,clk1M
    );
	 
	 wire LOCKED_OUT,CLKIN_IBUFG_OUT;
	 wire clk_24M;                      //24M时钟
	 reg [4:0] div1,div2,div3,div4;
	 
	 parameter clk_div1 = 4;
	 parameter clk_div2 = 2;
	 parameter clk_div3 = 16;
	 parameter clk_div4 = 24;
	 

	 
	 DCM2 DCM2 (                          
    .CLKIN_IN(clock), 
	 .CLK0_OUT(clk),
    .CLK2X_OUT(clk_48M),  
	 .CLKFX_OUT(clk_96M),
    .LOCKED_OUT(LOCKED_OUT)
	 );
	 
	 assign rst = (FPGA_RST == 0)? ~LOCKED_OUT:1'b1;
	 
	 always@(posedge clk or posedge rst)    //24Mclk的4分频
	 begin
		if(rst) begin div1 <= 0; clk6M <= 0; end
		else 
			begin
			div1 <= div1 +1;
				if(div1 == clk_div1/2 - 1) 
					begin
						clk6M <= ~clk6M;
						div1 <=0;
					end
			end
	 end
	 
	 always@(posedge clk or posedge rst)    //24Mclk的2分频
	 begin
		if(rst) begin div2 <= 0; clk12M <= 0; end
		else 
			begin
			div2 <= div2 +1;
				if(div2 == clk_div2/2 - 1) 
					begin
						clk12M <= ~clk12M;
						div2 <=0;
					end
			end
	 end
	 
	 always@(posedge clk or posedge rst)    //24Mclk的16分频
	 begin
		if(rst) begin div3 <= 0; clk1_5M <= 0; end
		else 
			begin
			div3 <= div3 +1;
				if(div3 == clk_div3/2 - 1) 
					begin
						clk1_5M <= ~clk1_5M;
						div3 <=0;
					end
			end
	 end

	 always@(posedge clk or posedge rst)    //24Mclk的16分频
	 begin
		if(rst) begin div4 <= 0; clk1M <= 0; end
		else 
			begin
			div4 <= div4 +1;
				if(div4 == clk_div4/2 - 1) 
					begin
						clk1M <= ~clk1M;
						div4 <=0;
					end
			end
	 end
endmodule
