`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:43:55 04/03/2018 
// Design Name: 
// Module Name:    read_flash 
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
 module read_flash(
	input clk,rst,tRead,
	input en_read,
	input [4:0] state,
	input [13:0] read_data_cnt,
	input [7:0] read_flash_dataout,
	output [7:0] read_flash_datain,
	
	input [23:0] addr_row,
	output reg [1:0]read_addr_row_error,		//������������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
		
	output [11:0] read_bad_block_ram_addr,		//����������ַ
	input read_bad_block_ram_dataout,			//�������������ݣ�1��ʾ�ÿ�Ϊ���飬0��ʾ�ÿ�Ϊ�ÿ�
	
	output read_en_ECCram,							//����ECCram��ʹ���ź�
	output reg read_we_ECCram,						//����ECCram��д�����ź�
	output [9:0] read_ECCram_addr,				//����ECCram�ĵ�ַ
	output reg [7:0] read_ECCram_datain,		//ECCram�����źţ����ڰ�ÿ128B���ɵ�3B��ECC��д��ram���Լ���ÿҳ������ECC����д��RAM
	input [7:0] read_ECCram_dataout,				//ECCram����źţ�����д��1ҳECC��󣬰Ѹ�ҳ���ɵ�ECC���flash������ECC��ȫ�������жԱ�
	output reg read_ECC_success,
	
	output [7:0]read_data,
	
	output reg [1:0]read_data_ECCstate,			//����ECC״̬��0Ϊû��ɼ�⣬1ΪECCУ����ȷ��2ΪECCУ������ǿ���������3ΪECCУ���������Ч
	output reg [15:0]read_data_change_addr		//��Ҫ�޸ĵ���������λ�ã�ǰ13λΪ������ֽڵ�ַ����3λΪ��תλΪ���ֽڵ�λ��
    );
	 
	 reg read_en_ECCram_write,read_en_ECCram_read;
	 reg m;
	 reg [1:0] i,j;
	 reg [9:0] ECCram_addr1_reg,ECCram_addr2_reg;				//��ECC�Ƚϵ�ʱ���¼ram��ַ����Ϊ����ECC�����ͬһ��ram�У���Ҫ�������Ĵ�����¼����ECC�뵱ǰ�ĵ�ַ
	 reg [3:0] ECCcompare_state;										//��ECC�Ƚϵ�ʱ����м�����ǰ6��״̬��ram���ȡ���ݣ��������������ECC����бȽ�
	 reg [23:0] read_ECC_data1,read_ECC_data2;					//������ECC�����飬�������бȽϡ�ECC1Ϊ��������������ݣ�ECC2Ϊ���������ݣ�����������ݲ�һ�£���Ҫ����ECC2���޸�
	 reg [23:0] ECC_compare_reg;										//������������ECC��������õ��Ľ��,�����ж�У����
	 reg [9:0] ECC_compare1,ECC_compare2;							//���õ���ECCУ��ֵ�����õĲ��֣��Ӹߵ��ͷֱ�Ϊcp5,cp3,cp1,rp13,rp11,rp9,rp7,rp5,rp3,rp1
	 reg [6:0] ECC_cnt;													//ECC��������������ECC�ȽϵĹ����м�¼���е��ڼ���ECC��ıȽ�
	 reg [9:0] read_ECCram_addr_write,read_ECCram_addr_read;	//��/дʱ����ECCram�ĵ�ַ
	 
//*************     read_write_cmdģ��      *************//
	wire [7:0] cmd_start,cmd_finish,cmd_data;

//*************     read_write_addrģ��     *************//
	wire [15:0] addr_column;
	wire [7:0] addr_data;

//*************    read_generate_ECCģ��    *************//
	reg read_ECC_start;			//ECC��ʼ��־λ��Ϊ1ʱ�����ݽ���Ԥ����Ϊ0ʱ���cp��rp
	wire [6:0] readECC_cnt;		//ECC����������ÿ128�μ�������3B��ECC��
	wire [7:0] read_ECC_cp;		//ECC����У��
	wire [15:0] read_ECC_rp;	//ECC����У��
//	wire write_ECC_out;			//ECC�������־λ����ʱ�ö�ʱ��ȷ��ECC���������ò������źţ����ݷ����ʱ�������ж������Ƿ���Ҫ�ø��źţ�

	assign read_data = read_flash_dataout;
	
	assign readECC_cnt[6:0] = read_data_cnt[6:0];			
	assign cmd_start = 8'h00;										//��ʼ����00
	assign cmd_finish = 8'h30;										//��������30
	assign addr_column = 16'h0000;								//�е�ַ�̶�Ϊ0��ÿ�δ�ÿһҳ�Ŀ�ͷ��ʼ��
		
	assign read_flash_datain = en_read ? (cmd_data | addr_data) : 0;
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			read_ECC_start <= 0;
		else
			if( (state == 10) & tRead & ~(read_data_cnt[13]) )		//������״̬10��tReadΪ1�Ҽ���ֵС��8K��ʱ��ECC_start��Ϊ1
				read_ECC_start <= 1;
			else
				read_ECC_start <= 0;
	end
	assign read_bad_block_ram_addr = addr_row[18:7];	//������߼���Ϊ��ȷ��ram�����״̬ȷʵ�ǵ�ǰ�е�ַ��״̬���������Ϊ�ӳٵ����е�ַ��һ��Ϊ���飬��һ��Ϊ�ÿ�ʱҲ������һ��
	
	always @(posedge clk or posedge rst)					//д��ַ��ʼ��,����������Լ�ÿ��д��һҳ���Զ�+1
	begin
	if(rst)
	begin
		m <= 0;
		read_addr_row_error <= 0;
	end
	else
		begin
			if(en_read)
			begin
				if(read_bad_block_ram_dataout)		
				if(m == 0)
					m <= 1;
				else
				begin
					m <= 0;
					read_addr_row_error <= 2;
				end
				else
					read_addr_row_error <= 1;
			end
			else
				read_addr_row_error <= 0;
		end
	end

	assign read_ECCram_addr = (state == 10) ? read_ECCram_addr_write : ((state == 18) ? read_ECCram_addr_read : 0);
	assign read_en_ECCram = (state == 10) ? read_en_ECCram_write : ((state == 18) ? read_en_ECCram_read : 0);
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			i <= 0;
			j <= 0;
			read_en_ECCram_write <= 0;					//ECCramʹ��
			read_we_ECCram <= 0;					//ECCramдʹ��
			read_ECCram_addr_write <= 0;		//ECCram��ַ
			read_ECCram_datain <= 0;			//�����ECCram�е�ECC�룬��Ϊ���֣�һ����ÿ��128B���ݲ���3B�ģ���һ���Ǵ�flash�������
		end
		else
		begin
			if(state == 10)						//��״̬Ϊ10��������ram���ECC��Ĺ���
			begin
				read_ECCram_addr_write[9] <= read_data_cnt[13];
				if(!read_data_cnt[13])			//��ECCram��д�����Ŷ����ݲ�����ECC����
					if(!tRead)
					begin
						read_en_ECCram_write <= 1;
						if(i < 2)
						i <= i+1;
						else
						case(j)
						0:
						begin
							read_we_ECCram <= 1;
							read_ECCram_addr_write[8:0] <= read_data_cnt[12:7]*3+1;	//�ճ�ram������ʼ�ĵ�ַ������ʱ��ͣ���ڸõ�ַ��
							read_ECCram_datain <= read_ECC_rp[7:0];
							j <= 1;
						end
						1:
						begin
							read_we_ECCram <= 1;
							read_ECCram_addr_write[8:0] <= read_data_cnt[12:7]*3+2;
							read_ECCram_datain <= read_ECC_rp[15:8];
							j <= 2;
						end
						2:
						begin
							read_we_ECCram <= 1;
							read_ECCram_addr_write[8:0] <= read_data_cnt[12:7]*3+3;
							read_ECCram_datain <= read_ECC_cp[7:0];
							j <= 3;
						end
						3:j <= 3; 			//ÿ����RAMд��3B��ECC����ֹͣ
						endcase
					end
					else
					begin
						read_en_ECCram_write <= 0;
						read_we_ECCram <= 0;
						read_ECCram_addr_write <= 0;
						read_ECCram_datain <= 0;
						i <= 0;
						j <= 0;
					end
				else									//��ECCram��д���flash������ECC����
				begin
					read_en_ECCram_write <= 1;
					read_we_ECCram <= 1;
					read_ECCram_addr_write[8:0] <= read_data_cnt[8:0]+1;	//�ճ���ʼ��ַ
					read_ECCram_datain <= read_flash_dataout;
				end
			end
			else
			begin
				read_en_ECCram_write <= 0;
				read_we_ECCram <= 0;
				read_ECCram_addr_write <= 0;
				read_ECCram_datain <= 0;
			end
		end
	end
	
	always @(posedge clk or posedge rst)	//��״̬18�£�������ECC���ECCram�ж��������бȽ�
	begin
		if(rst)
		begin
			read_ECC_data1 <= 0;					//��ram������������������ECC��,�Ӹߵ��ͷֱ�Ϊcp,rp2,rp1
			read_ECC_data2 <= 0;					//��ram������Ĵ�flash�������ECC��
			read_ECC_success <=0 ;				//ECC������ɱ�־�ź�
			ECCram_addr1_reg <= 1;				//ECC�Ƚ��еĵ�ַ1
			ECCram_addr2_reg <= 10'b1000_0000_01;				//ECC�Ƚ��еĵ�ַ2
			ECCcompare_state <= 0;				//ECC�Ƚ�״̬
			ECC_cnt <= 0;							//ECC������
			read_ECCram_addr_read <= 0;			//ECCram��ַ
			read_en_ECCram_read <= 0;			//ECCramʹ���ź�
			ECC_compare1 <= 0;
			ECC_compare2 <= 0;
			read_data_ECCstate <= 0;
			read_data_change_addr <= 0;
		end
		else
		begin
			if(state == 18)
			begin
			if(ECC_cnt < 64)
			begin
				read_en_ECCram_read <=1;
				read_ECC_success <= 0;
				case(ECCcompare_state)
				0:
				begin
					ECCcompare_state <= 1;							//��ȡECCram�ĵ�ַ���и�ֵ�����������ECC���rp1
					read_ECCram_addr_read <= ECCram_addr1_reg;
					ECCram_addr1_reg <= ECCram_addr1_reg+1;
				end
				1:
				begin
					ECCcompare_state <= 2;							//��ַ���Ϊrp2
					read_ECCram_addr_read <= ECCram_addr1_reg;
					ECCram_addr1_reg <= ECCram_addr1_reg+1;
				end
				2:
				begin
					ECCcompare_state <= 3;							//��ַ���Ϊcp������Ϊrp1
					read_ECCram_addr_read <= ECCram_addr1_reg;
					ECCram_addr1_reg <= ECCram_addr1_reg+1;
					read_ECC_data1[7:0] <= read_ECCram_dataout;
				end
				3:
				begin
					ECCcompare_state <= 4;							//��ַ���Ϊ��flash������ECC���rp1������Ϊrp2
					read_ECCram_addr_read <= ECCram_addr2_reg;
					ECCram_addr2_reg <= ECCram_addr2_reg+1;
					read_ECC_data1[15:8] <= read_ECCram_dataout;
				end
				4:
				begin
					ECCcompare_state <= 5;							//��ַ���Ϊ��flash������ECC���rp2������Ϊ���������cp
					read_ECCram_addr_read <= ECCram_addr2_reg;
					ECCram_addr2_reg <= ECCram_addr2_reg+1;
					read_ECC_data1[23:16] <= read_ECCram_dataout;
				end
				5:
				begin
					ECCcompare_state <= 6;							//��ַ���Ϊ��flash������ECC���cp������Ϊ��flash������ECC���rp1
					read_ECCram_addr_read <= ECCram_addr2_reg;
					ECCram_addr2_reg <= ECCram_addr2_reg+1;
					read_ECC_data2[7:0] <= read_ECCram_dataout;
				end
				6:
				begin
					ECCcompare_state <= 7;						//����Ϊ��flash������ECC���rp2
					read_ECC_data2[15:8] <= read_ECCram_dataout;
				end
				7:														//����Ϊ��flash������ECC���cp
				begin
					read_ECC_data2[23:16] <= read_ECCram_dataout;
					ECCcompare_state <= 8;
				end
				8:
				begin
					ECCcompare_state <= 9;							//�Ի�õ�����ECC��������
					ECC_compare_reg <= (read_ECC_data1 & ~read_ECC_data2)|(~read_ECC_data1 & read_ECC_data2);
				end
				9: 
				begin														//�����õĲ������
					ECCcompare_state <= 10;
					ECC_compare1[9] <= ECC_compare_reg[21];
					ECC_compare1[8] <= ECC_compare_reg[19];
					ECC_compare1[7] <= ECC_compare_reg[17];
					ECC_compare1[6] <= ECC_compare_reg[13];
					ECC_compare1[5] <= ECC_compare_reg[11];
					ECC_compare1[4] <= ECC_compare_reg[9];
					ECC_compare1[3] <= ECC_compare_reg[7];
					ECC_compare1[2] <= ECC_compare_reg[5];
					ECC_compare1[1] <= ECC_compare_reg[3];
					ECC_compare1[0] <= ECC_compare_reg[1];
					ECC_compare2[9] <= ECC_compare_reg[20];
					ECC_compare2[8] <= ECC_compare_reg[18];
					ECC_compare2[7] <= ECC_compare_reg[16];
					ECC_compare2[6] <= ECC_compare_reg[12];
					ECC_compare2[5] <= ECC_compare_reg[10];
					ECC_compare2[4] <= ECC_compare_reg[8];
					ECC_compare2[3] <= ECC_compare_reg[6];
					ECC_compare2[2] <= ECC_compare_reg[4];
					ECC_compare2[1] <= ECC_compare_reg[2];
					ECC_compare2[0] <= ECC_compare_reg[0];
				end
				10:
				begin														
					if(ECC_compare1 == ~ECC_compare2 | (ECC_compare1 == 0 & ECC_compare2 == 0))	//�ж��Ƿ�Ϊ��Ч����
					begin
					if((ECC_compare1 == 0)&(ECC_compare2 == 0) )					//�ж����ֵ�Ƿ���ȷ��������ȷ����ram��ַ���и�ֵ�����Ҫ�޸ĵ�ֵ�ĵ�ַ
					begin
						ECCcompare_state <= 11;
						ECC_cnt <= ECC_cnt+1;
						ECC_compare_reg <= 0;
						ECC_compare1 <= 0;
						read_data_ECCstate <= 1;
					end
					else
					begin
						read_data_change_addr[15:10] <= ECC_cnt;
						read_data_change_addr[9:3] <= ECC_compare1[6:0];
						read_data_change_addr[2:0] <= ECC_compare1[9:7];
						read_data_ECCstate <= 2;
						ECCcompare_state <= 11;
					end
					end
					else
					begin
						read_data_ECCstate <= 3;				
						ECCcompare_state <= 11;
					end
				end
				11:
				begin												//�����ô�ECC������������һ��ECC�������ж�
					ECCcompare_state <= 0;
					ECC_cnt <= ECC_cnt+1;
					ECC_compare_reg <= 0;
					ECC_compare1 <= 0;
					ECC_compare2 <= 0;
					read_data_ECCstate <= 0;
					read_data_change_addr <= 0;
				end
				default:
					ECCcompare_state <= 0;
				endcase
			end
			else if(ECC_cnt == 64)
					begin
						ECC_cnt <= 65;
						read_en_ECCram_read <= 0;
						read_ECC_success <= 1;
						read_ECC_data1 <= 0;					
						read_ECC_data2 <= 0;					
						ECCram_addr1_reg <= 1;				
						ECCram_addr2_reg <= 10'b1000_0000_01;				
						ECCcompare_state <= 0;				
						read_ECCram_addr_read <= 0;
					end
					else
						read_ECC_success <= 0;
			end
		else
			ECC_cnt <= 0;
		end
	end
	
//****************************************************//
//			 				д����				 						//
//****************************************************//

	write_cmd  read_write_cmd(	
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

	write_addr  read_write_addr(	
	.clk(clk),
	.rst(rst),
	.addr_column(addr_column),
	.addr_row(addr_row),
	.addr_data(addr_data),
	.state(state)
	);
	
//****************************************************//
//			 				����ECC��			 						//
//****************************************************//

	read_generate_ECC read_generate_ECC(
	.prior_data1(read_data),
	.rst(rst),
	.clk(clk),
	.ECC_start(read_ECC_start),
	.data_cnt1(readECC_cnt),
	.cp(read_ECC_cp),
	.rp(read_ECC_rp)
//	.ECC_out(write_ECC_out)
	);

endmodule
