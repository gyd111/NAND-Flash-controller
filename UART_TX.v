`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:32:00 01/18/2019 
// Design Name: 
// Module Name:    UART_TX 
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
module UART_TX(
    input clk,clk12M,
	 input rst,
	 input[7:0] data,               //待上传的数据
	 input data_fin,                //数据准备好标志,保持一个周期为1	
    output reg transfer_fin,       //发送完成标志	 
	 output reg f_tx                //UART口的TX端
    );
	
reg [3:0] cnt,cnt1;
reg en_transfer;
reg [9:0]data_send;
reg data_fin_1,data_fin_2;
wire pos_data_fin;

   
always @(posedge clk or posedge rst)
begin
  if(rst) begin data_fin_1<=0;data_fin_2<=0; end
  else    begin data_fin_2<=data_fin_1;data_fin_1<=data_fin;  end
end
assign pos_data_fin= ~data_fin_2 & data_fin_1;

always @(posedge clk or posedge rst)
begin
  if(rst) begin data_send<=0; en_transfer<=0; end
  else
    begin 
      if(pos_data_fin)      begin  data_send<={1'b1,data,1'b0};en_transfer<=1; end
		else if(transfer_fin) begin  data_send<=10'b1111111111;en_transfer<=0; end
      else                  begin  data_send<=data_send; en_transfer<=en_transfer; end		
	 end
end

//*********************发送单个字节*****************//        
always @(posedge clk12M or posedge rst)
begin
  if(rst) 
    begin
	   f_tx<=1;
		cnt<=0;
		cnt1<=0;
		transfer_fin<=0;
	 end
  else
    begin
      if(en_transfer)
		  begin
		    if(cnt1<1) begin f_tx<=1;cnt<=0;cnt1<=cnt1+1;transfer_fin<=0; end   //一个字节发送完成后en_transfer需要再过一个时钟才能为0，所以延时
			 else if(cnt==10)
			   begin
				f_tx<=1;
				cnt<=0;
				cnt1<=0;
				transfer_fin<=1;
				end
			 else
			   begin
				f_tx<= data_send[cnt];
		      cnt<=cnt+1;
				cnt1<=cnt1;
				transfer_fin<=0;
				end
		  end
		else
		  begin
         f_tx<=1;
		   cnt<=0;
			cnt1<=0;
		   transfer_fin<=0;
			
        end		  
    end	  
end
//*****************************************************//


endmodule
