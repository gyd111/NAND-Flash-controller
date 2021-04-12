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
	 output reg[2:0] FPGA_Crash            //该信号用于表示FPGA程序死机；1表示nandflash的busy信号无响应；3FPGA接收到的命令单位（一个单位为4字节）数量不完整
	 
    );
	 
	 
    always@(posedge clk or posedge rst)    
	 begin
		if(rst) 
		  FPGA_Crash<=0;
		else
		  begin
		    if(nandflash_busy_Noresponse == 1)
			    FPGA_Crash<=1;            //nandflash的busy信号无响应
			 else if(uart_cmd_incomplete == 1)
			    FPGA_Crash<=2;            //uart口命令接收不完整
			 else if(flash_cmd_incomplete == 1)
			    FPGA_Crash<=3;            //FPGA接收到的命令单位（一个单位为4字节）数量不完整
		  end
		
    end

endmodule
