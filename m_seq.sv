class m_seq extends uvm_sequence#(axi_tx);
  axi_tx txQ[$];
  axi_tx temp,rx;
	`uvm_object_utils(m_seq)
	`NEW_OBJ
endclass
class m_seq1 extends m_seq;// 1 wr
	`uvm_object_utils(m_seq1)
	`NEW_OBJ

	task body();
		`uvm_do_with(req,{req.wr_rd==1;})
	endtask
endclass
class m_seq2 extends m_seq; // 5 wr
	`uvm_object_utils(m_seq2)
	`NEW_OBJ

	task body();
		repeat(5)begin
		`uvm_do_with(req,{req.wr_rd==1;})
		end
	endtask
endclass
class m_seq3 extends m_seq;// 5wr 5rd
	`uvm_object_utils(m_seq3)
	`NEW_OBJ

	task body();
      repeat(5) begin
        `uvm_do_with(req, {req.wr_rd==1;})
        $cast(temp, req.clone());   // creates a NEW independent object
        txQ.push_back(temp);
      end
      repeat(5) begin
        rx = txQ.pop_front();
        `uvm_do_with(req, {
            req.wr_rd       == 0;
            req.addr        == rx.addr;
            req.burst_size  == rx.burst_size;
            req.burst_len   == rx.burst_len;
            req.burst_type  == rx.burst_type;
        })
      end
    endtask
endclass
class m_seq4 extends m_seq;// nwr nrd
	`uvm_object_utils(m_seq4)
	`NEW_OBJ

	task body();
      repeat(`N) begin
        `uvm_do_with(req, {req.wr_rd==1;})
        $cast(temp, req.clone());   //creates a NEW independent object
        txQ.push_back(temp);
      end
      repeat(`N) begin
        rx = txQ.pop_front();
        `uvm_do_with(req, {
            req.wr_rd       == 0;
            req.addr        == rx.addr;
            req.burst_size  == rx.burst_size;
            req.burst_len   == rx.burst_len;
            req.burst_type  == rx.burst_type;
        })
     end
	endtask
endclass
class m_seq5 extends m_seq;// nwr_nrd with shuffle
	`uvm_object_utils(m_seq5)
	`NEW_OBJ

	task body();
      repeat(`N) begin
        `uvm_do_with(req, {req.wr_rd==1;})
        $cast(temp, req.clone());   
        txQ.push_back(temp);
      end
      repeat(`N) begin
	  	txQ.shuffle();
        rx = txQ.pop_front();
        `uvm_do_with(req, {
            req.wr_rd       == 0;
            req.addr        == rx.addr;
            req.burst_size  == rx.burst_size;
            req.burst_len   == rx.burst_len;
            req.burst_type  == rx.burst_type;
        })
    end
   endtask
endclass
class m_seq6 extends m_seq;// fixed nwr nrd
	`uvm_object_utils(m_seq6)
	`NEW_OBJ

	task body();
      repeat(`N) begin
        `uvm_do_with(req, {req.wr_rd==1;req.burst_type==FIXED;})
        $cast(temp, req.clone());   //creates a NEW independent object
        txQ.push_back(temp);
      end
      repeat(`N) begin
        rx = txQ.pop_front();
        `uvm_do_with(req, {
            req.wr_rd       == 0;
            req.addr        == rx.addr;
            req.burst_size  == rx.burst_size;
            req.burst_len   == rx.burst_len;
            req.burst_type  == rx.burst_type;
        })
     end
   endtask
endclass
class m_seq7 extends m_seq;// wrap nwr nrd
	`uvm_object_utils(m_seq7)
	`NEW_OBJ

	task body();
      repeat(`N) begin
        `uvm_do_with(req, {req.wr_rd==1;req.burst_type==WRAP;})
        $cast(temp, req.clone());   //creates a NEW independent object
        txQ.push_back(temp);
      end
      repeat(`N) begin
        rx = txQ.pop_front();
        `uvm_do_with(req, {
            req.wr_rd       == 0;
            req.addr        == rx.addr;
            req.burst_size  == rx.burst_size;
            req.burst_len   == rx.burst_len;
            req.burst_type  == rx.burst_type;
        })
     end
   endtask
endclass
