`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:44:07 04/03/2018 
// Design Name: 
// Module Name:    erase_flash 
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
module erase_flash(
	input rst,clk,en_erase_page,
	input [4:0]state,
	input [23:0] erase_addr_row, 
	output reg [1:0]erase_addr_row_error,			//����������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	input [7:0]erase_flash_dataout,					//FLASH��������ݣ�����״̬�Ĵ����ļ��
	output [7:0] erase_flash_datain,					//����ģ����������������������
	output [11:0]erase_bad_block_ram_addr,			//����������ַ
	input erase_bad_block_ram_dataout,				//�������������ݣ�1��ʾ�ÿ�Ϊ���飬0��ʾ�ÿ�Ϊ�ÿ�
	output reg [1:0] erase_success
    );


	reg [1:0] n;
	reg m;
//*************     write_write_cmdģ��      *************//
	wire [7:0] cmd_start,cmd_finish,cmd_data;

//*************     write_write_addģ��      *************//
	wire [15:0] addr_column;
	wire [7:0] addr_data;


	assign cmd_start = 8'h60;
	assign cmd_finish = 8'hD0;
	assign addr_column = 16'h0000;
	
	assign erase_flash_datain = en_erase_page ? (addr_data | cmd_data) : 0;
	assign erase_bad_block_ram_addr = erase_addr_row[18:7];
	
	always @(posedge clk or posedge rst)					//д��ַ��ʼ��,����������Լ�ÿ��д��һҳ���Զ�+1
	begin
	if(rst)
	begin
		erase_addr_row_error <= 0;
		m <= 0;
	end
	else
		begin
			if(en_erase_page)
			if(m == 0)
				m <= 1;
			else
			begin
				if(erase_bad_block_ram_dataout)	
						erase_addr_row_error <= 2;
				else
					erase_addr_row_error <= 1;
			end
			else
			begin
				erase_addr_row_error <= 0;
				m <= 0;
			end
		end
	end

	always @(posedge clk or posedge rst)			//��ɲ����������ȡ״̬�Ĵ�������д�ɹ��źŸ�ֵ
	begin
	if(rst)
	begin
		erase_success <= 0;
		n <= 0;
	end
	else
		if(en_erase_page)
		if(state == 16) // state 16 �Ƕ�ȡ״̬�Ĵ���ֵ��״̬
		begin
			if(n < 2)
				n <= n+1;
			else
			begin
				n <= 0;
				if( !erase_flash_dataout[0] )
					erase_success <= 1;
				else
					erase_success <= 2;
			end
		end
		else
			erase_success <= 0;
	end


//****************************************************//
//			 				д����				 						//
//****************************************************//

	write_cmd  erase_write_cmd(	
	.clk(clk),
	.rst(rst),
	.cmd_start(cmd_start),
	.cmd_finish(cmd_finish),
	.cmd_data(cmd_data),
	.state(state)
	);

//****************************************************//
//			 				д��ַ				 						//
//****************************************************//

	write_addr  erase_write_addr(	
	.clk(clk),
	.rst(rst),
	.addr_column(addr_column),
	.addr_row(erase_addr_row),
	.addr_data(addr_data),
	.state(state)
	);

endmodule
