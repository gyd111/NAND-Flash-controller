`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:52:48 04/08/2018 
// Design Name: 
// Module Name:    read_flash_control 
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
module read_flash_control(
	input clk,rst,en_read,
	input [4:0]state,
	
	input [23:0]read_addr_row_reg,
	output reg [23:0] read_addr_row,
	input [7:0]read_data,//�� Flash ������������
	input [13:0]read_data_cnt,								//�����ݼ���
	input [1:0]read_addr_row_error,						//������������������������˿��ַ����õ�ַ�Ƿ�Ϊ����,0Ϊδ������1Ϊ�ÿ飬2Ϊ�黵
	input [1:0]read_data_ECCstate,						//����ECC״̬��0Ϊû��ɼ�⣬1ΪECCУ����ȷ��2ΪECCУ������ǿ���������3ΪECCУ���������Ч
	input [15:0]read_data_change_addr,					//��Ҫ�޸ĵ���������λ�ã�ǰ13λΪ������ֽڵ�ַ����3λΪ��תλΪ���ֽڵ�λ��
	
	input [7:0]read_ram_dataout,
	output [7:0]read_ram_datain,
	output [14:0]read_ram_addr,
	output read_en_ram,read_we_ram
    );
	 
	 reg [1:0] read_page;
	 reg date_change_complete;
	 wire [3:0] read_state;
	 reg 	[1:0]	read_data_useless;
	 reg [6:0]read_addr_reg; 			//����ҳ���жϵĵ�ַ����
	 reg n;
	 
	 reg en_read_reg;
	 wire pos_en_read;
	 
	 reg [7:0]read_ram_datain1;			//�ڶ����ݵĹ���ʱ�����ڶ������ݺ�д��ramʱ����ram��
	 reg [14:0]read_ram_addr1;
	 reg read_en_ram1,read_we_ram1;

	 reg [7:0]read_ram_datain2;			//��������ʱ���ڶ���ram���ݲ�����д��
	 reg [14:0]read_ram_addr2;
	 reg read_en_ram2,read_we_ram2;

	 reg [7:0]read_ram_datain3;			//������Чʱ������ram��256�ֽڴ�д��55
 	 reg [14:0]read_ram_addr3;
 	 reg read_en_ram3,read_we_ram3;
 
	 assign read_en_ram = (read_state == 4) ? read_en_ram1 : read_en_ram2 | read_en_ram3;						//��Ϊ��״̬4�л���״̬5��ʱ��
	 assign read_we_ram = (read_state == 4) ? read_we_ram1 : read_we_ram2 | read_we_ram3;						//���� read_cnt �ĵ�һλ���Ϊ0
	 assign read_ram_addr = (read_state == 4) ? read_ram_addr1 : read_ram_addr2 | read_ram_addr3;			//�������л��Ǹ�ʱ�����ڻ���һ�β���Ҫ��д��
	 assign read_ram_datain = (read_state == 4) ? read_ram_datain1 : read_ram_datain2 | read_ram_datain3;	//���Բ�����������д����������ֱ��������ֵ���
 
	 always @(posedge clk or posedge rst)			//����������Ч��־
	 begin
		if(rst)
			read_data_useless <= 2'd0;
		else
			if(read_state == 8 && ~read_data_change_addr[15])			// ǰ4096�޷�����������Ч
				read_data_useless[0] <= 1'b1;
			else if(read_state == 8 && read_data_change_addr[15])		// ��4096�޷�����������Ч
				read_data_useless[1] <= 1'b1;
			else
				if(read_state == 13)     			// ��������ʱ���read_data_useless �ź�����
					read_data_useless <= 2'd0;
	 end
	 
	 always @(posedge clk or posedge rst)			//�����е�ַ����ֱ�Ӹ�ֵ��Ϊ����ϵײ��ʱ��
	 begin
		if(rst)
			read_addr_row <= 0;
		else
			if(read_state == 2)
				read_addr_row <= read_addr_row_reg;
	 end
	 
	 always @(posedge clk or posedge rst)
	 begin
		if(rst)
			en_read_reg <= 0;
		else
			en_read_reg <= en_read;
	 end
	 
	 assign pos_en_read = en_read & ~en_read_reg;	//����en_read��������
	 
	 always @(posedge clk or posedge rst)				//������ҳ��
	 begin
		if(rst)
			read_page <= 0;
		else
		begin
			if(pos_en_read)
				read_addr_reg <= read_addr_row_reg[6:0];
			else
				if(read_addr_reg < 3)
					read_page <= read_addr_reg;
				else
					read_addr_reg <= read_addr_reg - 3;
		end
	 end
	 
	 always @(posedge clk or posedge rst)	//��8K���ݶ�����д��ram
	 begin
		if(rst)
		begin
			read_ram_datain1 <= 0;
			read_ram_addr1 <= 0;
			read_en_ram1 <= 0;
			read_we_ram1 <= 0;
		end
		else
		begin
			if(read_state == 4)
				if(read_data_cnt[13] == 0)
				begin
					read_en_ram1 <= 1;
					read_we_ram1 <= 1;
					read_ram_datain1 <= read_data;
					read_ram_addr1[12:0] <= read_data_cnt[12:0];
					read_ram_addr1[14:13] <= 0;
				end
				else
				begin
					read_en_ram1 <= 0;
					read_we_ram1 <= 0;
					read_ram_datain1 <= 0;
					read_ram_addr1 <= 0;
				end
			else
			begin
				read_en_ram1 <= 0;
				read_we_ram1 <= 0;
				read_ram_datain1 <= 0;
				read_ram_addr1 <= 0;
			end
		end
	 end
	
	 always @(posedge clk or posedge rst)		//��������Ҫ�޸ģ�����Ҫ�޸ĵ����ݴ�ram�ж������޸ĺ�д��ram
	 begin
		if(rst)
		begin
			read_en_ram2 <= 0;
			read_we_ram2 <= 0;
			read_ram_datain2 <= 0;
			read_ram_addr2 <= 0;
			date_change_complete <= 0;
			n <= 0;
		end
		else
		begin
			if(read_state == 7)
				if(n == 0)
				begin
					read_en_ram2 <= 1;
					read_we_ram2 <= 1;
					read_ram_addr2[12:0] <= read_data_change_addr[15:3];
					read_ram_addr2[14:13] <= 0;
					n <= 1;
				end
				else
					case(read_data_change_addr[2:0])
					3'b000:
					begin
						read_ram_datain2[0] <= ~read_ram_dataout[0];
						read_ram_datain2[7:1] <= read_ram_dataout[7:1];
						date_change_complete <= 1;
					end
					3'b001:
					begin
						read_ram_datain2[0] <= read_ram_dataout[0];
						read_ram_datain2[1] <= ~read_ram_dataout[1];
						read_ram_datain2[7:2] <= read_ram_dataout[7:2];
						date_change_complete <= 1;
					end
					3'b010:
					begin
						read_ram_datain2[1:0] <= read_ram_dataout[1:0];
						read_ram_datain2[2] <= ~read_ram_dataout[2];
						read_ram_datain2[7:3] <= read_ram_dataout[7:3];
						date_change_complete <= 1;
					end
					3'b011:
					begin
						read_ram_datain2[2:0] <= read_ram_dataout[2:0];
						read_ram_datain2[3] <= ~read_ram_dataout[3];
						read_ram_datain2[7:4] <= read_ram_dataout[7:4];
						date_change_complete <= 1;
					end
					3'b100:
					begin
						read_ram_datain2[3:0] <= read_ram_dataout[3:0];
						read_ram_datain2[4] <= ~read_ram_dataout[4];
						read_ram_datain2[7:5] <= read_ram_dataout[7:5];
						date_change_complete <= 1;
					end
					3'b101:
					begin
						read_ram_datain2[4:0] <= read_ram_dataout[4:0];
						read_ram_datain2[5] <= ~read_ram_dataout[5];
						read_ram_datain2[7:6] <= read_ram_dataout[7:6];
						date_change_complete <= 1;
					end
					3'b110:
					begin
						read_ram_datain2[5:0] <= read_ram_dataout[5:0];
						read_ram_datain2[6] <= ~read_ram_dataout[6];
						read_ram_datain2[7] <= read_ram_dataout[7];
						date_change_complete <= 1;
					end
					3'b111:
					begin
						read_ram_datain2[6:0] <= read_ram_dataout[6:0];
						read_ram_datain2[7] <= ~read_ram_dataout[7];
						date_change_complete <= 1;
					end
					endcase
			else
			begin
				n <= 0;
				date_change_complete <= 0;
				read_en_ram2 <= 0;
				read_we_ram2 <= 0;
				read_ram_datain2 <= 0;
				read_ram_addr2 <= 0;
			end
		end
	 end
	 
	 always @(posedge clk or posedge rst)		//������Чʱ��ram��8192 �� 8193 λ��д�� 0x55������д��0x00 
	 begin
		if(rst)
		begin
			read_ram_datain3 <= 0;
			read_ram_addr3 <= 0;
			read_en_ram3 <= 0;
			read_we_ram3 <= 0;
		end
		else
			if(read_state == 10) begin 					// read_state10 д��������Ч��Ϣ
				read_en_ram3 	<= 1;
				read_we_ram3 	<= 1;
				read_ram_addr3	<= 15'd8192;
				if(read_data_useless[0])  				// ǰ 4096 byte ������Ч
					read_ram_datain3 	<= 8'h55;
				else 
					read_ram_datain3 	<= 8'h00;	
			end
			else if(read_state == 11) begin
				read_en_ram3 	<= 1;
				read_we_ram3 	<= 1;
				read_ram_addr3	<= 15'd8193;
				if(read_data_useless[1])  				// �� 4096 byte ������Ч
					read_ram_datain3 	<= 8'h55;
				else 
					read_ram_datain3 	<= 8'h00;				
			end 
			else 
			begin
				read_en_ram3 		<= 0;
				read_we_ram3 		<= 0;
				read_ram_addr3 		<= 0;
				read_ram_datain3	<= 0;
			end
	 end
	 
	 
	 
	 
//****************************************************//
//    	  		  read FLASH״̬���� 								//
//****************************************************//	 

	read_flash_state_control read_flash_state_control(
    .clk(clk), 
    .rst(rst), 
    .en_read(en_read), 
    .read_addr_row_error(read_addr_row_error), 
    .read_data_ECCstate(read_data_ECCstate), 
    .read_page(read_page), 
    .date_change_complete(date_change_complete), 
	 .state(state),
	 .read_data_useless(read_data_useless),
    .read_state(read_state)
    );


endmodule
