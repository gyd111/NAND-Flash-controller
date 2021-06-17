`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/14 10:58:17
// Design Name: 
// Module Name: clk_div
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clk_div(
    input clk,
    
    output rst,
    output clk96M,
    output clk24M,
    output reg clk12M,
    output reg clk6M,
    output reg clk1M5,
    output reg clk1M,
    output reg clk1
    );

wire locked;
reg rst_t = 0;
reg [7:0]cnt_rst = 0;
assign rst = rst_t;
reg [4:0] div2,div3,div4;
reg [19:0] div1;
	 parameter clk_div1 = 1000000;
	 parameter clk_div2 = 2;
	 parameter clk_div3 = 16;
	 parameter clk_div4 = 24;
	 
  clk_wiz_0 clk_0
  (
   // Clock in ports
  .clk_in1(clk),
  // Clock out ports  
  .clk_out1(clk24M),
  .clk_out2(  ),
  .clk_out3(clk96M),
  // Status and control signals               
  .reset(rst), 
  .locked(locked)

  );

always@(posedge clk)
begin
    if(cnt_rst == 8'hff)
        rst_t <= 0;
    else
    begin
        cnt_rst <= cnt_rst + 1'b1;
        rst_t <= 1;
    end
end

always@(posedge clk12M or posedge rst)
begin
    if(rst)
    begin
        clk6M <= 0;
    end
    else
    begin
        clk6M <= ~clk6M;
    end
end

	 always@(posedge clk24M or posedge rst)    //24Mclk的2分频
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
	 
	 always@(posedge clk24M or posedge rst)    //24Mclk的16分频
	 begin
		if(rst) begin div3 <= 0; clk1M5 <= 0; end
		else 
			begin
			div3 <= div3 +1;
				if(div3 == clk_div3/2 - 1) 
					begin
						clk1M5 <= ~clk1M5;
						div3 <=0;
					end
			end
	 end

	 always@(posedge clk24M or posedge rst)    //24Mclk的16分频
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

    always@(posedge clk1M or posedge rst)
    begin
        if(rst) begin div1 <= 0; clk1 <= 0; end
        else
            begin
            div1 <= div1 + 1;
                if(div1 == clk_div1/2 - 1)
                    begin
                        clk1 <= ~clk1;
                        div1 <= 0;
                    end
            end
    end


endmodule
