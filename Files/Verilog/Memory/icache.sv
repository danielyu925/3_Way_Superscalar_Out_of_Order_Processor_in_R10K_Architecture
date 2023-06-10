/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Module Name :  icache.sv                                          //
//                                                                     //
//   Description :                                                     // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module icache (
    input                                               clock,
    input                                               reset,
    input                                               take_branch,
    input        [`SUPERSCALAR_WAYS-1:0]                Imem2proc_response,           // <- controller.mem2proc_response
    input        [(2*`XLEN)-1:0]                        Imem2proc_data,               // <- controller.mem2proc_data
    input        [`SUPERSCALAR_WAYS-1:0]                Imem2proc_tag,                // <- controller.mem2proc_tag


    input        [1:0]  choose_address,                     
    input        [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0]     proc2Icache_addr,   // <- fetch_stage.proc2Icache_addr
    input        [`SUPERSCALAR_WAYS-1:0][(2*`XLEN)-1:0] cachemem_data,           // <- cache.rd1_data
    input        [`SUPERSCALAR_WAYS-1:0]                cachemem_valid,                // <- cache.rd1_valid

    input                                               hit_but_stall,                 // <- fetch.hit_but_stall

    output logic [1:0]                                  proc2Imem_command,      // -> mem.proc2mem_command
    output logic [`XLEN-1:0]                            proc2Imem_addr,   // -> mem.proc2mem_addr

    output logic [`SUPERSCALAR_WAYS-1:0][`XLEN-1:0]     Icache_data_out,  // -> fetch_stage.cache_data
    output logic [`SUPERSCALAR_WAYS-1:0]                Icache_valid_out,  // -> fetch_stage.cache_valid
    output logic [`SUPERSCALAR_WAYS-1:0]                current_mem_tag,
    output logic [`SUPERSCALAR_WAYS-1:0][4:0]           current_index,     // -> cache.rd1_idx
    output logic [`SUPERSCALAR_WAYS-1:0][7:0]           current_tag,       // -> cache.rd1_tag

    output logic [4:0]                                  fetch_index,     
    output logic [7:0]                                  fetch_tag,

    output logic [`XLEN-1:0]                            fetch_addr,

    output logic                                        data_write_enable,
    output logic                                        changed_addr,
    output logic                                        update_mem_tag,
    output logic                                        miss_outstanding,
    output logic                                        unanswered_miss
);

 
  logic [3:0] current_mem_tag;

  logic miss_outstanding;


  logic [4:0]   fetch_index;
  logic [4:0]   fetch_index_next;
  logic [7:0]   fetch_tag;
  logic [7:0]   fetch_tag_next;

  logic [`XLEN-1:0] fetch_addr;
  logic [`XLEN-1:0] last_fetch_addr;

  assign {current_tag[0], current_index[0]} = proc2Icache_addr[0][`XLEN-1:3];
  assign {current_tag[1], current_index[1]} = proc2Icache_addr[1][`XLEN-1:3];
  assign {current_tag[2], current_index[2]} = proc2Icache_addr[2][`XLEN-1:3];

  assign {fetch_tag_next, fetch_index_next} = fetch_addr[`XLEN-1:3];

  logic changed_addr;
  assign changed_addr = reset ? 0 : (current_index[0] != fetch_index) || (current_tag[0] != fetch_tag); // still needed for "update_mem_tag"
	
  logic cache_miss;
  assign cache_miss = ~cachemem_valid[0] | ~cachemem_valid[1] | ~cachemem_valid[2];

  //wire send_request = miss_outstanding && !changed_addr;

  assign Icache_data_out[0] = proc2Icache_addr[0][2] ? cachemem_data[0][63:32] : cachemem_data[0][31:0];
  assign Icache_data_out[1] = proc2Icache_addr[1][2] ? cachemem_data[1][63:32] : cachemem_data[1][31:0];
  assign Icache_data_out[2] = proc2Icache_addr[2][2] ? cachemem_data[2][63:32] : cachemem_data[2][31:0];

  assign Icache_valid_out[0] = cachemem_valid[0];
  assign Icache_valid_out[1] = cachemem_valid[1];
  assign Icache_valid_out[2] = cachemem_valid[2];

  logic data_write_enable;
  assign data_write_enable = (current_mem_tag == Imem2proc_tag) &&
                             (current_mem_tag != 0);
  logic read_error;
  assign read_error = fetch_addr != last_fetch_addr;

  logic unanswered_miss;
  assign unanswered_miss = reset ? 0 : take_branch  ? cache_miss :
                           changed_addr ? cache_miss :
                           read_error    ? cache_miss : miss_outstanding && (Imem2proc_response == 0);
  logic fetch_signal;
  assign  fetch_signal = ~reset & ~unanswered_miss & ~hit_but_stall;

  
  logic update_mem_tag;
  assign update_mem_tag = (changed_addr ) || (unanswered_miss) || data_write_enable;

  assign proc2Imem_command = reset            ? BUS_NONE :
                             fetch_signal ? BUS_LOAD : BUS_NONE;

  assign proc2Imem_addr = fetch_signal ? fetch_addr : 0;

//  assign wr_index = fetch_wr_enable    ? fetch_index : 0;

//  assign wr_tag = fetch_wr_enable    ? fetch_tag : 0;

  always_comb begin
    if (choose_address == 2'd0) begin
      fetch_addr = {proc2Icache_addr[0][`XLEN-1:3],3'b0};
    end
    else if (choose_address == 2'd1) begin
      fetch_addr = {proc2Icache_addr[1][`XLEN-1:3],3'b0};
    end
    else if (choose_address == 2'd2) begin
      fetch_addr = {proc2Icache_addr[2][`XLEN-1:3],3'b0};
    end
    else begin
      fetch_addr = {proc2Icache_addr[0][`XLEN-1:3],3'b0};
    end
  end
/*  always_comb begin
	for (int i = 0; i < `SUPERSCALAR_WAYS; i = i + 1) begin
		 Icache_data_out[i] = proc2Icache_addr[i][2] ? cachemem_data[i][63:32] : cachemem_data[i][31:0];
		 Icache_valid_out[i] = cachemem_valid[i];
 		 //proc2Imem_addr[i] = {proc2Icache_addr[i][`XLEN-1:3],3'b0};
		 
		 
        end
   end*/
  // synopsys sync_set_reset "reset"
  always_ff @(posedge clock) begin
    if(reset) begin
      fetch_index       <= `SD -1;   // These are -1 to get ball rolling when
      fetch_tag         <= `SD -1;   // reset goes low because addr "changes"
      current_mem_tag  <= `SD 0;              
      miss_outstanding <= `SD 0;
      last_fetch_addr <= `SD 0;
     
    end else begin
      fetch_index       <= `SD fetch_index_next;
      fetch_tag         <= `SD fetch_tag_next;
      miss_outstanding <= `SD unanswered_miss;
      last_fetch_addr <= `SD fetch_addr;

      if((data_write_enable || take_branch) == 1'b1) begin
	  	current_mem_tag <= `SD 0; 
      end	
      else if(update_mem_tag) begin
       	 	current_mem_tag <= `SD Imem2proc_response;
      end
     
    end
  end
endmodule  // icache