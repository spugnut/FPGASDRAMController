//**************************************************************//
//** SDRAM Controller v.01a - SS 2019                         **//
//** Based on initial expermiments with Hynix HY57V561620F    **//
//** 256Mb (16Mx16bit) 4 bank SDRAM                           **//
//** Basic functionality only, no burst access.               **//
//**************************************************************//

//AC timings
//localparam DRIVECLOCKPERIOD = 31.25; 	//Testing at 32.00Mhz - period @ 31.25ns
localparam DRIVECLOCKPERIOD = 20; 	//Testing at 50.00Mhz - period @ 20ns
//localparam DRIVECLOCKPERIOD = 7.58;       //132Mhz design max - period @ ~7.58ns
//localparam DRIVECLOCKPERIOD = 400; 	   //Testing at 10.00Mhz - period @ 400ns
localparam iDelay = 200 * 1000;			//Init delay in ns
localparam tRC =  63;  					 	//RAS CYCLE TIME in nS
localparam tRCD = 20; 						//RAS TO CAS DELAY in nS
localparam tRAS = 42; 						//RAS MINIMUM ACTIVE TIME in nS
localparam tRP =  20;  						//RAS PRECHARGE TIME in nS
localparam tRRD = 15; 						//RAS TO RAS BANK ACTIVE DELAY in nS
localparam tREF = 64; 						//MAX refresh time in msec

//Physical RAM properties
localparam noBanks = 4;
localparam noRows = 8192;

//Calculated or specified cycle delays
localparam tCCD = 1;  						//CAS TO CAS Delay in CLOCK CYCLES
localparam tDPL = 2;  						//DataIn to Precharge delay in CLOCK CYCLES
parameter int iDelayCycles =    (iDelay + DRIVECLOCKPERIOD - 1) / DRIVECLOCKPERIOD; //Init delay in CLOCK cycles
parameter int tRCDelayCycles = (tRC + DRIVECLOCKPERIOD - 1) / DRIVECLOCKPERIOD;  //RCD delay in CLOCK cycles
parameter int tRCDDelayCycles = (tRCD + DRIVECLOCKPERIOD - 1) / DRIVECLOCKPERIOD;  //RCD delay in CLOCK cycles
parameter int tRPCycles =       (tRP + DRIVECLOCKPERIOD - 1) / DRIVECLOCKPERIOD; //Precharge delay in CLOCK cycles
parameter int tRASMaxCycles = (100000/DRIVECLOCKPERIOD); //Maximum row open time in CLOCK cycles
localparam CASCycles = 4; 				//CAS address strobe delay in CLOCK cycles
localparam autoRefreshInitCycles = 8;  //Number of complete bank REFRESH cycles in init phase;
parameter int interRefreshCycles =  (tREF * 1000000) / noRows - 1000; //1000 cycle fudge factor.

module MemoryController(input logic ramclk,
//Read handling
input logic readRequest, //Incoming read request
output logic readRequestGrant, //Incoming read request grant
input logic [31:0] readAddress, //The read address
output logic [15:0] readData, //The data output
output logic readValid, //advise the caller the data on the bus is valid.

//Write handling
input logic writeRequest, 
output logic writeRequestGrant, //Incoming write request grant
input logic [31:0] writeAddress, //The write address
input logic [15:0] writeData, //The input data to be written.
output logic writeCommit, //advise caller the data on the bus has been written.

//Output SDRAM signals
output logic CKE, CS , RAS, CAS, WE,
output logic [12:0] addr,
output logic [1:0] bank = 2'b00,
output logic [1:0] dqm,
inout wire [15:0] dq
);

typedef enum logic [3:0] { 
MODEREG =     4'b0000,
NOP =         4'b0111,
BANKACTIVE =  4'b0011,
READ =        4'b0101,
WRITE = 		  4'b0100,
PRECHARGE   = 4'b0010,
AUTOREFRESH = 4'b0001
} Commands;

typedef enum logic [3:0]{
	INIT, INITREFRESH, INITSETREG, IDLE, READHANDLING, WRITEHANDLING, REFRESH
} InternalState;

InternalState state  = INIT;
Commands command = NOP;
logic requestRead; 
logic requestWrite;
logic [15:0] subState = 0; //Tracks substates within states.
logic [15:0] delayCounter = 0; //Tracks clock cycle delays within states.
logic [15:0] refreshDelayCounter = 0;
logic [12:0] autoRefreshCounter = 0;
logic [4:0] initRefreshCounter = 0;
logic [15:0] rowOpenCounter = 0;

logic moveToRead, moveToWrite;

assign moveToRead = readRequest;
assign moveToWrite = ~readRequest & writeRequest;
assign CKE = 1'bZ;
assign dqm = 2'b00;
assign CS = command[3];
assign RAS = command[2];
assign CAS = command [1];
assign WE = command[0]; 

//TRISTATE - URGHH.
logic dataout_enable /* synthesis preserve */;
logic [15:0]dq_i; //This is the internal input net, driven from a constant assign from dq.
assign dq_i = dq; //Drives the internal value from the input;
	
logic [15:0]dq_o =0; //And this, this is the internal output net - see the assign of DB.
assign dq = dataout_enable ? dq_o : 16'bZZZZZZZZZZZZZZZZ; //Output values when dataout_enable is true, otherwise HZ.


always @ (posedge ramclk) begin
	writeCommit <= 0;
	readValid <= 0;
	readRequestGrant <= 0;
	writeRequestGrant <= 0;
	refreshDelayCounter <= refreshDelayCounter + 16'b1;
	case (state)
		INIT: begin
			dataout_enable <= 0;
			command <= NOP;
			if (delayCounter == iDelayCycles) begin
				state <= INITREFRESH;
				delayCounter <= 0;
				subState <= 0;
			end
			delayCounter <= delayCounter + 16'd1;
		end
		INITREFRESH: begin
			//If we've hit the require number of refreshes
			if (initRefreshCounter == autoRefreshInitCycles) begin
				state <= INITSETREG; //Go to set register
				subState <= 0;   //Clear the substate counter
				autoRefreshCounter <= 0; //and the autorefresh counter (we'll need it shortly).
			end
			else
			begin
				command <= AUTOREFRESH; //Set the autorefresh command.
				if (autoRefreshCounter == 8191) begin //If we've counted up to the row count
					autoRefreshCounter <= 0;           //reset the row counter
					initRefreshCounter <= initRefreshCounter + 5'd1; //and increment the cycle count.
				end	
				autoRefreshCounter <= autoRefreshCounter + 13'd1;
			end
		end
		INITSETREG: begin
			if (subState == 0) begin //One shot			
				addr <= 13'b000001000110000;
				dataout_enable <= 1;
				// A9 - 1 for single write. A6:4 = 011 for CAS3. A3 = 0 for burst sequential.
				//A2:0 = 000 for burst length 1.
				command <= MODEREG;
				subState <= 1;
			end
			else begin
				state <= IDLE;
				subState <= 0;
				refreshDelayCounter <= 0;
			end
		end
		IDLE: begin
			subState <= 0;
			delayCounter <= 0;
			command <= NOP;
			dataout_enable <= 0;
			if (refreshDelayCounter > interRefreshCycles) begin
				state <= REFRESH;
				refreshDelayCounter <=0;
			end
			if (moveToRead) begin
				readRequestGrant <= 1;
				state <=READHANDLING;
			end
			if (moveToWrite) begin
				writeRequestGrant <= 1;
				state <= WRITEHANDLING;
			end
		end
		WRITEHANDLING: begin
			HandleW();
		end
		READHANDLING: begin
			HandleR();
		end
		REFRESH: begin
			command <= NOP;
			if (delayCounter == 0) command <= AUTOREFRESH; //Set the autorefresh command.
			if (tRCDelayCycles == tRCDelayCycles) begin
				state <= IDLE;
			end		
		end
	endcase
end

task HandleR();
	dataout_enable <= 0;
	command <= NOP;
	case (subState)
		0: begin	
			bank <= readAddress[23:22];
			addr <= readAddress[21:9]; 
			if (delayCounter == 0) command <= BANKACTIVE;
			delayCounter <= delayCounter + 16'd1;
			if (delayCounter == tRCDDelayCycles) begin
				subState <= 1;
				delayCounter <= 0;				
			end
		end
		1: begin			
			if (delayCounter == 0) command <= READ; //read command in the first cycle after tRCD.
			addr <= readAddress[8:0]; 
			delayCounter <= delayCounter + 16'd1;
			if (delayCounter == CASCycles) begin
				delayCounter <= 0;
				readData <= dq_i;
				readValid <= 1;
				subState <= 2;
			end
		end
		2: begin		   
			if (delayCounter == 0) command <= PRECHARGE;
			delayCounter <= delayCounter + 16'd1;
			if (delayCounter == tRPCycles) begin			
				subState <= 0;
				state <= IDLE;
				writeCommit <= 1;
			end
		end
	endcase
endtask

task HandleW();
	command <= NOP;
	case (subState)
		0: begin //Activate bank & row
			bank <= writeAddress[23:22];
			addr <= writeAddress[21:9]; 
			if (delayCounter == 0) command <= BANKACTIVE;
			delayCounter <= delayCounter + 16'd1;
			if (delayCounter == tRCDDelayCycles) begin
				subState <= 1;
				delayCounter <= 0;				
			end
		end
		1: begin
			if (delayCounter == 0) command <= WRITE;
			addr <= writeAddress[8:0];
			dataout_enable <= 1;
			dq_o <= writeData;
			delayCounter <= delayCounter + 16'd1;
			if (delayCounter == tDPL) begin
				subState <= 2;
				delayCounter <= 0;
			end
		end
		2: begin		   
			if (delayCounter == 0) command <= PRECHARGE;
			delayCounter <= delayCounter + 16'd1;
			if (delayCounter == tRPCycles) begin
				dq_o <= 0;
				dataout_enable <= 0;			
				subState <= 0;
				state <= IDLE;
				writeCommit <= 1;
			end
		end
	endcase
endtask

endmodule