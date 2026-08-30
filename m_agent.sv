class m_agent extends uvm_agent;
	`uvm_component_utils(m_agent)
	`NEW_COMP
	m_sqr msqr;
	m_drv mdrv;
	function void build();
		msqr=m_sqr::type_id::create("msqr",this);
		mdrv=m_drv::type_id::create("mdrv",this);
	endfunction
	function void connect();
		mdrv.seq_item_port.connect(msqr.seq_item_export);
	endfunction
endclass
