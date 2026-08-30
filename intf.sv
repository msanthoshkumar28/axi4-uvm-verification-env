interface intf(input bit aclk,arst);
// write addr channel signal
	bit awvalid;
	bit awready;
	bit [3:0]awid;
	bit [`ADDR_WIDTH-1:0]awaddr;
	bit [3:0]awlen;
	bit [2:0]awsize;
	bit [1:0]awburst;
// write data channel signal
	bit wvalid;
	bit wready;
	bit[3:0] wid;
	bit[`DATA_WIDTH-1:0]wdata;
	bit[`STRB_WIDTH-1:0]wstrb;
	bit wlast;
//write response channel signal
	bit bvalid;
	bit bready;
	bit[3:0] bid;
	bit bresp;
//read addr channel signal
	bit arvalid;
	bit arready;
	bit[3:0]arid;
	bit[`ADDR_WIDTH-1:0]araddr;
	bit[3:0] arlen;
	bit[2:0] arsize;
	bit[1:0] arburst;
//read data & resp channel signal
	bit rvalid;
	bit rready;
	bit[3:0] rid;
	bit[`DATA_WIDTH-1:0]rdata;
	bit rlast;
	bit rresp;
endinterface

