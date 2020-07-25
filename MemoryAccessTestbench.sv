module MemoryAccessTestbench (input logic clk,
output logic CKE, WE, CAS, RAS, CS, memclk,
output logic [12:0] addr,
output logic [1:0] bank,
output logic [1:0] dqm,
inout wire [15:0] dq,
output logic light);

//These signals are required for the vJTAG module
logic tck, tdi, tdo, cdr, eldr, e2dr, pdr; 
logic sdr, udr, uir, cir, e1dr, bypass_reg;
logic [2:0] ir_in;
logic ir_out;
logic [3:0] registeraddress;
logic [2:0] opco;
logic [31:0] shift_buffer = 32'h0;
logic [31:0] active_register = 0;
logic [31:0] test_buffer = 0;
logic [31:0] registers [3:0];

//JTAG OPCODES 
localparam BYPASS =     4'b1111;
localparam IDCODE =     4'b0001;
localparam READREG =    4'b0010;
localparam SETREGISTER =   4'b0011;
localparam RUNTEST    = 4'b0100; 
localparam PRESENCE   = 4'b0101;
localparam SETTEST    = 4'b0110;
localparam WRITEREG   = 4'b0111;
localparam NIL	       = 4'b1111;

//Memory controller signals
logic readRequest, readRequestGrant;
logic [31:0] readAddress;
logic [15:0] readData;
logic readValid;

logic membusy;

logic writeRequest, writeRequestGrant;
logic [31:0] writeAddress;
logic [15:0] writeData;
logic writeCommit;

//PLL
logic locked;
MemPLL pll (clk, memclk, locked);

//Test signals
logic [3:0] SelectedTest = 0;
logic [4:0] StageCounter = 0;
logic run = 0;
logic trigger = 0;

MemoryController mem (memclk, readRequest, readRequestGrant, readAddress, readData, readValid,
writeRequest, writeRequestGrant, writeAddress, writeData, writeCommit, CKE, CS, RAS, CAS, WE,
addr, 
bank, 
dqm,
dq);

//Instantiation of the JTAG module.
JTAG v(
 .tdo (tdo),
 .tck (tck),
 .tdi (tdi),
 .ir_in(ir_in),
 .ir_out(ir_out),
 .virtual_state_cdr (cdr),
 .virtual_state_e1dr(e1dr),
 .virtual_state_e2dr(e2dr),
 .virtual_state_pdr (pdr),
 .virtual_state_sdr (sdr),
 .virtual_state_udr (udr),
 .virtual_state_uir (uir),
 .virtual_state_cir (cir)
);

	
assign ir_out = ir_in[0]; //Assignment for passthrough.

always_ff @ (posedge tck) begin	
	if (sdr) begin				
		shift_buffer <= {tdi, shift_buffer[31:1]}; //VJ State is Shift DR, so we shift using tdi and the existing bits.		
	end	
	if (cdr) begin //Capture DR is asserted. This means we lookup the current instruction and plop stuff here.
		case (opco)
			IDCODE: shift_buffer <= 32'h100011d3;
			READREG: shift_buffer <= registers[active_register];			
		endcase
	end
	if (udr) begin
		case (opco)						
			SETREGISTER: active_register <= shift_buffer;	
			SETTEST: test_buffer <= shift_buffer;				
		endcase		
	end
end


always_ff @ (posedge uir) begin
   trigger <= 0;
	if (opco != ir_in) trigger <= 1;
	opco <= ir_in;
	case (ir_in)
		PRESENCE: begin
			light = ~light;
		end
		NIL: begin
			light = 0;
		end
	endcase
end

always_comb begin
	if (ir_in == BYPASS) tdo <= tdi;
	else tdo <= shift_buffer[0];	
end

always_ff @ (posedge memclk) begin	
	case (opco)						
		WRITEREG: registers[active_register] <= shift_buffer;					
		RUNTEST: begin
			if (trigger) begin
			//Set the test as selected.
				run <= 1;
				SelectedTest <= test_buffer[3:0];
				StageCounter <= 0;
			end
		end
	endcase
	if (run) begin
		case (SelectedTest)
			3'b001: begin
				BasicRW();
			end
			3'b010: begin
				BasicW();
			end
			3'b011: begin
				BasicR();
			end
			3'b100: begin
				WValue();
			end
			3'b101: begin
				SequenceTest();
			end
		endcase
	end
end

task SequenceTest;				
	case (StageCounter) 
		0: begin
			StageCounter <= 1;
			writeAddress <= 32'd0;			
		end
		1: begin			
			writeRequest <= 1;
			writeData <= 65535 - writeAddress[15:0];
			StageCounter <= StageCounter + 5'b1;
		end
		2: begin
			//await the grant from the controller.
			if (writeRequestGrant) begin
				StageCounter <= StageCounter +5'b1;
				writeRequest <= 0;
			end
		end
		3: begin
			//Await the commit signal
			if (writeCommit) begin 
				writeAddress <= writeAddress + 1'b1;
				StageCounter <= 5'b1;			
				writeData <= 0;
			end
			if (writeAddress == 32'd4194313) begin			
				StageCounter <= 4;		
				readAddress <= 32'd0;				
			end	
		end
		
		4: begin
			//Setup the read request			
			readRequest <= 1;
			//If granted then advance
			if (readRequestGrant) begin
				StageCounter <= StageCounter + 5'b1;				
				readRequest <= 0;
			end
		end
		5: begin
			//read is marked valid, check value
			if (readValid) begin
			   StageCounter <= 4;
				readAddress <= readAddress + 1;				
				if (readData != readAddress) begin
					SelectedTest <= 0;
					registers[1] <= readAddress;
					registers[0] <= 0;
				end
				if (readAddress > 32'd4194314) StageCounter <= 6;
			end
		end
		6: begin
			registers[0] <= 1;
			registers[1] <= 0;
			SelectedTest <= 0;
			run <= 0;
		end
	endcase
endtask

task BasicR();
	case (StageCounter) 	
		0: begin
			//Setup the read request
			readAddress <= registers[0];
			readRequest <= 1;
			//If granted then advance
			if (readRequestGrant) begin
				StageCounter <= StageCounter + 5'b1;				
				readRequest <= 0;
			end
		end
		1: begin
			//read is marked valid, capture to lowest register.
			if (readValid) begin
				registers[0] <= readData;			
				SelectedTest <= 0;
				run <= 0;
			end
		end
	endcase
endtask

task WValue();
	case (StageCounter) 
		0: begin
			//Setup a write request with parameter buffer input.
			writeAddress <= registers[0];
			writeRequest <= 1;
			writeData <= registers[1];
			StageCounter <= StageCounter + 5'b1;
		end
		1: begin
			//await the grant from the controller.
			if (writeRequestGrant) begin
				StageCounter <= StageCounter + 5'b1;
				writeRequest <= 0;
			end
		end
		2: begin
			//Await the commit signal
			if (writeCommit) begin 					
				writeData <= 0;
				SelectedTest <= 0;
				run <= 0;
			end
		end
	endcase
endtask

task BasicW();
	case (StageCounter) 
		0: begin
			//Setup a write request with broken barber pole input.
			writeAddress <= 0;
			writeRequest <= 1;
			writeData <= 16'b1110101110101110;
			StageCounter <= StageCounter + 5'b1;
		end
		1: begin
			//await the grant from the controller.
			if (writeRequestGrant) begin
				StageCounter <= StageCounter + 5'b1;
				writeRequest <= 0;
			end
		end
		2: begin
			//Await the commit signal
			if (writeCommit) begin 					
				writeData <= 0;
				SelectedTest <= 0;
				run <= 0;
			end
		end
	endcase
endtask

task BasicRW();
	case (StageCounter) 
		0: begin
			//Setup a write request with barber pole input.
			writeAddress <= 0;
			writeRequest <= 1;
			writeData <= 16'b1010101010101010;
			StageCounter <= StageCounter + 5'b1;
		end
		1: begin
			//await the grant from the controller.
			if (writeRequestGrant) begin
				StageCounter <= StageCounter +5'b1;
				writeRequest <= 0;
			end
		end
		2: begin
			//Await the commit signal
			if (writeCommit) begin 
				StageCounter <= StageCounter + 5'b1;			
				writeData <= 0;
			end
		end
		
		3: begin
			//Setup a write request with broken pole input.
			writeAddress <= 1;
			writeRequest <= 1;
			writeData <= 16'b1110111010111010;
			StageCounter <= StageCounter + 5'b1;
		end
		4: begin
			//await the grant from the controller.
			if (writeRequestGrant) begin
				StageCounter <= StageCounter + 5'b1;
				writeRequest <= 0;
			end
		end
		5: begin
			//Await the commit signal
			if (writeCommit) begin 
				StageCounter <= StageCounter + 5'b1;			
				writeData <= 0;
			end
		end
		
		6: begin
			//Setup the read request
			readAddress <= 0;
			readRequest <= 1;
			//If granted then advance
			if (readRequestGrant) begin
				StageCounter <= StageCounter + 5'b1;				
				readRequest <= 0;
			end
		end
		7: begin
			//read is marked valid, capture to lowest register.
			if (readValid) begin
				registers[0] <= readData;			
				SelectedTest <= 0;
				run <= 0;
			end
		end
	endcase
endtask

endmodule