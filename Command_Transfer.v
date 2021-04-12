`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:04:40 07/24/2018 
// Design Name: 
// Module Name:    Command_Transfer 
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
module Command_Transfer(
	input clk,rst,clk1M,
	output reg RXD_MCU,
	
	input en_bad_block_renew_transfer,						//��MCU���͸��º�Ļ�����־����
	input [11:0]bad_block_renew_addr,						//�����ַ
	
	input en_vibTransfer,
	input [15:0]acc_data,
	output reg end_vibTransfer,
	
	input en_writeAddr_Transfer,
	output reg end_writeAddr_Transfer,
	input [23:0]write_addr_row,
	
	input en_demand_write_addr,
	output reg end_demand_write_addr,
	
	input en_baud_transfer,                          //����MCU��UART_A1�ڵĲ����ʵĲ���
	input [7:0]baud_CMD,
	output reg end_baud_transfer,
	
	input end_init_flash_addr,end_erase
    );
	 
	 reg [9:0] data_send_vib,data_send_badblock,data_send_writeaddr,data_send_init_flash,data_send_finerase,data_send_baud;	//������ķ��ͼĴ���
	 reg [9:0] data_send;					//���ͼĴ���
	 reg en_bad_block_transfer,end_bad_block_transfer;
	 reg en_init_flash_transfer,end_init_flash_transfer;
	 reg en_finerase,end_finerase;
//	 reg end_baud_transfer;
	 reg [3:0]state;
	 reg [3:0]i; 								//���ͼ�����
	 wire en_transfer;						//ʹ�ܷ����ź�
	 reg transfer_fin,transfer_fin_r;
	 wire pos_transfer_fin;					//ÿ�η�����һ��byte�ı�־�ź�
	 reg [9:0] wait_cnt;						//�ȴ�������������ÿ�ν�����һ��byte�Ĵ�����еȴ���Ϊ����datasend���и�ֵ
	// reg vib_transfer_end_respond_flag,vib_transfer_end_respond_flag_r;   //��ֵ���ͽ�����־
	 wire neg_flag,neg_flag1,neg_flag2,neg_flag3,neg_flag4,neg_flag5;              //�½��ؼ��
	 reg  end_vibTransfer_r,end_baud_transfer_r;
	 
//******************************UART_TX****************************************************//
 always @(posedge clk1M or posedge rst)	//����Ҫ�����ӳ٣���Ϊ��ģ����1Mʱ�Ӵ�����ÿ�η������㹻��ʱ��������ģ���ʹ���ź�����������źŸ�ֵ
	 begin												//������Ҫ�ӳ٣�����һ���ֽڵ�ʱ���źŸ�ֵ��Ҫʱ��
		if(rst)
		begin
			RXD_MCU <= 1;
			i <= 0;
			transfer_fin <= 0;
			wait_cnt <= 0;
		end	
		else
			if(en_transfer)
			begin
			if(wait_cnt < 200)          //�ȴ�200us����֤���͵���Ƭ�������ݼ��ʱ�����㹻���Ա㵥Ƭ������ȷ���մ������ݣ����﷢�͵���Ƭ��
			  begin                     //������û�����ʵ�Ҫ��������ʱ�ȵ��Թ���û��Ӱ�죩
			  wait_cnt <= wait_cnt+1;
			  RXD_MCU <= 1;
			  i <= 0;
			  transfer_fin <= 0;
			  end
			else
				if(i == 10)
				begin
					i <= 0;
					RXD_MCU <= 1;
					transfer_fin <= 1;
					wait_cnt <= 0;
				end
				else
				begin
					RXD_MCU <= data_send[i];
					i <= i+1;
					transfer_fin <= 0;
					wait_cnt <= wait_cnt;
				end
			end
			else
			begin
				transfer_fin <= 0;
				i <= 0;
				RXD_MCU <= 1;
				wait_cnt <= 0;
			end
	 end
//****************************************************************************************//	 

	 always @(posedge clk or posedge rst)			//�Ѹ��»�����ʹ�������źţ�ת���ɵȴ�end��־���˲Ż�Ϊ0�ĵ�ƽ�ź�
	 begin
		if(rst)
			en_bad_block_transfer <= 0;
		else
			if(end_bad_block_transfer)
				en_bad_block_transfer <= 0;
			else if(en_bad_block_renew_transfer)
				en_bad_block_transfer <= 1;
	 end
	 
	 assign en_transfer = en_baud_transfer | en_bad_block_transfer | en_vibTransfer | en_writeAddr_Transfer | en_demand_write_addr | en_init_flash_transfer | en_finerase;
	 
	 always @(posedge clk or posedge rst)
	 begin
		if(rst)
			data_send<=0;
		else
			if(en_bad_block_transfer)
				data_send <= data_send_badblock;
			else if(en_vibTransfer)
				data_send <= data_send_vib;
			else if(en_writeAddr_Transfer)
				data_send <= data_send_writeaddr;
			else if(en_demand_write_addr)
				data_send <= data_send_writeaddr;
			else if(en_init_flash_transfer)
				data_send <= data_send_init_flash;
			else if(en_finerase)
				data_send <= data_send_finerase;
		   else if(en_baud_transfer)
			   data_send <= data_send_baud;
		   else
			   data_send <= 10'b11_1111_1111;
	 end
	 

	 always @(posedge clk or posedge rst)  //���������,ԭ����transfer_finΪƵ��1Mʱ�ӵ�һ��ʱ����������壬����24Mʱ����˵��һ������Ϊ24�����ڵ�����
	 begin
		if(rst) transfer_fin_r <= 0;
		else transfer_fin_r <= transfer_fin;
	 end
	 
	 assign pos_transfer_fin = ~transfer_fin_r && transfer_fin; 
	 
//.............................................................................
	 always @(posedge clk or posedge rst)
	 begin
		if(rst)
			state <= 0;
		else
		 begin
		   if((neg_flag)||(neg_flag3)||(neg_flag4)||(neg_flag5)||(neg_flag1)||(neg_flag2))
				state <= 0;
			else if(pos_transfer_fin)
				state <= state+1;
		   else
			   state <= state;  
		 end
	 end
//.............................................................................
	 reg end_init_flash_transfer_r;
	 reg end_finerase_r;
	 reg end_writeAddr_Transfer_r,end_demand_write_addr_r;
    always @(posedge clk or posedge rst)
	 begin
		if(rst)
		 begin
		  end_vibTransfer_r         <= 0;
		  end_init_flash_transfer_r <= 0;
		  end_finerase_r            <= 0;
		  end_writeAddr_Transfer_r  <= 0;
		  end_demand_write_addr_r   <= 0;
		  end_baud_transfer_r       <= 0;
		 end
		else
		 begin
		  end_vibTransfer_r         <= end_vibTransfer;
		  end_init_flash_transfer_r <= end_init_flash_transfer;
		  end_finerase_r            <= end_finerase;
		  end_writeAddr_Transfer_r  <= end_writeAddr_Transfer;
		  end_demand_write_addr_r   <= end_demand_write_addr;
		  end_baud_transfer_r       <= end_baud_transfer;
		 end
	 end	
	 
	 assign neg_flag  = (~end_vibTransfer)&end_vibTransfer_r;                 //����½��أ���ʾ��ֵ�������
	 assign neg_flag1 = (~end_init_flash_transfer)&end_init_flash_transfer_r; //����½��أ���ʾ��ʼ��дflash��ַ���
	 assign neg_flag2 = (~end_finerase)&end_finerase_r;                       //����½��أ���ʾ����flash���
	 assign neg_flag3 = (~end_writeAddr_Transfer)&end_writeAddr_Transfer_r;   //����½��أ���ʾд��ַ������ɣ��⾮ģʽ���Զ�����д��ַ��
	 assign neg_flag4 = (~end_demand_write_addr)&end_demand_write_addr_r;     //����½��أ���ʾд��ַ������ɣ��ǲ⾮ģʽ����λ��������������д��ַ��
    assign neg_flag5 = (~end_baud_transfer)&end_baud_transfer_r;             //����½��أ���ʾ������������������
//............................................................................

//...........................�л�������........................................//  
	always @(posedge clk or posedge rst)
	 begin
	   if(rst)
		  begin
		  data_send_baud    <= 0;
		  end_baud_transfer <= 0;
		  end
		else
		  begin
		  if(en_baud_transfer)
			 begin
			 case(state)
			 0:
			   begin
				data_send_baud    <= {1'b1,8'hB0,1'b0};
            end_baud_transfer <= 0;					
				end
			 1:
			   begin
				data_send_baud    <= {1'b1,8'h00,1'b0};
            end_baud_transfer <= 0;	
				end
			 2:
			   begin
				data_send_baud    <= {1'b1,baud_CMD,1'b0};
            end_baud_transfer <= 0;	
				end
			 3:
			   begin
				data_send_baud    <= {1'b1,8'h00,1'b0};
            end_baud_transfer <= 0;				
				end
			 4:
			   begin
				data_send_baud    <= 0;
            end_baud_transfer <= 1;
				end
			 default:
			   begin
				data_send_baud    <= 0;
            end_baud_transfer <= 0;
				end
			 endcase
			 end
		  else
			 begin
			 data_send_baud    <= 0;
		    end_baud_transfer <= 0;	
			 end
		  end
	 end
   
	 always @(posedge clk or posedge rst)
	 begin
		if(rst)
		begin
			data_send_badblock <= 0;
			end_bad_block_transfer <= 0;
		end
		else
			if(en_bad_block_transfer)
			case(state)
			0:
				begin
					data_send_badblock <= {1'b1,8'hB3,1'b0};
					end_bad_block_transfer <= 0;
				end
			1:
				begin
					data_send_badblock <= {1'b1,8'h00,1'b0};
					end_bad_block_transfer <= 0;
				end
			2:
				begin
					data_send_badblock <= {1'b1,bad_block_renew_addr[7:0],1'b0};
					end_bad_block_transfer <= 0;
				end
			3:
				begin
					data_send_badblock <= {5'b1,bad_block_renew_addr[11:8],1'b0};
					end_bad_block_transfer <= 0;
				end
			4: 
				begin
					data_send_badblock <= 0;
					end_bad_block_transfer <= 1;
				end
			default:
				begin
					data_send_badblock <= 0;
					end_bad_block_transfer <= 0;
				end
			endcase
			else
				end_bad_block_transfer <= 0;
	 end

	 always @(posedge clk or posedge rst)
	 begin
		if(rst)
		begin
			data_send_vib <= 0;
			end_vibTransfer <= 0;
			end
		else
			if(en_vibTransfer)
			case(state)
			0:
				begin
					data_send_vib <= {1'b1,8'hB1,1'b0};
					end_vibTransfer <= 0;
				end
			1:
				begin
					data_send_vib <= {1'b1,8'h00,1'b0};
					end_vibTransfer <= 0;
				end
			2:
				begin
					data_send_vib <= {1'b1,acc_data[7:0],1'b0};
					end_vibTransfer <= 0;
				end
			3:
				begin
					//data_send_vib <= {1'b1,8'h00,1'b0};
					data_send_vib   <= {1'b1,acc_data[15:8],1'b0};
					end_vibTransfer <= 0;
				end
			4: 
				begin
					data_send_vib <= 0;
					end_vibTransfer <= 1;    					
				end
			default:
				begin
					data_send_vib <= 0;
					end_vibTransfer <= 0;
				end
			endcase
			else
				end_vibTransfer <= 0;
				
	 end
    
	
	 always @(posedge clk or posedge rst)
	 begin
		if(rst)
		begin
			data_send_writeaddr <= 0;
			end_writeAddr_Transfer <= 0;
		end
		else
			if(en_writeAddr_Transfer | en_demand_write_addr)
			case(state)
			0:
				begin
					data_send_writeaddr <= {1'b1,8'hB2,1'b0};
					end_writeAddr_Transfer <= 0;
				end
			1:
				begin
					data_send_writeaddr <= {1'b1,8'h00,1'b0};
					end_writeAddr_Transfer <= 0;
				end
			2:
				begin
					data_send_writeaddr <= {1'b1,write_addr_row[7:0],1'b0};				 
					end_writeAddr_Transfer <= 0;
				end
			3:
				begin
					data_send_writeaddr <= {1'b1,write_addr_row[15:8],1'b0};				
					end_writeAddr_Transfer <= 0;
				end
			4: 
				begin
					data_send_writeaddr <= {1'b1,8'hB2,1'b0};
					end_writeAddr_Transfer <= 0;
				end
			5:
				begin
					data_send_writeaddr <= {1'b1,8'h01,1'b0};
					end_writeAddr_Transfer <= 0;
				end
			6:
				begin
					data_send_writeaddr <= {1'b1,write_addr_row[23:16],1'b0};				
					end_writeAddr_Transfer <= 0;
				end
			7:
				begin
					data_send_writeaddr <= {1'b1,8'h00,1'b0};			
					end_writeAddr_Transfer <= 0;
				end
			8:
				begin
					data_send_writeaddr <= 0;
					end_writeAddr_Transfer <= 1;
					end_demand_write_addr <= 1;
				end
			default:
				begin
					data_send_writeaddr <= 0;
					end_writeAddr_Transfer <= 0;
					end_demand_write_addr <= 0;
				end
			endcase
			else
			begin
				end_writeAddr_Transfer <= 0;
				end_demand_write_addr <= 0;
			end
	 end

	always @(posedge clk or posedge rst)
	begin
		if(rst)
			en_init_flash_transfer <= 0;
		else
			if(end_init_flash_addr)
				en_init_flash_transfer <= 1;
			else if(end_init_flash_transfer)
				en_init_flash_transfer <= 0;
	end

	always @(posedge clk or posedge rst)
	 begin
		if(rst)
		begin
			data_send_init_flash <= 0;
			end_init_flash_transfer <= 0;
		end
		else
			if(en_init_flash_transfer)
			case(state)
			0:
				begin
					data_send_init_flash <= {1'b1,8'hAF,1'b0};
					end_init_flash_transfer <= 0;
				end
			1:
				begin
					data_send_init_flash <= {1'b1,8'h00,1'b0};
					end_init_flash_transfer <= 0;
				end
			2:
				begin
					data_send_init_flash <= {1'b1,8'h00,1'b0};
					end_init_flash_transfer <= 0;
				end
			3:
				begin
					data_send_init_flash <= {1'b1,8'h00,1'b0};
					end_init_flash_transfer <= 0;
				end
			4: 
				begin
					data_send_init_flash <= 0;
					end_init_flash_transfer <= 1;
				end
			default:
				begin
					data_send_init_flash <= 0;
					end_init_flash_transfer <= 0;
				end
			endcase
			else
				end_init_flash_transfer <= 0;
	 end

	always @(posedge clk or posedge rst)
	begin
		if(rst)
			en_finerase <= 0;
		else
			if(end_erase)
				en_finerase <= 1;
			else if(end_finerase)
				en_finerase <= 0;
	end

	always @(posedge clk or posedge rst)
	 begin
		if(rst)
		begin
			data_send_finerase <= 0;
			end_finerase <= 0;
		end
		else
			if(en_finerase)
			case(state)
			0:
				begin
					data_send_finerase <= {1'b1,8'hAE,1'b0};
					end_finerase <= 0;
				end
			1:
				begin
					data_send_finerase <= {1'b1,8'h00,1'b0};
					end_finerase <= 0;
				end
			2:
				begin
					data_send_finerase <= {1'b1,8'h00,1'b0};
					end_finerase <= 0;
				end
			3:
				begin
					data_send_finerase <= {1'b1,8'h00,1'b0};
					end_finerase <= 0;
				end
			4: 
				begin
					data_send_finerase <= 0;
					end_finerase <= 1;
				end
			default:
				begin
					data_send_finerase <= 0;
					end_finerase <= 0;
				end
			endcase
			else
				end_finerase <= 0;
	 end
	 
endmodule
