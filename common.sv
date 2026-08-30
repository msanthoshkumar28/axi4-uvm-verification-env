`define NEW_COMP function new(input string name="",uvm_component parent); \
						super.new(name,parent); \
					endfunction
`define NEW_OBJ function new(input string name=""); \
						super.new(name); \
					endfunction

`define DATA_WIDTH 32
`define ADDR_WIDTH 32
`define STRB_WIDTH `DATA_WIDTH/8
`define N 1

