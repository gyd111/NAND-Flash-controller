`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:37:54 01/20/2019 
// Design Name: 
// Module Name:    a1_485_inout 
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
module a1_485_inout(
     input clk_96M,
	  input rst,
	  input [7:0]CMD,
	  input Receive_finish,
     input pos_end_respond_2E,	  
	  input read_finish,
	  input [3:0] read_state,
	  output reg f_re,         //A1_485接收控制端
	  output reg f_de         //A1_495发送控制端
    );

always@(posedge clk_96M or posedge rst)
begin
  if(rst) begin f_re<=0;f_de<=0; end
  else
   begin
	  if(Receive_finish)
	   begin
		 f_re<=1;
       f_de<=1;		 
		end
	  else if(read_state==3 || pos_end_respond_2E)
	   begin
		 f_re<=0;
       f_de<=0;		 
		end
	  else
	   begin
		 f_re<=f_re;
       f_de<=f_de;
		end
	end
end
endmodule
