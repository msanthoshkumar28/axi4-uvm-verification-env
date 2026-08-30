class s_agent extends uvm_agent;
	`uvm_component_utils(s_agent)
	`NEW_COMP
	s_resp sresp;
	function void build();
		sresp=s_resp::type_id::create("sresp",this);
	endfunction
endclass

