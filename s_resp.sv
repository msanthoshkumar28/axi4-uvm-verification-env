class s_resp extends uvm_component;
    `uvm_component_utils(s_resp)
    `NEW_COMP
    virtual intf vif;
    bit [7:0] mem[int];

    // write addr vars
    bit [`ADDR_WIDTH-1:0] awaddr_t;
    bit [3:0]             awlen_t;
    bit [2:0]             awsize_t;
    bit [1:0]             awburst_t;

    // read addr vars
    bit [`ADDR_WIDTH-1:0] araddr_t;
    bit [3:0]             arlen_t;
    bit [2:0]             arsize_t;
    bit [1:0]             arburst_t;

    function void build();
        if(!(uvm_config_db#(virtual intf)::get(this,get_full_name,"vif",vif)))
            `uvm_info("RESP", "intf of resp not connected", UVM_LOW)
    endfunction

    task run();
        // local captures to avoid race with shared vars inside forked tasks
        bit [`ADDR_WIDTH-1:0] araddr_cap;
        bit [3:0]             arlen_cap;
        bit [2:0]             arsize_cap;
        bit [3:0]             arid_cap;
        bit [3:0]             wid_cap;

        forever begin
            @(posedge vif.aclk);

            //----------------------------------------------------
            // Write Address Channel
            //----------------------------------------------------
            if(vif.awvalid) begin
                awaddr_t  = vif.awaddr;   // blocking: capture immediately
                awlen_t   = vif.awlen;
                awsize_t  = vif.awsize;
                awburst_t = vif.awburst;
                vif.awready <= 1;
            end 
            else begin
                vif.awready <= 0;
            end

            //----------------------------------------------------
            // Write Data Channel
            //----------------------------------------------------
            vif.wready <= vif.wvalid;
            if(vif.wvalid && vif.wready) begin
			  	for(int i=0;i<(2**awsize_t);i++)begin
				//  part select indexing - [start_bit : no.of bits]
					mem[awaddr_t+i]=vif.wdata[(i*8)+:8];
					`uvm_info("CHECK",$sformatf("mem[%0d]=%0h",(awaddr_t+i),mem[awaddr_t+i]),UVM_LOW)
				end
				case(awburst_t)
                	2'b00:awaddr_t = awaddr_t;
                	2'b01:awaddr_t += (2**awsize_t);
                	2'b10:begin
						int total_byte_tx = (2**awsize_t) * (awlen_t+1);
						bit[`ADDR_WIDTH-1:0] wrap_lower= ((awaddr_t/total_byte_tx)*total_byte_tx);
						bit[`ADDR_WIDTH-1:0] wrap_upper= wrap_lower + total_byte_tx;
						awaddr_t +=(2**awsize_t);
						if(awaddr_t==wrap_upper)	awaddr_t = wrap_lower;
					end
				endcase
            end

            //----------------------------------------------------
            // Write Response Channel (forked — non-blocking)
            //----------------------------------------------------
            if(vif.wlast && vif.wvalid && vif.wready) begin
                wid_cap = vif.wid;
                fork
                    write_resp(wid_cap);
                join_none
            end

            //----------------------------------------------------
            // Read Address Channel (forked — non-blocking)
            //----------------------------------------------------
            if(vif.arvalid) begin
                araddr_cap = vif.araddr;  // capture before deassertion
                arlen_cap  = vif.arlen;
                arsize_cap = vif.arsize;
                arid_cap   = vif.arid;
                arburst_t  = vif.arburst;
                vif.arready <= 1;
                fork
                    read_data(arid_cap, arlen_cap, araddr_cap, arsize_cap ,arburst_t);
                join_none
            end
			else begin
                vif.arready <= 0;
            end

        end // forever
    endtask

    //----------------------------------------------------
    // Write Response Task
    //----------------------------------------------------
    task write_resp(bit [3:0] id);
        @(posedge vif.aclk);
        vif.bresp  <= 0;
        vif.bid    <= id;
        vif.bvalid <= 1;
        wait(vif.bready == 1);
        @(posedge vif.aclk);
        vif.bresp  <= 0;
        vif.bid    <= 0;
        vif.bvalid <= 0;
    endtask

    //----------------------------------------------------
    // Read Data Task
    // araddr/arsize passed as args to avoid shared-var race
    //----------------------------------------------------
    task read_data(bit [3:0]             id,
                   bit [3:0]             arlen,
                   bit [`ADDR_WIDTH-1:0] araddr,
                   bit [2:0]             arsize,
				   bit [1:0]             arburst);

        @(posedge vif.aclk); // one cycle gap after arready

        for(int i = 0; i <= arlen; i++) begin
            @(posedge vif.aclk);
            // drive data and valid together BEFORE waiting for rready
            vif.rvalid <= 1;
			for(int i=0;i<(2**arsize);i++)begin
            	vif.rdata[(i*8)+:8] <= mem.exists(araddr+i)?mem[araddr+i] : 8'h0;
				`uvm_info("RX_CHECK",$sformatf("mem[%0d]=%0h",(awaddr_t+i),mem[awaddr_t+i]),UVM_LOW)
			end
            vif.rid    <= id;
            vif.rresp  <= 0;
            vif.rlast  <= (i == arlen) ? 1 : 0;
			case(arburst)
                	2'b00:araddr = araddr;
                	2'b01:araddr += (2**arsize);
                	2'b10:begin
						int total_byte_rx = (2**arsize) * (arlen+1);
						bit[`ADDR_WIDTH-1:0] wrap_lower_r= ((araddr/total_byte_rx)*total_byte_rx);
						bit[`ADDR_WIDTH-1:0] wrap_upper_r= wrap_lower_r + total_byte_rx;
						araddr +=(2**arsize);
						if(araddr==wrap_upper_r)	araddr = wrap_lower_r;
					end
			endcase
            // wait for master to accept
            wait(vif.rready == 1);
        end

        // deassert after burst
        @(posedge vif.aclk);
        vif.rvalid <= 0;
        vif.rdata  <= 0;
        vif.rid    <= 0;
        vif.rresp  <= 0;
        vif.rlast  <= 0;
    endtask

endclass
