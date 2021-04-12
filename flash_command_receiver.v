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
	input [31:0]cmd,														//�������ģ����ղ���������������,[31:24]Ϊ���[23:16]Ϊ������[15:0]Ϊ����
	input start_trs,														//����������ź�

	input end_erase,end_read,end_write,
	output reg en_erase,en_read,
	output reg [23:0] erase_addr_start,erase_addr_finish,		//����ģ�����ʼ��ַ�ͽ�����ַ
	output reg [23:0] read_addr_row_reg,							//��ģ�����ʼ�ͽ����е�ַ
   output reg en_write,                                     //ʹ��д16k��������
	
	output reg en_init_flash_addr,
	input end_init_flash_addr,
	output reg [23:0] init_addr_row,									//дģ��ĳ�ʼ��д��ַ
	
	output reg [7:0] init_bad_block_ram_data,						//��ʼ�������ram����
	output reg [8:0] init_bad_block_ram_addr,						//��ʼ�������ram��ַ
	output reg en_init_bad_block_ram,we_init_bad_block_ram, 	//��ʼ�������ram�Ŀ����ź�
	
	input end_infopage_write,
	output reg flash_cmd_incomplete,                   //FPGA���յ������λ��һ����λΪ4�ֽڣ�����������
	output reg en_infopage_write,                             //ʹ��дMCU��������Ϣҳ����
	output reg en_log_write                                   //ʹ��дlog����
    );
	 
	reg cmd_start;
	reg end_cmd1,end_cmd2,end_cmd3,end_cmd4,end_cmd5;
	reg [1:0]i;
	reg [2:0]j;
	reg end_init_block_bad_ram;
	
	reg [23:0] cmd_incomplete_cnt;                  //��λ�����������ռ�ʱ
	reg Rec_cmd1,Rec_cmd2,Rec_cmd3,Rec_cmd4;      //���������Լ�ʱ��ʼ�ͽ�����־

	always @(posedge rst or posedge clk)			//ÿ��������������ʱ����cmd_startΪ1��������������cmd_startΪ0
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
			    if(cmd_incomplete_cnt == 2400000)    //��ʱ100ms
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
	
	
	always @(posedge rst or posedge clk)			//ÿ��������������ʱ����cmd_startΪ1��������������cmd_startΪ0
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

	always @(posedge rst or posedge clk)			//���յ���flash������en_read�Ͷ���ַ���и�ֵ
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

	always @(posedge rst or posedge clk)	//���յ���flash������en_erase�Ͳ�������ʼ������ַ���и�ֵ
	begin												//��ֵ˳��Ϊ��ʼ��ַ��[15:8],��ʼ��ַ��[7:0],��ʼ��ַ��[23:16],������ַ��[7:0],������ַ��[23:16],������ַ��[15:8]
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

	always @(posedge rst or posedge clk)			//���յ���ʼ��д��ַ������ʹ���źź�д��ַ���и�ֵ
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
	
	always @(posedge clk or posedge rst)			//��ʼ�������,cmd�ɵ����߷�
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
	
	always @(posedge rst or posedge clk)			//���յ�д��Ϣҳ�����д��Ϣҳ��16k����������
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
