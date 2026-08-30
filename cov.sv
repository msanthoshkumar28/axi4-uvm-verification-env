class axi_cov extends uvm_subscriber#(axi_tx);
    `uvm_component_utils(axi_cov)
    axi_tx tx;

    covergroup axi_cg;
        // ---- Address Coverage ----
        cp_addr: coverpoint tx.addr {
            bins low    = {[0          : 32'h3FFF_FFFF]};
            bins mid    = {[32'h4000_0000 : 32'h7FFF_FFFF]};
            bins high   = {[32'h8000_0000 : 32'hFFFF_FFFF]};
        }
        // ---- Burst Length ----
        cp_len: coverpoint tx.burst_len {
            bins single = {0};
            bins short  = {[1:4]};
            bins long   = {[5:15]};
        }
        // ---- Burst Size ----
        cp_size: coverpoint tx.burst_size {
            bins byte1  = {0};  // 1 byte
            bins byte2  = {1};  // 2 bytes
            bins byte4  = {2};  // 4 bytes
            bins byte8  = {3};  // 8 bytes
        }
        // ---- Burst Type ----
        cp_burst: coverpoint tx.burst_type {
            bins FIXED  = {0};
            bins INCR   = {1};
            bins WRAP   = {2};
        }
        // ---- Direction ----
        cp_dir: coverpoint tx.wr_rd {
            bins WRITE  = {1};
            bins READ   = {0};
        }
        // ---- Cross Coverage ----
        cx_len_x_burst: cross cp_len, cp_burst;
        cx_dir_x_len:   cross cp_dir, cp_len;
        cx_dir_x_burst: cross cp_dir, cp_burst;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        axi_cg = new();
    endfunction

    // called automatically when ap.write(tx) fires
    function void write(axi_tx t);
        tx = t;
        axi_cg.sample();
    endfunction
endclass
