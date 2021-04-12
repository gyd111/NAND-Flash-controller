`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:58:56 04/12/2018 
// Design Name: 
// Module Name:    erase_flash_state_control 
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
module erase_flash_state_control(
	input clk,rst,en_erase,end_erase_page,
	input [23:0]erase_addr_finish,erase_addr_row,
	input [1:0]erase_addr_row_error,
	output reg[2:0] erase_state
	);

	reg n;
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			erase_state <= 0;
		else
			case(erase_state)
			0:									//�ϵ��ʼ̬
				erase_state <= 1;
			1:									//����̬
				if(en_erase)
					erase_state <= 2;
				else
					erase_state <= 1;
			2:									//����һҳ��ʼ
				erase_state <= 3;
			3:									//�жϸ�ҳ�Ƿ�Ϊ����
			begin
				if(n == 0)					//��ʱһ���������жϣ���Ϊ��ַ��ֵ��ÿ��д�Ŀ�ʼ���ײ�ģ����������һ��ʱ�����ڵ��ӳ�
					n <= 1;
				else
				if(erase_addr_row_error == 0)
					erase_state <= 3;
				else if(erase_addr_row_error == 1)
					erase_state <= 4;
				else if(erase_addr_row_error == 2)
					erase_state <= 5;
			end
			4:									//�ȴ�������
			begin
				n <= 0;
				if(end_erase_page)
					erase_state <= 5;
				else
					erase_state <= 4;
			end
			5:									//�ж��Ƿ�ȫ���������
			begin
				n <= 0;
				if(erase_addr_row < erase_addr_finish)
					erase_state <= 6;
				else
					erase_state <= 7;
			end
			6:									//����һҳ
				erase_state <= 3;
			7:									//����ȫ�����
				erase_state <= 1;
			default:
				erase_state <= 0;
			endcase
	end

endmodule
