`timescale 1ns / 1ps
module breath_led(
    input   sys_clk   ,  //时钟信号50Mhz
    input   sys_rst_n ,  //复位信号

    output  led          //LED
);

//reg define
reg  [15:0]  period_cnt ;   //周期计数器频率：1khz 周期:1ms  计数值:1ms/20ns=50000
reg  [15:0]  duty_cycle ;   //占空比数值
reg          inc_dec_flag ; //0 递增  1 递减


//根据占空比和计数值之间的大小关系来输出LED
assign   led = (period_cnt >= duty_cycle) ?  1'b1  :  1'b0;

//周期计数器
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        period_cnt <= 16'd0;
    else if(period_cnt == 16'd50000)
        period_cnt <= 16'd0;
    else
        period_cnt <= period_cnt + 1'b1;
end

//在周期计数器的节拍下递增或递减占空比
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        duty_cycle   <= 16'd0;
        inc_dec_flag <= 1'b0;
    end
    else begin
        if(period_cnt == 16'd50000) begin    //计满1ms
            if(inc_dec_flag == 1'b0) begin   //占空比递增状态
                if(duty_cycle == 16'd50000)  //如果占空比已递增至最大
                    inc_dec_flag <= 1'b1;    //则占空比开始递减
                else                         //否则占空比以25为单位递增
                    duty_cycle <= duty_cycle + 16'd50; // cycle = 2 * 50000 / 50 * 1ms = 2s
            end
            else begin                       //占空比递减状态
                if(duty_cycle == 16'd0)      //如果占空比已递减至0
                    inc_dec_flag <= 1'b0;    //则占空比开始递增
                else                         //否则占空比以25为单位递减
                    duty_cycle <= duty_cycle - 16'd25;
            end
        end
    end
end

endmodule
