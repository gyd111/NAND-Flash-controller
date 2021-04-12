`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:58:56 04/12/2018 
// Design Name: 
// Module Name:    erase_flash_state_control 
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
module erase_flash_state_control(
	input clk,rst,en_erase,end_erase_page,
	input [23:0]erase_addr_finish,erase_addr_row,
	input [1:0]erase_addr_row_error,
	output reg[2:0] erase_state
	);

	reg n;
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			erase_state <= 0;
		else
			case(erase_state)
			0:									//上电初始态
				erase_state <= 1;
			1:									//空闲态
				if(en_erase)
					erase_state <= 2;
				else
					erase_state <= 1;
			2:									//擦第一页开始
				erase_state <= 3;
			3:									//判断该页是否为坏块
			begin
				if(n == 0)					//延时一个周期再判断，因为地址赋值在每次写的开始，底层模块的输出会有一个时钟周期的延迟
					n <= 1;
				else
				if(erase_addr_row_error == 0)
					erase_state <= 3;
				else if(erase_addr_row_error == 1)
					erase_state <= 4;
				else if(erase_addr_row_error == 2)
					erase_state <= 5;
			end
			4:									//等待擦结束
			begin
				n <= 0;
				if(end_erase_page)
					erase_state <= 5;
				else
					erase_state <= 4;
			end
			5:									//判断是否全部擦除完成
			begin
				n <= 0;
				if(erase_addr_row < erase_addr_finish)
					erase_state <= 6;
				else
					erase_state <= 7;
			end
			6:									//擦下一页
				erase_state <= 3;
			7:									//擦除全部完成
				erase_state <= 1;
			default:
				erase_state <= 0;
			endcase
	end

endmodule
