`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:15:34 01/18/2019 
// Design Name: 
// Module Name:    read_contonl 
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
module read_contonl(
    input clk,clk_96M,
	 input rst,
	 input [3:0] read_state,
	 input read_one_page,
	 input[7:0] CMD_to_485inout,
	 input pos_end_respond_2E,
	 input Receive_finish,
	 input respond_2E,
	 input transfer_fin,            //uart�ڷ������
	 input end_read,                //��һҳ����
	 input [23:0] read_addr_start,  //�����ݵ���ʼ��ַ
	 input [23:0] read_addr_end,    //�����ݵĽ�����ַ
	 input [7:0]  data_ram,         //ram�ж���������
	 output reg change_ram,         //�л�ram
	 output reg en_read,            //ʹ�ܶ�
	 output reg[23:0] read_addr,    //����ַ
	 output [7:0] data,             //���͵�����
	 output data_fin,               //���ͱ�־
	 output reg read_finish,        //������ɱ�־
	 output reg en,we,              //ramʹ�ܺͶ�д�ź�
	 output f_de,f_re,              //a1_485�Ķ�д�����ź�
	 output reg[14:0] addr_ram,      //ram�ĵ�ַ
	 output reg end_respond_2E,
	 output reg end_read_state5,      //����AA 02 16 FF������־
	 output reg end_read_state6       //����check-code 55������־
    );

wire pos_end_read;                       //����������������
wire pos_uart_tx_fin,pos_data1_fin;
reg [23:0]read_cnt;                      //��ҳ������
reg [23:0]page_cnt;                      //��ʼ��ַ��������ַ��ҳ��
reg en_uart_tx;                          //ʹ��uart�ڷ���
reg uart_tx_fin;                         //uart�ڷ�����һҳ
reg uart_tx_fin_1,uart_tx_fin_2;
reg [4:0]cnt1,cnt2;                      //������
reg end_read1,end_read2;
reg data1_fin_1,data1_fin_2;
reg data1_fin,data2_fin,data3_fin,data4_fin;                        
reg [7:0] data1,data2,data3,data4; 
reg [7:0] check_code;                    //У����

//*********************data,data_finѡ��**********//
assign  data = (respond_2E==1) ? data2 : ((read_state==5)?data3:((read_state==6)?data4:data1));
assign  data_fin = (respond_2E==1) ? data2_fin : ((read_state==5)?data3_fin:((read_state==6)?data4_fin:data1_fin)); 
       
//**********************��������������*************//
always@(posedge clk or posedge rst)
begin
  if(rst) begin end_read1<=0;end_read2<=0;end
  else
    begin
    end_read1<=end_read;
	 end_read2<=end_read1;
	 end
end
assign pos_end_read = ~end_read2 & end_read1;  //���������
//***********************************************//
always@(posedge clk or posedge rst)            //���ƶ���ҳ��������л�ram�ź�
begin
  if(rst) begin read_cnt<=0; change_ram<=0; end
  else
  begin
    if(read_state==2)
	  begin
      if(pos_end_read) begin read_cnt<=read_cnt+1; change_ram<=1;end
      else begin read_cnt<=read_cnt; change_ram<=0; end
	  end
	 else
	  begin
	  read_cnt<=0; 
	  change_ram<=0;
	  end
  end
end 

//**********************����uart_txһҳ�������������*************//
always@(posedge clk or posedge rst)
begin
  if(rst) begin uart_tx_fin_1<=0;uart_tx_fin_2<=0;end
  else    begin uart_tx_fin_2<=uart_tx_fin_1;uart_tx_fin_1 <= uart_tx_fin; end
end
assign pos_uart_tx_fin = ~uart_tx_fin_2 & uart_tx_fin_1;  //���������
//***********************************************//

always@(posedge clk_96M or posedge rst)                   //ȷ����Ҫ��ȡ��ҳ��
begin
if(rst) begin page_cnt<=0; end
else
 begin
  if((read_state==2) && (CMD_to_485inout==8'h16))
     page_cnt<=read_addr_end-read_addr_start+1;           //������ҳ��
  else if(read_state==3) 
     page_cnt<=0;
  else
     page_cnt<=page_cnt; 
 end
end

//assign page_cnt=read_addr_end-read_addr_start+1;           //������ҳ��

always@(posedge clk or posedge rst)
begin
  if(rst) begin read_finish<=0;en_read<=0;read_addr<=0;en_uart_tx <=0; end
  else 
    if(read_state==2)
    begin
	   if(end_read) begin  en_read<=0; en_uart_tx <=1; end
	   else
        begin		 
		  if(read_one_page)
			 begin
			   en_read<=1;
				read_addr <= read_addr_start;
			 end
		  else if(read_cnt<page_cnt && pos_uart_tx_fin==1)             
		    begin
            en_read<=1;
				read_addr<=read_addr+1;				
          end
		  else if(read_cnt>=page_cnt && pos_uart_tx_fin==1)
          begin
			  read_finish<=1;
			  en_read<=0;
          end 
		  else
			 begin
           read_finish<=0;
			  en_read<=en_read;
			  en_uart_tx <=0;
          end			 
		  end		 
	 end
	 else
	 begin
      read_finish<=0;
	   en_read<=0;
      read_addr<=0;
      en_uart_tx <=0;		
	 end
end

reg en_uart_tx_1,en_uart_tx_2,transfer_fin_1,transfer_fin_2;
wire pos_en_uart_tx,pos_transfer_fin;
reg [1:0]state_1,state_2;                   //���ƶ�ȡһҳ��״̬
reg [13:0] Byte_cnt;                //�����ֽڸ����ļ�����
//*******************************���ƶ�һҳ����*******************//
always@(posedge clk or posedge rst)
begin
  if(rst) begin  en_uart_tx_1<=0; end
  else    begin  en_uart_tx_2<=en_uart_tx_1;en_uart_tx_1<=en_uart_tx; end
end
assign pos_en_uart_tx = ~en_uart_tx_2 & en_uart_tx_1;

always@(posedge clk or posedge rst)
begin
  if(rst) begin state_1<=0;  end
  else
    if(read_state==2)
     begin
	   case(state_1)
	   0: 
	     begin
		   if(pos_en_uart_tx) state_1<=1;
		   else state_1<=0;
		  end
	   1:
	     begin
		   if(pos_uart_tx_fin) state_1<=0;
		   else state_1<=1;
		  end
	   default:begin state_1<=0;end
	   endcase
	 end
	 else
    state_1<=0;
end

always@(posedge clk or posedge rst)  //���transfer_fin��������
begin
  if(rst) begin transfer_fin_1<=0;transfer_fin_2<=0; end
  else    begin transfer_fin_2<=transfer_fin_1;transfer_fin_1<=transfer_fin; end
end
assign pos_transfer_fin = ~transfer_fin_2 & transfer_fin_1;

always@(posedge clk or posedge rst)  //һҳ���ݷ��ͼ���
begin
  if(rst) begin  Byte_cnt<=0;uart_tx_fin<=0; end
  else
   if(read_state==2)
	 begin
     if(Byte_cnt==8192) begin Byte_cnt<=0;uart_tx_fin<=1; end
     else if(pos_transfer_fin ) begin Byte_cnt<=Byte_cnt+1; uart_tx_fin<=0; end
     else if(uart_tx_fin) begin Byte_cnt<=0;uart_tx_fin<=0;  end
     else 
     begin
	   Byte_cnt<= Byte_cnt;
	   uart_tx_fin<=uart_tx_fin;
	  end
    end
	else
	 begin
      Byte_cnt<=0;
		uart_tx_fin<=0;
    end	 
end

always@(posedge clk or posedge rst)   
begin
  if(rst) begin  data1_fin_1<=0; end
  else    begin  data1_fin_2<=data1_fin_1;data1_fin_1<=data1_fin; end
end
assign pos_data1_fin= ~data1_fin_2 & data1_fin_1;  //data_fin������

always@(posedge clk or posedge rst)           //һ���ֽ����ݵ�׼���뷢���л���1��ʾ׼��������0��ʾ׼����
begin
  if(rst)  begin state_2<=0; end
  else 
   if(read_state==2)
	 case(state_2)
	 0:
	   begin
		 if(pos_data1_fin) state_2<=1; 
		 else state_2<=0;
		end
	 1:
	   begin
		 if(pos_transfer_fin) state_2<=0;
		 else state_2<=1;	   
		end
	 default:
	   begin
		  state_2<=0;
		end
	 endcase
   else
	 state_2<=0;   
end

always@(posedge clk or posedge rst)
begin
 if(rst) begin en<=0;we<=0;addr_ram<=0;cnt1<=0;data1_fin<=0; end
 else
  begin
   if(state_1)
	 begin
	  if(state_2==0)
	   begin 
	    en<=1;
		 we<=0;
		 addr_ram<=Byte_cnt;
		 if(cnt1<4)       begin cnt1<=cnt1+1; data1_fin<=0; end       //������һҳ���ݺ�Ҫ����3��clk��state_1��Ϊ0������cnt1�ӳ�4��clk
		 else if(cnt1==4) begin cnt1<=0;data1_fin<=1;data1<=data_ram;  end
		 else             begin cnt1<=0; data1_fin<=0;data1<=data1;end
		end
	  else
	   begin
		  data1<=data1;
		  data1_fin<=0;
		  cnt1<=0;
		end
	 end
	else
	 begin
	 en<=0;
	 we<=0;
	 addr_ram<=0;
	 cnt1<=0;
	 data1_fin<=0;
	 end
  end
end

//***********************************************//
//                 �ϴ�AA 02 16 FF                //                          
//***********************************************//
reg [3:0]state_4;
reg [2:0] cnt_2;
always@(posedge clk or posedge rst) 
begin
 if(rst) begin state_4<=0;data3<=0;data3_fin<=0;end_read_state5<=0;cnt_2<=0; end
 else
   if(read_state==5)
	begin
	  case(state_4)
	  0: 
	    begin
	     if(cnt_2<3) begin  state_4<=0;data3<=0;data3_fin<=0;end_read_state5<=0;cnt_2<=cnt_2+1;  end
		  else if(cnt_2==3) 
		   begin   
		    state_4<=0;
			 data3<=8'hAA;
			 data3_fin<=1;
			 end_read_state5<=0;
			 cnt_2<=cnt_2+1;
		   end
		  else
		   begin
	       if(pos_transfer_fin) begin state_4<=1;data3<=0;data3_fin<=0;end_read_state5<=0;cnt_2<=0;  end
		    else                 begin state_4<=0;data3<=data3;data3_fin<=0;end_read_state5<=0;cnt_2<=cnt_2;  end
	      end
		  end
		1: 
		  begin
		   if(cnt_2<2) begin  state_4<=1;data3<=0;data3_fin<=0;end_read_state5<=0;cnt_2<=cnt_2+1;  end
		   else if(cnt_2==2) 
		    begin   
		     state_4<=1;
			  data3<=8'h02;
			  data3_fin<=1;
			  end_read_state5<=0;
			  cnt_2<=cnt_2+1;
		    end
		   else
		    begin
	        if(pos_transfer_fin) begin state_4<=2;data3<=0;data3_fin<=0;end_read_state5<=0;cnt_2<=0;  end
		     else                 begin state_4<=1;data3<=data3;data3_fin<=0;end_read_state5<=0;cnt_2<=cnt_2;  end
	       end
		  end
		2: 
		  begin
		   if(cnt_2<2) begin  state_4<=2;data3<=0;data3_fin<=0;end_read_state5<=0;cnt_2<=cnt_2+1;  end
		   else if(cnt_2==2) 
		    begin   
		     state_4<=2;
			  data3<=8'h16;
			  data3_fin<=1;
			  end_read_state5<=0;
			  cnt_2<=cnt_2+1;
		    end
		   else
		    begin
	        if(pos_transfer_fin) begin state_4<=3;data3<=0;data3_fin<=0;end_read_state5<=0;cnt_2<=0;  end
		     else                 begin state_4<=2;data3<=data3;data3_fin<=0;end_read_state5<=0;cnt_2<=cnt_2;  end
	       end
		  end
		3: 
		  begin
		   if(cnt_2<2) begin  state_4<=3;data3<=0;data3_fin<=0;end_read_state5<=0;cnt_2<=cnt_2+1;  end
		   else if(cnt_2==2) 
		    begin   
		     state_4<=3;
			  data3<=8'hFF;
			  data3_fin<=1;
			  end_read_state5<=0;
			  cnt_2<=cnt_2+1;
		    end
		   else
		    begin
	        if(pos_transfer_fin) begin state_4<=0;data3<=0;data3_fin<=0;end_read_state5<=1;cnt_2<=0;  end
		     else                 begin state_4<=3;data3<=data3;data3_fin<=0;end_read_state5<=0;cnt_2<=cnt_2;  end
	       end
		  end
		 default: begin state_4<=0;data3<=0;data3_fin<=0;end_read_state5<=0;cnt_2<=0; end
	    endcase
	end
  else
   begin
	 state_4<=0;
	 data3<=0;
	 data3_fin<=0;
	 end_read_state5<=0;
	 cnt_2<=0;
	end	
end
//***********************************************//
//                 ����У����                     //                          
//***********************************************//
always@(posedge clk or posedge rst) 
begin
  if(rst) begin check_code<=8'hE9;  end    //8'hE9<=8'h16^8'hFF  
  else
   begin
    if(read_state==2)
      begin	 
		 if(cnt1==4) check_code<=check_code^data_ram;
		 else        check_code<=check_code;
      end		 
	 else if(read_state==6) check_code<=check_code;
	 else                   check_code<=8'hE9;   //8'hE9<=8'h16^8'hFF  
	end
end
//***********************************************//
//                 �ϴ�check_code��55             //                          
//***********************************************//
reg [3:0] state_5;
reg [2:0] cnt_3;
always@(posedge clk or posedge rst) 
begin
 if(rst) begin state_5<=0;data4<=0;data4_fin<=0;end_read_state6<=0;cnt_3<=0; end
 else
   if(read_state==6)
	 begin
	  case(state_5) 
	   0:
		  begin
		  if(cnt_3<3) begin  state_5<=0;data4<=0;data4_fin<=0;end_read_state6<=0;cnt_3<=cnt_3+1;  end
		  else if(cnt_3==3) 
		    begin   
		     state_5<=0;
			  data4<=check_code;
			  data4_fin<=1;
			  end_read_state6<=0;
			  cnt_3<=cnt_3+1;
		    end
		  else
		    begin
	        if(pos_transfer_fin) begin state_5<=1;data4<=0;data4_fin<=0;end_read_state6<=0;cnt_3<=0;  end
		     else                 begin state_5<=0;data4<=data4;data4_fin<=0;end_read_state6<=0;cnt_3<=cnt_3;  end
	       end
		  end
	   1:
		  begin
		  if(cnt_3<3) begin  state_5<=1;data4<=0;data4_fin<=0;end_read_state6<=0;cnt_3<=cnt_3+1;  end
		  else if(cnt_3==3) 
		    begin   
		     state_5<=1;
			  data4<=8'h55;
			  data4_fin<=1;
			  end_read_state6<=0;
			  cnt_3<=cnt_3+1;
		    end
		  else
		    begin
	        if(pos_transfer_fin) begin state_5<=0;data4<=0;data4_fin<=0;end_read_state6<=1;cnt_3<=0;  end
		     else                 begin state_5<=1;data4<=data4;data4_fin<=0;end_read_state6<=0;cnt_3<=cnt_3;  end
	       end
		  end
	  endcase
	 end
	else
	 begin
	  state_5<=0;
	  data4<=0;
	  data4_fin<=0;
	  end_read_state6<=0;
	  cnt_3<=0;
	 end
end
//***********************************************//
//              ��Ӧreturn_bypass                //                          
//***********************************************//
reg respond_2E_1,respond_2E_2;
wire pos_respond_2E;
reg [3:0] state_3;                                //״̬
reg [2:0] cnt_1;

always@(posedge clk or posedge rst)              //���������
begin
  if(rst)  begin  respond_2E_1<=0; respond_2E_2<=0; end
  else     begin  respond_2E_1<=respond_2E; respond_2E_2<=respond_2E_1;end   
end
assign pos_respond_2E = ~respond_2E_2 & respond_2E_1;

always@(posedge clk or posedge rst)              //��Ӧ����
begin
  if(rst) begin  data2<=0;data2_fin<=0;state_3<=0;end_respond_2E<=0;cnt_1<=0; end
  else
   case(state_3)
	0:
	  begin 
	   if(pos_respond_2E) begin  state_3<=1; cnt_1<=0;end_respond_2E<=0; end
		else  begin state_3<=0;end_respond_2E<=0;cnt_1<=0; end
	  end
	1:
	  begin
	    if(cnt_1<2) begin  cnt_1<=cnt_1+1;  end
		 else if(cnt_1==2)
		  begin
	      data2<=8'hAA;
		   data2_fin<=1;
			cnt_1<=cnt_1+1;
		 end
		 else
		   if(pos_transfer_fin)  begin state_3<=2; cnt_1<=0; end
		   else  begin state_3<=1; data2_fin<=0; end
	  end
	2:
	  begin
	    if(cnt_1<2) begin  cnt_1<=cnt_1+1;  end
		 else if(cnt_1==2)
		  begin
	      data2<=8'h02;
		   data2_fin<=1;
			cnt_1<=cnt_1+1;
		 end
		 else
		   if(pos_transfer_fin)  begin state_3<=3; cnt_1<=0; end
		   else  begin state_3<=2; data2_fin<=0; end
	  end
	3:
	  begin
	    if(cnt_1<2) begin  cnt_1<=cnt_1+1;  end
		 else if(cnt_1==2)
		  begin
	      data2<=CMD_to_485inout;
		   data2_fin<=1;
			cnt_1<=cnt_1+1;
		 end
		 else
		   if(pos_transfer_fin)  begin state_3<=4; cnt_1<=0; end
		   else  begin state_3<=3; data2_fin<=0; end
	  end
	4:
	  begin
	    if(cnt_1<2) begin  cnt_1<=cnt_1+1;  end
		 else if(cnt_1==2)
		  begin
	      data2<=8'h00;
		   data2_fin<=1;
			cnt_1<=cnt_1+1;
		 end
		 else
		   if(pos_transfer_fin)  begin state_3<=5; cnt_1<=0; end
		   else  begin state_3<=4; data2_fin<=0; end	  
	  end
	5:
	  begin
	    if(cnt_1<2) begin  cnt_1<=cnt_1+1;  end
		 else if(cnt_1==2)
		  begin
	      data2<=CMD_to_485inout;
		   data2_fin<=1;
			cnt_1<=cnt_1+1;
		 end
		 else
		   if(pos_transfer_fin)  begin state_3<=6; cnt_1<=0; end
		   else  begin state_3<=5; data2_fin<=0; end
	  end
	6:
	  begin
	    if(cnt_1<2) begin  cnt_1<=cnt_1+1;  end
		 else if(cnt_1==2)
		  begin
	      data2<=8'h55;
		   data2_fin<=1;
			cnt_1<=cnt_1+1;
		 end
		 else
		   if(pos_transfer_fin)  begin state_3<=0; data2_fin<=0; end_respond_2E<=1; end
		   else  begin state_3<=6; data2_fin<=0; end	  
	  end
	 default: begin state_3<=0; data2_fin<=0; data2<=0;end_respond_2E<=0; end
	endcase
end

a1_485_inout a1_485_inout(
  .clk_96M(clk_96M),
  .rst(rst),
  .CMD(CMD_to_485inout),
  .pos_end_respond_2E(pos_end_respond_2E),
  .Receive_finish(Receive_finish),
  .read_finish(read_finish),
  .read_state(read_state),
  .f_re(f_re),
  .f_de(f_de)
);
endmodule
