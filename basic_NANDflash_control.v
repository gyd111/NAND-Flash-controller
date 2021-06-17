`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:38:22 04/03/2018 
// Design Name: 
// Module Name:    basic_NANDflash_control 
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
module basic_NANDflash_control(
	input clk,rst,clk12M,clk24M,								// clk is 6M
	output [4:0] state,											//״̬������֪ͨ�ⲿģ���������ݵ�ʱ��
	input en_write_page,en_read,en_erase_page,			//ʹ���ź�
	output end_write_page,end_read,end_erase_page,		//�����ź�
	
	input [7:0]flash_dataout,									//flash�������
	output [7:0]flash_datain,									//flash��������
	input ready_busy,												//flash����/æµ��־�ź�
	output ce,cle,ale,we,re,								//flash�����ź�
	
	input [7:0] init_bad_block_ram_data,					//��ʼ�������ram����
	input [8:0] init_bad_block_ram_addr,					//��ʼ�������ram��ַ
	input en_init_bad_block_ram,we_init_bad_block_ram, //��ʼ�������ram�Ŀ����ź�
	
	input [7:0] write_data,										//�ⲿ����д��flash������
	input [23:0] write_addr_row,								//�ⲿ�����д��ַ
	output [13:0]write_data_cnt,								//д���������ڿ����ⲿ���������
	output [1:0]write_addr_row_error,						//д����������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	output [1:0]write_success,									//д�ɹ���־,����д�����м��״̬�Ĵ���BIT0�ж�д��״����1Ϊ�����ɹ���0Ϊ����ʧ��
	
	input [23:0] read_addr_row,								//�ⲿ����Ķ���ַ
	output [7:0]read_data,										//����Ĵ�flash�ڶ���������
	output [13:0]read_data_cnt,								//�����ݼ���
	output [1:0]read_addr_row_error,							//������������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	output [1:0]read_data_ECCstate,							//����ECC״̬��0Ϊû��ɼ�⣬1ΪECCУ����ȷ��2ΪECCУ������ǿ���������3ΪECCУ���������Ч
	output [16:0]read_data_change_addr,						//��Ҫ�޸ĵ���������λ�ã�ǰ13λΪ������ֽڵ�ַ����3λΪ��תλΪ���ֽڵ�λ��
//	output read_data_flag,
	
	input [23:0]erase_addr_row,
	output [1:0]erase_addr_row_error,						//��������������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵

	output en_bad_block_renew_transfer,						//��MCU���͸��º�Ļ�����־����
	output [11:0]bad_block_renew_addr,						//�����ַ
	output nandflash_busy_Noresponse
	 );

//*************   state_controlģ��    *************//


//*************    write_flashģ��     *************//
	wire write_complete;								//д��ɱ�־������д�����м��״̬�Ĵ���BIT0�ж�д��״̬��0λû��ɼ�⣬1Ϊ��ɼ�⣨��ɼ�ⲻһ�����������ȷ�ģ�
	wire [11:0] write_bad_block_ram_addr;		//����������ַ
	wire write_bad_block_ram_dataout;			//�������������ݣ�1��ʾ�ÿ�Ϊ���飬0��ʾ�ÿ�Ϊ�ÿ�
	wire write_en_ECCram,write_we_ECCram;		//����ECCram�Ŀ����ź�
	wire [9:0] write_ECCram_addr;					//����ECCram�ĵ�ַ
	wire [7:0] write_ECCram_datain;				//ECCram�����źţ����ڰ�ÿ128B���ɵ�3B��ECC��д��ram
	wire [7:0] write_ECCram_dataout;				//ECCram����źţ�����д��1ҳԭʼ���ݺ󣬰Ѹ�ҳ���ɵ�ECC��д��flash
	wire [7:0]write_flash_datain;					//дģ����������ݣ���flash��IO�ڶԽ�
	wire [7:0]write_flash_dataout;				//дģ����������ݣ���flash��IO�ڶԽӣ����ڶ�״̬�Ĵ���
	wire tWrite;										//д��ͣ��־��ÿд128B��Ҫ��ͣһ��ʱ�����ECC������

	
//*************     read_flashģ��     *************//
	wire [7:0] read_flash_dataout;
	wire [7:0] read_flash_datain;
	wire [11:0] read_bad_block_ram_addr;		//����������ַ
	wire read_bad_block_ram_dataout;				//�������������ݣ�1��ʾ�ÿ�Ϊ���飬0��ʾ�ÿ�Ϊ�ÿ�
	wire read_en_ECCram;								//����ECCram��ʹ���ź�
	wire read_we_ECCram;								//����ECCram��д�����ź�
	wire [9:0] read_ECCram_addr;					//����ECCram�ĵ�ַ
	wire[7:0] read_ECCram_datain;					//ECCram�����źţ����ڰ�ÿ128B���ɵ�3B��ECC��д��ram���Լ���ÿҳ������ECC����д��RAM
	wire [7:0] read_ECCram_dataout;				//ECCram����źţ�����д��1ҳECC��󣬰Ѹ�ҳ���ɵ�ECC���flash������ECC��ȫ�������жԱ�
	wire read_ECC_success;
	wire tRead;											//����ͣ��־��ÿ��128B��Ҫ��ͣһ��ʱ������ECC��


//*************     erase_flashģ��     *************//
	wire [7:0]erase_flash_dataout;				//FLASH��������ݣ�����״̬�Ĵ����ļ��
	wire [7:0] erase_flash_datain;				//����ģ����������������������
	wire [11:0]erase_bad_block_ram_addr;		//����������ַ
	wire erase_bad_block_ram_dataout;			//�������������ݣ�1��ʾ�ÿ�Ϊ���飬0��ʾ�ÿ�Ϊ�ÿ�
	wire [1:0] erase_success;


//*************   bad_block_manageģ��  *************//
	wire end_bad_block_renew;							//����������£�����״̬
	wire we_bad_block_renew;
	wire bad_block_renew_datain;			

//*************    bad_block_ramģ��    *************//
	wire en_bad_block_ram;
	wire we_bad_block_ram;
	wire bad_block_ram_datain;
	wire bad_block_ram_dataout;
	wire bad_block_ram_dataout_reg;
	wire [11:0] bad_block_ram_addr;
	
//*************      ECC_RAMģ��        *************//
	wire en_ECCram,we_ECCram;
	wire [9:0] ECCram_addr;
	wire [7:0] ECCram_datain;
	wire [7:0] ECCram_dataout;
//**************    ���� ��Ҫɾ��  *******************//
    wire en_ecc;
    wire[9:0]add_ecc;
    wire	[6:0]	ECC_cnt;
//debug
//ECC_signa your_instance_name (
//	.clk(clk24M), // input wire clk
//	.probe0(state), // input wire [4:0]  probe0  
//	.probe1(en_ECCram), // input wire [0:0]  probe1 
//	.probe2(we_ECCram), // input wire [0:0]  probe2 
//	.probe3(ECCram_addr), // input wire [9:0]  probe3 
//	.probe4(ECCram_datain), // input wire [7:0]  probe4 
//	.probe5(ECCram_dataout), // input wire [7:0]  probe5
//	.probe6(ECC_cnt)
//);
	assign flash_datain = read_flash_datain | write_flash_datain | erase_flash_datain;
	assign write_flash_dataout = (state == 16) ? flash_dataout : 0; // ���ڶ�״̬�Ĵ�����ʱ��
	assign read_flash_dataout  = (state == 10) ? flash_dataout : 0;	// ���ڶ�flash��ʱ��
	assign erase_flash_dataout = (state == 16) ? flash_dataout : 0; // ���ڶ�״̬�Ĵ�����ʱ��

	assign en_ECCram       = (state == 9) ? write_en_ECCram : (((state == 10) | (state == 18)) ? read_en_ECCram : 0);//����ecc ram ��Ҫ��Ϊ0 
	assign we_ECCram       = (state == 9) ? write_we_ECCram : (((state == 10) | (state == 18)) ? read_we_ECCram : 0);
	assign ECCram_datain   = (state == 9) ? write_ECCram_datain : (((state == 10) | (state == 18)) ? read_ECCram_datain : 0);
	assign write_ECCram_dataout = (state == 9) ? ECCram_dataout : 0;
	assign read_ECCram_dataout  = ((state == 10) | (state == 18)) ? ECCram_dataout : 0;
	assign ECCram_addr     = (state == 9) ? write_ECCram_addr : (((state == 10) | (state == 18)) ? read_ECCram_addr : 0);//����ecc ram ��Ҫ��Ϊ0 

	assign bad_block_ram_addr = (state == 17) ? bad_block_renew_addr : (en_write_page ? write_bad_block_ram_addr : (en_erase_page ? erase_bad_block_ram_addr : (en_read ? read_bad_block_ram_addr : 0)));
	assign en_bad_block_ram = 1;
	assign we_bad_block_ram = we_bad_block_renew;
	assign bad_block_ram_datain = bad_block_renew_datain;
	assign read_bad_block_ram_dataout = en_read ? bad_block_ram_dataout : 0;
	assign write_bad_block_ram_dataout = en_write_page ? bad_block_ram_dataout : 0;
	assign erase_bad_block_ram_dataout = en_erase_page ? bad_block_ram_dataout : 0;
	
	assign bad_block_ram_dataout = (en_write_page | en_erase_page | en_read) ? bad_block_ram_dataout_reg : 0;
   //assign bad_block_ram_dataout = (en_write_page | en_erase_page | en_read) ? (bad_block_ram_addr == 12'h604 ? temp : bad_block_ram_dataout_reg) : 0;
    reg  temp;
    always @(posedge clk24M) begin
        if(bad_block_ram_addr == 12'h604)
            temp    <= 1'b1;
        else
            temp    <= 1'b0;
    end 
//****************************************************//
//    	  		  test mod   							//
//****************************************************//	 
//vio_1 vio_inst_1(
//    .clk(clk24M ),
//    .probe_in0( ECCram_dataout ),
////    .probe_in1(state),
////    .probe_in2(test_nf),
//    .probe_out0( en_ecc ),
//    .probe_out1( add_ecc )
////    .probe_out2( start_w),
////    .probe_out3( start_r),
////    .probe_out4(change_ram)
//);

//****************************************************//
//    	  		  ����״̬�������ź� 							//
//****************************************************//	 

	state_control state_control(
	.rst(rst),
	.ready_busy(ready_busy),
	.clk(clk),
	.clk12M(clk12M),
	.tclk(clk24M),             // ����ʹ�ã�������ila��ʱ���ź�
	.en_erase_page(en_erase_page),
	.en_write_page(en_write_page),
	.en_read(en_read),
	.end_write_page(end_write_page),
	.end_read(end_read),
	.end_erase_page(end_erase_page),
	.state(state),
	.tWrite(tWrite),
	.tRead(tRead),
//	.read_data_flag(read_data_flag),
	.write_data_cnt(write_data_cnt),
	.read_data_cnt(read_data_cnt),
	.erase_success(erase_success),
	.write_complete(write_complete),
	.read_ECC_success(read_ECC_success),
	.erase_addr_row_error(erase_addr_row_error),
	.write_addr_row_error(write_addr_row_error),
	.read_addr_row_error(read_addr_row_error),
	.end_bad_block_renew(end_bad_block_renew),
	.nandflash_busy_Noresponse(nandflash_busy_Noresponse),
	.ce(ce),
	.cle1(cle),
	.ale1(ale),
	.we1(we),
	.re1(re)
	);	

//****************************************************//
//    	  			  дFLASHģ�� 								//
//****************************************************//	 
	
	write_flash write_flash(
	.clk(clk),
	.tclk(clk24M),				// for test 
	.rst(rst),
	.tWrite(tWrite),
	.en_write_page(en_write_page),
	.state(state),
	.write_data_cnt(write_data_cnt),
	.write_flash_datain(write_flash_datain),
	.write_flash_dataout(write_flash_dataout),
	.write_complete(write_complete),
	.write_success(write_success),
	.write_data(write_data),
	.addr_row(write_addr_row),
	.write_addr_row_error(write_addr_row_error),
	.write_bad_block_ram_addr(write_bad_block_ram_addr),
	.write_bad_block_ram_dataout(write_bad_block_ram_dataout),
	.write_en_ECCram(write_en_ECCram),
	.write_we_ECCram(write_we_ECCram),
	.write_ECCram_addr(write_ECCram_addr),
	.write_ECCram_datain(write_ECCram_datain),
	.write_ECCram_dataout(write_ECCram_dataout)
	);

//****************************************************//
//    	  			  ��FLASHģ�� 								//
//****************************************************//	 

	read_flash read_flash(
	.clk(clk),
	.tclk(clk24M),             // ��ʱ�ź�
	.rst(rst),
	.tRead(tRead),
	.en_read(en_read),
	.state(state),
	.read_data_cnt(read_data_cnt),
	.read_flash_dataout(read_flash_dataout),
	.read_flash_datain(read_flash_datain),
	.addr_row(read_addr_row),
	.read_addr_row_error(read_addr_row_error),
	.read_bad_block_ram_addr(read_bad_block_ram_addr),
	.read_bad_block_ram_dataout(read_bad_block_ram_dataout),
	.read_en_ECCram(read_en_ECCram),
	.read_we_ECCram(read_we_ECCram),
	.read_ECCram_addr(read_ECCram_addr),
	.read_ECCram_datain(read_ECCram_datain),
	.read_ECCram_dataout(read_ECCram_dataout),
	.read_ECC_success(read_ECC_success),
	.read_data(read_data),
	.read_data_ECCstate(read_data_ECCstate),
	.read_data_change_addr(read_data_change_addr),
	.ECC_cnt(ECC_cnt)
	);

//****************************************************//
//    	  			  ����FLASHģ�� 							//
//****************************************************//	 

	erase_flash erase_flash(
	.clk(clk),
	.rst(rst),
	.en_erase_page(en_erase_page),
	.state(state),
	.erase_flash_dataout(erase_flash_dataout),
	.erase_flash_datain(erase_flash_datain),
	.erase_addr_row(erase_addr_row),
	.erase_addr_row_error(erase_addr_row_error),
	.erase_bad_block_ram_addr(erase_bad_block_ram_addr),
	.erase_bad_block_ram_dataout(erase_bad_block_ram_dataout),
	.erase_success(erase_success)
	);

//****************************************************//
//    	  				  ��������								//
//****************************************************//	 

	bad_block_manage bad_block_manage(
	.clk(clk),
	.rst(rst),
	.erase_addr_row(erase_addr_row),
	.en_erase_page(en_erase_page),
	.state(state),
	.en_bad_block_renew_transfer(en_bad_block_renew_transfer),
	.end_bad_block_renew(end_bad_block_renew),
	.bad_block_renew_addr(bad_block_renew_addr),
	.we_bad_block_renew(we_bad_block_renew),
	.bad_block_renew_datain(bad_block_renew_datain)
	);

//****************************************************//
//    	  				  �����RAM 								//
//****************************************************//	 

	bad_block_ram bad_block_ram (
  .clka(clk24M), 								// input clka
  .ena(en_init_bad_block_ram), 		// input ena
  .wea(we_init_bad_block_ram), 		// input [0 : 0] wea
  .addra(init_bad_block_ram_addr), 	// input [8 : 0] addra
  .dina(init_bad_block_ram_data), 	// input [7 : 0] dina
  .clkb(clk),							   // input clkb
  .enb(en_bad_block_ram),				// input enb, always be 1
  .web(we_bad_block_ram), 				// input [0 : 0] web
  .addrb(bad_block_ram_addr),			// input [11 : 0] addrb
  .dinb(bad_block_ram_datain), 		// input [0 : 0] dinb
  .doutb(bad_block_ram_dataout_reg) 		// output [0 : 0] doutb
);

//****************************************************//
//    	  			  ECC����RAM 								//
//****************************************************//	 
		
	ECC_RAM ECC_RAM (
  .clka(clk), 					// input clka
  .ena(en_ECCram), 			// input ena
  .wea(we_ECCram), 			// input [0 : 0] wea
  .addra(ECCram_addr), 		// input [9 : 0] addra
  .dina(ECCram_datain), 	// input [7 : 0] dina
  .douta(ECCram_dataout) 	// output [7 : 0] douta
);

endmodule
