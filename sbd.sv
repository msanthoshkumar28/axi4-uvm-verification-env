`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)

class axi_sbd extends uvm_scoreboard;

  `uvm_component_utils(axi_sbd)
  `NEW_COMP
  uvm_analysis_imp_wr #(axi_tx, axi_sbd) wr_imp;
  uvm_analysis_imp_rd #(axi_tx, axi_sbd) rd_imp;

  int mem[*];
  bit [31:0] exp_data;

  int matching;
  int mismatching;

  int addr_t;
  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    wr_imp = new("wr_imp", this);
    rd_imp = new("rd_imp", this);

  endfunction

  function void write_wr(axi_tx tx);
	addr_t = tx.addr;
    foreach(tx.dataQ[i]) begin
        mem[addr_t] = tx.dataQ[i];
        addr_t = tx.addr + (i * (2**tx.burst_size));
    end
  endfunction

  function void write_rd(axi_tx tx);
	addr_t = tx.addr;
    foreach(tx.dataQ[i]) begin
		exp_data=mem[addr_t];
      		if(exp_data == tx.dataQ[i])
      		  matching++;
      		else 
      		  mismatching++;
        addr_t = tx.addr + (i * (2**tx.burst_size));
    end
  endfunction
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if(mismatching == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
  endfunction
endclass
