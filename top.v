`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/19 09:50:17
// Design Name: 
// Module Name: top
// Project Name: nandflash control
// Target Devices: 
// Tool Versions: 
// Description: 
//              ASYNC
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input clk_in,
    input r_b,
    
    inout dqs,
    inout [7:0] dq,
    
    output ale,
    output ce,
    output	ce2,
    output cle,
    output re,
    output we,
    output wp,
    
    output led1,
    output led2,
    output n14,
    output n15,
    output p14,
    output p15,
    output test1,
    output test2
/*   signal for simulation*/
//    output [4:0]state,
//    input start_r,
//    input start_w,
//    input start_e,
//    output inout_flag//simulation
    );

//*************       Clock模块        *************//
	 wire rst,clk24M,clk6M,clk12M,clk1M,clk1_5M,clk96M,clk1;


/************************ contorl wire **********************************************/
wire [6:0]state_en_reg;
/************************ 测试 ******************************************************/
wire en_MCU;
wire [7:0]MCU_dataout;
wire [14:0]add_MCU;
reg [7:0]MCU_dataout_t;
reg[2:0]cnt_t;
wire start_w,start_r,start_e;
wire [4:0]state;
wire change_ram;//change ram
wire test_nf;
wire [7:0] dq;
wire    [7:0]   flash_data;

//assign flash_data = dq;
assign	ce2 = 1'b1; // target2's ce, always disable target2
assign n14 = cle;
assign n15 = ale;
assign p14 = we;
assign p15 = re;
assign wp = 1;

assign test1 = clk24M;
assign test2 = clk6M;

//vio_0 inst_vio_0(
//    .clk(clk24M ),
//    .probe_in0( MCU_dataout ),
//    .probe_in1(state),
//    .probe_in2(test_nf),
//    .probe_out0( en_MCU ),
//    .probe_out1( add_MCU ),
//    .probe_out2( start_w),
//    .probe_out3( start_r),
//    .probe_out4(change_ram),
//    .probe_out5(start_e)
//);

//ila_1 inst_ila_0(
//    .clk(clk6M),
//    .probe0( MCU_dataout)
//);

vio_re_wr_er vio_re_wr_er_inst (
  .clk(clk24M),             // input wire clk
  .probe_out0(start_r),     // output wire [0 : 0] probe_out0
  .probe_out1(start_w),     // output wire [0 : 0] probe_out1
  .probe_out2(start_e),      // output wire [0 : 0] probe_out2
  .probe_in0(state)
);

always@(posedge rst or posedge clk1)
begin
    if(rst)
    begin
        MCU_dataout_t <= 0;
        cnt_t <= 0;
    end
    else
    begin
        if(cnt_t ==0)
        begin
            MCU_dataout_t <= MCU_dataout;
            cnt_t <= 0;
        end
        else
            cnt_t <= cnt_t + 1;
    end
end

//****************************************************//
//					时钟例化											//
//****************************************************//
	clk_div clk_1 (
    .clk(clk_in), 
    .rst(rst), 
    .clk24M(clk24M), 
    .clk6M(clk6M), 
    .clk12M(clk12M), 
    .clk1M5(clk1_5M), 
    .clk1M(clk1M),
	 .clk96M(clk96M),
	 .clk1(clk1)
    );



test_nandflash test_nandflash(
    .clk_96M(clk96M),
	.clk( clk24M),
	.clk12M(clk12M),
	.clk1_5M(clk1_5M), 
    .clk1M(clk1M),
	.clk6M(clk6M),
	.rst( rst),
	.en_waveRam( en_MCU ),
	.we_waveRam( 0 ),
	.address_waveRam( add_MCU ),
	.data_in_waveRam(  ),
	.MCU_dataout( MCU_dataout ),
	
    .flash_IO(dq),
	.ready_busy(r_b),												//flash空闲/忙碌标志信号
	.ce(ce),
	.cle(cle),
	.ale(ale),
	.we(we),
	.re(re),									//flash控制信号
	
	.start_r( start_r),
	.start_w(start_w),
	.start_e(start_e),
	.state(state),
	.c_r( change_ram),
	.ram_adj(test_nf),
	.inout_flag(inout_flag)//
	
);

//always@(posedge clk1 or posedge rst)
//begin
//    if(rst)
//    begin
//        led1 <= 0;
//    end
//    else
//    begin
//        led1 <= ~led1;
//    end
//end
breath_led  breath_led_inst(
    .sys_clk   (clk_in),  //50Mhz
    .sys_rst_n (~rst),  
    .led       (led1)   
);



endmodule
