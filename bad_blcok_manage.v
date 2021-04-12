`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:44:47 04/03/2018 
// Design Name: 
// Module Name:    bad_blcok_manage 
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
module bad_block_manage(
	input rst,clk,
	input [23:0]erase_addr_row,
	input en_erase_page,
	input [4:0] state,
	
	output reg end_bad_block_renew,							//����������£�����״̬
	output [11:0]bad_block_renew_addr,
	output reg we_bad_block_renew,
	output bad_block_renew_datain,			
	output reg en_bad_block_renew_transfer					//��MCU���͸��º�Ļ�����־�ź�
    );
	 	 
	reg [11:0] bad_block_addr;
	reg [1:0] i;

	assign bad_block_renew_addr = bad_block_addr;
	assign bad_block_renew_datain = (state == 17) ? 1 : 0;

	always @(posedge clk or posedge rst)			//ȷ�������ַ
	begin
		if(rst)
			bad_block_addr <= 0;
		else
			if(state == 17)
			begin
				if(en_erase_page)
				bad_block_addr <= erase_addr_row[18:7];
			end
			else
				bad_block_addr <= 0;
	end
	
	always @(posedge clk or posedge rst)		//��we��ֵ���Ա�֤ÿ��д����ram�����ڵ�ַ�Ѿ�����ֵΪ�����ַ��
	begin
		if(rst)
		begin
			we_bad_block_renew <= 0;
			end_bad_block_renew <= 0;
			en_bad_block_renew_transfer <= 0;
			i<=0;
		end
		else
			if(state == 17)
				if(i < 2)
				begin
					we_bad_block_renew <=0;
					i <= i+1;
				end
				else if(i == 2)
				begin
					we_bad_block_renew <= 1;
					en_bad_block_renew_transfer <= 1;
					i <= 3;
				end
				else
				begin
					end_bad_block_renew <= 1;
					we_bad_block_renew <= 0;
					en_bad_block_renew_transfer <= 0;
				end
			else
			begin
				i <= 0;
				we_bad_block_renew <= 0;
				end_bad_block_renew <= 0;
				en_bad_block_renew_transfer <= 0;
			end
	end

endmodule
