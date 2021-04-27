`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:57:59 04/16/2018 
// Design Name: 
// Module Name:    read_flash_state_control 
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
module read_flash_state_control(
	input clk,rst,en_read,
	input [1:0]read_addr_row_error,						//读操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
	input [1:0]read_data_ECCstate,						//数据ECC状态，0为没完成检测，1为ECC校验正确，2为ECC校验错误但是可以修正，3为ECC校验后数据无效
	input [1:0]read_page,									//读页数，表示当前所读的页数为一个周期的哪一页
	input date_change_complete,							//数据修正完成标志
	input [4:0] state,
	input 	[1:0]	read_data_useless,
	output reg [3:0] read_state
    );

	reg n;
	reg [1:0] m;
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			read_state <= 0;
			n <= 0;
		end
		else
		case(read_state)
		0:														//上电初始状态
			read_state <= 1;
		1:														//空闲状态，每次读完后进入该状态
			if(en_read)
				read_state <= 2;
			else
				read_state <= 1;
		2:														//读页起始
			read_state <= 3;
		3:														//判断坏块
			if(n == 0)					//延时一个周期再判断，因为地址赋值在每次写的开始，底层模块的输出会有一个时钟周期的延迟
				n <= 1;
			else
				if(read_addr_row_error == 0)
					read_state <= 3;
				else if(read_addr_row_error == 1)
					read_state <= 4;
				else if(read_addr_row_error == 2)
					read_state <= 13;
		4:														//读数据
			begin
				n <= 0;
				if(state == 18)									// 此时已经读完了数据区和ECC区的数据 需要进行ECC校验
					read_state <= 5;
				else
					read_state <= 4;
			end
		5:														//判断ECC是否完成
			if(m < 2)				//延迟三个周期再进行判断，因为从状态6回到状态5最短是1个时钟周期，而基础读模块内最少需要3个时钟周期才能从最后一次完成ECCstate赋值到进入初始化状态(state == 12)
				m <= m+1;
			else
				if(state == 12)
					read_state <= 9;
				else if(state == 18)
					read_state <= 6;
		6:														//判断ECC状态
		begin	
			m <= 0;
			n <= 0;
			if(read_data_ECCstate == 0)
				read_state <= 6;
			else if(read_data_ECCstate == 1)
				read_state <= 5;
			else if(read_data_ECCstate == 2)
				read_state <= 7;
			else if(read_data_ECCstate == 3)
				read_state <= 8;
		end
		7:														//数据修正
			if(date_change_complete)
				read_state <= 5;
			else
				read_state <= 7;
		8:														//记录数据无效标志
				read_state <= 5;
		9:													//	ECC 完成后写入数据有效信息
				read_state <= 10;
		10:  												// 一个时钟周期用于判断前4096数据是否有效，并写入有效信息
			read_state	<= 11;						
		11 : 												//一个时钟周期用于判断后4096数据是否有效，并写入有效信息		
			read_state	<= 13;								
		12:													// 未使用
			read_state <= 13;
		13:													//结束该次读
			read_state <= 1;
		default:
			read_state <= 0;
		endcase
	end

endmodule
