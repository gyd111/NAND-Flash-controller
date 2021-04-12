`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:47:20 04/08/2018 
// Design Name: 
// Module Name:    flash_command_receiver 
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
module flash_command_receiver(
	input clk,rst,
	input [31:0]cmd,														//命令接收模块接收并初步处理后的命令,[31:24]为命令，[23:16]为计数，[15:0]为数据
	input start_trs,														//命令到来脉冲信号

	input end_erase,end_read,end_write,
	output reg en_erase,en_read,
	output reg [23:0] erase_addr_start,erase_addr_finish,		//擦除模块的起始地址和结束地址
	output reg [23:0] read_addr_row_reg,							//读模块的起始和结束行地址
   output reg en_write,                                     //使能写16k能谱数据
	
	output reg en_init_flash_addr,
	input end_init_flash_addr,
	output reg [23:0] init_addr_row,									//写模块的初始化写地址
	
	output reg [7:0] init_bad_block_ram_data,						//初始化坏块表ram数据
	output reg [8:0] init_bad_block_ram_addr,						//初始化坏块表ram地址
	output reg en_init_bad_block_ram,we_init_bad_block_ram, 	//初始化坏块表ram的控制信号
	
	input end_infopage_write,
	output reg flash_cmd_incomplete,                   //FPGA接收到的命令单位（一个单位为4字节）数量不完整
	output reg en_infopage_write,                             //使能写MCU发来的信息页数据
	output reg en_log_write                                   //使能写log数据
    );
	 
	reg cmd_start;
	reg end_cmd1,end_cmd2,end_cmd3,end_cmd4,end_cmd5;
	reg [1:0]i;
	reg [2:0]j;
	reg end_init_block_bad_ram;
	
	reg [23:0] cmd_incomplete_cnt;                  //单位命令完整接收计时
	reg Rec_cmd1,Rec_cmd2,Rec_cmd3,Rec_cmd4;      //命令完整性计时开始和结束标志

	always @(posedge rst or posedge clk)			//每当有新命令来的时候让cmd_start为1，该命令处理完后让cmd_start为0
	begin
		if(rst)
		  begin
		    cmd_incomplete_cnt <=0;
			 flash_cmd_incomplete <=0;
		  end
		else
		  begin
		   if(Rec_cmd1 | Rec_cmd2 | Rec_cmd3 | Rec_cmd4)
			  begin
			    if(cmd_incomplete_cnt == 2400000)    //定时100ms
				   flash_cmd_incomplete <=1;
				 else 
				   cmd_incomplete_cnt<=cmd_incomplete_cnt+1;
			  end
			else
			  begin
		       cmd_incomplete_cnt <=0;
			    flash_cmd_incomplete <=0;			    
			  end
		  end
   end		
	
	
	always @(posedge rst or posedge clk)			//每当有新命令来的时候让cmd_start为1，该命令处理完后让cmd_start为0
	begin
		if(rst)
			cmd_start <= 0;
		else
			if(start_trs)
				cmd_start <= 1;
			else
				if(end_cmd1 | end_cmd2 | end_cmd3 | end_cmd4 | end_cmd5)
					cmd_start <= 0;
	end

	always @(posedge rst or posedge clk)			//接收到读flash命令后对en_read和读地址进行赋值
	begin
		if(rst)
		begin
			en_read <= 0;
			read_addr_row_reg <= 0;
			end_cmd1 <= 0;
			Rec_cmd1 <=0;
		end
		else
		begin
			if(end_read)
				en_read <= 0;
			else
			if(cmd_start)
			begin
			if(cmd[31:24] == 8'hAD)
				case(cmd[23:16])
				8'h00:
				begin
					read_addr_row_reg[7:0] <= cmd[15:8];
					read_addr_row_reg[15:8] <= cmd[7:0];
					end_cmd1 <= 1;
					Rec_cmd1 <= 1;
				end
				8'h01:
				begin
					read_addr_row_reg[23:16] <= cmd[15:8];
					en_read <= 1;
					end_cmd1 <= 1;
					Rec_cmd1 <=0;
				end
				default:
				begin
					read_addr_row_reg <= 0;
					en_read <= 0;
				end
				endcase
			end
			else
				end_cmd1 <= 0;
		end
	end

	always @(posedge rst or posedge clk)	//接收到擦flash命令后对en_erase和擦除的起始结束地址进行赋值
	begin												//赋值顺序为起始地址的[15:8],起始地址的[7:0],起始地址的[23:16],结束地址的[7:0],结束地址的[23:16],结束地址的[15:8]
		if(rst)
		begin
			en_erase <= 0;
			erase_addr_start <= 0;
			erase_addr_finish <= 0;
			end_cmd2 <= 0;
			Rec_cmd2 <= 0;
		end
		else
		begin
			if(end_erase)
				en_erase <= 0;
			else
			if(cmd_start)
			begin
			if(cmd[31:24] == 8'hAE)
				case(cmd[23:16])
				8'h00:
				begin
					erase_addr_start[7:0] <= cmd[15:8];
					erase_addr_start[15:8] <= cmd[7:0];
					end_cmd2 <= 1;
					Rec_cmd2 <= 1;
				end
				8'h01:
				begin
					erase_addr_start[23:16] <= cmd[15:8];
				//	erase_addr_finish[7:0] <= cmd[7:0];
					end_cmd2 <= 1;
				end
				8'h02:
				begin
					erase_addr_finish[7:0] <= cmd[15:8];
					erase_addr_finish[15:8] <= cmd[7:0];
				//	en_erase <= 1;
				//	end_cmd2 <= 1;
				end
				8'h03:
				begin
				   erase_addr_finish[23:16] <= cmd[15:8];
               en_erase <= 1;
				   end_cmd2 <= 1; 
               Rec_cmd2 <= 0;					
				end
				default:
				begin
					erase_addr_finish <= 0;
					erase_addr_start <= 0;
					en_erase <= 0;
				end
				endcase
			end
			else
				end_cmd2 <= 0;
		end
	end

	always @(posedge rst or posedge clk)			//接收到初始化写地址命令后对使能信号和写地址进行赋值
	begin
		if(rst)
		begin
			en_init_flash_addr <= 0;
			init_addr_row <= 0;
			end_cmd3 <= 0;
			Rec_cmd3 <= 0;
		end
		else
		begin
			if((end_init_flash_addr==1)&&(en_init_flash_addr==1))
				en_init_flash_addr <= 0;
			else
			if(cmd_start)
			begin
			if(cmd[31:24] == 8'hAF)
				case(cmd[23:16])
				8'h00:
				begin
					init_addr_row[7:0] <= cmd[15:8];
					init_addr_row[15:8] <= cmd[7:0];
					end_cmd3 <= 1;
					Rec_cmd3 <= 1;
				end
				8'h01:
				begin
					init_addr_row[23:16] <= cmd[15:8];
					en_init_flash_addr <= 1;
					end_cmd3 <= 1;
					Rec_cmd3 <=0;
				end
				default:
				begin
					init_addr_row <= 0;
					en_init_flash_addr <= 0;
				end
				endcase
			end
			else
				end_cmd3 <= 0;
		end
	end
   
	always@(posedge clk or posedge rst)
	begin
	  if(rst) Rec_cmd4 <= 0;
	  else
	    begin
		   if(cmd_start)
			  begin
	         if(cmd[31:24] == 8'hB0)
				  begin
			       if(cmd[23:16] == 8'h00)
					   Rec_cmd4 <= 1;
					 else if(cmd[23:16] == 8'hFF)
					   Rec_cmd4 <= 0;
					 
			     end
		     end
		 end	
	end
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		  begin
			 end_init_block_bad_ram <= 0;			 
		  end
		else		   
			if(cmd[31:24] == 8'hB0)
			begin			 
				if(cmd[23:16] == 8'hFF)
					if(j < 6)
						j <= j+1;
					else
					  begin
						 end_init_block_bad_ram <= 1;						
					  end
			end
			else
			begin
				j <= 0;
				end_init_block_bad_ram <= 0;
			end
			
	end
	
	always @(posedge clk or posedge rst)			//初始化坏块表,cmd由低往高发
	begin
		if(rst)
		begin
			init_bad_block_ram_data <= 0;
			init_bad_block_ram_addr <= 0;
			en_init_bad_block_ram <= 0;
			we_init_bad_block_ram <= 0;
			end_cmd4 <= 0;
			i <= 0;
		end
		else
		begin
			if(end_init_block_bad_ram)
			begin
				en_init_bad_block_ram <= 0;
				we_init_bad_block_ram <= 0;
			end
			else
			if(cmd_start)
			begin
			if(cmd[31:24] == 8'hB0)
			begin
				en_init_bad_block_ram <= 1;
				we_init_bad_block_ram <= 1;
				case(i)
				0:
				begin	
					init_bad_block_ram_addr <= cmd[23:16]*2;
					init_bad_block_ram_data <= cmd[15:8];
					i <= 1;					
				end
				1:
				begin
					init_bad_block_ram_addr <= cmd[23:16]*2+1;
					init_bad_block_ram_data <= cmd[7:0];
					i <= 2;
					end_cmd4 <= 1;
				end
				2:i<=0;
				endcase
			end
			end
			else
				end_cmd4 <= 0;
		end
	end
	
	always @(posedge rst or posedge clk)			//接收到写信息页命令后写信息页和16k的能谱数据
	begin
		if(rst)
		begin
			en_infopage_write <= 0;
			end_cmd5 <= 0;
			en_write<=0;
		end
		else
		begin
			if(end_write)
			  begin
				en_infopage_write <= 0;
				en_log_write <=0;
				en_write<=0;
			  end
			else
			  if(cmd_start)
			  begin
			    if(cmd[31:24] == 8'hAC)
			      begin
			      en_write <=1;
		    		en_infopage_write <= 1;
					end_cmd5 <= 1;
			      end
				 else if(cmd[31:24] == 8'hA0)
				   begin
					  en_write <=1;
					  en_log_write <=1;
					  end_cmd5 <=1;
					end
			  end
		     else
				end_cmd5 <= 0;
		end
	end

endmodule
