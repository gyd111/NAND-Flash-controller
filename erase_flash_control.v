`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:52:54 04/08/2018 
// Design Name: 
// Module Name:    erase_flash_control 
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
module erase_flash_control(
	input clk,rst,
	input en_erase,end_erase_page,
	output end_erase,
	output reg en_erase_page,
	
	input [1:0]erase_addr_row_error, // 2 Îª»µ¿é£¬1ÎªºÃ¿é£¬ 0ÎªÎ´¼ìË÷
	
	input [23:0] erase_addr_start,erase_addr_finish,
	output reg [23:0]erase_addr_row
    );
	 
	 wire [2:0] erase_state;

	 assign end_erase = (erase_state == 7) ? 1 : 0;
	 
	 always @(posedge clk or posedge rst)
	 begin
		if(rst)
			en_erase_page <= 0;
		else
			if(erase_state == 2 | erase_state == 6)
				en_erase_page <= 1;
			else	if(erase_state == 5 | end_erase_page)
				en_erase_page <= 0;
	 end
	 
	 always @(posedge clk or posedge rst)
	 begin
		if(rst)
			erase_addr_row <= 0;
		else
			if(erase_state == 2)
				erase_addr_row <= erase_addr_start;
			else if(erase_state == 6)
				begin
					erase_addr_row[6:0] <= 0;
					erase_addr_row[18:7] <= erase_addr_row[18:7]+1;
				end
	 end
	 
	 
	 
	 
	 
//****************************************************//
//    	  		  ²ÁFLASH×´Ì¬¿ØÖÆ 								//
//****************************************************//	 

	erase_flash_state_control erase_flash_state_control(
    .clk(clk), 
    .rst(rst), 
    .en_erase(en_erase), 
    .end_erase_page(end_erase_page), 
    .erase_addr_finish(erase_addr_finish), 
    .erase_addr_row(erase_addr_row), 
    .erase_addr_row_error(erase_addr_row_error), 
    .erase_state(erase_state)
    );
	
	
endmodule
