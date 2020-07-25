package require Tcl 8.3
##############################################################################################
############################# Basic vJTAG Interface ##########################################
##############################################################################################
set PRESENCE_TESTNO 5 

#This portion of the script is derived from some of the examples from Altera, and from the 
#rather nice writeup by Chris on the DE0 at http://idlelogiclabs.com
#http://idlelogiclabs.com/2012/04/15/talking-to-the-de0-nano-using-the-virtual-jtag-interface/
 
global usbblaster_name
global test_device

# List all available programming hardwares, and select the USBBlaster.
# (Note: this example assumes only one USBBlaster connected.)
# Programming Hardwares:
foreach hardware_name [get_hardware_names] {
#   puts $hardware_name
    if { [string match "USB-Blaster*" $hardware_name] } {
        set usbblaster_name $hardware_name
    }
}
 
puts "Using JTAG chain from $usbblaster_name.";
 
foreach device_name [get_device_names -hardware_name $usbblaster_name] {
    if { [string match "@1*" $device_name] } {
        set test_device $device_name
    }
}
puts "Connecting to FPGA JTAG fabric: $test_device.\n";
 
proc openport {} {
    global usbblaster_name
        global test_device
    open_device -hardware_name $usbblaster_name -device_name $test_device
}
 
proc closeport { } {
    catch {device_unlock}
    catch {close_device}
}

proc userinput {} {
    openport
    device_lock -timeout 10000
	help
    while {1 == 1} {	
	puts -nonewline "\n> "
		set cmd [string toupper [gets stdin]]
		set items [split $cmd " "]
		switch [lindex $items 0] {			
			IDCODE {
				idcode
			}
			BASICRW {
				basicrw
			}
			BASICRWP {
				basicrwp
			}
			READ {
				read [lindex $items 1]
			}
			READBULK {
				readbulk
			}
			DEADWRITE {
				deadwrite
			}
			WRITEVALUE {
				writevalue [lindex $items 1]
			}
			SEQUENCE {
				sequence
			}	
			PUSHFILE {
				pushfile [lindex $items 1]
			}				
			DUMPREG {
				dumpreg [lindex $items 1]
			}
			PRESENCE {
				presence
			}
			HELP {
				help
			}
			QUIT {
				puts "Ok. Daisy, Daisy....."
				break
			}
			default {				
				puts "Talk sense man - or I'll set Crem on you."
			}
		}			
	}
    closeport
}

proc help {} {
	puts "************************************"	
	puts "SDRAM Test Suite Control Script v1.0"	
	puts "Valid commands:"
	puts "    IDCODE"
	puts "    DUMPREG \[number\]"
	puts "    BASICRW"
	puts "    PRESENCE"
	puts "    READ"
	puts "    READBULK"
	puts "    WRITEVALUE \[value\]"
	puts "    DEADWRITE"
	puts "    BASICRWP"
	puts "    SEQUENCE"
	puts "    HELP"
	puts "    QUIT"
	puts "************************************"
}

proc idcode {} {
    device_virtual_ir_shift -instance_index 0 -ir_value 1 -no_captured_ir_value
    set tdi [device_virtual_dr_shift -instance_index 0 -dr_value [dec2bin 0 32] -length 32] 	
    setJTAGBypass 
    puts "Device ID: $tdi"
}

proc pushfile { fileName } {
     # Open the file, and set up to process it in binary mode.

     set f [open $fileName r]
     fconfigure $f \
         -translation binary \
         -encoding binary \
         -buffering full -buffersize 16384

     while { 1 } {
         set s [read $f 8]
         # Convert the data to hex and to characters.
         binary scan $s c value
         puts [format {%08x} $value ]
         # Stop if we've reached end of file
         if { [string length $s] == 0 } {
             break
         }
     }
     # When we're done, close the file.
     close $f
}

proc presence {} {	
	#Light toggle instruction.
	device_virtual_ir_shift -instance_index 0 -ir_value 5
	setJTAGBypass
}

proc writevalue value {
	puts "Write input value $value to first address."
	puts "Mem clock @133Mhz CAS3"

	setParameter 0 0
	setParameter 1 $value
	runTest 4
	
	# Set IR back to 0, which is bypass mode
	setJTAGBypass
}

proc deadwrite {} {
	puts "Write brokenbarberpole to first address."
	puts "Mem clock @133Mhz CAS3"
		
	set tdi [readRegister 0]
	puts "REG:  $tdi"	

	runTest 2
	
	# Set IR back to 0, which is bypass mode
	setJTAGBypass
}

proc read address {
	puts "Read address $address"
	puts "Mem clock @133Mhz CAS3"
		
	setParameter 0 $address
	runTest 3	
	setJTAGBypass
	set tdi [readRegister 0]	
	puts "REG:  $tdi"
}

proc readbulk {} {
	for {set i 0} {$i < 8} {incr i} {
		setParameter 0 $i
		runTest 3	
		setJTAGBypass
		set tdi [readRegister 0]
		puts -nonewline " $tdi "
		if {$i % 2 == 1} {puts ""}
	}
}


proc sequence {} {
	puts "Whole memory write with address values, then verified with read."
	puts "Mem clock @133Mhz CAS3"
	
	set tdi [readRegister 0]
	puts "REG:  $tdi"
		
	runTest 5
	
	puts "Test run - 1 Second delay..."
	after 1000
	puts "Performing fetch, good luck."
		
	set tdi [readRegister 0]	
	set memloc [readRegister 1] 
	
	puts "Test complete."
	puts "REG0:  $tdi"
	puts "REG1:  $memloc"
	if {$tdi == "1"} {
		puts "**TEST PASSED**"
	} else {
		puts "**TEST FAILED**"
	}
	setJTAGBypass
}


proc basicrwp {} {
	puts "Basic write, followed by read. (Single address, persisted 15secs with a broken barberpole input)."
	puts "Mem clock @133Mhz CAS3"
	
	set tdi [readRegister 0]	
	puts "REG:  $tdi"
	
	#Basic write
	runTest 2 
	puts "Value written - 15 sec delay..."
	after 15000
	puts "Performing fetch, good luck."
	#Basic read
	runTest 3 
	
	set tdi [readRegister 0]
	puts "Test complete, value below should be 16bit broken barberpole: b00000000000000001110101110101110"
	puts "REG:  $tdi"
	if {$tdi == "00000000000000001110101110101110"} {
		puts "**TEST PASSED**"
	} else {
		puts "**TEST FAILED**"
	}
	setJTAGBypass
}

proc basicrw {} {
	puts "Two writes, followed by read of first address. (Different input patterns)"
	puts "Mem clock @133Mhz CAS4"
	
	set tdi [readRegister 0]	
	puts "REG:  $tdi"	

	runTest 1
	set tdi [readRegister 0]

	puts "Test complete, value below should be 16bit barberpole: b00000000000000001010101010101010"
	puts "REG:  $tdi"
	if {$tdi == "00000000000000001010101010101010"} {
		puts "**TEST PASSED**"
	} else {
		puts "**TEST FAILED**"
	}
	setJTAGBypass
}

proc dec2bin {i {width {}}} {
    #returns the binary representation of $i
    # width determines the length of the returned string (left truncated or added left 0)
    # use of width allows concatenation of bits sub-fields

    set res {}
    if {$i<0} {
        set sign -
        set i [expr {abs($i)}]
    } else {
        set sign {}
    }
    while {$i>0} {
        set res [expr {$i%2}]$res
        set i [expr {$i/2}]
    }
    if {$res eq {}} {set res 0}

    if {$width ne {}} {
        append d [string repeat 0 $width] $res
        set res [string range $d [string length $res] end]
    }
    return $sign$res
}

proc bin2dec bin {
    if {$bin == 0} {
        return 0
    } elseif {[string match -* $bin]} {
        set sign -
        set bin [string range $bin[set bin {}] 1 end]
    } else {
        set sign {}
    }
    return $sign[expr 0b$bin]
}

proc runTest testno {
	#Go to set instruction
	device_virtual_ir_shift -instance_index 0 -ir_value 6 
	#push in test value
	device_virtual_dr_shift -instance_index 0 -length 32 -dr_value [dec2bin $testno 32]  
	
	#Run test
	device_virtual_ir_shift -instance_index 0 -ir_value 4 
}

proc setParameter {register paramvalue} {
	#Go to set register instruction
	device_virtual_ir_shift -instance_index 0 -ir_value 3 

	#Set the parameter to be the requested register
	device_virtual_dr_shift -instance_index 0 -length 32 -dr_value [dec2bin $register 32]

	#Go to write register instruction
	device_virtual_ir_shift -instance_index 0 -ir_value 7
	device_virtual_dr_shift -instance_index 0 -length 32 -dr_value [dec2bin $paramvalue 32]
	setJTAGBypass 
}

proc readRegister regno {
	#Go to set register instruction
	device_virtual_ir_shift -instance_index 0 -ir_value 3 
	#Set the parameter to be the requested register
	device_virtual_dr_shift -instance_index 0 -length 32 -dr_value [dec2bin $regno 32]   

	#Issue read command
	device_virtual_ir_shift -instance_index 0 -ir_value 2 
	return [device_virtual_dr_shift -instance_index 0 -dr_value [dec2bin 0 32] -length 32] 	
}

proc setJTAGBypass {} {
    device_virtual_ir_shift -instance_index 0 -ir_value 0 -no_captured_ir_value
}

userinput