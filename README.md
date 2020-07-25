# FPGASDRAMController
Basic SDRAM controller

This HDL project defines a basic (WIP) memory controller currently targeted at the Hynix HY57V561620F series SDRAM chip. This project is currently wired as a functional module and a JTAG testbench,
which can be driven via a TCL script and the Quartus_STP host executable.

To test the project, first select or add the appropriate clock timing for your intended use case using the DRIVECLOCKPERIOD parameter in MemoryController.sv, and then set the appropriate
matching frequency for the output of the C0 port on the MemPLL Megafunction. Carefully check the pin assigments in the Quartus pin-planner to ensure that the pinout matches the physical
characteristics of your board.

After synthesis, the resulting bitstream can be imported to your FPGA board, and will expose a virtual TAP which can be addressed using the Quartus STP tool. To begin, adjust your PATH environment variable
to add an entry for the Quartus bin folder (C:\intelFPGA_lite\20.1\quartus\bin64 for the current lite release). With this in place, open a command prompt in the project folder and start the test harness with the command  `quartus_stp -t SDRAMTest.tcl` - this will
display the options menu for the various tests available within the harness.

Note that this project is WIP and does a naive open/close of a given row in the memory for each access, and also that the issue of clock-domain crossing over the JTAG controller is not currently addressed. This will result in 
the harness providing **eventually consistant** test results at higher memory clock speeds, with the actual result of the last test often being available on a repeated read of the output register. 
