	`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:23:48 01/23/2011
// Design Name:   LSP Select 2
// Module Name:   
// Project Name:  Qua Lsp
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Synthesis Filtering
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module lsp_select_2_test;

`include "paramList.v"
`include "constants_param_list.v"

	// Inputs
	reg clk;
	reg reset;
	reg start;
	reg [11:0] lspcb1Addr;
	
	wire [31:0] memIn;
	wire [31:0] constMemIn;


	// Outputs
	wire memWriteEn;
	wire [11:0] memWriteAddr;
	wire [11:0] constMemAddr;
	wire [31:0] memOut;
	wire done;
	
	wire unusedOverflow;
	
	//Mux0 regs	
	reg lagMuxSel;
	reg [11:0] lagMuxOut;
	reg [11:0] testReadRequested;
	//Mux1 regs	
	reg lagMux1Sel;
	reg [11:0] lagMux1Out;
	reg [11:0] testWriteRequested;
	//Mux2 regs	
	reg lagMux2Sel;
	reg [31:0] lagMux2Out;
	reg [31:0] testWriteOut;
	//Mux3 regs	
	reg lagMux3Sel;
	reg lagMux3Out;
	reg testWriteEnable;
	reg [11:0] lspcb1;
	integer i, j;

	// Instantiate the Unit Under Test (UUT)
	lsp_select_2_pipe uut (
		.clk(clk), 
		.reset(reset), 
		.start(start), 
		.memIn(memIn), 
		.done(done), 
		.lagMuxSel(lagMuxSel), 
		.lagMux1Sel(lagMux1Sel), 
		.lagMux2Sel(lagMux2Sel), 
		.lagMux3Sel(lagMux3Sel), 
		.testReadRequested(testReadRequested), 
		.testWriteRequested(testWriteRequested), 
		.testWriteOut(testWriteOut), 
		.testWriteEnable(testWriteEnable),
		.lspcb1Addr(lspcb1Addr)
	);
					
	reg [15:0] rbufVector[0:9999];
	reg [15:0] wegtVector[0:9999];
	reg [15:0] indexVector[0:9999];
					 
	initial 
		begin
			// samples out are samples from ITU G.729 test vectors
			$readmemh("input_rbuf.out", rbufVector);
			$readmemh("input_wegt.out", wegtVector);
			$readmemh("output_index.out", indexVector);
			//add update file here
		end

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		start = 0;		
		lagMuxSel = 0;
		lspcb1Addr = LSPCB1 + (80*16);
		
		@(posedge clk) #5;	
		reset = 1;		
		@(posedge clk); 
		@(posedge clk) #5;
		reset = 0;
		// Wait 100 ns for global reset to finish
		@(posedge clk); 
		@(posedge clk) #10;
        
		for(j=0;j<5;j=j+1)
		begin
			
			//Test # 1
			lagMuxSel = 0;
			lagMux1Sel = 1;
			lagMux2Sel = 1;
			lagMux3Sel = 1;
			@(posedge clk); 
			@(posedge clk) #10;
			
			for(i=0;i<10;i=i+1)
			begin			
				@(posedge clk); 
				@(posedge clk) #5;
				testWriteRequested = {LSP_SELECT_1_RBUF[11:4],i[3:0]};
				testWriteOut = rbufVector[(j*10)+i];
				testWriteEnable = 1;
				@(posedge clk); 
				@(posedge clk) #5;
			end
			
			for(i=0;i<10;i=i+1)
			begin			
				@(posedge clk); 
				@(posedge clk) #5;
				testWriteRequested = {LSP_SELECT_1_WEGT[11:4],i[3:0]};
				testWriteOut = wegtVector[(j*10)+i];
				testWriteEnable = 1;
				@(posedge clk); 
				@(posedge clk) #5;
			end
			
			@(posedge clk); 
			@(posedge clk) #5;			
			lagMux1Sel = 0;
			lagMux2Sel = 0;
			lagMux3Sel = 0;
	
			
			// Add stimulus here
			start = 1;
			@(posedge clk); 
			@(posedge clk) #5;
			start = 0;
			@(posedge clk); 
			@(posedge clk) #5;
			
			wait(done);
			lagMuxSel = 1;
			for(i = 0; i<1; i=i+1)
			begin			
				testReadRequested = {LSP_SELECT_1_INDEX[11:0]};
				@(posedge clk);
				@(posedge clk) #5;
				if (memIn[15:0] != indexVector[(j*1)+i])
						$display($time, " ERROR: index'[%d] = %x, expected = %x", (j*1)+i, memIn, indexVector[(j*1)+i]);
					else
						$display($time, " CORRECT:  index'[%d] = %x", (j*1)+i, memIn);
			end
		end	// end j loop

	end
	
initial forever #10 clk = ~clk; 
endmodule

