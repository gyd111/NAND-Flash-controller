`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:12:19 01/16/2019 
// Design Name: 
// Module Name:    Data_download 
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
module Data_download(
    input clk,clk12M,clk_96M,                    
	 input rst,
	 input end_read,
	 input change_bypass,
	 input end_baud_transfer,
	 input [7:0] data_ram,             //RAM中读出的数据
	 input f_rx,                       //uart接收端
	 output f_tx,                      //uart发送端
	 output f_de,f_re,                 //a1_485的读写控制端
    output en,we,                     //RAM读写使能
    output [14:0] addr_ram,           //RAM地址	 
	 output reg return_bypass,         //使能UART_A1回到直通状态
	 output change_ram,                //切换ram            
	 output en_read,                   //读使能                 
	 output [23:0] read_addr,          //读地址
    output reg[7:0]baud_CMD,          //切换波特率命令
    output reg en_baud_transfer       //使能发送波特率切换命令	 
    );
	 

wire neg_trig; 
reg rx_r1,rx_r2;
reg[3:0] bit_cnt;              //接收位计数
reg[3:0] sample_cnt;           //接收时采样计数  
reg rx_busy;                   //单个字节接收开始标志
reg en_send;                   //接收到一字节命令标志
reg en_send_r1;                //缓存en_send的值
reg[9:0] cmd_data_buf;         //命令缓存
reg[7:0] cmd_data;             //接收到的一字节命令
wire data_fin;                 //待发送数据准备就绪标志
wire [7:0] data;               //待发送的数据
wire transfer_fin;             //uart口发送完成
wire read_finish;

//**********************接收485发来的一个字节数据*********************//
always @(posedge clk_96M or posedge rst)  //检测到下降沿用掉1个时钟了
  begin
	 if(rst) begin rx_r1 <= 1; rx_r2 <= 1; end
	 else begin rx_r1 <= f_rx; rx_r2 <= rx_r1; end
  end
assign neg_trig = rx_r2 & ~rx_r1;	     //检测下降沿

always @(posedge clk_96M or posedge rst)
begin
  if(rst) 
    begin   
	 bit_cnt<=0;
	 sample_cnt<=0;
	 rx_busy<=0;
	 en_send<=0;
    end
  else
    begin
	 if(~rx_busy)
	   begin
	   if(en_send_r1)  en_send<=0;
	   else if(neg_trig)
		  begin
		   rx_busy<=1;
			en_send<=0;
			sample_cnt<=2;      //触发采样开始时已经是第2个时钟上升沿
			bit_cnt<=0;
			cmd_data<=0;
			cmd_data_buf<=0;
		  end
		else
		  begin
		  rx_busy<=rx_busy;   //保持空闲态
		  end
		end
	 else
		begin
		sample_cnt<=sample_cnt+1;
		if(sample_cnt==2) begin cmd_data_buf[bit_cnt]<= f_rx; end
		else if((sample_cnt==4) && (bit_cnt==0) &&  (cmd_data_buf[0] == 1)) begin  rx_busy<=0; end
		else if((sample_cnt==4) && (bit_cnt==9) &&  (cmd_data_buf[9] == 0)) begin  rx_busy<=0; end
		else if((sample_cnt==4) && (bit_cnt==9) &&  (cmd_data_buf[9] == 1))
		  begin
		  en_send<= 1;
		  cmd_data<= cmd_data_buf[8:1];
		  bit_cnt<=0;
		  rx_busy<=0;
		  sample_cnt<=0;
		  end
		else if(sample_cnt==6) begin bit_cnt<=bit_cnt+1; end
		else if(sample_cnt==7) begin sample_cnt<=0; end
      else 
        begin
        bit_cnt<=bit_cnt;
		  rx_busy<=rx_busy;
		  en_send<=en_send;
		  cmd_data<=cmd_data;
		  cmd_data_buf<=cmd_data_buf;
        end		  
		end
	 end
end
//*********************************************************//

reg[7:0] CMD[0:13];            //用于存储上位机下发的命令的数组
wire pos_en_send;              //检测en_send的上升沿
reg[3:0] CMD_cnt;              //接收的命令计数
reg[1:0]CMD_type_flag;         //命令区分标志，1表示读数据命令，2表示切换波特率命令
reg Receive_finish;            //完整命令接收完成标志，1表示接收到1个命令，0表示没有接收到命令
reg[7:0] check_code;           //校验码
reg[7:0] CMD_to_485inout;      //接收到的命令给a1_485_inout模块
reg respond_2E;                //响切换直通命令2E
wire end_respond_2E;
wire end_read_state5,end_read_state6;
reg end_respond_2E_1,end_respond_2E_2;
wire pos_end_respond_2E; 
reg end_CMD;                   //结束命令执行
          
//**********************接收一个完整的命令,****************************//
always@(posedge clk_96M or posedge rst)
begin
  if(rst) begin en_send_r1<=0; end
  else begin  en_send_r1 <= en_send; end        //en_send_r1比en_send晚一个时钟周期	
end
assign  pos_en_send = en_send & ~en_send_r1;    //上升沿

always@(posedge clk_96M or posedge rst)
begin
  if(rst) begin check_code<=0; Receive_finish<=0; CMD_type_flag<=0; CMD_cnt<=0; CMD[0]<=0;CMD[1]<=0;CMD[2]<=0;CMD[3]<=0;CMD[4]<=0;CMD[5]<=0;CMD[6]<=0;CMD[7]<=0;CMD[8]<=0;CMD[9]<=0;CMD[10]<=0;CMD[11]<=0;CMD[12]<=0;CMD[13]<=0;  end
  else if(Receive_finish) 
    begin
	  Receive_finish<=0;
	 end
  else if(end_CMD)
    begin
	   CMD[0]<=0;CMD[1]<=0;CMD[2]<=0;CMD[3]<=0;CMD[4]<=0;CMD[5]<=0;CMD[6]<=0;CMD[7]<=0;
		CMD[8]<=0;CMD[9]<=0;CMD[10]<=0;CMD[11]<=0;CMD[12]<=0;CMD[13]<=0;
	 end
  else  
    begin
	 if(pos_en_send)
	   begin
		case(CMD_cnt)
		 0:
			 begin
			   if(cmd_data==8'hAA) begin  CMD[0]<=cmd_data;  CMD_cnt<=1; end
            else begin CMD_cnt<=0; check_code<=0; end  			 
			 end
		 1:
			 begin
			   if(cmd_data==8'h02) begin CMD[1]<=cmd_data;  CMD_cnt<=2; end
			   else CMD_cnt<=0; 
			 end
       2:
			 begin
			   if(cmd_data==8'h16) begin CMD[2]<=cmd_data; CMD_to_485inout<=cmd_data; CMD_cnt<=3; CMD_type_flag<=1; check_code<=cmd_data; end
			   else if((cmd_data==8'h29) || (cmd_data==8'h2A) || (cmd_data==8'h2B)) 
				  begin CMD[2]<=cmd_data; CMD_to_485inout<=cmd_data; CMD_cnt<=3; CMD_type_flag<=2;  end
            else begin CMD_cnt<=0; check_code<=0;CMD_to_485inout<=0; end			 
			 end	
		 3:
			 begin
			   if(cmd_data==8'h00 || cmd_data==8'h08) begin CMD[3]<=cmd_data;  CMD_cnt<=4;check_code<= check_code^cmd_data;end
			   else CMD_cnt<=0; 
			 end
		 4:
			 begin
			   if(CMD_type_flag == 2)
				  begin
			       if((cmd_data==8'h29) || (cmd_data==8'h2A) || (cmd_data==8'h2B)) begin CMD[4]<=cmd_data;  CMD_cnt<=5; end
				    else begin CMD_type_flag<=0; CMD_cnt<=0;  end
              end	
            else
              begin
                CMD[4]<=cmd_data;  
					 CMD_cnt<=5;
					 check_code<= check_code^cmd_data;
              end				  
			 end	
		 5:
			 begin
			   if(CMD_type_flag==2) 
				  begin
				    if(cmd_data==8'h55) begin Receive_finish<=1; CMD[5]<=cmd_data; CMD_cnt<=0;end
				    else 
				      begin
				      CMD_cnt<=0;
				      Receive_finish<=0;
				     end
				  end
				else
				   begin
			      CMD[5]<=cmd_data;  
					CMD_cnt<=6;
					check_code<= check_code^cmd_data;
               end				
			 end
       6:
          begin
           CMD[6]<=cmd_data;  
			  CMD_cnt<=7;
			  check_code<= check_code^cmd_data;
          end
       7:
          begin
           CMD[7]<=cmd_data;  
			  CMD_cnt<=8;
			  check_code<= check_code^cmd_data;
          end
       8:
          begin
           CMD[8]<=cmd_data;  
			  CMD_cnt<=9;
			  check_code<= check_code^cmd_data;
          end			 
       9:
          begin
           CMD[9]<=cmd_data;  
			  CMD_cnt<=10;
			  check_code<= check_code^cmd_data;
          end
		 10:
          begin
          CMD[10]<=cmd_data;  
	  	    CMD_cnt<=11;
			 check_code<= check_code^cmd_data;
          end
       11:
          begin
           CMD[11]<=cmd_data;  
			  CMD_cnt<=12;
			  check_code<= check_code^cmd_data;
          end	
       12:
          begin
			   if(check_code == cmd_data )
				  begin
              CMD[12]<=cmd_data;  
			     CMD_cnt<=13;
				  end
				else
              begin
				   CMD_cnt<=0;
					check_code<=0;
              end				  
          end
       13:
          begin
           if(cmd_data == 8'h55) begin Receive_finish<=1; CMD_cnt<=0;  end
			  else 
			    begin
				  Receive_finish<=0;
				  CMD_cnt<=0;
				 end
          end
		 default: begin Receive_finish<=0; CMD_cnt<=0;  end
      endcase 			 
	  end
	 else
	   begin
		Receive_finish <= Receive_finish; 
		CMD_cnt<=CMD_cnt;
		CMD_type_flag<=CMD_type_flag;
		end
	 end
end
//*********************************************************//

reg en_CMD;                                   //使能命令执行
reg end_CMD1,end_CMD2;
reg [31:0] read_addr_start, read_addr_end;    //读数据的起始地址和结束地址
reg [3:0] read_state;                         //状态
reg read_one_page;                            //读第一页标志
reg [3:0] return_state;                       //返回直通状态
wire CMD_To_MCU_Finish;                       //通过uart_A1发送命令完成标志
//*****************************命令处理*************************//
always@(posedge clk_96M or posedge rst)
begin
  if(rst) begin en_CMD<=0;  end
  else
    begin
	 if(Receive_finish)  en_CMD<=1;             //收到一个命令将使能一次
	 else if(end_CMD)    en_CMD<=0;
	 else en_CMD <= en_CMD;
    end
end

always@(posedge clk_96M or posedge rst)        //若收到的是读数据的命令，则read_one_page置1，启动读第一页，否则该变量无效
begin 
  if(rst)                       begin read_one_page<=0;  end
  else if(Receive_finish)       read_one_page<=1;
  else if(end_read || end_CMD)  read_one_page<=0;
  else                          read_one_page<=read_one_page;
end

always@(posedge clk or posedge rst)            //命令已经执行，使能结束命令执行
begin
  if(rst) begin end_CMD<=0;  end
  else
    begin
	 if(end_CMD1==1 || end_CMD2==1) begin  end_CMD<=1; end
	 else if(end_CMD==1 && en_CMD==0) begin end_CMD<=0; end
	 else end_CMD<=end_CMD;
	 end 
end
//***********************切换波特率*************************************//
always@(posedge clk or posedge rst)            //检测波特率设置完成上升沿
begin
  if(rst) begin end_respond_2E_1<=0;end_respond_2E_2<=0; end
  else    begin end_respond_2E_2<=end_respond_2E_1;end_respond_2E_1<=end_respond_2E; end
end
assign pos_end_respond_2E = ~end_respond_2E_2 & end_respond_2E_1;


always@(posedge clk or posedge rst)            //执行切换波特率的状态机
begin 
  if(rst)  begin  return_state<=0;return_bypass<=0; end_CMD1<=0;respond_2E<=0; end
  else 
    begin
    case(return_state)
	  0:                                       
	    begin
		  if(en_CMD && (CMD[2]!=8'h16) && (change_bypass==1)) begin return_state<=4; respond_2E<=0; return_bypass<=0; end_CMD1<=0; end
		  else                                                begin return_state<=0; return_bypass<=0; end_CMD1<=0; respond_2E<=0; end
		 end
	  1:                                           //向上位机响应命令
	    begin   
		    if(pos_end_respond_2E) begin return_state<=2; return_bypass<=1; respond_2E<=0; end_CMD1<=0;  end
			 else                   begin return_state<=1; respond_2E<=1; return_bypass<=0; end_CMD1<=0;  end
		 end
	  2:
	    begin
		  if(change_bypass==0 && return_bypass==1) begin  return_state<=3; respond_2E<=0; return_bypass<=0; end_CMD1<=1; end
		  else                                     begin  return_state<=2; return_bypass<=1; respond_2E<=0; end_CMD1<=0;  end
		 end
	  3:
	    begin
		   if(en_CMD == 0) begin end_CMD1<=0; return_state<=0; respond_2E<=0; return_bypass<=0; end
			else            begin return_state<=3; respond_2E<=0; return_bypass<=0; end_CMD1<=1; end
		 end
	  4:                                         //发送命令到单片机UART_A0切换波特率
	    begin
		  if(end_baud_transfer) begin  return_state<=1; respond_2E<=1; return_bypass<=0; end_CMD1<=0; end
		  else                  begin  return_state<=4; respond_2E<=0; return_bypass<=0; end_CMD1<=0;  end
		 end		
	  default: 
	    begin return_state<=0;return_bypass<=0; end_CMD1<=0;respond_2E<=0; end
	 endcase
	 end
end

always@(posedge clk or posedge rst)        //生成使能信号en_baud_transfer和数据baud_CMD      
begin 
  if(rst)
    begin
	 baud_CMD         <= 0;
	 en_baud_transfer <= 0;
	 end
  else
    begin
	 if(return_state == 4)
	   begin
		baud_CMD         <= CMD[2];
		en_baud_transfer <= 1;
		end
	 else
	   begin
		baud_CMD         <= 0;
		en_baud_transfer <= 0;
		end
	 end
end
//*********************************************************************************//

//**********************************读数据*****************************************//
always@(posedge clk or posedge rst)            //执行读数据命令
begin
  if(rst) begin read_addr_start<=0;read_addr_end<=0; read_state<=0;end_CMD2<=0;  end
  else
    begin
	   if(en_CMD && CMD[2]==8'h16)
		  case(read_state)
		    0:                          //24位有效地址合成
			    begin
		         read_addr_start[7:0]   <=  CMD[4];
			      read_addr_start[15:8]  <=  CMD[5];
			      read_addr_start[23:16] <=  CMD[6];
			      read_addr_end[7:0]     <=  CMD[8];
			      read_addr_end[15:8]    <=  CMD[9];
			      read_addr_end[23:16]   <=  CMD[10];
			      read_state<= 1;
					end_CMD2<=0;
		       end
			 1:                          //判断地址是否合理
             begin
				   if(read_addr_start > read_addr_end)  begin read_state<=3 ;end_CMD2<=0; end
					else                                 begin read_state<= 5;end_CMD2<=0; end								  
             end
          2:                         //读数据
             begin
				   if(read_finish) begin read_state<=6;end_CMD2<=0; end 
				   else            begin read_state<=2;end_CMD2<=0; end
             end
          3:                         //结束读数据
             begin
				  read_addr_start  <=  0;		      
			     read_addr_end    <=  0;			   
				  read_state<=4;
				  end_CMD2<=1;				 
             end
			 4: begin
			     read_state<=0;
				  end_CMD2<=0;	 
			    end
          5: begin                   //发送数据头AA 02 16 FF
              if(end_read_state5) begin read_state<=2;end_CMD2<=0; end
				  else                begin read_state<=5;end_CMD2<=0; end
             end
          6: begin                   //发送校验码+55
              if(end_read_state6) begin read_state<=3;end_CMD2<=0; end
				  else                begin read_state<=6;end_CMD2<=0; end
             end			 
          default:
			    begin
				  read_state<=0;
				  end_CMD2<=0;	
				  read_addr_start<=0;
				  read_addr_end<=0;
				 end				 
		  endcase
		else
		  begin
		    read_state<=0;
			 end_CMD2<=0;
          read_addr_start<=0;
			 read_addr_end<=0; 			 
		  end
	 end
end
//*******************************************************************************//



UART_TX UART_TX(             //UART_TX发送数据
.clk(clk),
.clk12M(clk12M),
.rst(rst),
.data(data),
.data_fin(data_fin),
.transfer_fin(transfer_fin),
.f_tx(f_tx)
);

read_contonl read_contonl(
  .clk(clk),
  .clk_96M(clk_96M),
  .rst(rst),
  .f_de(f_de),
  .f_re(f_re),
  .CMD_to_485inout(CMD_to_485inout),
  .Receive_finish(Receive_finish),
  .read_state(read_state),
  .transfer_fin(transfer_fin),
  .end_read(end_read),
  .read_addr_start(read_addr_start),
  .read_addr_end(read_addr_end),
  .read_one_page(read_one_page),
  .data_ram(data_ram),
  .en_read(en_read),
  .read_addr(read_addr),
  .data(data),
  .data_fin(data_fin),
  .read_finish(read_finish),
  .en(en),
  .we(we),
  .addr_ram(addr_ram),
  .change_ram(change_ram),
  .end_respond_2E(end_respond_2E),
  .respond_2E(respond_2E),
  .pos_end_respond_2E(pos_end_respond_2E),
  .end_read_state5(end_read_state5),
  .end_read_state6(end_read_state6)
);
endmodule
