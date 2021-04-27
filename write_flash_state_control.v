`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:22:09 04/11/2018 
// Design Name: 
// Module Name:    write_flash_state_control 
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
module write_flash_state_control(
	input clk,rst,en_write,
	input en_infopage_write,
//	output reg end_infopage_write,
	
	input [4:0]state,
	input [1:0] write_success,						//写成功标志,用于写操作中检测状态寄存器BIT0判断写入状况。0为未操作，1为操作成功，2为操作失败（保持在2两个周期）
	input [1:0]write_addr_row_error,				//写操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏（保持在2两个周期）
   	input [23:0]write_addr_row,
	input [1:0] write_time,						// 写的次数
	input en_write_info,						//写信息页标志位
	input en_log_write,                       	//使能写log标志
	
	output reg [3:0] write_state,
	output reg end_write
	 );
	 
	 reg n,m;
	 
	// reg wait_en_nentpage_write;
	// reg end_wait_en_nentpage_write;
	// reg write_success_r;
	// wire pos_write_success;  //检测写成功上升沿
	
/*	always @(posedge clk or posedge rst)
	begin
		if(rst)
		  begin
		    write_success_r <= 0;	
		  end
		else
		  write_success_r <= write_success[0];		 
   end
	assign pos_write_success = (~write_success_r) & write_success[0];
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		  begin
		    wait_en_nentpage_write <= 0;
		  end
		else
		  begin
		    if(pos_write_success == 1)
		      wait_en_nentpage_write <= 1;
			 else if(end_wait_en_nentpage_write == 1)
			   wait_en_nentpage_write <= 0;
		  end
	end	  
*/
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			write_state <= 0;
			end_write <=0;
			n <= 0;
			
	//		m <= 0;
	//		end_wait_en_nentpage_write <= 0;
		end
		else
		begin
			case(write_state)
			0:									//上电状态
				write_state <= 1;
			1:									//空闲状态，每次写完后进入该状态
			begin
				if(en_write == 1)
					write_state <= 2;
				else
					write_state <= 1;
			end
			2:									//初始状态，接收到写命令后进入该状态，开始写第一页
			begin
				write_state <= 3; 
			end
			3:									//判断坏块
			begin
				if(n == 0)					//延时一个周期再判断，因为地址赋值在每次写的开始，底层模块的输出会有一个时钟周期的延迟
					n <= 1;
				else
				if(write_addr_row_error == 0)
					write_state <= 3;
				else if(write_addr_row_error == 1)
					write_state <= 4;
				else if(write_addr_row_error == 2)
					write_state <= 5;
			end
			4:									//基础写功能的实现
			begin
				n <= 0;
				if(state == 3)					// state3是写结束命令的状态
					write_state <= 15;
				else
					write_state <= 4;
			end
			5:									//判断坏块后发现该页为坏块状态
			begin
				n <= 0;
				write_state <= 2;
			end
			6:									//判断是否写成功
			begin
			//	end_infopage_write <= 0;
				if(write_success == 0)
					write_state <= 6;
				else if(write_success == 1)
				begin
					if(en_write_info)
						write_state <= 2;
					else 
					   write_state <= 9;	
				end
				else if(write_success == 2)
				begin
					if(en_write_info)
						write_state <= 11;
					else
						write_state <= 10;
				end
				else 
				  write_state <= 6;  
			end
			7:									//开始写第二页
			  begin
				write_state <= 4;
			//	end_wait_en_nentpage_write <= 0;
			  end
			8:									//开始写第三页
			  begin
				write_state <= 4;
			//	end_wait_en_nentpage_write <= 0;
			  end
			9:	               					//写完成
			 begin
				write_state <= 12;
				end_write <=1;
			  // end_infopage_write<=0;
			 end
			10:								//页数据写失败，说明该块为新的坏块，需要写下该块共写了多少页数据，然后跳块重新写该周期数据
				write_state <= 4;
			11:								//写信息页失败，跳转状态2重新写
				write_state <= 2;
			12:								//写完成后判断该块是否写完，若写完需要跳块
			begin
				if(write_addr_row[6:0] == 126)
					write_state <= 14;
				else
					write_state <= 13;
			end			
			13:								//结束写过程
			begin
		     	write_state <= 1;
				end_write <=0;
			end
			14:								//一块写完进行跳块
				write_state <= 13;
			15:								//每页写完地址+1
				write_state <= 6;
			default:
				write_state <= 0;
			endcase
			end
	end

endmodule
