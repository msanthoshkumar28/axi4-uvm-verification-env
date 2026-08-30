class env extends uvm_env;
	`uvm_component_utils(env)
	`NEW_COMP
	m_agent ma;
	s_agent sa;
	axi_mon mon;
	axi_sbd sbd;
    axi_cov  wr_cov;   // write coverage
    axi_cov  rd_cov;   // read coverage
	function void build();
		ma=m_agent::type_id::create("ma",this);
		sa=s_agent::type_id::create("sa",this);
		mon =axi_mon::type_id::create("mon",this);
		sbd =axi_sbd::type_id::create("sbd",this);
        wr_cov = axi_cov::type_id::create("wr_cov", this);
        rd_cov = axi_cov::type_id::create("rd_cov", this);
	endfunction
    function void connect_phase(uvm_phase phase);
        mon.wr_ap.connect(wr_cov.analysis_export);
        mon.rd_ap.connect(rd_cov.analysis_export);
        mon.wr_ap.connect(sbd.wr_imp);
        mon.rd_ap.connect(sbd.rd_imp);
    endfunction
endclass
