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
	 
	
	reg en; //发送使能
	reg clk_50k;
	reg [3:0] binary_sct_addr_r;
	reg [4:0] clk_div_cnt;
	reg [2:0] out_cnt;
	wire [4:1] gray_sct_addr; //为方便发送逻辑的编写，故改为了【4：1】
	

assign gray_sct_addr[4:1] = binary_sct_addr[3:0];

	always@(posedge clk_div16 or posedge rst)  //30分频
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
		if(rst) begin out_uart <= 1; out_cnt <= 5; end		//先发高位，
		else 
			begin
				if(en) 
					begin
						if(out_cnt == 5) begin out_uart <= 0; out_cnt <= out_cnt -1; end
						else if(out_cnt == 0) begin out_uart <= 1; out_cnt <= 5; end //发送结束后一直是高
						else begin out_uart <= gray_sct_addr[out_cnt]; out_cnt <= out_cnt -1; end //因为gray_sct_addr设置为【4：1】，这里out_cnt不用减一
					end
				else begin out_uart <= 1; out_cnt <= 5; end
			end
	end
	
	
	
//****************************************************//
//		测试用 观测当前二进制和格雷码是否对应						//
//****************************************************//	
//	always@(posedge clk_50k or posedge rst)  //测试用 观测当前二进制和格雷码是否对应
//	begin
//		if(rst) 
//			begin 
//			out_uart <= 1; 
//			out_binary <= 1;
//			out_cnt <= 5; 
//			end		//先发高位，
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
//						else if(out_cnt == 0)  //其实这个部分基本没用，因为上面的控制程序的触发时钟用的是clk，所以这个always根本就检测不到out_cnt == 0，而是先检测到en=0。
//							begin 
//							out_uart <= 1;
//							out_binary <= 1;
//							out_cnt <= 5; 
//							end //发送结束后一直是高
////						else begin out_uart <= gray_sct_addr[out_cnt]; out_cnt <= out_cnt -1; end //因为gray_sct_addr设置为【4：1】，这里out_cnt不用减一
//						else 
//							begin 
//							out_binary <= binary_sct_addr[out_cnt -1];
//							out_uart <= gray_sct_addr[out_cnt];
//							out_cnt <= out_cnt -1;
//							end //发送2进制码做测试
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
