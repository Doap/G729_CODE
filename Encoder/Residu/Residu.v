`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Cooper
// 
// Create Date:    21:04:25 01/21/2011 
// Design Name: 
// Module Name:    Residu 
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
module Residu(clk, reset, start, done, A, X, Y, LG, memReadDataA, memReadDataX, memWriteEn, memReadAddrA,
				  memReadAddrX, memWriteAddr, memWriteData, L_multOutA, L_multOutB, L_multIn, L_macOutA, L_macOutB, 
				  L_macOutC, L_macIn, subOutA, subOutB, subIn, L_shlOutA, L_shlOutB, L_shlIn, addOutA, 
				  addOutB, addIn, L_addOutA, L_addOutB, L_addIn, L_shlDone, L_shlReady);

//Inputs
input clk, reset, start;
input [11:0] A, X, Y;
input [5:0] LG;
input [31:0] memReadDataA, memReadDataX;
input [31:0] L_multIn;
input [15:0] subIn;
input [31:0] L_macIn;
input [31:0] L_shlIn;
input [15:0] addIn;
input [31:0] L_addIn;
input L_shlDone;

//Outputs
output reg done;
output reg memWriteEn;
output reg [11:0] memReadAddrA, memReadAddrX;
output reg [11:0] memWriteAddr;
output reg [31:0] memWriteData;
output reg [15:0] subOutA, subOutB;
output reg [15:0] L_multOutA, L_multOutB;
output reg [15:0] L_macOutA, L_macOutB;
output reg [31:0] L_macOutC;
output reg [31:0] L_shlOutA;
output reg [15:0] L_shlOutB;
output reg [15:0] addOutA, addOutB;
output reg [31:0] L_addOutA, L_addOutB;
output reg L_shlReady;

//Wires

//Regs
reg [3:0] state, nextstate;
reg [5:0] I, nextI;
reg [3:0] J, nextJ;
reg [31:0] temp, nexttemp;
reg [31:0] S, nextS;
reg resetI, ldI;
reg resetJ, ldJ;
reg resettemp, ldtemp;
reg resetS, ldS;

//Flops
//state
always @ (posedge clk)
begin
	if (reset)
		state <= 0;
	else
		state <= nextstate;
end

//I, outer for() loop
always @ (posedge clk)
begin
	if (reset)
		I <= 0;
	else if (resetI)
		I <= 0;
	else if (ldI)
		I <= nextI;
end

//J, inner for() loop
always @ (posedge clk)
begin
	if (reset)
		J <= 1;
	else if (resetJ)
		J <= 1;
	else if (ldJ)
		J <= nextJ;
end

//temp, stores value from memory
always @ (posedge clk)
begin
	if (reset)
		temp <= 0;
	else if (resettemp)
		temp <= 0;
	else if (ldtemp)
		temp <= nexttemp;
end

//S, ultimate result of Residu after function calls
always @ (posedge clk)
begin
	if (reset)
		S <= 0;
	else if (resetS)
		S <= 0;
	else if (ldS)
		S <= nextS;
end

//Parameters/States
parameter S0_INIT = 4'd0;
parameter S1_FOR1 = 4'd1;
parameter S2_MEM1 = 4'd2;
parameter S3_LMULT = 4'd3;
parameter S4_FOR2 = 4'd4;
parameter S5_MEM2 = 4'd5;
parameter S6_LMAC = 4'd6;
parameter S7_LSHL = 4'd7;
parameter S8_ROUND = 4'd8;
parameter S9_INC = 4'd9;
parameter S10_DONE = 4'd10;
parameter M = 4'd10;

//FSM
//States:
//INIT: reset flops, check if start high
	//if(start): goto FOR1
	//else: goto INIT
//FOR1: check if for1 valid
	//if(i < lg): request x[i], goto MEM1
	//else: goto DONE
//MEM1: request a[0], store x[i], goto LMULT
//LMULT: do L_mult, store result in S, goto FOR2
//FOR2: check if for2 valid
	//if(j <= M): request a[j], goto MEM2
	//else: goto LSHL
//MEM2: do i-j, request x[i-j], store a[j], goto LMAC
//LMAC: do L_mac, store result in S, goto FOR2
//LSHL: do L_shl, store result in S, goto ROUND
//ROUND: do round, store in memory at y[i]({y,i}) goto FOR1
//DONE: done signal



always @ (*)
begin
	//set outputs to default
	nextstate = state;
	nextI = I;
	resetI = 0;
	ldI = 0;
	nextJ = J;
	resetJ = 0;
	ldJ = 0;
	nexttemp = temp;
	resettemp = 0;
	ldtemp = 0;
	nextS = S;
	resetS = 0;
	ldS = 0;
	memReadAddrA = 0;
	memReadAddrX = 0;
	done = 0;
	memWriteEn = 0;
	memWriteAddr = 0;
	memWriteData = 0;
	subOutA = 0;
	subOutB = 0;
	L_multOutA = 0;
	L_multOutB = 0;
	L_macOutA = 0;
	L_macOutB = 0;
	L_macOutC = 0;
	L_shlOutA = 0;
	L_shlOutB = 0;
	addOutA = 0;
	addOutB = 0;
	L_addOutA = 0;
	L_addOutB = 0;
	L_shlReady = 0;
	
	case (state)
		S0_INIT:
		begin
			resetI = 1;
			resetJ = 1;
			resettemp = 1;
			resetS = 1;
			if (start)
				nextstate = S1_FOR1;
			else
				nextstate = S0_INIT;
		end
		
		S1_FOR1:
		begin
			if (I < LG)
			begin
				addOutA = X;
				addOutB = I;
				memReadAddrX = addIn[11:0];
				nextstate = S2_MEM1;
			end
			else 
				nextstate = S10_DONE;
		end
		
		S2_MEM1:
		begin
			memReadAddrA = A[11:0];
			nexttemp = memReadDataX;
			ldtemp = 1;
			nextstate = S3_LMULT;
		end
		
		S3_LMULT:
		begin
			L_multOutA = temp;
			L_multOutB = memReadDataA;
			nextS = L_multIn;
			ldS = 1;
			nextstate = S4_FOR2;
		end
		
		S4_FOR2:
		begin
			if (J <= M)
			begin
				addOutA = A;
				addOutB = J;
				memReadAddrA = addIn;
				nextstate = S5_MEM2;
			end
			else
				nextstate = S7_LSHL;
		end
		
		S5_MEM2:
		begin
			subOutA = {10'd0, I[5:0]};
			subOutB = {12'd0, J[3:0]};
			//add instead of concatenate
			addOutA = {5'd0, X[11:0]};
			addOutB = subIn;
			memReadAddrX = addIn;
			nexttemp = memReadDataA;
			ldtemp = 1;
			nextstate = S6_LMAC;
		end
		
		S6_LMAC:
		begin
			L_macOutA = temp[15:0];
			L_macOutB = memReadDataX[15:0];
			L_macOutC = S;
			nextS = L_macIn;
			ldS = 1;
			addOutA = J;
			addOutB = 'd1;
			nextJ = addIn;
			ldJ = 1;
			nextstate = S4_FOR2;
		end
		
		S7_LSHL:
		begin
			L_shlReady = 1;
			L_shlOutA = S;
			L_shlOutB = 16'd3;
			if(L_shlDone == 1)
			begin	
				L_shlReady = 0;	
				nextS = L_shlIn;
				ldS = 1;
				nextstate = S8_ROUND;
			end
			else
				nextstate = S7_LSHL;
		end
		
		S8_ROUND:
		begin
			//find round and do what it does
			L_addOutA = S;
			L_addOutB = 32'h00008000;
			if(L_addIn[31] == 1)
				memWriteData = {16'hffff,L_addIn[31:16]};
			else if(L_addIn[31] == 0)
				memWriteData = {16'd0,L_addIn[31:16]};
			addOutA = Y;
			addOutB = I;
			memWriteAddr = addIn;
			memWriteEn = 1;
			nextstate = S9_INC;
		end
		
		S9_INC:
		begin
			addOutA = I;
			addOutB = 'd1;
			nextI = addIn;
			ldI = 1;
			resetJ = 1;
			nextstate = S1_FOR1;
		end
		
		S10_DONE:
		begin
			done = 1;
			nextstate = S0_INIT;
		end
		
	endcase
end



endmodule

