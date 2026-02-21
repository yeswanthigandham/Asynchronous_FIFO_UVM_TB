// Code your testbench here
// or browse Examples

package tb_pkg;
import uvm_pkg::*;
  `include "uvm_macros.svh"
  // -------------------------------------------------
  // Global testbench parameters
  // -------------------------------------------------
parameter int DEPTH=8;
parameter int DATA_WIDTH=8;


//Write seq_item
class wrseq_item extends uvm_sequence_item;
	`uvm_object_utils(wrseq_item)
	
	rand bit w_en;
	rand bit [DATA_WIDTH-1:0]data_in;
	bit full;
	
	function new(string name="wrseq_item");
		super.new(name);
	endfunction
	
	constraint write_enable { w_en dist {0:=30,1:=70};}
	
endclass

//Read Seq_item
class rdseq_item extends uvm_sequence_item;
	`uvm_object_utils(rdseq_item)
	
	rand bit r_en;
	//rand bit [DATA_WIDTH-1:0]din;
	bit  [DATA_WIDTH-1:0]data_out;
	bit empty;
	
	function new(string name="rdseq_item");
		super.new(name);
	endfunction
	
	constraint read_enable { r_en dist {0:=30,1:=70};}
	
endclass

//write sequence
class wrseq extends uvm_sequence#(wrseq_item);
	`uvm_object_utils(wrseq)
	rand int wr_txn_count;
  
  function new(string name="wrseq");
		super.new(name);
  endfunction
  
	constraint wr_txns { 
      					wr_txn_count inside {[50:80]};
                       }
  
	virtual task body();
         wrseq_item wrseq_item1;
		this.randomize();
      
      	`uvm_info(get_type_name(),$sformatf("generating write txns=%0d \n",wr_txn_count),UVM_LOW);
		
     
	
      repeat(wr_txn_count) begin
			wrseq_item1=wrseq_item::type_id::create("wrseq_item1");	
			start_item(wrseq_item1);
			assert(wrseq_item1.randomize());
			finish_item(wrseq_item1);
		end
	endtask
	
endclass
//read sequence
class rdseq extends uvm_sequence#(rdseq_item);
	`uvm_object_utils(rdseq)
	rand int rd_txn_count;
  function new(string name="rdseq");
		super.new(name);
	endfunction
	constraint rd_txns { rd_txn_count inside {[50:80]};} 
	virtual task body();
      rdseq_item rdseq_item1;
		this.randomize();
	`uvm_info(get_type_name(),$sformatf("generating read txns=%0d \n",rd_txn_count),UVM_LOW);
	
	repeat(rd_txn_count) begin
		rdseq_item1=rdseq_item::type_id::create("rdseq_item1");	
		start_item(rdseq_item1);
		assert(rdseq_item1.randomize());
		finish_item(rdseq_item1);
	end
	endtask
	
endclass

//write seqr
class wrseqr extends uvm_sequencer#(wrseq_item);
	`uvm_component_utils(wrseqr)
	function new(string name="wrseqr", uvm_component parent);
		super.new(name,parent);
	endfunction
endclass
//read_seqr
class rdseqr extends uvm_sequencer#(rdseq_item);
	`uvm_component_utils(rdseqr)
	function new(string name="rdseqr", uvm_component parent);
		super.new(name,parent);
	endfunction
endclass
//write driver
class wrdriver extends uvm_driver#(wrseq_item);
	`uvm_component_utils(wrdriver)
	virtual intf vif;
	function new(string name="wrdriver",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual intf)::get(this,"","vif",vif))
			`uvm_error(get_type_name(),"failed to get virtual intf");
	endfunction
	
	task run_phase(uvm_phase phase);
		wrseq_item wrseq_item1;
		forever begin
		   seq_item_port.get_next_item(wrseq_item1);
		   drive_write(wrseq_item1);
		   seq_item_port.item_done();
		end
	endtask
	
	task drive_write(wrseq_item wrseq_item1);
	 @(posedge vif.wclk);
	 if (vif.wrst_n) begin
	 vif.w_en<=wrseq_item1.w_en;
	 vif.data_in<=wrseq_item1.data_in;
	 end
	endtask
	
endclass
//read driver
class rddriver extends uvm_driver#(rdseq_item);
	`uvm_component_utils(rddriver)
	virtual intf vif;
	function new(string name="rddriver",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual intf)::get(this,"","vif",vif))
			`uvm_error(get_type_name(),"failed to get virtual intf");
	endfunction
	
	task run_phase(uvm_phase phase);
		rdseq_item rdseq_item1;
		forever begin
		   seq_item_port.get_next_item(rdseq_item1);
		   drive_read(rdseq_item1);
		   seq_item_port.item_done();
		end
	endtask
	
	task drive_read(rdseq_item rdseq_item1);
	 @(posedge vif.rclk);
	 if(vif.rrst_n) begin
	 vif.r_en<=rdseq_item1.r_en;
	 //vif.data_in<=rdseq_item1.data_in;
	 end
	endtask
	
endclass
//write mon
class wrmon extends uvm_monitor;
	`uvm_component_utils(wrmon)
	virtual intf vif;
	uvm_analysis_port#(wrseq_item) wr_a_port;
	function new(string name="wrmon",uvm_component parent);
		super.new(name,parent);
		wr_a_port=new("wr_a_port",this);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual intf)::get(this,"","vif",vif))
			`uvm_error(get_type_name(),"failed to get virtual intf");
	endfunction		
	
	task run_phase(uvm_phase phase);
	    wrseq_item wrseq_item1;
		forever begin
		wrseq_item1=wrseq_item::type_id::create("wrseq_item1");
		@(posedge vif.wclk);
		if(vif.w_en && vif.wrst_n) begin
		    wrseq_item1.w_en=vif.w_en;
			wrseq_item1.data_in=vif.data_in;
			wrseq_item1.full=vif.full;
		end
		
		wr_a_port.write(wrseq_item1);
		end
	endtask
		
	
endclass
//read mon
class rdmon extends uvm_monitor;
	`uvm_component_utils(rdmon)
	virtual intf vif;
	uvm_analysis_port#(rdseq_item) rd_a_port;
	function new(string name="rdmon",uvm_component parent);
		super.new(name,parent);
		rd_a_port=new("rd_a_port",this);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(virtual intf)::get(this,"","vif",vif))
          `uvm_error(get_type_name(),"failed to get virtual intf\n");
	endfunction		
	
	task run_phase(uvm_phase phase);
	    rdseq_item rdseq_item1;
		forever begin
		rdseq_item1=rdseq_item::type_id::create("rdseq_item1");
		@(posedge vif.rclk);
		if(vif.r_en && vif.rrst_n) begin
		    rdseq_item1.r_en=vif.r_en;
			rdseq_item1.data_out=vif.data_out;
			rdseq_item1.empty=vif.empty;
		end		
		rd_a_port.write(rdseq_item1);
		end
	endtask
	
endclass
//write agent
class wragent extends uvm_agent;
	`uvm_component_utils(wragent)
	wrseqr wrseqr1;
	wrdriver wrdriver1;
	wrmon wrmon1;
	
	function new(string name="wragent",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(get_is_active()== UVM_ACTIVE) begin
		   wrseqr1=wrseqr::type_id::create("wrseqr1",this);
		   wrdriver1=wrdriver::type_id::create("wrdriver1",this);
		end
		wrmon1=wrmon::type_id::create("wrmon1",this);
	endfunction
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		if(get_is_active()==UVM_ACTIVE)
		wrdriver1.seq_item_port.connect(wrseqr1.seq_item_export);
	endfunction	
	
endclass
//read agent
class rdagent extends uvm_agent;
	`uvm_component_utils(rdagent)
	rdseqr rdseqr1;
	rddriver rddriver1;
	rdmon rdmon1;
	
	function new(string name="rdagent",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(get_is_active()== UVM_ACTIVE) begin
		   rdseqr1=rdseqr::type_id::create("rdseqr1",this);
		   rddriver1=rddriver::type_id::create("rddriver1",this);
		end
		rdmon1=rdmon::type_id::create("rdmon1",this);
	endfunction
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		if(get_is_active()==UVM_ACTIVE)
		rddriver1.seq_item_port.connect(rdseqr1.seq_item_export);
	endfunction	
	
endclass

//virtual seqr
class my_virtual_seqr extends uvm_sequencer;
	`uvm_component_utils(my_virtual_seqr)
	wrseqr wrseqr1;
	rdseqr rdseqr1;
	function new(string name="my_virtual_seqr",uvm_component parent);
		super.new(name,parent);
	endfunction
endclass

//virtual sequence
class my_virtual_seq extends uvm_sequence;
	`uvm_object_utils(my_virtual_seq)
	`uvm_declare_p_sequencer(my_virtual_seqr)
	
	function new(string name="my_virtual_seq");
		super.new(name);
	endfunction
	
	wrseq wrseq1;
	rdseq rdseq1;

	task pre_body();
		wrseq1=wrseq::type_id::create("wrseq1");
		rdseq1=rdseq::type_id::create("rdseq1");
	endtask
	
	task body();
		fork
			wrseq1.start(p_sequencer.wrseqr1);
			rdseq1.start(p_sequencer.rdseqr1);
		join
	endtask
endclass

//scoreboard
`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)
class scoreboard extends uvm_scoreboard;
	`uvm_component_utils(scoreboard)
	
	uvm_analysis_imp_wr#(wrseq_item,scoreboard) wr_a_imp;
	uvm_analysis_imp_rd#(rdseq_item,scoreboard) rd_a_imp;
	
	bit [DATA_WIDTH-1:0]ref_fifo_q[$];
	bit [DATA_WIDTH-1:0]exp_data;
	
	function new(string name="scoreboard",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		wr_a_imp=new("wr_a_imp",this);
		rd_a_imp=new("rd_a_imp",this);
	endfunction
	
	virtual function void write_wr(wrseq_item wrseq_item1);
        if(wrseq_item1.w_en && !wrseq_item1.full) begin
			ref_fifo_q.push_back(wrseq_item1.data_in);
			`uvm_info(get_type_name(),$sformatf("PUSHING DATA IN REF_FIFO=%0h\n",wrseq_item1.data_in),UVM_LOW);
		end
	endfunction

	virtual function void write_rd(rdseq_item rdseq_item1);
		if(rdseq_item1.r_en && !rdseq_item1.empty) begin
			exp_data=ref_fifo_q.pop_front();
			`uvm_info(get_type_name(),$sformatf("POP DATA=%0h",exp_data),UVM_LOW);
			if(rdseq_item1.data_out == exp_data) begin
				`uvm_info(get_type_name(),$sformatf("SCBD DATA MATCHED Actual=%0h exp=%0h",rdseq_item1.data_out,exp_data),UVM_LOW);
			end
			else begin
				`uvm_info(get_type_name(),$sformatf("SCBD DATA MISMATCH Actual=%0h exp=%0h",rdseq_item1.data_out,exp_data),UVM_LOW);
				`uvm_error(get_type_name(),"DATA MISMATCH\n");
				end
		end
	endfunction
endclass

//env
class env extends uvm_env;
	`uvm_component_utils(env)
	
	wragent wragent1;
	rdagent rdagent1;
	scoreboard scoreboard1;
	my_virtual_seqr my_virtual_seqr1;
	
	function new(string name="env", uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		wragent1=wragent::type_id::create("wragent1",this);
      rdagent1=rdagent::type_id::create("rdagent1",this);
		scoreboard1=scoreboard::type_id::create("scoreboard1",this);
		my_virtual_seqr1=my_virtual_seqr::type_id::create("my_virtual_seqr1",this);
	endfunction
	
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		wragent1.wrmon1.wr_a_port.connect(scoreboard1.wr_a_imp);
		rdagent1.rdmon1.rd_a_port.connect(scoreboard1.rd_a_imp);
		my_virtual_seqr1.wrseqr1=wragent1.wrseqr1;
		my_virtual_seqr1.rdseqr1=rdagent1.rdseqr1;
	endfunction
endclass

//test
class test extends uvm_test;
	`uvm_component_utils(test);
	env env1;
	my_virtual_seq my_virtual_seq1;
	
	function new(string name="test",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env1=env::type_id::create("env1",this);
		my_virtual_seq1=my_virtual_seq::type_id::create("my_virtual_seq1",this);
	endfunction
	
	task run_phase(uvm_phase phase);
		my_virtual_seq my_virtual_seq1;
		phase.raise_objection(this);
		my_virtual_seq1=my_virtual_seq::type_id::create("my_virtual_seq1",this);
		my_virtual_seq1.start(env1.my_virtual_seqr1);
		phase.drop_objection(this);
	endtask
	
endclass

endpackage
`timescale 1ns/1ps
import uvm_pkg::*;
import tb_pkg::*;
`include "uvm_macros.svh"
//tb_top
module tb_top;

//clock
//logic wclk,rclk;

// Interface
  intf vif();

//DUT INSTANCE
  asynchronous_fifo dut(
    .wclk(vif.wclk),
    .rclk(vif.rclk),
    .wrst_n(vif.wrst_n),
    .rrst_n(vif.rrst_n),
    .w_en(vif.w_en),
    .r_en(vif.r_en),
    .data_in(vif.data_in),
    .data_out(vif.data_out),
    .full(vif.full),
    .empty(vif.empty)
  );

// Clock generation
  initial begin
    vif.wclk = 0;
    
    forever #5 vif.wclk = ~vif.wclk;   // 100 MHz
   // forever #5 rclk = ~rclk;   // 100 MHz
  end
  
  initial begin
    vif.rclk= 0;
    forever #8 vif.rclk = ~vif.rclk;   // 100 MHz
  end
  

//Reset generation
  // Reset generation
  initial begin
    vif.wrst_n    = 0;
    vif.rrst_n    = 0;
    vif.r_en   = 0;
    vif.w_en   = 0;
    vif.data_in = 0;

    repeat (3) @(posedge vif.wclk);
    vif.wrst_n = 1;
    repeat (2) @(posedge vif.rclk);
        vif.rrst_n = 1;
  end
  // UVM configuration and test start
  initial begin
    // Make virtual interface visible to UVM
    uvm_config_db#(virtual intf)::set(null, "*", "vif", vif);
    // Start UVM
    run_test("test");  
  end

  initial begin
    $dumpvars;
    $dumpfile ("dump.vcd");
  end
  

endmodule


