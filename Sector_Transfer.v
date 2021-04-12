`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:15:11 12/14/2015 
// Design Name: 
// Module Name:    Scter_Transfer 
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
module Scter_Transfer(
	input clk,
	input rst,
	input clk_div16,
	input [3:0] binary_sct_addr,
	
	output reg out_uart
    );
	 
	
	reg en; //����ʹ��
	reg clk_50k;
	reg [3:0] binary_sct_addr_r;
	reg [4:0] clk_div_cnt;
	reg [2:0] out_cnt;
	wire [4:1] gray_sct_addr; //Ϊ���㷢���߼��ı�д���ʸ�Ϊ�ˡ�4��1��
	

assign gray_sct_addr[4:1] = binary_sct_addr[3:0];

	always@(posedge clk_div16 or posedge rst)  //30��Ƶ
	begin
		if(rst) begin clk_div_cnt <= 0; clk_50k <= 0; end
		else 
			begin
				if(clk_div_cnt == 30/2 -1) begin clk_div_cnt <= 0; clk_50k <= ~clk_50k; end
				else clk_div_cnt <= clk_div_cnt +1; 
			end
	end
	
	always@(posedge clk or posedge rst)
	begin
		if(rst)
			begin
			binary_sct_addr_r <= 0;
			en <= 0;
			end
		else
			begin
				binary_sct_addr_r <= binary_sct_addr;
				if(binary_sct_addr_r != binary_sct_addr) en <= 1;
				else if(out_cnt == 0) en <= 0;
			end
	end
	
	
	always@(posedge clk_50k or posedge rst)
	begin
		if(rst) begin out_uart <= 1; out_cnt <= 5; end		//�ȷ���λ��
		else 
			begin
				if(en) 
					begin
						if(out_cnt == 5) begin out_uart <= 0; out_cnt <= out_cnt -1; end
						else if(out_cnt == 0) begin out_uart <= 1; out_cnt <= 5; end //���ͽ�����һֱ�Ǹ�
						else begin out_uart <= gray_sct_addr[out_cnt]; out_cnt <= out_cnt -1; end //��Ϊgray_sct_addr����Ϊ��4��1��������out_cnt���ü�һ
					end
				else begin out_uart <= 1; out_cnt <= 5; end
			end
	end
	
	
	
//****************************************************//
//		������ �۲⵱ǰ�����ƺ͸������Ƿ��Ӧ						//
//****************************************************//	
//	always@(posedge clk_50k or posedge rst)  //������ �۲⵱ǰ�����ƺ͸������Ƿ��Ӧ
//	begin
//		if(rst) 
//			begin 
//			out_uart <= 1; 
//			out_binary <= 1;
//			out_cnt <= 5; 
//			end		//�ȷ���λ��
//		else 
//			begin
//				if(en) 
//					begin
//						if(out_cnt == 5) 
//							begin 
//							out_uart <= 0;
//							out_binary <= 0;
//							out_cnt <= out_cnt -1;
//							end
//						else if(out_cnt == 0)  //��ʵ������ֻ���û�ã���Ϊ����Ŀ��Ƴ���Ĵ���ʱ���õ���clk���������always�����ͼ�ⲻ��out_cnt == 0�������ȼ�⵽en=0��
//							begin 
//							out_uart <= 1;
//							out_binary <= 1;
//							out_cnt <= 5; 
//							end //���ͽ�����һֱ�Ǹ�
////						else begin out_uart <= gray_sct_addr[out_cnt]; out_cnt <= out_cnt -1; end //��Ϊgray_sct_addr����Ϊ��4��1��������out_cnt���ü�һ
//						else 
//							begin 
//							out_binary <= binary_sct_addr[out_cnt -1];
//							out_uart <= gray_sct_addr[out_cnt];
//							out_cnt <= out_cnt -1;
//							end //����2������������
//					end
//				else 
//					begin 
//					out_uart <= 1; 
//					out_binary <= 1;
//					out_cnt <= 5; 
//					end
//			end
//	end

endmodule
