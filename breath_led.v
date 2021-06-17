`timescale 1ns / 1ps
module breath_led(
    input   sys_clk   ,  //ʱ���ź�50Mhz
    input   sys_rst_n ,  //��λ�ź�

    output  led          //LED
);

//reg define
reg  [15:0]  period_cnt ;   //���ڼ�����Ƶ�ʣ�1khz ����:1ms  ����ֵ:1ms/20ns=50000
reg  [15:0]  duty_cycle ;   //ռ�ձ���ֵ
reg          inc_dec_flag ; //0 ����  1 �ݼ�


//����ռ�ձȺͼ���ֵ֮��Ĵ�С��ϵ�����LED
assign   led = (period_cnt >= duty_cycle) ?  1'b1  :  1'b0;

//���ڼ�����
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        period_cnt <= 16'd0;
    else if(period_cnt == 16'd50000)
        period_cnt <= 16'd0;
    else
        period_cnt <= period_cnt + 1'b1;
end

//�����ڼ������Ľ����µ�����ݼ�ռ�ձ�
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        duty_cycle   <= 16'd0;
        inc_dec_flag <= 1'b0;
    end
    else begin
        if(period_cnt == 16'd50000) begin    //����1ms
            if(inc_dec_flag == 1'b0) begin   //ռ�ձȵ���״̬
                if(duty_cycle == 16'd50000)  //���ռ�ձ��ѵ��������
                    inc_dec_flag <= 1'b1;    //��ռ�ձȿ�ʼ�ݼ�
                else                         //����ռ�ձ���25Ϊ��λ����
                    duty_cycle <= duty_cycle + 16'd50; // cycle = 2 * 50000 / 50 * 1ms = 2s
            end
            else begin                       //ռ�ձȵݼ�״̬
                if(duty_cycle == 16'd0)      //���ռ�ձ��ѵݼ���0
                    inc_dec_flag <= 1'b0;    //��ռ�ձȿ�ʼ����
                else                         //����ռ�ձ���25Ϊ��λ�ݼ�
                    duty_cycle <= duty_cycle - 16'd25;
            end
        end
    end
end

endmodule
