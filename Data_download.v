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
	 input [7:0] data_ram,             //RAM�ж���������
	 input f_rx,                       //uart���ն�
	 output f_tx,                      //uart���Ͷ�
	 output f_de,f_re,                 //a1_485�Ķ�д���ƶ�
    output en,we,                     //RAM��дʹ��
    output [14:0] addr_ram,           //RAM��ַ	 
	 output reg return_bypass,         //ʹ��UART_A1�ص�ֱͨ״̬
	 output change_ram,                //�л�ram            
	 output en_read,                   //��ʹ��                 
	 output [23:0] read_addr,          //����ַ
    output reg[7:0]baud_CMD,          //�л�����������
    output reg en_baud_transfer       //ʹ�ܷ��Ͳ������л�����	 
    );
	 

wire neg_trig; 
reg rx_r1,rx_r2;
reg[3:0] bit_cnt;              //����λ����
reg[3:0] sample_cnt;           //����ʱ��������  
reg rx_busy;                   //�����ֽڽ��տ�ʼ��־
reg en_send;                   //���յ�һ�ֽ������־
reg en_send_r1;                //����en_send��ֵ
reg[9:0] cmd_data_buf;         //�����
reg[7:0] cmd_data;             //���յ���һ�ֽ�����
wire data_fin;                 //����������׼��������־
wire [7:0] data;               //�����͵�����
wire transfer_fin;             //uart�ڷ������
wire read_finish;

//**********************����485������һ���ֽ�����*********************//
always @(posedge clk_96M or posedge rst)  //��⵽�½����õ�1��ʱ����
  begin
	 if(rst) begin rx_r1 <= 1; rx_r2 <= 1; end
	 else begin rx_r1 <= f_rx; rx_r2 <= rx_r1; end
  end
assign neg_trig = rx_r2 & ~rx_r1;	     //����½���

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
			sample_cnt<=2;      //����������ʼʱ�Ѿ��ǵ�2��ʱ��������
			bit_cnt<=0;
			cmd_data<=0;
			cmd_data_buf<=0;
		  end
		else
		  begin
		  rx_busy<=rx_busy;   //���ֿ���̬
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

reg[7:0] CMD[0:13];            //���ڴ洢��λ���·������������
wire pos_en_send;              //���en_send��������
reg[3:0] CMD_cnt;              //���յ��������
reg[1:0]CMD_type_flag;         //�������ֱ�־��1��ʾ���������2��ʾ�л�����������
reg Receive_finish;            //�������������ɱ�־��1��ʾ���յ�1�����0��ʾû�н��յ�����
reg[7:0] check_code;           //У����
reg[7:0] CMD_to_485inout;      //���յ��������a1_485_inoutģ��
reg respond_2E;                //���л�ֱͨ����2E
wire end_respond_2E;
wire end_read_state5,end_read_state6;
reg end_respond_2E_1,end_respond_2E_2;
wire pos_end_respond_2E; 
reg end_CMD;                   //��������ִ��
          
//**********************����һ������������,****************************//
always@(posedge clk_96M or posedge rst)
begin
  if(rst) begin en_send_r1<=0; end
  else begin  en_send_r1 <= en_send; end        //en_send_r1��en_send��һ��ʱ������	
end
assign  pos_en_send = en_send & ~en_send_r1;    //������

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

reg en_CMD;                                   //ʹ������ִ��
reg end_CMD1,end_CMD2;
reg [31:0] read_addr_start, read_addr_end;    //�����ݵ���ʼ��ַ�ͽ�����ַ
reg [3:0] read_state;                         //״̬
reg read_one_page;                            //����һҳ��־
reg [3:0] return_state;                       //����ֱͨ״̬
wire CMD_To_MCU_Finish;                       //ͨ��uart_A1����������ɱ�־
//*****************************�����*************************//
always@(posedge clk_96M or posedge rst)
begin
  if(rst) begin en_CMD<=0;  end
  else
    begin
	 if(Receive_finish)  en_CMD<=1;             //�յ�һ�����ʹ��һ��
	 else if(end_CMD)    en_CMD<=0;
	 else en_CMD <= en_CMD;
    end
end

always@(posedge clk_96M or posedge rst)        //���յ����Ƕ����ݵ������read_one_page��1����������һҳ������ñ�����Ч
begin 
  if(rst)                       begin read_one_page<=0;  end
  else if(Receive_finish)       read_one_page<=1;
  else if(end_read || end_CMD)  read_one_page<=0;
  else                          read_one_page<=read_one_page;
end

always@(posedge clk or posedge rst)            //�����Ѿ�ִ�У�ʹ�ܽ�������ִ��
begin
  if(rst) begin end_CMD<=0;  end
  else
    begin
	 if(end_CMD1==1 || end_CMD2==1) begin  end_CMD<=1; end
	 else if(end_CMD==1 && en_CMD==0) begin end_CMD<=0; end
	 else end_CMD<=end_CMD;
	 end 
end
//***********************�л�������*************************************//
always@(posedge clk or posedge rst)            //��Ⲩ�����������������
begin
  if(rst) begin end_respond_2E_1<=0;end_respond_2E_2<=0; end
  else    begin end_respond_2E_2<=end_respond_2E_1;end_respond_2E_1<=end_respond_2E; end
end
assign pos_end_respond_2E = ~end_respond_2E_2 & end_respond_2E_1;


always@(posedge clk or posedge rst)            //ִ���л������ʵ�״̬��
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
	  1:                                           //����λ����Ӧ����
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
	  4:                                         //���������Ƭ��UART_A0�л�������
	    begin
		  if(end_baud_transfer) begin  return_state<=1; respond_2E<=1; return_bypass<=0; end_CMD1<=0; end
		  else                  begin  return_state<=4; respond_2E<=0; return_bypass<=0; end_CMD1<=0;  end
		 end		
	  default: 
	    begin return_state<=0;return_bypass<=0; end_CMD1<=0;respond_2E<=0; end
	 endcase
	 end
end

always@(posedge clk or posedge rst)        //����ʹ���ź�en_baud_transfer������baud_CMD      
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

//**********************************������*****************************************//
always@(posedge clk or posedge rst)            //ִ�ж���������
begin
  if(rst) begin read_addr_start<=0;read_addr_end<=0; read_state<=0;end_CMD2<=0;  end
  else
    begin
	   if(en_CMD && CMD[2]==8'h16)
		  case(read_state)
		    0:                          //24λ��Ч��ַ�ϳ�
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
			 1:                          //�жϵ�ַ�Ƿ����
             begin
				   if(read_addr_start > read_addr_end)  begin read_state<=3 ;end_CMD2<=0; end
					else                                 begin read_state<= 5;end_CMD2<=0; end								  
             end
          2:                         //������
             begin
				   if(read_finish) begin read_state<=6;end_CMD2<=0; end 
				   else            begin read_state<=2;end_CMD2<=0; end
             end
          3:                         //����������
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
          5: begin                   //��������ͷAA 02 16 FF
              if(end_read_state5) begin read_state<=2;end_CMD2<=0; end
				  else                begin read_state<=5;end_CMD2<=0; end
             end
          6: begin                   //����У����+55
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



UART_TX UART_TX(             //UART_TX��������
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
