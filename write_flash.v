`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date:    16:43:47 04/03/2018 
// Design Name: 
// Module Name:    write_flash 

module write_flash(
	input clk,rst,tWrite,en_write_page,
	input	tclk,
	input [4:0]state,
	input [13:0]write_data_cnt,						//д���ݼ���
	output [7:0]write_flash_datain,					//дģ����������ݣ���flash��IO�ڶԽ�
	input [7:0]write_flash_dataout,					//дģ����������ݣ���flash��IO�ڶԽӣ����ڶ�״̬�Ĵ���
	output reg [1:0]write_success,					//д�ɹ���־,����д�����м��״̬�Ĵ���BIT0�ж�д��״����0Ϊδ��������1Ϊ�����ɹ���2Ϊ����ʧ��
	output reg write_complete,						//д��ɱ�־������д�����м��״̬�Ĵ���BIT0�ж�д��״̬��0λû��ɼ�⣬1Ϊ��ɼ�⣨��ɼ�ⲻһ�������ʱ��ȷ�ģ�
	
	input [7:0] write_data,							//�ⲿ�����д����	
	input [23:0] addr_row,							//����д��ַ
	output reg [1:0]write_addr_row_error,			//д����������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
		
	output [11:0] write_bad_block_ram_addr,		     //����������ַ
	input write_bad_block_ram_dataout,				 //�������������ݣ�1��ʾ�ÿ�Ϊ���飬0��ʾ�ÿ�Ϊ�ÿ�
	
	output reg write_en_ECCram,write_we_ECCram,	     //����ECCram�Ŀ����ź�
	output reg [9:0] write_ECCram_addr,				 //����ECCram�ĵ�ַ
	output reg [7:0] write_ECCram_datain,			 //ECCram�����źţ����ڰ�ÿ128B���ɵ�3B��ECC��д��ram
	input [7:0] write_ECCram_dataout			     //ECCram����źţ�����д��1ҳԭʼ���ݺ󣬰Ѹ�ҳ���ɵ�ECC��д��flash
    );
	 
	reg [7:0] write_ECC_data;
//*************     write_write_cmdģ��      *************//
	wire [7:0] cmd_start,cmd_finish,cmd_data;

//*************     write_write_addrģ��      *************//
	wire [15:0] addr_column;
	wire [7:0] addr_data;

//*************    write_generate_ECCģ��     *************//
	reg write_ECC_start;			//ECC��ʼ��־λ��Ϊ1ʱ�����ݽ���Ԥ����Ϊ0ʱ���cp��rp
	wire [6:0] writeECC_cnt;		//ECC����������ÿ128�μ�������3B��ECC��
	wire [7:0] write_ECC_cp;		//ECC����У��
	wire [15:0] write_ECC_rp;		//ECC����У��
//	wire write_ECC_out;				//ECC�������־λ����ʱ�ö�ʱ��ȷ��ECC���������ò������źţ����ݷ����ʱ�������ж������Ƿ���Ҫ�ø��źţ�

	reg [1:0]i,j;
	reg [1:0]n;
	reg m;

	assign writeECC_cnt[6:0] = write_data_cnt[6:0];			
	assign cmd_start   = 8'h80;									//��ʼ����80
	assign cmd_finish  = 8'h10;									//��������10
	assign addr_column = 16'h0000;								//�е�ַ�̶�Ϊ0��ÿ�δ�ÿһҳ�Ŀ�ͷ��ʼд
	
	/*
		for test , when write data cnt is 1, reverse the write data's bit 0
	*/
	wire	[7:0]	test_ecc_data;
	assign test_ecc_data = (write_data_cnt == 'd2) ? {write_data[7:1], ~write_data[0]} : write_data;
	// state == 11 ���ϵ��ĵ�һ����λ����
	assign write_flash_datain = (state == 11) ? 8'hff : (en_write_page ? (cmd_data | addr_data | test_ecc_data | write_ECC_data) : 0);  // test ecc data is write data

	always @(posedge clk or posedge rst)
	begin
		if(rst)
			write_ECC_start <= 0;
		else
			if((state == 9) & tWrite & ~(write_data_cnt[13]) )		//������״̬9��tWriteΪ1�Ҽ���ֵС��8K��ʱ��ECC_start��Ϊ1
				write_ECC_start <= 1;
			else
				write_ECC_start <= 0;
	end
	
	assign write_bad_block_ram_addr = addr_row[18:7];	//������߼���Ϊ��ȷ��ram�����״̬ȷʵ�ǵ�ǰ�е�ַ��״̬���������Ϊ�ӳٵ����е�ַ��һ��Ϊ���飬��һ��Ϊ�ÿ�ʱҲ������һ��
	
	always @(posedge clk or posedge rst)					//д��ַ��ʼ��,����������Լ�ÿ��д��һҳ���Զ�+1
	begin
	if(rst)
	begin
		write_addr_row_error <= 0;
		m <= 0;
	end
	else
		begin
			if(en_write_page)
			if(m == 0)
				m <= 1;
			else
			begin
				if(write_bad_block_ram_dataout)	// ����
						write_addr_row_error <= 2;
				else
					write_addr_row_error <= 1;
			end
			else
			begin
				write_addr_row_error <= 0;
				m <= 0;
			end
		end
	end
	
	always @(posedge clk or posedge rst)
	begin
	if(rst)
	begin
		i <= 0;
		j <= 0;
		write_en_ECCram <= 0;
		write_we_ECCram <= 0;
		write_ECCram_addr <= 0;
		write_ECCram_datain <= 0;
		write_ECC_data <= 0;
	end
	else
		if(state == 9)
		if(!write_data_cnt[13])						//�жϼ����Ƿ�С��8K��С��8Kʱ��ECCram��дECC�룬����8Kʱ��ECC�����
		if(!tWrite)
		begin
			write_en_ECCram <= 1;
			if(i < 2)
				i <= i+1;
			else
			begin
			case(j)
			0:
			begin
				write_we_ECCram <= 1;
				write_ECCram_addr <= write_data_cnt[12:7]*3+1;	//�ճ�ram������ʼ�ĵ�ַ������ʱ��ͣ���ڸõ�ַ��
				write_ECCram_datain <= write_ECC_rp[7:0];
				j <= 1;
			end
			1:
			begin
				write_we_ECCram <= 1;
				write_ECCram_addr <= write_data_cnt[12:7]*3+2;
				write_ECCram_datain <= write_ECC_rp[15:8];
				j <= 2;
			end
			2:
			begin
				write_we_ECCram <= 1;
				write_ECCram_addr <= write_data_cnt[12:7]*3+3;
				write_ECCram_datain <= write_ECC_cp[7:0];
				j <= 3;
			end
			3:j <= 3; 			//ÿ����RAMд��3B��ECC����ֹͣ
			endcase
			end
		end
		else
		begin
			write_en_ECCram <= 0;
			write_we_ECCram <= 0;
			write_ECCram_addr <= 0;
			write_ECCram_datain <= 0;
			i <= 0;
			j <= 0;
		end
		else
		begin
			write_ECCram_addr <= write_data_cnt[7:0]+1;		//����ECC��
			write_en_ECCram <= 1;
			write_we_ECCram <= 0;
			write_ECC_data <= write_ECCram_dataout;
		end
		else
		begin
			i <= 0;
			j <= 0;
			write_en_ECCram <= 0;
			write_we_ECCram <= 0;
			write_ECCram_addr <= 0;
			write_ECCram_datain <= 0;
			write_ECC_data <= 0;
		end
	end

	always @(posedge clk or posedge rst)			//���д�������ȡ״̬�Ĵ�������д�ɹ��źŸ�ֵ
	begin
	if(rst)
	begin
		write_success <= 0;
		n <= 0;
		write_complete <= 0;
	end
	else
		if(en_write_page)
		begin
		if(state == 16)
			if(n < 2)
				n <= n+1;
			else
			begin
				if( !write_flash_dataout[0] )
				begin
					write_success <= 1;
					write_complete <= 1;
				end
				else
				begin
					write_success <= 2;
					write_complete <= 1;
				end
			end
		end
		else
		begin
			n <= 0;
			write_success <= 0;
			write_complete <= 0;
		end
	end
//****************************************************//
//			 				д����				 						//
//****************************************************//

	write_cmd  write_write_cmd(	
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

	write_addr  write_write_addr(	
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

	write_generate_ECC write_generate_ECC(
	.prior_data1(write_data),
	.rst(rst),
	.tclk(tclk),
	.clk(clk),
	.ECC_start(write_ECC_start),
	.data_cnt1(writeECC_cnt),
	.cp(write_ECC_cp),
	.rp(write_ECC_rp)
//	.ECC_out(write_ECC_out)
	);

endmodule
