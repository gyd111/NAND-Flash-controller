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
           input                clk    ,
           input                rst    ,
           input                start_w,    //test input write
           input                start_r,    //test input read
           input                start_e,    //test input erase
           output reg [31:0]    cmd    ,
           output reg           start_cmd   //cmd改变后产生一个该脉冲
       );


reg start_r_p,start_w_p,start_e_p,c_r_p;
wire pos_start_r,pos_start_w,pos_start_e,pos_c_r;
reg [7:0] cnt_send_cmd;
reg [2:0]start_send_reg;

parameter read_add          = 24'h01_02_03;
parameter write_add         = 24'h01_02_03;
parameter erase_start_add   = 24'h01_02_03;
parameter erase_end_add     = 24'h01_02_03;


always@(posedge clk or posedge rst) //检测上升沿
    if(rst) begin
        start_r_p <= 0;
        start_w_p <= 0;
        start_e_p <= 0;
    end
    else begin
        start_r_p <= start_r;
        start_w_p <= start_w;
        start_e_p <= start_e;
    end
assign pos_start_r = ~start_r_p && start_r;
assign pos_start_w = ~start_w_p && start_w;
assign pos_start_e = ~start_e_p && start_e;
always@(posedge clk) begin
    if(rst) begin
        cmd <= 0;
        start_cmd <= 0;
        start_send_reg <= 0;
        cnt_send_cmd <= 0;
    end
    else begin
        
        if(pos_start_w) begin
            start_send_reg <= 3'b100;
        end
        if(pos_start_r) begin
            start_send_reg <= 3'b101;
        end
        if(pos_start_e) begin
            start_send_reg <= 3'b110;
        end
        if(cnt_send_cmd == 30) begin
            start_send_reg <= 0;
            cnt_send_cmd <= 0;
        end
        else begin
            if(start_send_reg[2]) begin
                cnt_send_cmd <= cnt_send_cmd + 1;
                if(start_send_reg[1]) begin  //擦除flash
                    case (cnt_send_cmd)
                        7'b1: begin
                            start_cmd <= 7'd1;
                            cmd <= {16'hAE_00 , erase_start_add[23:8]};
                        end
                        7'd5: begin
                            start_cmd   <= 7'd0;
                        end
                        7'd9: begin
                            start_cmd <= 7'd1;
                            cmd <= {16'hAE_01,erase_start_add[7:0],8'h00};
                        end
                        7'd13: begin
                            start_cmd <= 7'd0;   
                        end
                        7'd17: begin
                            start_cmd <= 7'd1;
                            cmd <= {16'hAE_02,erase_end_add[23:8]};
                        end
                        7'd21: begin
                            start_cmd   <= 7'd0;
                        end
                        7'd25: begin
                           start_cmd    <= 7'd1;
                           cmd <= {16'hAE_03,erase_end_add[7:0],8'h00}; 
                        end
                        7'd29: begin
                            start_cmd   <= 7'd0;
                        end 
                        default: start_cmd  <= 7'd0;
                    endcase 
                end
                else if( start_send_reg[0]) begin   //读flash
                    if(cnt_send_cmd == 1) begin
                        start_cmd <= 1;
                        cmd <= {16'hAD_00,read_add[23:8]};
                    end
                    if(cnt_send_cmd == 5) begin
                        start_cmd <= 0;
                    end
                    if(cnt_send_cmd == 9) begin
                        start_cmd <= 1;
                        cmd <= {16'hAD_01,read_add[7:0],8'h00};
                    end
                    if(cnt_send_cmd == 13) begin
                        start_cmd <= 0;
                    end
                end
                else begin               //写flash
                    if(cnt_send_cmd == 1)//初始化写地址
                    begin
                        start_cmd <= 1;
                        cmd <= {16'hAF_00,write_add[23:8]};
                    end
                    if(cnt_send_cmd == 5) begin
                        start_cmd <= 0;
                    end
                    if(cnt_send_cmd == 9) begin
                        start_cmd <= 1;
                        cmd <= {16'hAF_01,write_add[7:0],8'h00};
                    end
                    if(cnt_send_cmd == 13) begin
                        start_cmd <= 0;
                    end
                    if(cnt_send_cmd == 17)//开始写flash
                    begin
                        start_cmd <= 1;
                        cmd <= 32'hA0_00_0000;
                    end
                    if(cnt_send_cmd == 21) begin
                        start_cmd <= 0; 
                    end
                end
            end
        end
    end
end

endmodule
