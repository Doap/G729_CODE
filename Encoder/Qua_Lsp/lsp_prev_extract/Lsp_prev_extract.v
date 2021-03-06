`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:22:38 02/14/2011 
// Design Name: 
// Module Name:    Lsp_prev_extract 
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
module Lsp_prev_extract(start, clk, done, reset, lspele,freq_prev, lsp, readAddr, readIn,fgAddr,fg_sum_invAddr,
								constantMemIn,constantMemAddr,writeAddr, writeOut, writeEn, L_msu_a, L_msu_b, 
								L_msu_c, L_msu_in, L_mult_a,L_mult_b,L_mult_in, L_shl_a, L_shl_b, L_shl_in, add_a,
								add_b, add_in, L_shl_ready, L_shl_done);
								

	input start;
   input clk;
   input reset;
	input [11:0] lspele;
	input [11:0] freq_prev;
	input [11:0] lsp;
	input [11:0] fgAddr;
	input [11:0] fg_sum_invAddr;
	input [31:0] readIn;
	input [31:0] constantMemIn;
	
	output reg done;
	output reg [11:0] writeAddr;
	output reg [31:0] writeOut;
	output reg writeEn;
	output reg [11:0] readAddr;
	output reg [11:0] constantMemAddr;
	input [31:0] L_mult_in, L_msu_in, L_shl_in;
	input [15:0] add_in;
	input L_shl_done;
	output reg [15:0] L_mult_a, L_mult_b, L_msu_a, L_msu_b, L_shl_b, add_a, add_b;
	output reg [31:0] L_msu_c, L_shl_a;
	output reg L_shl_ready;
	
	parameter INIT = 0;
	parameter S1 = 1;
	parameter S2 = 2;
	parameter S3 = 3;
	parameter S4 = 4;
	parameter S5 = 5;
	parameter S6 = 6;

	wire [11:0] lspele;	
	wire [11:0] freq_prev;
	wire [11:0] lsp;
	reg [15:0] temp_freq_prev, next_temp_freq_prev;
	reg [31:0] L_temp, next_L_temp;
	reg [15:0] temp, next_temp;
	reg [3:0] state, nextstate;
	reg [15:0] j, nextj, k, nextk;
	
	/*wire [11:0] fg;
	wire [11:0] fg_sum_inv;
	assign fg = 12'd384;
	assign fg_sum_inv = 12'd304;*/
	
	always @(posedge clk)
		begin
			if(reset)
				j <= 0;
			else
				j <= nextj;
		end

	always @(posedge clk)
		begin
			if(reset)
				k <= 0;
			else
				k <= nextk;
		end

	always @(posedge clk)
		begin
			if (reset)
				 state <= INIT;
			else
				 state <= nextstate;
		 end

	always @(posedge clk)
		begin
			if (reset)
				 L_temp <= 0;
			else
				 L_temp <= next_L_temp;
		 end
		 
	always @(posedge clk)
		begin
			if (reset)
				 temp <= 0;
			else
				 temp <= next_temp;
		 end

	always @(posedge clk)
		begin
			if (reset)
				 temp_freq_prev <= 0;
			else
				 temp_freq_prev <= next_temp_freq_prev;
		 end

	always @(*)
		begin
			nextstate = state;
			writeAddr = 0;
			writeOut = 0;
			writeEn = 0;
			readAddr = 0;
			constantMemAddr = 0;
			done = 0;
			nextj = j;
			nextk = k;
			next_L_temp = L_temp;
			next_temp = temp;
			next_temp_freq_prev = temp_freq_prev;
			L_mult_a = 0;
			L_mult_b = 0;
			L_msu_a = 0;
			L_msu_b = 0;
			L_msu_c = 0;
			L_shl_a = 0;
			L_shl_b = 0;
			add_a = 0;
			add_b = 0;
			
			case(state)
				INIT:
					begin
						readAddr = {lsp[11:4], j[3:0]};									//read in lsp[j]
						
						if(start)
							nextstate = S1;
					end
					
				S1:	//start of j loop
					begin
						if(j == 10)
							begin
								nextj = 0;
								done = 1;
								nextstate = INIT;
							end
							
						else
							begin
								next_L_temp = {readIn[15:0], 16'b0};					//L_temp = L_deposit_h(lsp[j]);
								readAddr = {freq_prev[11:6],k[1:0],j[3:0]};		//read in freq_prev[k][j]
								nextstate = S2;
							end
					end
								
				S2:	//start of k loop
					begin
						if(k == 4)
							begin
								next_temp = L_temp[31:16];									//temp = extract_h(L_temp);
								constantMemAddr = {fg_sum_invAddr[11:4], j[3:0]};					//read in fg_sum_inv[j]
								nextstate = S4;
							end
						
						else
							begin
								next_temp_freq_prev = readIn[15:0];						
								constantMemAddr = {fgAddr[11:6],k[1:0],j[3:0]};					//read in fg[k][j]
								nextstate = S3;
							end
					end
				
				S3:
					begin
						readAddr = {freq_prev[11:6], add_in[1:0], j[3:0]};
						L_msu_a = temp_freq_prev;
						L_msu_b = constantMemIn[15:0];
						L_msu_c = L_temp;
						next_L_temp = L_msu_in;												//L_temp = L_msu(L_temp, freq_prev[j][k], fg[j][k]);
						add_a = k;
						add_b = 1'd1;
						nextk = add_in;														//k++
						nextstate = S2;
					end
					
				S4:
					begin
						L_mult_a = temp;
						L_mult_b = constantMemIn[15:0];
						next_L_temp = L_mult_in;											//L_temp = L_mult(temp, fg_sum_inv[j]);
						L_shl_ready = 1;
						L_shl_a = L_mult_in;
						L_shl_b = 'd3;
						nextstate = S5;
					end
					
				S5:
					begin
						if(L_shl_done)
							begin
								writeAddr = {lspele[11:4], j[3:0]};
								writeOut  = L_shl_in[31:16];										//lsp_ele[j] = extract_h(L_shl(L_temp,3));
								writeEn = 1;						
								readAddr = {lsp[11:4], add_in[3:0]};							//read in lsp[j]
								add_a = j;
								add_b = 1'd1;
								nextj = add_in;														//j++
								nextk = 0;
								nextstate = S1;
							end
							
						else
							begin
								L_shl_a = L_temp;
								L_shl_b = 'd3;
								nextstate = S5;
							end
					end
					
			endcase
			
		end

endmodule
