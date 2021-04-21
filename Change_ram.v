`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:23:41 03/14/2016 
// Design Name: 
// Module Name:    Change_ram 
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
module Change_ram(
	input clk,
	input rst,
	input change_ram,
	input ram_busy,
	
	output ram_change,      //反映ram_adj的变化情况，ram_adj变化则为1不变则为0
	output reg ram_adj
    );
	
	reg a1_ram_adj,a2_ram_adj;//用于检测ram_adj的上升和下降沿
	wire pos_change_ram;
	
	reg change_ram_r1; //用来检测沿
	reg change_ram_r2;
	reg hold_change;	//用来保存切换指令
	
	
	always@(posedge clk or posedge rst)   //检测上升沿
	begin
		if(rst) begin change_ram_r1 <= 0; change_ram_r2 <= 0; end
		else 
			begin
			change_ram_r1 <= change_ram;
			change_ram_r2 <= change_ram_r1;
			end
	end
	
	assign pos_change_ram = ~change_ram_r2 && change_ram_r1;  //检测上升沿
	
	
	always@(posedge clk or posedge rst)  //切换ram
	begin
		if(rst) begin 
		  ram_adj <= 0; 
		  hold_change <= 0;
		end
		else 
			begin
				if(ram_busy)
					begin
						if(pos_change_ram) hold_change <= 1; //如果收到切换ram的指令，但是ram正在读写，则通过hold_change来保存切换指令。
					end
				else
					begin
						if(pos_change_ram) begin ram_adj <= ~ram_adj; hold_change <= 0; end
						else if(hold_change) begin ram_adj <= ~ram_adj; hold_change <= 0; end //如果ram不busy了，又检测到刚刚保存的切换指令，就切换ram。
					end
			end
	end
	
	 always @(posedge clk or posedge rst)      //判断ram_adj的变化，上升沿或者下降沿
	 begin
	   if(rst)
		  begin
		  a1_ram_adj <= 1;                      //通过改变这两个的初始值可以决定最开始的第一个周期 
	     a2_ram_adj <= 1;
		  end
		else 
		  begin
		  a1_ram_adj <= ram_adj;
		  a2_ram_adj <= a1_ram_adj;
		  end
	 end
	 
	 assign ram_change = (a1_ram_adj != a2_ram_adj)? 1'b1:1'b0;  //当满足条件的时候，说明ram_adj发生了变化

endmodule
