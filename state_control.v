`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:43:37 04/03/2018 
// Design Name: 
// Module Name:    state_control 
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
module state_control(
	input rst,ready_busy,clk,clk12M,en_erase_page,en_write_page,en_read, // clk is 24M
	output reg end_write_page,end_read,end_erase_page,
	output reg [4:0] state,

	output reg tWrite,tRead,												//读写控制信号，当该信号为1时进行读写，每128K数据读写需要暂停读写进行一次ECC,用此信号控制
	output reg [13:0] write_data_cnt,read_data_cnt,					//读写计数信号
//	output reg read_data_flag,												//读标志，用于区分状态10内是在读数据还是在读ECC码。

	input [1:0] erase_success,												//擦成功标志。用于擦操作中检测状态寄存器BIT0判断写入状况。0为没完成检测，1为操作成功，2为操作失败进入坏块管理。
	input write_complete,													//写完成标志，用于写操作中检测状态寄存器BIT0判断写入状态。0位没完成检测，1为完成检测（完成检测不一定检测结果时正确的）
	input read_ECC_success,													//读操作对比ECC校验码操作完成标志位，置0为没完成操作，置1代表已完成对读出的ECC码和生成的ECC码的校验，并对读出的数据进行修正.
	input [1:0]erase_addr_row_error,										//擦除坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
	input [1:0]write_addr_row_error,										//写操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
	input [1:0]read_addr_row_error,										//读操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
	input end_bad_block_renew,												//坏块更新完成标志信号

   output reg nandflash_busy_Noresponse,                       //nandflash的busy信号无响应标志
	output ce,
	output reg cle1,ale1,we1,re1
    );

	reg [1:0]tADL;										//暂停时间，在写完地址后，写数据开始前需要暂停几个周期，然后才能开始写数据
	reg [3:0]tECC;										//ECC暂停计时，每128K数据读写需要暂停读写进行一次ECC
	reg i,j;												//状态16和状态9开始时暂停一个周期，因为时序要求
	reg [1:0] m,n;										//状态10开始时暂停两个周期
	reg [4:0] nandflash_busy_Noresponse_cnt;     //nandflash的busy信号无响应计数
	
	reg re_flag,k;
	reg cle,ale,we,re;
	
	
	always @(negedge clk or posedge rst)	//nandflash的busy信号无响应判断
	begin
	  if(rst)
	    begin
		   nandflash_busy_Noresponse_cnt<=0;
		   nandflash_busy_Noresponse<=0;
		 end
	  else
	    begin
		   if(state == 13)
			  begin 
			    if(nandflash_busy_Noresponse_cnt == 15)
				    nandflash_busy_Noresponse<=1;
				 else
				    nandflash_busy_Noresponse_cnt<=nandflash_busy_Noresponse_cnt +1;
			  end
			else
			  begin
			     nandflash_busy_Noresponse_cnt<=0;
		        nandflash_busy_Noresponse<=0;
			  end
		 end
	end
	
	always @(posedge clk12M)	//we延时半个周期
	begin
		we1 <= we;
		cle1 <= cle;
		ale1 <= ale;
		re1 <= re;
	end
	
	assign ce = 0;
	
   always @ (posedge clk or posedge rst)	
	begin
		if(rst)
		begin
			re_flag <= 0;
			k <= 0;
		end
		else
			if(state == 10)
				if(k == 0)
					k <= 1;
				else
					re_flag <= 1;
			else
			begin
				k <= 0;
				re_flag <= 0;
			end
	end

	always @(clk or rst)	//对控制信号进行赋值
	begin
		if(rst)
		begin
			cle <= 0;
			ale <= 0;
			we <= 0;
			re <= 1;
			n <= 0;
			i <= 0;
		end
		else
			case(state)
			0:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			1:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			2:
				begin
					cle <= 1;
					ale <= 0;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			3:
				begin
					cle <= 1;
					ale <= 0;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			4:
				begin
					cle <= 0;
					ale <= 1;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			5:
				begin
					cle <= 0;
					ale <= 1;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			6:	
				begin
					cle <= 0;
					ale <= 1;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			7:
				begin
					cle <= 0;
					ale <= 1;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			8:
				begin
					cle <= 0;
					ale <= 1;
					we <= clk;
					re <= 1;
					n <= 0;
					i <= 0;
				end
			9:
				begin
					cle <= 0;
					ale <= 0;
					re <= 1;
					i <= 0;
					if(tWrite)
					begin
						if(write_data_cnt == 8192 | write_data_cnt == 8193)		//写完8192个原始数据，并且完成ECC计算后，先让we保持为0两个周期，目的是调整时序，因为ECC码从ram输出到输入到flash会有两个周期的时间差
							we <= 0;
						else	if(n < 2)
									n <= n+1;
								else
								begin
									we <= clk;
									n <= 2;
								end
					end
					else if(n > 0)							//因为是电平触发，两次计数才是一个时钟周期
							begin
								n <= n - 1;
								we <= clk;
							end
							else
							begin
								we <= 0;
								n <= 0;
							end
				end
			10:
				begin
					cle <= 0;
					ale <= 0;
					we <= 1;
					i <= 0;
					n <= 0;
					if(tRead & re_flag)
						re <= clk;
					else
						re <= 1;
				end
			11:
				begin
					cle <= 1;
					ale <= 0;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			12:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			13:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			14:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			15:
				begin
					cle <= 1;
					ale <= 0;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			16:
				begin
					cle <= 0;
					ale <= 0;
					we <= 1;
					n <= 0;
					if(i)
					begin
						re <= clk;
						i <= 1;
					end
					else
						i <= i+1;
				end
			17:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			18:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			default:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			endcase
	end


	always @(negedge clk or posedge rst)	//状态机
	begin
	if(rst)
	begin
		state <= 0;
		end_erase_page <= 0;
		end_write_page <= 0;
		end_read <= 0;
		write_data_cnt <= 0;
		read_data_cnt <= 0;
		tADL <= 0;
		tECC <= 0;
		tWrite <= 0;
		tRead <= 0;
//		read_data_flag <= 0;
		j <= 0;
		m <= 0;
	end
	else
		if(ready_busy == 0)
		begin
			case(state)
			3:
				state <= 13;
			11:
				state <= 12;
			12:
				state <= 12;
			13:
				state <= 14;
			14:
				state <= 14;
			default
				state <= state;
			endcase
		end
		else
		begin
			case(state)
			0:										//刚上电状态
				state <= 1;
			1:										//上电后READY
				state <= 11;
			2:										//写起始命令
			begin
				if(en_erase_page == 1)
					state <= 6;
				else
					state <= 4;
			end
			3:										//写结束命令
				state <= 13;
			4:										//写第一个列地址
				state <= 5;
			5:										//写第二个列地址
				state <= 6;
			6:										//写第一个行地址
				state <= 7;
			7:										//写第二个行地址
				state <= 8;
			8:										//写第三个行地址
			begin
				tWrite <= 0;
				j <= 0;
				if(en_erase_page == 1)
				begin
					state <= 3;
				end
				else if(en_write_page == 1)
				begin
					if(tADL == 3)
					begin
						state <= 9;
						tADL <= 0;
					end
					else
					begin
						state <= 8;
						tADL <= tADL + 1;
					end
				end
				else if(en_read == 1)
				begin
					state <= 3;
				end				
			end
			9:									//写状态
			begin
			if(j == 0)
			begin
				j <= 1;					//在进入9状态后计数暂停一个周期，在刚进入9状态由于tWrite需要过一个周期才为1，导致的we会保持为0多一个周期
				tWrite <= 1;
			end	
			else
				if(write_data_cnt < 8384+1)			//数据输出的速度比计数的速度慢1
					begin	
						if(write_data_cnt <= 8192)							//写数据区数据
						begin
							if(write_data_cnt[6:0] < 7'b1111111)
							begin
								tWrite <= 1;
								state <= 9;
								write_data_cnt <= write_data_cnt + 1;
							end
							else					
							begin
								if(tECC < 7)
								begin
									tECC <= tECC+1;
									tWrite <= 0;
								end
								else
								begin
									tECC <= 0;
									tWrite <= 1;
									write_data_cnt <= write_data_cnt + 1;
								end
							end
						end
						else			//写ECC码数据
						begin
							state <= 9;
							write_data_cnt <= write_data_cnt + 1;
							tWrite <= 1;
						end
					end
				else
				begin
					write_data_cnt <= 0;
					state <= 3;
				end
			end
			10:											//读状态
			begin
			if(m < 2)
			begin
				m <= m+1;
				tRead <= 1;
//				read_data_flag <= 1;
			end
			else
				if(read_data_cnt < 8384)							//读数据区及ECC区数据
				begin
				if(read_data_cnt < 8192)							//读数据区数据
				begin
							if(read_data_cnt[6:0] < 7'b1111111)
							begin
								tRead <= 1;
								state <= 10;
								read_data_cnt <= read_data_cnt + 1;
							end
							else					
							begin
								if(tECC < 7)
								begin
									tECC <= tECC+1;
									tRead <= 0;
								end
								else
								begin
									tECC <= 0;
									tRead <= 1;
									read_data_cnt <= read_data_cnt + 1;
								end
							end
				end
				else
				begin
					state <= 10;
//					read_data_flag <= 0;
					read_data_cnt <= read_data_cnt+1;
				end
				end
				else			
				begin
					state <= 18;
					read_data_cnt <= 0;
				end
			end
			11:												//写初始化ff命令
				state <= 11;
			12:												//空闲态，所有的操作都从该状态起始，结束后回到该状态
			begin												//不需要对end判断保持12状态，因为该模块为下降沿赋值，使能模块是上升沿赋值，所以可以保证end只有一个脉冲且会停留在状态12
				if(en_erase_page | en_write_page | en_read)
				begin
					if(erase_addr_row_error == 1 | write_addr_row_error == 1 | read_addr_row_error == 1)
						state <= 2;
					else if(read_addr_row_error == 2)
						begin
							state <= 12;
							end_read <= 1;
						end
					else if(write_addr_row_error == 2)
						begin
							state <= 12;
							end_write_page <= 1;
						end
					else if(erase_addr_row_error == 2)
						begin
							state <= 12;
							end_erase_page <= 1;
						end
					else
						state <= 12;
				end
				else
				begin
					end_write_page <= 0;
					end_read <= 0;
					end_erase_page <= 0;
					state <= 12;
				end
			end
			13:												//R/B为1的空闲态，用于等待RB回到0
				state <= 13;
			14:												//R/B为0的空闲态，用于等待RB回到1
			begin
				if(en_erase_page == 1)
					state <= 15;
				else if(en_write_page == 1)
						state <= 15;
				else if(en_read == 1)
						state <= 10;
			end
			15:												//写70命令去读状态寄存器
				state <= 16;
			16:												//读状态寄存器
			begin
				if(en_write_page)
				begin
					case(write_complete)
					0:
						state <= 16;
					1:
						begin
							state <= 12;
							end_write_page <= 1;
						end
					endcase
				end
				else if(en_erase_page)
							case(erase_success)
							0:
								state <= 16;
							1:
							begin
								end_erase_page <= 1;
								state <= 12;
							end
							2:
								state <= 17;
							endcase
			end
			17:								//坏块管理，发现新的坏块后进入该状态
			begin
				if(end_bad_block_renew)
				begin
					state <= 12;
					end_erase_page <= 1;
				end
				else
					state <= 17;
			end
			18:								//操作ECC进行纠正对比
			begin
				m <= 0;
				case(read_ECC_success)
				0:
					state <= 18;
				1:
				begin
					state <= 12;
					end_read <= 1;
				end
				endcase
			end
			default:
				state <= 0;
			endcase
		end		//ready_busy == 1	
	 end
endmodule
