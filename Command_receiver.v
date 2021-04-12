`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:20:37 10/21/2015 
// Design Name: 
// Module Name:    Command_Receiver 
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
module Command_Receiver(
	input clk,
	input rst,
	input start_w,//test input write
	input start_r,//test input read
	input start_e,//test input erase
	input c_r,//test change ram
	input end_clr,				//������ɱ�־λ
	input end_demand_write_addr,
	input ram_change,
	input return_bypass,             //ʹ��UART_A1�ص�ֱͨ״̬
	output reg change_bypass,        //ʹ���ж�uart_A1ֱͨ״̬
	output reg en_demand_write_addr,
	output reg change_ram,	
	output reg en_clr,      //����ʹ��
	output reg [31:0]cmd,
	output reg uart_cmd_incomplete,  //uart��������ղ�������־
	output reg start_cmd		//cmd�ı�����һ��������
    );
	
	 reg [31:0]cmd_reg;
	 wire pos_start_trs;
	 reg start_trs;
	 reg start_trs_r;
	 reg [7:0] cmd_data;
	 reg [2:0] cmd_cnt;
	 reg [7:0] cmd_select;
	 reg rx_r1;
	 reg rx_r2;
	 reg [9:0] cmd_buf;//�����
	 reg [9:7] sample;//�����Ĵ���
	 reg [4:0] i;//����ʱ��������
	 reg [3:0] cnt;//���� λ����
	 
	 reg en_send;
	 reg en_send_r;//���ڲ���һ�������start_trs
	 
	 wire neg_trig;    //�½��ش��� ��ʼ��������
	 
	 reg [15:0] cmd_incomplete_cnt;  //uart��������ռ����ʱ
	 reg start_cnt;                 //uart��������ռ����ʱ��ʼ��־

reg start_r_p,start_w_p,start_e_p,c_r_p;
wire pos_start_r,pos_start_w,pos_start_e,pos_c_r;
reg [7:0] cnt_send_cmd;
reg [2:0]start_send_reg;

parameter read_add          = 24'h01_02_03;
parameter write_add         = 24'h01_02_03;
parameter erase_start_add   = 24'h01_02_03;
parameter erase_end_add     = 24'h01_02_03;
	 
	 always@(posedge clk or posedge rst)
	 begin
	   if(rst)
		  begin
		    cmd_incomplete_cnt <=0;
			 uart_cmd_incomplete <=0;
		  end
		else
		  begin
		    if(start_cnt)
			   begin
				  if(cmd_incomplete_cnt == 24000 )     //��ʱ1ms
				    uart_cmd_incomplete <= 1;
				  else
				    cmd_incomplete_cnt <= cmd_incomplete_cnt+1;
				end
			 else
			   begin
				  cmd_incomplete_cnt <=0;
			     uart_cmd_incomplete <=0;
				end
		  end		
	 end

	 
	 always@(posedge clk or posedge rst)
	 begin
		if(rst) begin start_trs <= 0; en_send_r <= 1; end
		else 
			begin
				en_send_r <= en_send;  //en_send_r��en_send��һ��ʱ������
				if(en_send_r) start_trs <= 0; //��⵽en_send_rΪ�ߵ�ʱ�� �õ�
				if(en_send) start_trs <= 1; //��⵽en_send��ʱ�� �ø�
			end
	 end
	 
	 	always @(posedge clk or posedge rst)  //���������
	 begin
		if(rst) start_trs_r <= 0;
		else start_trs_r <= start_trs;
	 end
	 assign pos_start_trs = ~start_trs_r && start_trs; 

always@(posedge clk or posedge rst) //���������
    if(rst)
    begin
        start_r_p <= 0;
        start_w_p <= 0;
        start_e_p <= 0;
        c_r_p <= 0;
    end
    else
    begin
        start_r_p <= start_r;
        start_w_p <= start_w;
        start_e_p <= start_e;
        c_r_p <= c_r;
    end
assign pos_start_r = ~start_r_p && start_r;
assign pos_start_w = ~start_w_p && start_w;
assign pos_start_e = ~start_e_p && start_e;
assign pos_c_r = ~c_r_p && c_r;
always@(posedge clk or posedge rst)
begin
    if(rst)
    begin
        cmd <= 0;
        start_cmd <= 0;
        start_send_reg <= 0;
        cnt_send_cmd <= 0;
        change_ram <= 0;
    end
    else
    begin
//        if(start_cmd)
//            start_cmd <= 0;
//        else
        if(change_ram)
            change_ram <= 0;
        else if(pos_c_r)
            change_ram <= 1;
        
        begin
            if(pos_start_w)
            begin
                start_send_reg <= 3'b100;
            end
            if(pos_start_r)
            begin
                start_send_reg <= 3'b101;
            end
            if(pos_start_e)
            begin
                start_send_reg <= 3'b110;
            end
            
            if(cnt_send_cmd == 30)
            begin
                start_send_reg <= 0;
                cnt_send_cmd <= 0;
            end
            else
            begin
                if(start_send_reg[2])
                begin
                    cnt_send_cmd <= cnt_send_cmd + 1;
                    if(start_send_reg[1])   //����flash
                    begin
                        if(cnt_send_cmd == 1)
                        begin
                            start_cmd <= 1;
                            cmd <= {16'hAE_00 , erase_start_add[23:8]};
                        end
                        if(cnt_send_cmd == 5)
                        begin
                            start_cmd <= 0;
                        end
                        if(cnt_send_cmd == 9)
                        begin
                            start_cmd <= 1;
                            cmd <= {16'hAE_01,erase_start_add[7:0],8'h00};
                        end
                        if(cnt_send_cmd == 13)
                        begin
                            start_cmd <= 0;
                        end
                        if(cnt_send_cmd == 17)
                        begin
                            start_cmd <= 1;
                            cmd <= {16'hAE_02,erase_end_add[23:8]};
                        end
                        if(cnt_send_cmd == 21)
                        begin
                            start_cmd <= 0;
                        end
                        if(cnt_send_cmd == 25)
                        begin
                            start_cmd <= 1;
                            cmd <= {16'hAE_03,erase_end_add[7:0],8'h00};
                        end
                        if(cnt_send_cmd == 29)
                        begin
                            start_cmd <= 0;
                        end
                        
                    end
                    else
                    if( start_send_reg[0])  //��flash
                    begin
                        if(cnt_send_cmd == 1)
                        begin
                            start_cmd <= 1;
                            cmd <= {16'hAD_00,read_add[23:8]};
                        end
                        if(cnt_send_cmd == 5)
                        begin
                            start_cmd <= 0;
                        end
                        if(cnt_send_cmd == 9)
                        begin
                            start_cmd <= 1;
                            cmd <= {16'hAD_01,read_add[7:0],8'h00};
                        end
                        if(cnt_send_cmd == 13)
                        begin
                            start_cmd <= 0;
                        end
                    end
                    else
                    begin               //дflash
                        if(cnt_send_cmd == 1)//��ʼ��д��ַ
                        begin
                            start_cmd <= 1;
                            cmd <= {16'hAF_00,write_add[23:8]};
                        end
                        if(cnt_send_cmd == 5)
                        begin
                            start_cmd <= 0;
                        end
                        if(cnt_send_cmd == 9)
                        begin
                            start_cmd <= 1;
                            cmd <= {16'hAF_01,write_add[7:0],8'h00};
                        end
                        if(cnt_send_cmd == 13)
                        begin
                            start_cmd <= 0;
                        end
                        if(cnt_send_cmd == 17)//��ʼдflash
                        begin
                            start_cmd <= 1;
                            cmd <= 32'hA0_00_0000;
                        end
                        if(cnt_send_cmd == 21)
                        begin
                            start_cmd <= 0;
                        end
                    end
                end
            end
        end
    end
end
	 
	 always @ (posedge clk or posedge rst)
	 begin
		if(rst)
		begin
//			cmd <= 32'b0;
			cmd_cnt <= 3'b000;
//			start_cmd <=0;
			start_cnt<=0;
		end
		else
		begin
//			if(start_cmd)
//				start_cmd<=0;
//			else
				if(pos_start_trs)
				begin
					case(cmd_cnt)
						0: begin cmd_select[7:0] <= cmd_data[7:0];cmd_reg[31:24] <= cmd_data[7:0];cmd_cnt<=1;start_cnt<=1;end
						1: begin cmd_reg[23:16] <= cmd_data[7:0];cmd_cnt<=2;end
						2: begin cmd_reg[15:8] <= cmd_data[7:0];cmd_cnt<=3;end
//						3: begin cmd[31:8]<=cmd_reg[31:8];cmd[7:0]<=cmd_data[7:0];cmd_cnt<=0;start_cmd<=1;start_cnt<=0;end
//						default: begin cmd_cnt<=0;start_cmd<=0;end
					endcase
				end
		end
	 end
		

	always @ (posedge clk or posedge rst)
	begin
		if(rst)
		begin
//			change_ram <= 0;
			en_clr <= 0;
		   change_bypass<=0;
			en_demand_write_addr<=0;
		end
//		else if(cmd_cnt == 3)
//			begin
//				case(cmd_select)
//					8'h55:begin en_demand_write_addr<=0;change_ram <= 0;en_clr <= 1;change_bypass<=0;  end		//����ram
//			//		8'hAA:begin en_demand_write_addr<=0;change_ram <= 1;en_clr <= 0;en_write <= 1;end		   //�л�ram+������д��flash
//					8'hAB:begin en_demand_write_addr<=0;change_ram <= 1;en_clr <= 0;change_bypass<=0;   end	//ֻ�л�ram
//					8'hB2:begin en_demand_write_addr<=1;change_ram <= 0;en_clr <= 0;change_bypass<=0;   end	//��Ҫflashд��ַ
//					8'hB4:begin en_demand_write_addr<=0;change_ram <= 0;en_clr <= 0;change_bypass<=1;   end   //�ж�uart_A1��ֱͨ��FPGA������485��������
//					default : begin en_demand_write_addr<=0;change_ram <= 0;en_clr <= 0;change_bypass <= change_bypass; end
//				endcase
//			end
//		else
//			begin
//			   change_ram<=0;
//				if(en_clr && end_clr) en_clr <= 0;
//            if(change_bypass && return_bypass) change_bypass<=0;
//				if(en_demand_write_addr && end_demand_write_addr) en_demand_write_addr <= 0;
//			end
	end
	 
endmodule
