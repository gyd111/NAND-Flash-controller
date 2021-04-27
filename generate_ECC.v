`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:18:01 04/03/2018 
// Design Name: 
// Module Name:    generate_ECC 
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
module write_generate_ECC(
	input	[7:0]	prior_data1,
	input			clk,
	input			rst,
	input			ECC_start,
	input 		[6:0]	data_cnt1,
//	output reg	[7:0]	ECC_data,
	output reg	[7:0]	cp,
	output reg	[15:0]	rp
//	output reg	ECC_out

	
//为了观测添加的输出信号
//	output	reg	[2:0]	code_time,
//	output	reg			init_xor_code,
//	output	reg			otp_finish,
//	output	reg	[7:0]	column_xor,
//	output	reg	[127:0]	row_xor
	);
	
	reg [6:0]data_cnt;
	reg [7:0]prior_data;
	
	reg	[2:0]		code_time;	//对ECC_data赋值次数
	wire otp_finish;	//一次128byte数据的基础异或完成
	reg init_xor_code;	//清除基础行列异或值标志位
	reg [7:0]	column_xor;
	reg [127:0]	row_xor;
///	assign	otp_finish = (data_cnt == 7'b1111111) ? 1 : 0;
//将8bit的数据依次按位异或得到异或后的值（列异或值）
	
	always@(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			data_cnt <= 0;
			prior_data <= 0;
		end
		else
		begin
			data_cnt <= data_cnt1;
			prior_data <= prior_data1;
		end
	end
	
	always @(negedge clk or posedge rst)
	begin
		if(rst)
			column_xor <= 8'h00;
		else
		begin
			if(ECC_start == 1)
			begin
				column_xor <= column_xor ^ prior_data1;
			end
			else
			begin
				if(init_xor_code == 1)
					column_xor <= 8'h00;
				else
					column_xor <= column_xor;
			end
		end
	end

 assign otp_finish = (data_cnt[6]) & (data_cnt[5]) & (data_cnt[4]) & (data_cnt[3]) & (data_cnt[2]) & (data_cnt[1]) & (data_cnt[0]);
	

	always @(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			row_xor <= 0;
//			otp_finish <= 1'b0;
		end
		else
		begin
			if(ECC_start == 1)
				case(data_cnt)
				8'd0:
					row_xor[0] <= ^prior_data;
				8'd1:
					row_xor[1] <= ^prior_data;
				8'd2:
					row_xor[2] <= ^prior_data;
				8'd3:
					row_xor[3] <= ^prior_data;
				8'd4:
					row_xor[4] <= ^prior_data;
				8'd5:
					row_xor[5] <= ^prior_data;
				8'd6:
					row_xor[6] <= ^prior_data;
				8'd7:
					row_xor[7] <= ^prior_data;
				8'd8:
					row_xor[8] <= ^prior_data;
				8'd9:
					row_xor[9] <= ^prior_data;
				8'd10:
					row_xor[10] <= ^prior_data;
				8'd11:
					row_xor[11] <= ^prior_data;
				8'd12:
					row_xor[12] <= ^prior_data;
				8'd13:
					row_xor[13] <= ^prior_data;
				8'd14:
					row_xor[14] <= ^prior_data;
				8'd15:
					row_xor[15] <= ^prior_data;
				8'd16:
					row_xor[16] <= ^prior_data;
				8'd17:
					row_xor[17] <= ^prior_data;
				8'd18:
					row_xor[18] <= ^prior_data;
				8'd19:
					row_xor[19] <= ^prior_data;
				8'd20:
					row_xor[20] <= ^prior_data;
				8'd21:
					row_xor[21] <= ^prior_data;
				8'd22:
					row_xor[22] <= ^prior_data;
				8'd23:
					row_xor[23] <= ^prior_data;
				8'd24:
					row_xor[24] <= ^prior_data;
				8'd25:
					row_xor[25] <= ^prior_data;
				8'd26:
					row_xor[26] <= ^prior_data;
				8'd27:
					row_xor[27] <= ^prior_data;
				8'd28:
					row_xor[28] <= ^prior_data;
				8'd29:
					row_xor[29] <= ^prior_data;
				8'd30:
					row_xor[30] <= ^prior_data;
				8'd31:
					row_xor[31] <= ^prior_data;
				8'd32:
					row_xor[32] <= ^prior_data;
				8'd33:
					row_xor[33] <= ^prior_data;
				8'd34:
					row_xor[34] <= ^prior_data;
				8'd35:
					row_xor[35] <= ^prior_data;
				8'd36:
					row_xor[36] <= ^prior_data;
				8'd37:
					row_xor[37] <= ^prior_data;
				8'd38:
					row_xor[38] <= ^prior_data;
				8'd39:
					row_xor[39] <= ^prior_data;
				8'd40:
					row_xor[40] <= ^prior_data;
				8'd41:
					row_xor[41] <= ^prior_data;
				8'd42:
					row_xor[42] <= ^prior_data;
				8'd43:
					row_xor[43] <= ^prior_data;
				8'd44:
					row_xor[44] <= ^prior_data;
				8'd45:
					row_xor[45] <= ^prior_data;
				8'd46:
					row_xor[46] <= ^prior_data;
				8'd47:
					row_xor[47] <= ^prior_data;
				8'd48:
					row_xor[48] <= ^prior_data;
				8'd49:
					row_xor[49] <= ^prior_data;
				8'd50:
					row_xor[50] <= ^prior_data;
				8'd51:
					row_xor[51] <= ^prior_data;
				8'd52:
					row_xor[52] <= ^prior_data;
				8'd53:
					row_xor[53] <= ^prior_data;
				8'd54:
					row_xor[54] <= ^prior_data;
				8'd55:
					row_xor[55] <= ^prior_data;
				8'd56:
					row_xor[56] <= ^prior_data;
				8'd57:
					row_xor[57] <= ^prior_data;
				8'd58:
					row_xor[58] <= ^prior_data;
				8'd59:
					row_xor[59] <= ^prior_data;
				8'd60:
					row_xor[60] <= ^prior_data;
				8'd61:
					row_xor[61] <= ^prior_data;
				8'd62:
					row_xor[62] <= ^prior_data;
				8'd63:
					row_xor[63] <= ^prior_data;
				8'd64:
					row_xor[64] <= ^prior_data;
				8'd65:
					row_xor[65] <= ^prior_data;
				8'd66:
					row_xor[66] <= ^prior_data;
				8'd67:
					row_xor[67] <= ^prior_data;
				8'd68:
					row_xor[68] <= ^prior_data;
				8'd69:
					row_xor[69] <= ^prior_data;
				8'd70:
					row_xor[70] <= ^prior_data;
				8'd71:
					row_xor[71] <= ^prior_data;
				8'd72:
					row_xor[72] <= ^prior_data;
				8'd73:
					row_xor[73] <= ^prior_data;
				8'd74:
					row_xor[74] <= ^prior_data;
				8'd75:
					row_xor[75] <= ^prior_data;
				8'd76:
					row_xor[76] <= ^prior_data;
				8'd77:
					row_xor[77] <= ^prior_data;
				8'd78:
					row_xor[78] <= ^prior_data;
				8'd79:
					row_xor[79] <= ^prior_data;
				8'd80:
					row_xor[80] <= ^prior_data;
				8'd81:
					row_xor[81] <= ^prior_data;
				8'd82:
					row_xor[82] <= ^prior_data;
				8'd83:
					row_xor[83] <= ^prior_data;
				8'd84:
					row_xor[84] <= ^prior_data;
				8'd85:
					row_xor[85] <= ^prior_data;
				8'd86:
					row_xor[86] <= ^prior_data;
				8'd87:
					row_xor[87] <= ^prior_data;
				8'd88:
					row_xor[88] <= ^prior_data;
				8'd89:
					row_xor[89] <= ^prior_data;
				8'd90:
					row_xor[90] <= ^prior_data;
				8'd91:
					row_xor[91] <= ^prior_data;
				8'd92:
					row_xor[92] <= ^prior_data;
				8'd93:
					row_xor[93] <= ^prior_data;
				8'd94:
					row_xor[94] <= ^prior_data;
				8'd95:
					row_xor[95] <= ^prior_data;
				8'd96:
					row_xor[96] <= ^prior_data;
				8'd97:
					row_xor[97] <= ^prior_data;
				8'd98:
					row_xor[98] <= ^prior_data;
				8'd99:
					row_xor[99] <= ^prior_data;
				8'd100:
					row_xor[100] <= ^prior_data;
				8'd101:
					row_xor[101] <= ^prior_data;
				8'd102:
					row_xor[102] <= ^prior_data;
				8'd103:
					row_xor[103] <= ^prior_data;
				8'd104:
					row_xor[104] <= ^prior_data;
				8'd105:
					row_xor[105] <= ^prior_data;
				8'd106:
					row_xor[106] <= ^prior_data;
				8'd107:
					row_xor[107] <= ^prior_data;
				8'd108:
					row_xor[108] <= ^prior_data;
				8'd109:
					row_xor[109] <= ^prior_data;
				8'd110:
					row_xor[110] <= ^prior_data;
				8'd111:
					row_xor[111] <= ^prior_data;
				8'd112:
					row_xor[112] <= ^prior_data;
				8'd113:
					row_xor[113] <= ^prior_data;
				8'd114:
					row_xor[114] <= ^prior_data;
				8'd115:
					row_xor[115] <= ^prior_data;
				8'd116:
					row_xor[116] <= ^prior_data;
				8'd117:
					row_xor[117] <= ^prior_data;
				8'd118:
					row_xor[118] <= ^prior_data;
				8'd119:
					row_xor[119] <= ^prior_data;
				8'd120:
					row_xor[120] <= ^prior_data;
				8'd121:
					row_xor[121] <= ^prior_data;
				8'd122:
					row_xor[122] <= ^prior_data;
				8'd123:
					row_xor[123] <= ^prior_data;
				8'd124:
					row_xor[124] <= ^prior_data;
				8'd125:
					row_xor[125] <= ^prior_data;
				8'd126:
					row_xor[126] <= ^prior_data;
				8'd127:
					row_xor[127] <= ^prior_data;
				endcase
			else
			begin
				if(init_xor_code == 1)
					row_xor <= 0;
				else
					row_xor <= row_xor;
			end
		end
	end
	
	
//三位ECC码的编写
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			cp <= 8'h00;
			rp <= 16'h0000;
		end
		else
		begin
			if(otp_finish == 1)
			begin
				if(init_xor_code == 0)
				begin
					cp[0]	<= column_xor[0] ^ column_xor[2] ^ column_xor[4] ^ column_xor[6];
					cp[1]	<= column_xor[1] ^ column_xor[3] ^ column_xor[5] ^ column_xor[7];
					cp[2] <= column_xor[0] ^ column_xor[1] ^ column_xor[4] ^ column_xor[5];
					cp[3] <= column_xor[2] ^ column_xor[3] ^ column_xor[6] ^ column_xor[7];
					cp[4] <= column_xor[0] ^ column_xor[1] ^ column_xor[2] ^ column_xor[3];
					cp[5] <= column_xor[4] ^ column_xor[5] ^ column_xor[6] ^ column_xor[7];
					cp[6] <= 1'b1;
					cp[7] <= 1'b1;
					rp[0]	<= row_xor[0] ^ row_xor[2] ^ row_xor[4] ^ row_xor[6] ^ row_xor[8] ^ row_xor[10] ^ row_xor[12] ^ row_xor[14] ^ row_xor[16] ^ row_xor[18] ^ row_xor[20] ^ row_xor[22] ^ row_xor[24] ^ row_xor[26] ^ row_xor[28] ^ row_xor[30] ^ row_xor[32] ^ row_xor[34] ^ row_xor[36] ^ row_xor[38] ^ row_xor[40] ^ row_xor[42] ^ row_xor[44] ^ row_xor[46] ^ row_xor[48] ^ row_xor[50] ^ row_xor[52] ^ row_xor[54] ^ row_xor[56] ^ row_xor[58] ^ row_xor[60] ^ row_xor[62] ^ row_xor[64] ^ row_xor[66] ^ row_xor[68] ^ row_xor[70] ^ row_xor[72] ^ row_xor[74] ^ row_xor[76] ^ row_xor[78] ^ row_xor[80] ^ row_xor[82] ^ row_xor[84] ^ row_xor[86] ^ row_xor[88] ^ row_xor[90] ^ row_xor[92] ^ row_xor[94] ^ row_xor[96] ^ row_xor[98] ^ row_xor[100] ^ row_xor[102] ^ row_xor[104] ^ row_xor[106] ^ row_xor[108] ^ row_xor[110] ^ row_xor[112] ^ row_xor[114] ^ row_xor[116] ^ row_xor[118] ^ row_xor[120] ^ row_xor[122] ^ row_xor[124] ^ row_xor[126];
					rp[1] <=	row_xor[1] ^ row_xor[3] ^ row_xor[5] ^ row_xor[7] ^ row_xor[9] ^ row_xor[11] ^ row_xor[13] ^ row_xor[15] ^ row_xor[17] ^ row_xor[19] ^ row_xor[21] ^ row_xor[23] ^ row_xor[25] ^ row_xor[27] ^ row_xor[29] ^ row_xor[31] ^ row_xor[33] ^ row_xor[35] ^ row_xor[37] ^ row_xor[39] ^ row_xor[41] ^ row_xor[43] ^ row_xor[45] ^ row_xor[47] ^ row_xor[49] ^ row_xor[51] ^ row_xor[53] ^ row_xor[55] ^ row_xor[57] ^ row_xor[59] ^ row_xor[61] ^ row_xor[63] ^ row_xor[65] ^ row_xor[67] ^ row_xor[69] ^ row_xor[71] ^ row_xor[73] ^ row_xor[75] ^ row_xor[77] ^ row_xor[79] ^ row_xor[81] ^ row_xor[83] ^ row_xor[85] ^ row_xor[87] ^ row_xor[89] ^ row_xor[91] ^ row_xor[93] ^ row_xor[95] ^ row_xor[97] ^ row_xor[99] ^ row_xor[101] ^ row_xor[103] ^ row_xor[105] ^ row_xor[107] ^ row_xor[109] ^ row_xor[111] ^ row_xor[113] ^ row_xor[115] ^ row_xor[117] ^ row_xor[119] ^ row_xor[121] ^ row_xor[123] ^ row_xor[125] ^ row_xor[127];					
					rp[2] <= row_xor[0] ^ row_xor[1] ^ row_xor[4] ^ row_xor[5] ^ row_xor[8] ^ row_xor[9] ^ row_xor[12] ^ row_xor[13] ^ row_xor[16] ^ row_xor[17] ^ row_xor[20] ^ row_xor[21] ^ row_xor[24] ^ row_xor[25] ^ row_xor[28] ^ row_xor[29] ^ row_xor[32] ^ row_xor[33] ^ row_xor[36] ^ row_xor[37] ^ row_xor[40] ^ row_xor[41] ^ row_xor[44] ^ row_xor[45] ^ row_xor[48] ^ row_xor[49] ^ row_xor[52] ^ row_xor[53] ^ row_xor[56] ^ row_xor[57] ^ row_xor[60] ^ row_xor[61] ^ row_xor[64] ^ row_xor[65] ^ row_xor[68] ^ row_xor[69] ^ row_xor[72] ^ row_xor[73] ^ row_xor[76] ^ row_xor[77] ^ row_xor[80] ^ row_xor[81] ^ row_xor[84] ^ row_xor[85] ^ row_xor[88] ^ row_xor[89] ^ row_xor[92] ^ row_xor[93] ^ row_xor[96] ^ row_xor[97] ^ row_xor[100] ^ row_xor[101] ^ row_xor[104] ^ row_xor[105] ^ row_xor[108] ^ row_xor[109] ^ row_xor[112] ^ row_xor[113] ^ row_xor[116] ^ row_xor[117] ^ row_xor[120] ^ row_xor[121] ^ row_xor[124] ^ row_xor[125];
					rp[3] <= row_xor[2] ^ row_xor[3] ^ row_xor[6] ^ row_xor[7] ^ row_xor[10] ^ row_xor[11] ^ row_xor[14] ^ row_xor[15] ^ row_xor[18] ^ row_xor[19] ^ row_xor[22] ^ row_xor[23] ^ row_xor[26] ^ row_xor[27] ^ row_xor[30] ^ row_xor[31] ^ row_xor[34] ^ row_xor[35] ^ row_xor[38] ^ row_xor[39] ^ row_xor[42] ^ row_xor[43] ^ row_xor[46] ^ row_xor[47] ^ row_xor[50] ^ row_xor[51] ^ row_xor[54] ^ row_xor[55] ^ row_xor[58] ^ row_xor[59] ^ row_xor[62] ^ row_xor[63] ^ row_xor[66] ^ row_xor[67] ^ row_xor[70] ^ row_xor[71] ^ row_xor[74] ^ row_xor[75] ^ row_xor[78] ^ row_xor[79] ^ row_xor[82] ^ row_xor[83] ^ row_xor[86] ^ row_xor[87] ^ row_xor[90] ^ row_xor[91] ^ row_xor[94] ^ row_xor[95] ^ row_xor[98] ^ row_xor[99] ^ row_xor[102] ^ row_xor[103] ^ row_xor[106] ^ row_xor[107] ^ row_xor[110] ^ row_xor[111] ^ row_xor[114] ^ row_xor[115] ^ row_xor[118] ^ row_xor[119] ^ row_xor[122] ^ row_xor[123] ^ row_xor[126] ^ row_xor[127];
					rp[4] <= row_xor[0] ^ row_xor[1] ^ row_xor[2] ^ row_xor[3] ^ row_xor[8] ^ row_xor[9] ^ row_xor[10] ^ row_xor[11] ^ row_xor[16] ^ row_xor[17] ^ row_xor[18] ^ row_xor[19] ^ row_xor[24] ^ row_xor[25] ^ row_xor[26] ^ row_xor[27] ^ row_xor[32] ^ row_xor[33] ^ row_xor[34] ^ row_xor[35] ^ row_xor[40] ^ row_xor[41] ^ row_xor[42] ^ row_xor[43] ^ row_xor[48] ^ row_xor[49] ^ row_xor[50] ^ row_xor[51] ^ row_xor[56] ^ row_xor[57] ^ row_xor[58] ^ row_xor[59] ^ row_xor[64] ^ row_xor[65] ^ row_xor[66] ^ row_xor[67] ^ row_xor[72] ^ row_xor[73] ^ row_xor[74] ^ row_xor[75] ^ row_xor[80] ^ row_xor[81] ^ row_xor[82] ^ row_xor[83] ^ row_xor[88] ^ row_xor[89] ^ row_xor[90] ^ row_xor[91] ^ row_xor[96] ^ row_xor[97] ^ row_xor[98] ^ row_xor[99] ^ row_xor[104] ^ row_xor[105] ^ row_xor[106] ^ row_xor[107] ^ row_xor[112] ^ row_xor[113] ^ row_xor[114] ^ row_xor[115] ^ row_xor[120] ^ row_xor[121] ^ row_xor[122] ^ row_xor[123];
					rp[5] <= row_xor[4] ^ row_xor[5] ^ row_xor[6] ^ row_xor[7] ^row_xor[12] ^ row_xor[13] ^ row_xor[14] ^ row_xor[15] ^ row_xor[20] ^ row_xor[21] ^ row_xor[22] ^ row_xor[23] ^ row_xor[28] ^ row_xor[29] ^ row_xor[30] ^ row_xor[31] ^ row_xor[36] ^ row_xor[37] ^ row_xor[38] ^ row_xor[39] ^ row_xor[44] ^ row_xor[45] ^ row_xor[46] ^ row_xor[47] ^ row_xor[52] ^ row_xor[53] ^ row_xor[54] ^ row_xor[55] ^ row_xor[60] ^ row_xor[61] ^ row_xor[62] ^ row_xor[63] ^ row_xor[68] ^ row_xor[69] ^ row_xor[70] ^ row_xor[71] ^ row_xor[76] ^ row_xor[77] ^ row_xor[78] ^ row_xor[79] ^ row_xor[84] ^ row_xor[85] ^ row_xor[86] ^ row_xor[87] ^ row_xor[92] ^ row_xor[93] ^ row_xor[94] ^ row_xor[95] ^ row_xor[100] ^ row_xor[101] ^ row_xor[102] ^ row_xor[103] ^ row_xor[108] ^ row_xor[109] ^ row_xor[110] ^ row_xor[111] ^ row_xor[116] ^ row_xor[117] ^ row_xor[118] ^ row_xor[119] ^ row_xor[124] ^ row_xor[125] ^ row_xor[126] ^ row_xor[127];
					rp[6] <= row_xor[0] ^ row_xor[1] ^ row_xor[2] ^ row_xor[3] ^ row_xor[4] ^ row_xor[5] ^ row_xor[6] ^ row_xor[7] ^ row_xor[16] ^ row_xor[17] ^ row_xor[18] ^ row_xor[19] ^ row_xor[20] ^ row_xor[21] ^ row_xor[22] ^ row_xor[23] ^ row_xor[32] ^ row_xor[33] ^ row_xor[34] ^ row_xor[35] ^ row_xor[36] ^ row_xor[37] ^ row_xor[38] ^ row_xor[39] ^ row_xor[48] ^ row_xor[49] ^ row_xor[50] ^ row_xor[51] ^ row_xor[52] ^ row_xor[53] ^ row_xor[54] ^ row_xor[55] ^ row_xor[64] ^ row_xor[65] ^ row_xor[66] ^ row_xor[67] ^ row_xor[68] ^ row_xor[69] ^ row_xor[70] ^ row_xor[71] ^ row_xor[80] ^ row_xor[81] ^ row_xor[82] ^ row_xor[83] ^ row_xor[84] ^ row_xor[85] ^ row_xor[86] ^ row_xor[87] ^ row_xor[96] ^ row_xor[97] ^ row_xor[98] ^ row_xor[99] ^ row_xor[100] ^ row_xor[101] ^ row_xor[102] ^ row_xor[103] ^ row_xor[112] ^ row_xor[113] ^ row_xor[114] ^ row_xor[115] ^ row_xor[116] ^ row_xor[117] ^ row_xor[118] ^ row_xor[119];
					rp[7] <= row_xor[8] ^ row_xor[9] ^ row_xor[10] ^ row_xor[11] ^ row_xor[12] ^ row_xor[13] ^ row_xor[14] ^ row_xor[15] ^ row_xor[24] ^ row_xor[25] ^ row_xor[26] ^ row_xor[27] ^ row_xor[28] ^ row_xor[29] ^ row_xor[30] ^ row_xor[31] ^ row_xor[40] ^ row_xor[41] ^ row_xor[42] ^ row_xor[43] ^ row_xor[44] ^ row_xor[45] ^ row_xor[46] ^ row_xor[47] ^ row_xor[56] ^ row_xor[57] ^ row_xor[58] ^ row_xor[59] ^ row_xor[60] ^ row_xor[61] ^ row_xor[62] ^ row_xor[63] ^ row_xor[72] ^ row_xor[73] ^ row_xor[74] ^ row_xor[75] ^ row_xor[76] ^ row_xor[77] ^ row_xor[78] ^ row_xor[79] ^ row_xor[88] ^ row_xor[89] ^ row_xor[90] ^ row_xor[91] ^ row_xor[92] ^ row_xor[93] ^ row_xor[94] ^ row_xor[95] ^ row_xor[104] ^ row_xor[105] ^ row_xor[106] ^ row_xor[107] ^ row_xor[108] ^ row_xor[109] ^ row_xor[110] ^ row_xor[111] ^ row_xor[120] ^ row_xor[121] ^ row_xor[122] ^ row_xor[123] ^ row_xor[124] ^ row_xor[125] ^ row_xor[126] ^ row_xor[127];
					rp[8] <= row_xor[0] ^ row_xor[1] ^ row_xor[2] ^ row_xor[3] ^ row_xor[4] ^ row_xor[5] ^ row_xor[6] ^ row_xor[7] ^ row_xor[8] ^ row_xor[9] ^ row_xor[10] ^ row_xor[11] ^ row_xor[12] ^ row_xor[13] ^ row_xor[14] ^ row_xor[15] ^ row_xor[32] ^ row_xor[33] ^ row_xor[34] ^ row_xor[35] ^ row_xor[36] ^ row_xor[37] ^ row_xor[38] ^ row_xor[39] ^ row_xor[40] ^ row_xor[41] ^ row_xor[42] ^ row_xor[43] ^ row_xor[44] ^ row_xor[45] ^ row_xor[46] ^ row_xor[47] ^ row_xor[64] ^ row_xor[65] ^ row_xor[66] ^ row_xor[67] ^ row_xor[68] ^ row_xor[69] ^ row_xor[70] ^ row_xor[71] ^ row_xor[72] ^ row_xor[73] ^ row_xor[74] ^ row_xor[75] ^ row_xor[76] ^ row_xor[77] ^ row_xor[78] ^ row_xor[79] ^ row_xor[96] ^ row_xor[97] ^ row_xor[98] ^ row_xor[99] ^ row_xor[100] ^ row_xor[101] ^ row_xor[102] ^ row_xor[103] ^ row_xor[104] ^ row_xor[105] ^ row_xor[106] ^ row_xor[107] ^ row_xor[108] ^ row_xor[109] ^ row_xor[110] ^ row_xor[111];
					rp[9] <= row_xor[16] ^ row_xor[17] ^ row_xor[18] ^ row_xor[19] ^ row_xor[20] ^ row_xor[21] ^ row_xor[22] ^ row_xor[23] ^ row_xor[24] ^ row_xor[25] ^ row_xor[26] ^ row_xor[27] ^ row_xor[28] ^ row_xor[29] ^ row_xor[30] ^ row_xor[31] ^row_xor[48] ^ row_xor[49] ^ row_xor[50] ^ row_xor[51] ^ row_xor[52] ^ row_xor[53] ^ row_xor[54] ^ row_xor[55] ^ row_xor[56] ^ row_xor[57] ^ row_xor[58] ^ row_xor[59] ^ row_xor[60] ^ row_xor[61] ^ row_xor[62] ^ row_xor[63]^ row_xor[80] ^ row_xor[81] ^ row_xor[82] ^ row_xor[83] ^ row_xor[84] ^ row_xor[85] ^ row_xor[86] ^ row_xor[87] ^ row_xor[88] ^ row_xor[89] ^ row_xor[90] ^ row_xor[91] ^ row_xor[92] ^ row_xor[93] ^ row_xor[94] ^ row_xor[95] ^ row_xor[112] ^ row_xor[113] ^ row_xor[114] ^ row_xor[115] ^ row_xor[116] ^ row_xor[117] ^ row_xor[118] ^ row_xor[119] ^ row_xor[120] ^ row_xor[121] ^ row_xor[122] ^ row_xor[123] ^ row_xor[124] ^ row_xor[125] ^ row_xor[126] ^ row_xor[127];
					rp[10] <= row_xor[0] ^ row_xor[1] ^ row_xor[2] ^ row_xor[3] ^ row_xor[4] ^ row_xor[5] ^ row_xor[6] ^ row_xor[7] ^ row_xor[8] ^ row_xor[9] ^ row_xor[10] ^ row_xor[11] ^ row_xor[12] ^ row_xor[13] ^ row_xor[14] ^ row_xor[15] ^ row_xor[16] ^ row_xor[17] ^ row_xor[18] ^ row_xor[19] ^ row_xor[20] ^ row_xor[21] ^ row_xor[22] ^ row_xor[23] ^ row_xor[24] ^ row_xor[25] ^ row_xor[26] ^ row_xor[27] ^ row_xor[28] ^ row_xor[29] ^ row_xor[30] ^ row_xor[31] ^ row_xor[64] ^ row_xor[65] ^ row_xor[66] ^ row_xor[67] ^ row_xor[68] ^ row_xor[69] ^ row_xor[70] ^ row_xor[71] ^ row_xor[72] ^ row_xor[73] ^ row_xor[74] ^ row_xor[75] ^ row_xor[76] ^ row_xor[77] ^ row_xor[78] ^ row_xor[79] ^ row_xor[80] ^ row_xor[81] ^ row_xor[82] ^ row_xor[83] ^ row_xor[84] ^ row_xor[85] ^ row_xor[86] ^ row_xor[87] ^ row_xor[88] ^ row_xor[89] ^ row_xor[90] ^ row_xor[91] ^ row_xor[92] ^ row_xor[93] ^ row_xor[94] ^ row_xor[95];
					rp[11] <= row_xor[32] ^ row_xor[33] ^ row_xor[34] ^ row_xor[35] ^ row_xor[36] ^ row_xor[37] ^ row_xor[38] ^ row_xor[39] ^ row_xor[40] ^ row_xor[41] ^ row_xor[42] ^ row_xor[43] ^ row_xor[44] ^ row_xor[45] ^ row_xor[46] ^ row_xor[47] ^ row_xor[48] ^ row_xor[49] ^ row_xor[50] ^ row_xor[51] ^ row_xor[52] ^ row_xor[53] ^ row_xor[54] ^ row_xor[55] ^ row_xor[56] ^ row_xor[57] ^ row_xor[58] ^ row_xor[59] ^ row_xor[60] ^ row_xor[61] ^ row_xor[62] ^ row_xor[63] ^ row_xor[96] ^ row_xor[97] ^ row_xor[98] ^ row_xor[99] ^ row_xor[100] ^ row_xor[101] ^ row_xor[102] ^ row_xor[103] ^ row_xor[104] ^ row_xor[105] ^ row_xor[106] ^ row_xor[107] ^ row_xor[108] ^ row_xor[109] ^ row_xor[110] ^ row_xor[111] ^ row_xor[112] ^ row_xor[113] ^ row_xor[114] ^ row_xor[115] ^ row_xor[116] ^ row_xor[117] ^ row_xor[118] ^ row_xor[119] ^ row_xor[120] ^ row_xor[121] ^ row_xor[122] ^ row_xor[123] ^ row_xor[124] ^ row_xor[125] ^ row_xor[126] ^ row_xor[127];
					rp[12] <= row_xor[0] ^ row_xor[1] ^ row_xor[2] ^ row_xor[3] ^ row_xor[4] ^ row_xor[5] ^ row_xor[6] ^ row_xor[7] ^ row_xor[8] ^ row_xor[9] ^ row_xor[10] ^ row_xor[11] ^ row_xor[12] ^ row_xor[13] ^ row_xor[14] ^ row_xor[15] ^ row_xor[16] ^ row_xor[17] ^ row_xor[18] ^ row_xor[19] ^ row_xor[20] ^ row_xor[21] ^ row_xor[22] ^ row_xor[23] ^ row_xor[24] ^ row_xor[25] ^ row_xor[26] ^ row_xor[27] ^ row_xor[28] ^ row_xor[29] ^ row_xor[30] ^ row_xor[31] ^ row_xor[32] ^ row_xor[33] ^ row_xor[34] ^ row_xor[35] ^ row_xor[36] ^ row_xor[37] ^ row_xor[38] ^ row_xor[39] ^ row_xor[40] ^ row_xor[41] ^ row_xor[42] ^ row_xor[43] ^ row_xor[44] ^ row_xor[45] ^ row_xor[46] ^ row_xor[47] ^ row_xor[48] ^ row_xor[49] ^ row_xor[50] ^ row_xor[51] ^ row_xor[52] ^ row_xor[53] ^ row_xor[54] ^ row_xor[55] ^ row_xor[56] ^ row_xor[57] ^ row_xor[58] ^ row_xor[59] ^ row_xor[60] ^ row_xor[61] ^ row_xor[62] ^ row_xor[63];
					rp[13] <= row_xor[64] ^ row_xor[65] ^ row_xor[66] ^ row_xor[67] ^ row_xor[68] ^ row_xor[69] ^ row_xor[70] ^ row_xor[71] ^ row_xor[72] ^ row_xor[73] ^ row_xor[74] ^ row_xor[75] ^ row_xor[76] ^ row_xor[77] ^ row_xor[78] ^ row_xor[79] ^ row_xor[80] ^ row_xor[81] ^ row_xor[82] ^ row_xor[83] ^ row_xor[84] ^ row_xor[85] ^ row_xor[86] ^ row_xor[87] ^ row_xor[88] ^ row_xor[89] ^ row_xor[90] ^ row_xor[91] ^ row_xor[92] ^ row_xor[93] ^ row_xor[94] ^ row_xor[95] ^ row_xor[96] ^ row_xor[97] ^ row_xor[98] ^ row_xor[99] ^ row_xor[100] ^ row_xor[101] ^ row_xor[102] ^ row_xor[103] ^ row_xor[104] ^ row_xor[105] ^ row_xor[106] ^ row_xor[107] ^ row_xor[108] ^ row_xor[109] ^ row_xor[110] ^ row_xor[111] ^ row_xor[112] ^ row_xor[113] ^ row_xor[114] ^ row_xor[115] ^ row_xor[116] ^ row_xor[117] ^ row_xor[118] ^ row_xor[119] ^ row_xor[120] ^ row_xor[121] ^ row_xor[122] ^ row_xor[123] ^ row_xor[124] ^ row_xor[125] ^ row_xor[126] ^ row_xor[127];
					rp[14] <= 1'b1;
					rp[15] <= 1'b1;
				end
				else
				begin
					cp <= cp;
					rp <= rp;
				end
			end
			else
			begin
				cp <= 8'h00;
				rp <= 16'h0000;
//				init_xor_code <= 1'b0;
			end
		end
	end
	
	always @(posedge clk)
	begin
		if(otp_finish == 1)
		begin
			if(code_time < 3'b111)	// hamming code 计算的等待时间
				code_time <= code_time + 1'b1;
			else
				code_time <= 3'b000;
		end
		else
			code_time <= 3'b000;
	end

		
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			init_xor_code <= 1'b0;
		else
			init_xor_code <= ((~code_time[2]) & (code_time[0])) | ((~code_time[2]) & (code_time[1]) & (~code_time[0]));		//在编码计数为0 1 2 3时初始化基础异或值, 这样设计是因为，上层存储ECC校验码的RAM是8bit的位宽，需要三个周期才可以存储完成
	end
/*	
	always @(negedge clk)
	begin
		case(code_time)
		3'b000:
		begin
			ECC_data <= 8'h00;
			ECC_out <= 1'b0;
		end
		3'b001:
		begin
			ECC_data <= rp[7:0];
			ECC_out <= 1'b1;
		end
		3'b010:
		begin
			ECC_data <= rp[15:8];
			ECC_out <= 1'b1;
		end
		3'b011:
		begin
			ECC_data <= cp;
			ECC_out <= 1'b1;
		end
		default
		begin
			ECC_data <= 8'h00;
			ECC_out <= 1'b0;
		end
		endcase
	end
*/		
endmodule
