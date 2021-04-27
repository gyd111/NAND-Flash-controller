`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:22:09 04/11/2018 
// Design Name: 
// Module Name:    write_flash_state_control 
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
module write_flash_state_control(
	input clk,rst,en_write,
	input en_infopage_write,
//	output reg end_infopage_write,
	
	input [4:0]state,
	input [1:0] write_success,						//д�ɹ���־,����д�����м��״̬�Ĵ���BIT0�ж�д��״����0Ϊδ������1Ϊ�����ɹ���2Ϊ����ʧ�ܣ�������2�������ڣ�
	input [1:0]write_addr_row_error,				//д����������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵��������2�������ڣ�
   	input [23:0]write_addr_row,
	input [1:0] write_time,						// д�Ĵ���
	input en_write_info,						//д��Ϣҳ��־λ
	input en_log_write,                       	//ʹ��дlog��־
	
	output reg [3:0] write_state,
	output reg end_write
	 );
	 
	 reg n,m;
	 
	// reg wait_en_nentpage_write;
	// reg end_wait_en_nentpage_write;
	// reg write_success_r;
	// wire pos_write_success;  //���д�ɹ�������
	
/*	always @(posedge clk or posedge rst)
	begin
		if(rst)
		  begin
		    write_success_r <= 0;	
		  end
		else
		  write_success_r <= write_success[0];		 
   end
	assign pos_write_success = (~write_success_r) & write_success[0];
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		  begin
		    wait_en_nentpage_write <= 0;
		  end
		else
		  begin
		    if(pos_write_success == 1)
		      wait_en_nentpage_write <= 1;
			 else if(end_wait_en_nentpage_write == 1)
			   wait_en_nentpage_write <= 0;
		  end
	end	  
*/
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			write_state <= 0;
			end_write <=0;
			n <= 0;
			
	//		m <= 0;
	//		end_wait_en_nentpage_write <= 0;
		end
		else
		begin
			case(write_state)
			0:									//�ϵ�״̬
				write_state <= 1;
			1:									//����״̬��ÿ��д�������״̬
			begin
				if(en_write == 1)
					write_state <= 2;
				else
					write_state <= 1;
			end
			2:									//��ʼ״̬�����յ�д���������״̬����ʼд��һҳ
			begin
				write_state <= 3; 
			end
			3:									//�жϻ���
			begin
				if(n == 0)					//��ʱһ���������жϣ���Ϊ��ַ��ֵ��ÿ��д�Ŀ�ʼ���ײ�ģ����������һ��ʱ�����ڵ��ӳ�
					n <= 1;
				else
				if(write_addr_row_error == 0)
					write_state <= 3;
				else if(write_addr_row_error == 1)
					write_state <= 4;
				else if(write_addr_row_error == 2)
					write_state <= 5;
			end
			4:									//����д���ܵ�ʵ��
			begin
				n <= 0;
				if(state == 3)					// state3��д���������״̬
					write_state <= 15;
				else
					write_state <= 4;
			end
			5:									//�жϻ�����ָ�ҳΪ����״̬
			begin
				n <= 0;
				write_state <= 2;
			end
			6:									//�ж��Ƿ�д�ɹ�
			begin
			//	end_infopage_write <= 0;
				if(write_success == 0)
					write_state <= 6;
				else if(write_success == 1)
				begin
					if(en_write_info)
						write_state <= 2;
					else 
					   write_state <= 9;	
				end
				else if(write_success == 2)
				begin
					if(en_write_info)
						write_state <= 11;
					else
						write_state <= 10;
				end
				else 
				  write_state <= 6;  
			end
			7:									//��ʼд�ڶ�ҳ
			  begin
				write_state <= 4;
			//	end_wait_en_nentpage_write <= 0;
			  end
			8:									//��ʼд����ҳ
			  begin
				write_state <= 4;
			//	end_wait_en_nentpage_write <= 0;
			  end
			9:	               					//д���
			 begin
				write_state <= 12;
				end_write <=1;
			  // end_infopage_write<=0;
			 end
			10:								//ҳ����дʧ�ܣ�˵���ÿ�Ϊ�µĻ��飬��Ҫд�¸ÿ鹲д�˶���ҳ���ݣ�Ȼ����������д����������
				write_state <= 4;
			11:								//д��Ϣҳʧ�ܣ���ת״̬2����д
				write_state <= 2;
			12:								//д��ɺ��жϸÿ��Ƿ�д�꣬��д����Ҫ����
			begin
				if(write_addr_row[6:0] == 126)
					write_state <= 14;
				else
					write_state <= 13;
			end			
			13:								//����д����
			begin
		     	write_state <= 1;
				end_write <=0;
			end
			14:								//һ��д���������
				write_state <= 13;
			15:								//ÿҳд���ַ+1
				write_state <= 6;
			default:
				write_state <= 0;
			endcase
			end
	end

endmodule
