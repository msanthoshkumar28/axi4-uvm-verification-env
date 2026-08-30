`include "uvm_pkg.sv"
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "common.sv"
`include "intf.sv"
`include "axi_tx.sv"
`include "m_seq.sv"
`include "m_sqr.sv"
`include "m_drv.sv"
`include "s_resp.sv"
`include "m_agent.sv"
`include "s_agent.sv"
`include "m_mon.sv"
`include "sbd.sv"
`include "cov.sv"
`include "env.sv"
`include "test.sv"

module top;
	bit aclk,arst;

	intf pif(aclk,arst);
	
	initial begin
	    uvm_config_db#(virtual intf)::set(uvm_root::get(),"*","vif",pif);     // test1 = 1 write | 
		run_test("test6");                                                    // test2 = 5 write | 
	end                                                                       // test3 = 5wr 5rd |-> INCR 
                                  											  // test4 = nwr nrd | 
	always #5 aclk=~aclk;                                                     // test5 = shuffle | 
                                                                              // test6 = FIXED
	initial begin               											  // test7 = WRAP
		aclk=0;
		arst=1;
		@(posedge aclk);
		arst=0;
	end
  initial begin
 	 $dumpfile("dump.vcd");
	 $dumpvars;
  end
endmodule
