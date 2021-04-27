`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:57:59 04/16/2018 
// Design Name: 
// Module Name:    read_flash_state_control 
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
module read_flash_state_control(
	input clk,rst,en_read,
	input [1:0]read_addr_row_error,						//������������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	input [1:0]read_data_ECCstate,						//����ECC״̬��0Ϊû��ɼ�⣬1ΪECCУ����ȷ��2ΪECCУ������ǿ���������3ΪECCУ���������Ч
	input [1:0]read_page,									//��ҳ������ʾ��ǰ������ҳ��Ϊһ�����ڵ���һҳ
	input date_change_complete,							//����������ɱ�־
	input [4:0] state,
	input 	[1:0]	read_data_useless,
	output reg [3:0] read_state
    );

	reg n;
	reg [1:0] m;
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			read_state <= 0;
			n <= 0;
		end
		else
		case(read_state)
		0:														//�ϵ��ʼ״̬
			read_state <= 1;
		1:														//����״̬��ÿ�ζ��������״̬
			if(en_read)
				read_state <= 2;
			else
				read_state <= 1;
		2:														//��ҳ��ʼ
			read_state <= 3;
		3:														//�жϻ���
			if(n == 0)					//��ʱһ���������жϣ���Ϊ��ַ��ֵ��ÿ��д�Ŀ�ʼ���ײ�ģ����������һ��ʱ�����ڵ��ӳ�
				n <= 1;
			else
				if(read_addr_row_error == 0)
					read_state <= 3;
				else if(read_addr_row_error == 1)
					read_state <= 4;
				else if(read_addr_row_error == 2)
					read_state <= 13;
		4:														//������
			begin
				n <= 0;
				if(state == 18)									// ��ʱ�Ѿ���������������ECC�������� ��Ҫ����ECCУ��
					read_state <= 5;
				else
					read_state <= 4;
			end
		5:														//�ж�ECC�Ƿ����
			if(m < 2)				//�ӳ����������ٽ����жϣ���Ϊ��״̬6�ص�״̬5�����1��ʱ�����ڣ���������ģ����������Ҫ3��ʱ�����ڲ��ܴ����һ�����ECCstate��ֵ�������ʼ��״̬(state == 12)
				m <= m+1;
			else
				if(state == 12)
					read_state <= 9;
				else if(state == 18)
					read_state <= 6;
		6:														//�ж�ECC״̬
		begin	
			m <= 0;
			n <= 0;
			if(read_data_ECCstate == 0)
				read_state <= 6;
			else if(read_data_ECCstate == 1)
				read_state <= 5;
			else if(read_data_ECCstate == 2)
				read_state <= 7;
			else if(read_data_ECCstate == 3)
				read_state <= 8;
		end
		7:														//��������
			if(date_change_complete)
				read_state <= 5;
			else
				read_state <= 7;
		8:														//��¼������Ч��־
				read_state <= 5;
		9:													//	ECC ��ɺ�д��������Ч��Ϣ
				read_state <= 10;
		10:  												// һ��ʱ�����������ж�ǰ4096�����Ƿ���Ч����д����Ч��Ϣ
			read_state	<= 11;						
		11 : 												//һ��ʱ�����������жϺ�4096�����Ƿ���Ч����д����Ч��Ϣ		
			read_state	<= 13;								
		12:													// δʹ��
			read_state <= 13;
		13:													//�����ôζ�
			read_state <= 1;
		default:
			read_state <= 0;
		endcase
	end

endmodule
