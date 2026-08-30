class m_drv extends uvm_driver#(axi_tx);
	`uvm_component_utils(m_drv)
	`NEW_COMP
	virtual intf vif;

	function void build();
		if(!(uvm_config_db#(virtual intf)::get(this,get_full_name,"vif",vif)))
		`uvm_info("DRV","intf of driver not connected",UVM_LOW)
	endfunction

	task run();
	 forever begin
	 	seq_item_port.get_next_item(req);
		req.print();
		drive_tx(req);
		seq_item_port.item_done();
	 end
	endtask
	task drive_tx(axi_tx tx);
		wait(vif.arst==0);
		if(tx.wr_rd==1)begin
		 write_addr(tx);
		 write_data(tx);
		 write_resp(tx);
		end
		else begin
		 read_addr(tx);
		 read_data(tx);
		end
	endtask
	task write_addr(axi_tx tx);
		@(posedge vif.aclk);
		 vif.awid      <= tx.tx_id;
		 vif.awlen     <= tx.burst_len;
		 vif.awsize    <= tx.burst_size;
		 vif.awburst   <= tx.burst_type;
		 vif.awaddr    <= tx.addr;
		 vif.awvalid   <= 1;
		 wait(vif.awready == 1);
		@(posedge vif.aclk);
		 vif.awid      <= 0;
		 vif.awlen     <= 0;
		 vif.awsize    <= 0;
		 vif.awburst   <= 0;
		 vif.awaddr    <= 0;
		 vif.awvalid   <= 0;
	endtask
	task write_data(axi_tx tx);
	 for(int i=0;i<=tx.burst_len;i++)begin
		@(posedge vif.aclk);
		 vif.wid	<=tx.tx_id;
		 vif.wdata	<=tx.dataQ.pop_front();
		 vif.wstrb	<=tx.strbQ.pop_front();
		 vif.wlast	<=(i==tx.burst_len)? 1:0;
		 vif.wvalid	<=1;
		 wait(vif.wready==1);
	 end
		@(posedge vif.aclk);
		 vif.wid	<=0;
		 vif.wdata	<=0;
		 vif.wstrb	<=0;
		 vif.wlast	<=0;
		 vif.wvalid	<=0;
	endtask
	task write_resp(axi_tx tx);
        while(vif.bvalid == 0)begin  //for clk synchronization
			@(posedge vif.aclk);
		end
		vif.bready <= 1;
		@(posedge vif.aclk);
		vif.bready <= 0;
	endtask
	task read_addr(axi_tx tx);
		@(posedge vif.aclk);
		 vif.arid    <= tx.tx_id;
		 vif.araddr  <= tx.addr;
		 vif.arlen   <= tx.burst_len;
		 vif.arsize  <= tx.burst_size;
		 vif.arburst <= tx.burst_type;
		 vif.arvalid <= 1;
		 wait(vif.arready == 1);
		@(posedge vif.aclk);
		 vif.arid    <= 0; 
		 vif.araddr  <= 0; 
		 vif.arlen   <= 0; 
		 vif.arsize  <= 0; 
		 vif.arburst <= 0; 
		 vif.arvalid <= 0;
	endtask
	task read_data(axi_tx tx);
		@(posedge vif.aclk);
		 repeat(tx.burst_len+1)begin
		 	while(vif.rvalid == 0)begin
		      @(posedge vif.aclk);
			end
			vif.rready <= 1;
		    @(posedge vif.aclk);
			vif.rready <= 0;
		 end
	endtask
endclass

