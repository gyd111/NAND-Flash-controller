`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:12:14 04/08/2018 
// Design Name: 
// Module Name:    NANDflash_control 
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
module NANDflash_control(
	input clk,rst,clk6M,clk12M,
	
	input [31:0]cmd,						//�������ģ����ղ���������������,[31:24]Ϊ���[23:16]Ϊ������[15:0]Ϊ����
	input start_trs,						//����������ź�
	
	input en_read_FPGA,                    //Data_downloadģ������Ķ�ʹ���ź�
	input [23:0] read_addr_FPGA,          //Data_downloadģ������Ķ���ַ
	input [7:0]flash_ram_dataout,
	output [7:0]flash_ram_datain,
	output flash_en_ram,flash_we_ram,
	output reg[14:0]flash_ram_addr,
	
	output inout_flag,							//��ʾflash��io�ں�ʱ���������ʱ����������,0Ϊ���룬1Ϊ���
	output read_flag,								//��ʾflash���ڶ�״̬����Ϊ��״̬ʱFLASH������ram��MCU������������ram����д״̬�ǲ���ͬһ��ram		
	
	input [7:0]flash_dataout,									//flash�������
	output [7:0]flash_datain,									//flash��������
	input ready_busy,												//flash����/æµ��־�ź�
	output ce,cle,ale,we,re,									//flash�����ź�
	
	output en_bad_block_renew_transfer,						//��MCU���͸��º�Ļ�����־����
	output [11:0]bad_block_renew_addr,						//�����ַ
	
	input end_writeAddr_Transfer,
	output en_writeAddr_Transfer,
	output [23:0]write_addr_row,
	
	output end_init_flash_addr,
	output end_erase,
	output flash_cmd_incomplete,
	output nandflash_busy_Noresponse,
	output end_read ,
	
	output wire [4:0]state
	
    );
//*************   command_receiveģ��    *************//
	wire [23:0] erase_addr_start,erase_addr_finish;		//����ģ�����ʼ��ַ�ͽ�����ַ
	wire [23:0] read_addr_row_reg,read_addr_row_reg_1;	//��ģ����е�ַ
	wire en_read_1,en_read;
	wire en_erase;
	wire en_write;
	wire en_log_write;
    
	wire [23:0] init_addr_row;									//дģ��ĳ�ʼ��д��ַ
	wire en_init_flash_addr;
	wire end_write;
	
	wire [7:0] init_bad_block_ram_data;						//��ʼ�������ram����
	wire [8:0] init_bad_block_ram_addr;						//��ʼ�������ram��ַ
	wire en_init_bad_block_ram,we_init_bad_block_ram;	//��ʼ�������ram�Ŀ����ź�
	
	wire en_infopage_write,end_infopage_write;
//*************    read_flash_controlģ��    *************//
	wire [7:0]read_data;
	wire [23:0] read_addr_row;
	
	wire [7:0]read_ram_dataout;
	wire [7:0]read_ram_datain;
	wire [14:0]read_ram_addr;
	wire read_en_ram,read_we_ram;
	
//*************   write_flash_controlģ��    *************//
	wire en_write_page,end_write_page;
	wire [7:0] write_data;
	
	wire write_en_ram;						
	wire [14:0]write_ram_addr;
	wire [7:0]write_ram_dataout;
	
//*************   erase_flash_controlģ��    *************//
	wire en_erase_page,end_erase_page;
	wire [23:0]erase_addr_row;

//************* basic_NANDflash_controlģ��  *************//
	

	wire [13:0]write_data_cnt;
	wire [1:0]write_addr_row_error;						//д����������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	wire [1:0]write_success;								//д�ɹ���־,����д�����м��״̬�Ĵ���BIT0�ж�д��״����1Ϊ�����ɹ���0Ϊ����ʧ��

	wire [13:0]read_data_cnt;								//�����ݼ���
	wire [1:0]read_addr_row_error;						//������������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	wire [1:0]read_data_ECCstate;							//����ECC״̬��0Ϊû��ɼ�⣬1ΪECCУ����ȷ��2ΪECCУ������ǿ���������3ΪECCУ���������Ч
	wire [15:0]read_data_change_addr;					//��Ҫ�޸ĵ���������λ�ã�ǰ13λΪ������ֽڵ�ַ����3λΪ��תλΪ���ֽڵ�λ��								//����־����������״̬10�����ڶ����ݻ����ڶ�ECC�롣

	wire [1:0]erase_addr_row_error;						//��������������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	
	assign flash_en_ram = en_write ? write_en_ram :  read_en_ram ;
	assign flash_we_ram = read_we_ram;
	assign flash_ram_datain = read_ram_datain;
	assign write_ram_dataout = en_write ? flash_ram_dataout : 0;
	assign read_ram_dataout = flash_ram_dataout;
	
	assign inout_flag = (state == 10 | state == 16) ? 1 : 0;
	
//	assign en_read = change_bypass ? en_read_FPGA:en_read_1;     //�޸ģ�ȡ��fpga��ȡ
    assign en_read = en_read_1;
//	assign read_addr_row_reg = change_bypass ? read_addr_FPGA:read_addr_row_reg_1;   //�޸�
    assign read_addr_row_reg = read_addr_row_reg_1;
	assign read_flag = en_read_1;
	
   //***************���Գ����**************//
	always@(negedge clk or posedge rst)
	begin
	  if(rst)
	    flash_ram_addr <=0;
     else
       flash_ram_addr <= en_write ? write_ram_addr :  read_ram_addr;	  
	end
	
//****************************************************//
//    	 			  flash���������� 						//
//****************************************************//	 

	flash_command_receiver flash_command_receiver (
    .clk(clk), 
    .rst(rst), 
    .cmd(cmd), 
    .start_trs(start_trs), 
    .end_erase(end_erase), 
    .end_read(end_read), 
    .en_erase(en_erase), 
    .en_read(en_read_1), 
    .erase_addr_start(erase_addr_start), 
    .erase_addr_finish(erase_addr_finish), 
    .read_addr_row_reg(read_addr_row_reg_1), 
    .en_init_flash_addr(en_init_flash_addr), 
    .end_init_flash_addr(end_init_flash_addr), 
    .init_addr_row(init_addr_row), 
    .init_bad_block_ram_data(init_bad_block_ram_data), 
    .init_bad_block_ram_addr(init_bad_block_ram_addr), 
    .en_init_bad_block_ram(en_init_bad_block_ram), 
    .we_init_bad_block_ram(we_init_bad_block_ram), 
    .end_infopage_write(end_infopage_write), 
    .en_infopage_write(en_infopage_write),
	 .en_write(en_write),
	 .end_write(end_write),
	 .flash_cmd_incomplete(flash_cmd_incomplete),
	 .en_log_write(en_log_write)
    );
	 
//****************************************************//
//    	 				 ��flash����  							//
//****************************************************//	 

	read_flash_control read_flash_control(
    .clk(clk6M), 
    .rst(rst), 
    .en_read(en_read), 
    .state(state), 
    .read_addr_row_reg(read_addr_row_reg), 
    .read_addr_row(read_addr_row), 
    .read_data(read_data), 
    .read_data_cnt(read_data_cnt), 
    .read_addr_row_error(read_addr_row_error), 
    .read_data_ECCstate(read_data_ECCstate), 
    .read_data_change_addr(read_data_change_addr), 
    .read_ram_dataout(read_ram_dataout), 
    .read_ram_datain(read_ram_datain), 
    .read_ram_addr(read_ram_addr), 
    .read_en_ram(read_en_ram), 
    .read_we_ram(read_we_ram)
    );
//****************************************************//
//    	 				 ����flash����  						//
//****************************************************//	 

	erase_flash_control	erase_flash_control(
    .clk(clk6M), 
    .rst(rst), 
    .en_erase(en_erase), 
    .end_erase_page(end_erase_page), 
    .end_erase(end_erase), 
    .en_erase_page(en_erase_page), 
    .erase_addr_row_error(erase_addr_row_error), 
    .erase_addr_start(erase_addr_start), 
    .erase_addr_finish(erase_addr_finish), 
    .erase_addr_row(erase_addr_row)
    );

//****************************************************//
//    	 				 дflash����  						//
//****************************************************//	 

	write_flash_control	write_flash_control(
    .clk(clk6M), 
    .rst(rst), 
    .en_write(en_write), 
    .end_write_page(end_write_page), 
    .en_write_page(en_write_page), 
    .end_write(end_write),
	 .en_infopage_write(en_infopage_write),
	 .end_infopage_write(end_infopage_write),
    .state(state), 
    .write_data_cnt(write_data_cnt), 
    .write_data(write_data), 
    .write_addr_row(write_addr_row), 
    .write_addr_row_error(write_addr_row_error), 
    .write_success(write_success), 
    .init_addr_row(init_addr_row), 
    .en_init_flash_addr(en_init_flash_addr), 
    .end_init_flash_addr(end_init_flash_addr), 
    .write_en_ram(write_en_ram), 
    .write_ram_addr(write_ram_addr), 
    .write_ram_dataout(write_ram_dataout),
	 .en_writeAddr_Transfer(en_writeAddr_Transfer),
	 .end_writeAddr_Transfer(end_writeAddr_Transfer),
	 .en_log_write(en_log_write)
    );


//****************************************************//
//    	 		  ����flashʵ�ֻ������� 						//
//****************************************************//	 

	basic_NANDflash_control basic_NANDflash_control (
    .clk(clk6M), 
    .rst(rst), 
    .clk12M(clk12M), 
	 .clk24M(clk),
    .state(state), 
    .en_write_page(en_write_page), 
    .en_read(en_read), 
    .en_erase_page(en_erase_page), 
    .end_write_page(end_write_page), 
    .end_read(end_read), 
    .end_erase_page(end_erase_page), 
    .flash_dataout(flash_dataout), 
    .flash_datain(flash_datain), 
    .ready_busy(ready_busy), 
    .ce(ce), 
    .cle(cle), 
    .ale(ale), 
    .we(we), 
    .re(re), 
    .init_bad_block_ram_data(init_bad_block_ram_data), 
    .init_bad_block_ram_addr(init_bad_block_ram_addr), 
    .en_init_bad_block_ram(en_init_bad_block_ram), 
    .we_init_bad_block_ram(we_init_bad_block_ram), 
    .write_data(write_data), 
    .write_addr_row(write_addr_row), 
    .write_data_cnt(write_data_cnt), 
    .write_addr_row_error(write_addr_row_error), 
    .write_success(write_success), 
    .read_addr_row(read_addr_row), 
    .read_data(read_data), 
    .read_data_cnt(read_data_cnt), 
    .read_addr_row_error(read_addr_row_error), 
    .read_data_ECCstate(read_data_ECCstate), 
    .read_data_change_addr(read_data_change_addr), 
//	 .read_data_flag(read_data_flag),
    .erase_addr_row(erase_addr_row), 
    .erase_addr_row_error(erase_addr_row_error), 
    .en_bad_block_renew_transfer(en_bad_block_renew_transfer), 
    .bad_block_renew_addr(bad_block_renew_addr),
	 .nandflash_busy_Noresponse(nandflash_busy_Noresponse)
    );

endmodule
