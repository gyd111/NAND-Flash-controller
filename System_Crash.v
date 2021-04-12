`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:30:30 09/25/2018 
// Design Name: 
// Module Name:    System_Crash 
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
module System_Crash(
    input clk,
	 input rst,
	 input uart_cmd_incomplete,
	 input flash_cmd_incomplete,
	 input nandflash_busy_Noresponse,
	 output reg[2:0] FPGA_Crash            //���ź����ڱ�ʾFPGA����������1��ʾnandflash��busy�ź�����Ӧ��3FPGA���յ������λ��һ����λΪ4�ֽڣ�����������
	 
    );
	 
	 
    always@(posedge clk or posedge rst)    
	 begin
		if(rst) 
		  FPGA_Crash<=0;
		else
		  begin
		    if(nandflash_busy_Noresponse == 1)
			    FPGA_Crash<=1;            //nandflash��busy�ź�����Ӧ
			 else if(uart_cmd_incomplete == 1)
			    FPGA_Crash<=2;            //uart��������ղ�����
			 else if(flash_cmd_incomplete == 1)
			    FPGA_Crash<=3;            //FPGA���յ������λ��һ����λΪ4�ֽڣ�����������
		  end
		
    end

endmodule
