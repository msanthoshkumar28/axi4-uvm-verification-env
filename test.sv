class test extends uvm_test;
	`uvm_component_utils(test)
	`NEW_COMP
	env e;
	function void build();
		e=env::type_id::create("e",this);
	endfunction
	function void end_of_elaboration();
		uvm_top.print_topology();
	endfunction
endclass
class test1 extends test; // 1_write
	`uvm_component_utils(test1)
	`NEW_COMP
	m_seq1 seq1;
	task run_phase(uvm_phase phase);
		seq1=m_seq1::type_id::create("seq1");
		phase.raise_objection(this);
		seq1.start(e.ma.msqr);
		phase.phase_done.set_drain_time(this,100);
		phase.drop_objection(this);
	endtask
endclass
class test2 extends test; // 5_write
	`uvm_component_utils(test2)
	`NEW_COMP
	m_seq2 seq2;
	task run_phase(uvm_phase phase);
		seq2=m_seq2::type_id::create("seq2");
		phase.raise_objection(this);
		seq2.start(e.ma.msqr);
		phase.phase_done.set_drain_time(this,100);
		phase.drop_objection(this);
	endtask
endclass
class test3 extends test; // 5wr_5rd
	`uvm_component_utils(test3)
	`NEW_COMP
	m_seq3 seq3;
	task run_phase(uvm_phase phase);
		seq3=m_seq3::type_id::create("seq3");
		phase.raise_objection(this);
		seq3.start(e.ma.msqr);
		phase.phase_done.set_drain_time(this,100);
		phase.drop_objection(this);
	endtask
endclass
class test4 extends test; // nwr_nrd
	`uvm_component_utils(test4)
	`NEW_COMP
	m_seq4 seq4;
	task run_phase(uvm_phase phase);
		seq4=m_seq4::type_id::create("seq4");
		phase.raise_objection(this);
		seq4.start(e.ma.msqr);
		phase.phase_done.set_drain_time(this,100);
		phase.drop_objection(this);
	endtask
endclass
class test5 extends test; // nwr_nrd shuffle
	`uvm_component_utils(test5)
	`NEW_COMP
	m_seq5 seq5;
	task run_phase(uvm_phase phase);
		seq5=m_seq5::type_id::create("seq5");
		phase.raise_objection(this);
		seq5.start(e.ma.msqr);
		phase.phase_done.set_drain_time(this,100);
		phase.drop_objection(this);
	endtask
endclass
class test6 extends test; // fixed nwr_nrd
	`uvm_component_utils(test6)
	`NEW_COMP
	m_seq6 seq6;
	task run_phase(uvm_phase phase);
		seq6=m_seq6::type_id::create("seq6");
		phase.raise_objection(this);
		seq6.start(e.ma.msqr);
		phase.phase_done.set_drain_time(this,100);
		phase.drop_objection(this);
	endtask
endclass
class test7 extends test; // wrap nwr_nrd
	`uvm_component_utils(test7)
	`NEW_COMP
	m_seq7 seq7;
	task run_phase(uvm_phase phase);
		seq7=m_seq7::type_id::create("seq7");
		phase.raise_objection(this);
		seq7.start(e.ma.msqr);
		phase.phase_done.set_drain_time(this,100);
		phase.drop_objection(this);
	endtask
endclass

