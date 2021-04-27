`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:43:37 04/03/2018 
// Design Name: 
// Module Name:    state_control 
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
module state_control(
	input rst,ready_busy,clk,clk12M,en_erase_page,en_write_page,en_read, // clk is 24M
	output reg end_write_page,end_read,end_erase_page,
	output reg [4:0] state,

	output reg tWrite,tRead,												//��д�����źţ������ź�Ϊ1ʱ���ж�д��ÿ128K���ݶ�д��Ҫ��ͣ��д����һ��ECC,�ô��źſ���
	output reg [13:0] write_data_cnt,read_data_cnt,					//��д�����ź�
//	output reg read_data_flag,												//����־����������״̬10�����ڶ����ݻ����ڶ�ECC�롣

	input [1:0] erase_success,												//���ɹ���־�����ڲ������м��״̬�Ĵ���BIT0�ж�д��״����0Ϊû��ɼ�⣬1Ϊ�����ɹ���2Ϊ����ʧ�ܽ��뻵�����
	input write_complete,													//д��ɱ�־������д�����м��״̬�Ĵ���BIT0�ж�д��״̬��0λû��ɼ�⣬1Ϊ��ɼ�⣨��ɼ�ⲻһ�������ʱ��ȷ�ģ�
	input read_ECC_success,													//�������Ա�ECCУ���������ɱ�־λ����0Ϊû��ɲ�������1��������ɶԶ�����ECC������ɵ�ECC���У�飬���Զ��������ݽ�������.
	input [1:0]erase_addr_row_error,										//����������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	input [1:0]write_addr_row_error,										//д����������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	input [1:0]read_addr_row_error,										//������������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	input end_bad_block_renew,												//���������ɱ�־�ź�

   output reg nandflash_busy_Noresponse,                       //nandflash��busy�ź�����Ӧ��־
	output ce,
	output reg cle1,ale1,we1,re1
    );

	reg [1:0]tADL;										//��ͣʱ�䣬��д���ַ��д���ݿ�ʼǰ��Ҫ��ͣ�������ڣ�Ȼ����ܿ�ʼд����
	reg [3:0]tECC;										//ECC��ͣ��ʱ��ÿ128K���ݶ�д��Ҫ��ͣ��д����һ��ECC
	reg i,j;												//״̬16��״̬9��ʼʱ��ͣһ�����ڣ���Ϊʱ��Ҫ��
	reg [1:0] m,n;										//״̬10��ʼʱ��ͣ��������
	reg [4:0] nandflash_busy_Noresponse_cnt;     //nandflash��busy�ź�����Ӧ����
	
	reg re_flag,k;
	reg cle,ale,we,re;
	
	
	always @(negedge clk or posedge rst)	//nandflash��busy�ź�����Ӧ�ж�
	begin
	  if(rst)
	    begin
		   nandflash_busy_Noresponse_cnt<=0;
		   nandflash_busy_Noresponse<=0;
		 end
	  else
	    begin
		   if(state == 13)
			  begin 
			    if(nandflash_busy_Noresponse_cnt == 15)
				    nandflash_busy_Noresponse<=1;
				 else
				    nandflash_busy_Noresponse_cnt<=nandflash_busy_Noresponse_cnt +1;
			  end
			else
			  begin
			     nandflash_busy_Noresponse_cnt<=0;
		        nandflash_busy_Noresponse<=0;
			  end
		 end
	end
	
	always @(posedge clk12M)	//we��ʱ�������
	begin
		we1 <= we;
		cle1 <= cle;
		ale1 <= ale;
		re1 <= re;
	end
	
	assign ce = 0;
	
   always @ (posedge clk or posedge rst)	
	begin
		if(rst)
		begin
			re_flag <= 0;
			k <= 0;
		end
		else
			if(state == 10)
				if(k == 0)
					k <= 1;
				else
					re_flag <= 1;
			else
			begin
				k <= 0;
				re_flag <= 0;
			end
	end

	always @(clk or rst)	//�Կ����źŽ��и�ֵ
	begin
		if(rst)
		begin
			cle <= 0;
			ale <= 0;
			we <= 0;
			re <= 1;
			n <= 0;
			i <= 0;
		end
		else
			case(state)
			0:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			1:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			2:
				begin
					cle <= 1;
					ale <= 0;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			3:
				begin
					cle <= 1;
					ale <= 0;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			4:
				begin
					cle <= 0;
					ale <= 1;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			5:
				begin
					cle <= 0;
					ale <= 1;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			6:	
				begin
					cle <= 0;
					ale <= 1;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			7:
				begin
					cle <= 0;
					ale <= 1;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			8:
				begin
					cle <= 0;
					ale <= 1;
					we <= clk;
					re <= 1;
					n <= 0;
					i <= 0;
				end
			9:
				begin
					cle <= 0;
					ale <= 0;
					re <= 1;
					i <= 0;
					if(tWrite)
					begin
						if(write_data_cnt == 8192 | write_data_cnt == 8193)		//д��8192��ԭʼ���ݣ��������ECC���������we����Ϊ0�������ڣ�Ŀ���ǵ���ʱ����ΪECC���ram��������뵽flash�����������ڵ�ʱ���
							we <= 0;
						else	if(n < 2)
									n <= n+1;
								else
								begin
									we <= clk;
									n <= 2;
								end
					end
					else if(n > 0)							//��Ϊ�ǵ�ƽ���������μ�������һ��ʱ������
							begin
								n <= n - 1;
								we <= clk;
							end
							else
							begin
								we <= 0;
								n <= 0;
							end
				end
			10:
				begin
					cle <= 0;
					ale <= 0;
					we <= 1;
					i <= 0;
					n <= 0;
					if(tRead & re_flag)
						re <= clk;
					else
						re <= 1;
				end
			11:
				begin
					cle <= 1;
					ale <= 0;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			12:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			13:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			14:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			15:
				begin
					cle <= 1;
					ale <= 0;
					we <= clk;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			16:
				begin
					cle <= 0;
					ale <= 0;
					we <= 1;
					n <= 0;
					if(i)
					begin
						re <= clk;
						i <= 1;
					end
					else
						i <= i+1;
				end
			17:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			18:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			default:
				begin
					cle <= 0;
					ale <= 0;
					we <= 0;
					re <= 1;
					i <= 0;
					n <= 0;
				end
			endcase
	end


	always @(negedge clk or posedge rst)	//״̬��
	begin
	if(rst)
	begin
		state <= 0;
		end_erase_page <= 0;
		end_write_page <= 0;
		end_read <= 0;
		write_data_cnt <= 0;
		read_data_cnt <= 0;
		tADL <= 0;
		tECC <= 0;
		tWrite <= 0;
		tRead <= 0;
//		read_data_flag <= 0;
		j <= 0;
		m <= 0;
	end
	else
		if(ready_busy == 0)
		begin
			case(state)
			3:
				state <= 13;
			11:
				state <= 12;
			12:
				state <= 12;
			13:
				state <= 14;
			14:
				state <= 14;
			default
				state <= state;
			endcase
		end
		else
		begin
			case(state)
			0:										//���ϵ�״̬
				state <= 1;
			1:										//�ϵ��READY
				state <= 11;
			2:										//д��ʼ����
			begin
				if(en_erase_page == 1)
					state <= 6;
				else
					state <= 4;
			end
			3:										//д��������
				state <= 13;
			4:										//д��һ���е�ַ
				state <= 5;
			5:										//д�ڶ����е�ַ
				state <= 6;
			6:										//д��һ���е�ַ
				state <= 7;
			7:										//д�ڶ����е�ַ
				state <= 8;
			8:										//д�������е�ַ
			begin
				tWrite <= 0;
				j <= 0;
				if(en_erase_page == 1)
				begin
					state <= 3;
				end
				else if(en_write_page == 1)
				begin
					if(tADL == 3)
					begin
						state <= 9;
						tADL <= 0;
					end
					else
					begin
						state <= 8;
						tADL <= tADL + 1;
					end
				end
				else if(en_read == 1)
				begin
					state <= 3;
				end				
			end
			9:									//д״̬
			begin
			if(j == 0)
			begin
				j <= 1;					//�ڽ���9״̬�������ͣһ�����ڣ��ڸս���9״̬����tWrite��Ҫ��һ�����ڲ�Ϊ1�����µ�we�ᱣ��Ϊ0��һ������
				tWrite <= 1;
			end	
			else
				if(write_data_cnt < 8384+1)			//����������ٶȱȼ������ٶ���1
					begin	
						if(write_data_cnt <= 8192)							//д����������
						begin
							if(write_data_cnt[6:0] < 7'b1111111)
							begin
								tWrite <= 1;
								state <= 9;
								write_data_cnt <= write_data_cnt + 1;
							end
							else					
							begin
								if(tECC < 7)
								begin
									tECC <= tECC+1;
									tWrite <= 0;
								end
								else
								begin
									tECC <= 0;
									tWrite <= 1;
									write_data_cnt <= write_data_cnt + 1;
								end
							end
						end
						else			//дECC������
						begin
							state <= 9;
							write_data_cnt <= write_data_cnt + 1;
							tWrite <= 1;
						end
					end
				else
				begin
					write_data_cnt <= 0;
					state <= 3;
				end
			end
			10:											//��״̬
			begin
			if(m < 2)
			begin
				m <= m+1;
				tRead <= 1;
//				read_data_flag <= 1;
			end
			else
				if(read_data_cnt < 8384)							//����������ECC������
				begin
				if(read_data_cnt < 8192)							//������������
				begin
							if(read_data_cnt[6:0] < 7'b1111111)
							begin
								tRead <= 1;
								state <= 10;
								read_data_cnt <= read_data_cnt + 1;
							end
							else					
							begin
								if(tECC < 7)
								begin
									tECC <= tECC+1;
									tRead <= 0;
								end
								else
								begin
									tECC <= 0;
									tRead <= 1;
									read_data_cnt <= read_data_cnt + 1;
								end
							end
				end
				else
				begin
					state <= 10;
//					read_data_flag <= 0;
					read_data_cnt <= read_data_cnt+1;
				end
				end
				else			
				begin
					state <= 18;
					read_data_cnt <= 0;
				end
			end
			11:												//д��ʼ��ff����
				state <= 11;
			12:												//����̬�����еĲ������Ӹ�״̬��ʼ��������ص���״̬
			begin												//����Ҫ��end�жϱ���12״̬����Ϊ��ģ��Ϊ�½��ظ�ֵ��ʹ��ģ���������ظ�ֵ�����Կ��Ա�֤endֻ��һ�������һ�ͣ����״̬12
				if(en_erase_page | en_write_page | en_read)
				begin
					if(erase_addr_row_error == 1 | write_addr_row_error == 1 | read_addr_row_error == 1)
						state <= 2;
					else if(read_addr_row_error == 2)
						begin
							state <= 12;
							end_read <= 1;
						end
					else if(write_addr_row_error == 2)
						begin
							state <= 12;
							end_write_page <= 1;
						end
					else if(erase_addr_row_error == 2)
						begin
							state <= 12;
							end_erase_page <= 1;
						end
					else
						state <= 12;
				end
				else
				begin
					end_write_page <= 0;
					end_read <= 0;
					end_erase_page <= 0;
					state <= 12;
				end
			end
			13:												//R/BΪ1�Ŀ���̬�����ڵȴ�RB�ص�0
				state <= 13;
			14:												//R/BΪ0�Ŀ���̬�����ڵȴ�RB�ص�1
			begin
				if(en_erase_page == 1)
					state <= 15;
				else if(en_write_page == 1)
						state <= 15;
				else if(en_read == 1)
						state <= 10;
			end
			15:												//д70����ȥ��״̬�Ĵ���
				state <= 16;
			16:												//��״̬�Ĵ���
			begin
				if(en_write_page)
				begin
					case(write_complete)
					0:
						state <= 16;
					1:
						begin
							state <= 12;
							end_write_page <= 1;
						end
					endcase
				end
				else if(en_erase_page)
							case(erase_success)
							0:
								state <= 16;
							1:
							begin
								end_erase_page <= 1;
								state <= 12;
							end
							2:
								state <= 17;
							endcase
			end
			17:								//������������µĻ��������״̬
			begin
				if(end_bad_block_renew)
				begin
					state <= 12;
					end_erase_page <= 1;
				end
				else
					state <= 17;
			end
			18:								//����ECC���о����Ա�
			begin
				m <= 0;
				case(read_ECC_success)
				0:
					state <= 18;
				1:
				begin
					state <= 12;
					end_read <= 1;
				end
				endcase
			end
			default:
				state <= 0;
			endcase
		end		//ready_busy == 1	
	 end
endmodule
