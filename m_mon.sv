class axi_mon extends uvm_monitor;
    `uvm_component_utils(axi_mon)
    `NEW_COMP
    virtual intf vif;
    uvm_analysis_port#(axi_tx) wr_ap;  // write transactions
    uvm_analysis_port#(axi_tx) rd_ap;  // read transactions

    function void build();
        wr_ap = new("wr_ap", this);
        rd_ap = new("rd_ap", this);
        if(!uvm_config_db#(virtual intf)::get(this, get_full_name, "vif", vif))
            `uvm_info("MON", "intf not connected", UVM_LOW)
    endfunction

    task run();
        fork
            monitor_write();
            monitor_read();
        join
    endtask

    task monitor_write();
        axi_tx tx;
        forever begin
            tx = axi_tx::type_id::create("tx");
            // collect AW channel
            @(posedge vif.aclk);
            wait(vif.awvalid && vif.awready);
            tx.wr_rd      = 1;
            tx.tx_id      = vif.awid;
            tx.addr       = vif.awaddr;
            tx.burst_len  = vif.awlen;
            tx.burst_size = vif.awsize;
            tx.burst_type = burst_type_t'(vif.awburst);//enum casting
            // collect W channel
            repeat(tx.burst_len+1) begin
                @(posedge vif.aclk);
                wait(vif.wvalid && vif.wready);
                tx.dataQ.push_back(vif.wdata);
                tx.strbQ.push_back(vif.wstrb);
            end
            // collect B channel
            @(posedge vif.aclk);
            wait(vif.bvalid && vif.bready);
            tx.respQ.push_back(vif.bresp);

            wr_ap.write(tx);  // broadcast to coverage + scoreboard
        end
    endtask

    task monitor_read();
        axi_tx tx;
        forever begin
            tx = axi_tx::type_id::create("tx");
            // collect AR channel
            @(posedge vif.aclk);
            wait(vif.arvalid && vif.arready);
            tx.wr_rd      = 0;
            tx.tx_id      = vif.arid;
            tx.addr       = vif.araddr;
            tx.burst_len  = vif.arlen;
            tx.burst_size = vif.arsize;
            tx.burst_type =burst_type_t'(vif.arburst);
            // collect R channel
            repeat(tx.burst_len+1) begin
                @(posedge vif.aclk);
                wait(vif.rvalid && vif.rready);
                tx.dataQ.push_back(vif.rdata);
                tx.respQ.push_back(vif.rresp);
            end
            rd_ap.write(tx);  // broadcast to coverage + scoreboard
        end
    endtask
endclass
