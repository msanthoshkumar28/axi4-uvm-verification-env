typedef enum bit[1:0]{FIXED=0,INCR,WRAP,RSVD}burst_type_t;
class axi_tx extends uvm_sequence_item;
	rand bit wr_rd;
	rand bit[3:0] tx_id;
	rand bit[`ADDR_WIDTH-1:0] addr;
	rand bit[`DATA_WIDTH-1:0] dataQ[$];
	rand bit[3:0] burst_len;
	rand bit[2:0] burst_size;
	rand burst_type_t burst_type;
	rand bit[1:0] respQ[$];
	rand bit[`STRB_WIDTH-1:0] strbQ[$];

    `uvm_object_utils_begin(axi_tx)
	`uvm_field_int(wr_rd,UVM_ALL_ON)
	`uvm_field_int(tx_id,UVM_ALL_ON)
	`uvm_field_int(addr,UVM_ALL_ON)
	`uvm_field_queue_int(dataQ,UVM_ALL_ON)
	`uvm_field_int(burst_len,UVM_ALL_ON)
	`uvm_field_int(burst_size,UVM_ALL_ON)
	`uvm_field_enum(burst_type_t,burst_type,UVM_ALL_ON)
	`uvm_field_queue_int(respQ,UVM_ALL_ON)
	`uvm_field_queue_int(strbQ,UVM_ALL_ON)
	`uvm_object_utils_end
	`NEW_OBJ
    
	constraint data{
		(wr_rd==1) -> dataQ.size()==burst_len+1;
		(wr_rd==0) -> dataQ.size()==0;
	}

	constraint strb{
        strbQ.size() == burst_len+1;
		foreach(strbQ[i]){
		 soft strbQ[i] == (1<<(2**burst_size))-1; 
		}
	}

	constraint wrap{
		burst_type == WRAP -> burst_len inside {1,3,7,15};
		burst_type == WRAP -> addr%(2**burst_size)==0;
	}

	constraint burst_t{
	 	   burst_type != RSVD;
	  soft burst_type == INCR;
	}

	constraint burst_size_t{
       burst_size == $clog2(`DATA_WIDTH/8);
	}
endclass
