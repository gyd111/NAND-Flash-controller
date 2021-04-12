`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:52:40 04/08/2018 
// Design Name: 
// Module Name:    write_flash_control 
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
module write_flash_control(
	input clk,rst,en_write,end_write_page,
	output reg en_write_page,
	output end_write,
	input en_infopage_write,
	input en_log_write,
	output end_infopage_write,
	
	
	input [4:0]state,
	input [13:0]write_data_cnt,					//д���������ڿ�������flashģ�������
	output [7:0] write_data,						//д����
	output reg [23:0] write_addr_row,			//д��ַ
	input [1:0]write_addr_row_error, 			//д����������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵��������2�������ڣ�
	input [1:0]write_success,						//д�ɹ���־,����д�����м��״̬�Ĵ���BIT0�ж�д��״����0Ϊδ������1Ϊ�����ɹ���2Ϊ����ʧ�ܣ�������2�������ڣ�
	
	input [23:0] init_addr_row,					//�ϵ������õ�ַ����־д�������׵�ַ���Ժ�����Ӹõ�ַ��ʼд
	input en_init_flash_addr,						//MCU��FPGA���ͳ�ʼ����ַ��FPGA������ʹ���ź�
	output reg end_init_flash_addr,				//��ɳ�ʼ����ַ��Ľ����ź�

	output write_en_ram,								//�����������ݼ���Ϣ����ram
	output [14:0]write_ram_addr,
	input [7:0]write_ram_dataout,
	
	input end_writeAddr_Transfer,
	output reg en_writeAddr_Transfer
    );

	reg n;
	reg [1:0]write_time;								//д���������ڿ���һ������д��ҳ����
	reg [7:0]write_page_info;						//д���127ҳ�ĸÿ�дҳ����Ϣ
	wire [7:0]write_ram_data_reg,write_page_info_reg;
	
	wire [3:0]write_state;
	reg en_write_info;
	
	
	assign write_data = en_write_info ? write_page_info_reg : write_ram_data_reg;
	assign write_ram_addr[14:13] = write_time[1:0];
	assign write_ram_addr[12:0] = (write_data_cnt[13] == 0) ? write_data_cnt[12:0] : 0;
	assign write_ram_data_reg = (state == 9) ? ( (write_data_cnt[13] == 0) ? write_ram_dataout : 8'h00) : 8'h00;
	assign write_page_info_reg = (state == 9) ? ( (write_data_cnt[13] == 0) ?   write_page_info  : 8'h00) : 8'h00;
	assign write_en_ram = (state == 9) ? 1 : 0;
	
//	assign end_write = (write_state == 13) ? 1 : 0;
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			en_writeAddr_Transfer <= 0;
		else
		begin
			if(end_writeAddr_Transfer)
				en_writeAddr_Transfer <= 0;
			else if(write_state == 13)
				en_writeAddr_Transfer <= 1;
		end
	end
	
	
	always @(posedge clk or posedge rst)	//��д������ֵ
	begin
		if(rst)
			write_time <= 0;
		else
		begin
			if(write_state == 2)
				write_time <= 0;
			else if(write_state == 7)
				write_time <= 1;
			else if(write_state == 8)
				write_time <= 2;
		end
	end
	
	always @(posedge clk or posedge rst)			//��д1��2��3ҳ����Ϣҳ��ʼ״̬ʱ��д��ҳʹ��Ϊ1��������д��ҳ��־Ϊ1���߼�⵽����ʱд��ҳʹ��Ϊ0
	begin
		if(rst)
			en_write_page <= 0;
		else
		begin
			if(write_state == 5 | end_write_page)
				en_write_page <= 0;
			else if(write_state == 2 | write_state == 7 | write_state == 8 |write_state == 10)
					en_write_page <= 1;
		end
	end
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			en_write_info <= 0;
		else
			if(write_state == 10)
				en_write_info <= 1;
			else	if(write_state == 2)
				en_write_info <= 0;
	end
	
	always @(posedge clk or posedge rst)		//���ڿ��Ƶ�����״̬6��д��Ϣҳ�ɹ�������ֻ����һ��
	begin
		if(rst)
			n<=0;
		else
			if(write_state == 6)
				n <= 1;
			else if(write_state == 8)
				n <= 0;
	end
	
	always @(posedge clk or posedge rst)					//����дҳ��ַ
	begin
		if(rst)
		  begin
		  	 write_addr_row <= 0;
			 end_init_flash_addr <= 0;
		  end
		else
			begin
			   if((end_init_flash_addr ==1)&&(en_init_flash_addr==0))
				  begin
				    end_init_flash_addr <= 0; 
				  end
				else
				  begin
				    if(en_init_flash_addr)					//��ַ��ʼ��
			         begin
		   		     write_addr_row <= init_addr_row;	//��ȥ1����Ϊ����ʼһ��д��ʱ��ַ��++
					     end_init_flash_addr <= 1;
				      end			 
				    else
				     begin
					   if(write_state == 15)								//д����ַ++
						   write_addr_row <= write_addr_row + 1;
					   else if(write_state == 5 | write_state == 14 )			//��⵽����/д��127ҳ���������
						  begin
							 write_addr_row[18:7] <= write_addr_row[18:7]+1;
							 write_addr_row[6:0] <= 0;
						  end
					   else if(write_state == 6 & en_write_info)					//д����Ϣҳ�ҳɹ�������������
						  if(n == 0)
						   begin
								write_addr_row[18:7] <= write_addr_row[18:7]+1;
								write_addr_row[6:0] <= 0;
						   end
					   else if(write_state == 10)								//��Ҫд��Ϣҳʱ�����ÿ�127ҳ
						  begin
						   write_addr_row[18:7] <= write_addr_row[18:7];
							write_addr_row[6:0] <= 127;
						  end
						else
						 write_addr_row <= write_addr_row; 
				     end
				  end
			end
	end
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			write_page_info <= 0;
		else
			if(write_state == 10)
				write_page_info <= write_addr_row[6:0];
		 //     write_page_info <= 8'h55;
	end
	
	
	
//****************************************************//
//    	  		  дFLASH״̬���� 								//
//****************************************************//	 

	write_flash_state_control write_flash_state_control(
    .clk(clk), 
    .rst(rst), 
    .en_write(en_write), 
	 .en_infopage_write(en_infopage_write),
 // .end_infopage_write(end_infopage_write),
    .state(state), 
    .write_success(write_success), 
    .write_addr_row_error(write_addr_row_error), 
    .write_addr_row(write_addr_row), 
    .write_time(write_time), 
    .en_write_info(en_write_info), 
    .write_state(write_state),
	 .end_write(end_write),
	 .en_log_write(en_log_write)
    );
	 
	 
endmodule
