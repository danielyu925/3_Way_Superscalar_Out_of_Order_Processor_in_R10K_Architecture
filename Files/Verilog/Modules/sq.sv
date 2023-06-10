/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  sq.sv                                               //
//                                                                     //
//  Description :                                                      // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module sq (
    input                                                                   clock, 
    input                                                                   reset,

    // Dispatch
    input                  [`SUPERSCALAR_WAYS-1:0]                          dispatch_store,
    output logic           [`SUPERSCALAR_WAYS-1:0]                          dispatch_stall,
    output logic           [`SUPERSCALAR_WAYS-1:0][`N_LSQ_ENTRIES_BITS-1:0] dispatch_idx,

    // RS
    output logic           [`N_LSQ_ENTRIES-1:0]                             load_tail_ready,

    // alu store
    input                  [`SUPERSCALAR_WAYS-1:0]                          alu_valid,
    input  SQ_ENTRY_PACKET [`SUPERSCALAR_WAYS-1:0]                          alu_store,
    input                  [`SUPERSCALAR_WAYS-1:0][`N_LSQ_ENTRIES_BITS-1:0] alu_idx,

    // fu load
    input  LOAD_SQ_PACKET  [1:0]                                            load_lookup,
    output SQ_LOAD_PACKET  [1:0]                                            load_forward,

    // Retire
    input                  [`SUPERSCALAR_WAYS-1:0]                          retire_store,
    output SQ_ENTRY_PACKET [`SUPERSCALAR_WAYS-1:0]                          cache_wb, // go to d cache
    output SQ_ENTRY_PACKET [`SUPERSCALAR_WAYS-1:0]                          sq_head   // go to d cache

`ifdef TEST_MODE
    , output SQ_ENTRY_PACKET [0:`N_LSQ_ENTRIES-1]                 sq_reg_display
    , output logic [`N_LSQ_ENTRIES_BITS-1:0]                      head_display, tail_display
    , output logic [`N_LSQ_ENTRIES_BITS-1:0]                      empty_entries_num_display
    , output logic [`N_LSQ_ENTRIES_BITS-1:0]                      filled_entries_num_display
    , output logic [1:0]                                          num_dispatch_store_display, num_retire_store_display
    , output SQ_ENTRY_PACKET [`N_LSQ_ENTRIES-1:0]                 older_store_display
    , output [`N_LSQ_ENTRIES-1:0]                                 older_store_valid_display
`endif
);
// registers
logic [1:0] num_dispatch_store, num_retire_store;
assign num_dispatch_store = dispatch_store[0] + dispatch_store[1] + dispatch_store[2];
assign num_retire_store = retire_store[0] + retire_store[1] + retire_store[2];

// store queue registers
SQ_ENTRY_PACKET [0:`N_LSQ_ENTRIES-1] sq_reg, sq_reg_next/*, sq_reg_after_retire*/;

// head and tail
logic [`N_LSQ_ENTRIES_BITS-1:0] head, wrapped_head; // points to the first valid entry
logic [`N_LSQ_ENTRIES_BITS-1:0] tail, wrapped_tail; // points tp the first empty entry
logic [`N_LSQ_ENTRIES_BITS-1:0] filled_entries_num; // number of filled entries
logic [`N_LSQ_ENTRIES_BITS:0]   empty_entries_num; // number of empty entries
logic [`N_LSQ_ENTRIES_BITS:0]   nxt_head, nxt_tail, nxt_filled_entries_num;
logic [`N_LSQ_ENTRIES_BITS-1:0] head_plus1, head_plus2;

assign nxt_head = head + num_retire_store;
assign nxt_tail = tail + num_dispatch_store;
assign nxt_filled_entries_num = filled_entries_num + num_dispatch_store - num_retire_store;

assign head_plus1 = head + 1;
assign head_plus2 = head + 2;

always_ff @(posedge clock) begin
    if (reset) begin
        head <=`SD 0;
        tail <=`SD 0;
        filled_entries_num <= `SD 0;
    end // if (reset)
    else begin
        head <= `SD nxt_head;
        tail <= `SD nxt_tail;
        filled_entries_num <= `SD nxt_filled_entries_num;
    end // if (~reset)
end

/* Dispatch */
// stall
assign empty_entries_num = `N_LSQ_ENTRIES - filled_entries_num;
always_comb begin
    if (empty_entries_num < 2) dispatch_stall = 3'b111;
    else if (empty_entries_num < 3) dispatch_stall = 3'b011;
    else if (empty_entries_num < 4) dispatch_stall = 3'b001;
    else dispatch_stall = 3'b000;
end

// dispatch index
always_comb begin
    dispatch_idx = 0;
    case(dispatch_store)
        3'b000: begin
            dispatch_idx[0] = tail;
            dispatch_idx[1] = tail;
            dispatch_idx[2] = tail;
        end
        3'b001: begin
            dispatch_idx[0] = tail;
            dispatch_idx[1] = tail;
            dispatch_idx[2] = tail;
        end
        3'b010: begin
            dispatch_idx[0] = tail + 1;
            dispatch_idx[1] = tail;
            dispatch_idx[2] = tail;
        end
        3'b011: begin
            dispatch_idx[0] = tail + 1;
            dispatch_idx[1] = tail;
            dispatch_idx[2] = tail;
        end
        3'b100: begin
            dispatch_idx[0] = tail + 1;
            dispatch_idx[1] = tail + 1;
            dispatch_idx[2] = tail;
        end
        3'b101: begin
            dispatch_idx[0] = tail + 1;
            dispatch_idx[1] = tail + 1;
            dispatch_idx[2] = tail;
        end
        3'b110: begin
            dispatch_idx[0] = tail + 2;
            dispatch_idx[1] = tail + 1;
            dispatch_idx[2] = tail ;
        end
        3'b111: begin
            dispatch_idx[0] = tail + 2;
            dispatch_idx[1] = tail + 1;
            dispatch_idx[2] = tail;
        end
    endcase
end

/* update store registers */
always_comb begin
    sq_reg_next = sq_reg;
    // retire entries
    if (num_retire_store > 0) sq_reg_next[head] = 0;
    if (num_retire_store > 1) sq_reg_next[head + 1] = 0;
    if (num_retire_store > 2) sq_reg_next[head + 2] = 0;

// update sq
    if (alu_valid[0]) sq_reg_next[alu_idx[0]] = alu_store[0];
    if (alu_valid[1]) sq_reg_next[alu_idx[1]] = alu_store[1];
    if (alu_valid[2]) sq_reg_next[alu_idx[2]] = alu_store[2];
end

always_ff @(posedge clock) begin
    if (reset)
        sq_reg <= `SD 0;
    else
        sq_reg <= `SD sq_reg_next;
end

/* RS send ready bit */
always_comb begin
    for (int i = 0; i < `N_LSQ_ENTRIES; i = i + 1) begin
        load_tail_ready[i] = 1'b1; // assuem all ready
        for (int j =0; j < `N_LSQ_ENTRIES; j = j + 1) begin // for each load entry
            // if the i_th entry is younger than head, but the older store is not ready
            if ((i >= head && j >= head && j < i) && (sq_reg[j].ready == 0)) begin
                load_tail_ready[i] = 1'b0; 
                break;
            end
            // if the i_th entry is older than head, but the entry in store queue is empty
            if ((i < head && (j < i || j >= head)) && (sq_reg[j].ready == 0)) begin
                load_tail_ready[i] = 1'b0;
                break;
            end
        end
    end
end

/* Retire */
// output to d_cache, clear retire
always_comb begin
    cache_wb = sq_head;

    if (num_retire_store == 0) cache_wb[2].ready = 0;
    if (num_retire_store <= 1) cache_wb[1].ready = 0;
    if (num_retire_store <= 2) cache_wb[0].ready = 0;
end

always_comb begin
    sq_head[2] = sq_reg[head];
    sq_head[1] = sq_reg[head_plus1];
    sq_head[0] = sq_reg[head_plus2];
end

/* load age logic with 2 load  */
logic [1:0][`N_LSQ_ENTRIES-1:0] older_store_num, older_store_valid;
logic [1:0][`N_LSQ_ENTRIES-1:0][`N_LSQ_ENTRIES_BITS-1:0] older_store_idx;
SQ_ENTRY_PACKET [1:0][`N_LSQ_ENTRIES-1:0] older_store_inst; 

// set older store value
assign  older_store_num[0] = (head <= load_lookup[0].tail_idx)?
                              load_lookup[0].tail_idx - head:
                              `N_LSQ_ENTRIES - head + load_lookup[0].tail_idx;
assign  older_store_num[1] = (head <= load_lookup[1].tail_idx)?
                              load_lookup[1].tail_idx - head:
                              `N_LSQ_ENTRIES - head + load_lookup[1].tail_idx;
always_comb begin
    older_store_valid[0] = 0;
    older_store_valid[1] = 0;
    for (int i = 0; i < `N_LSQ_ENTRIES; i=i+1) begin
        if (i + older_store_num[0] >= `N_LSQ_ENTRIES) older_store_valid[0][i] = 1'b1;
        if (i + older_store_num[1] >= `N_LSQ_ENTRIES) older_store_valid[1][i] = 1'b1;
    end
end

always_comb begin
    for (int i = 0; i < `N_LSQ_ENTRIES; i=i+1) begin
        older_store_idx[0][i] = i + load_lookup[0].tail_idx;
        older_store_idx[1][i] = i + load_lookup[1].tail_idx;

        older_store_inst[0][i] = sq_reg[older_store_idx[0][i]];
        older_store_inst[1][i] = sq_reg[older_store_idx[1][i]];
    end
end

// load stall
always_comb begin
    load_forward[0].stall = 1'b0;
    load_forward[1].stall = 1'b0;
    for (int i = 0; i < `N_LSQ_ENTRIES; i=i+1) begin
        if (~older_store_inst[0][i].ready && older_store_valid[0][i]) begin
            load_forward[0].stall = 1'b1;
            break;
        end
    end

    for (int i = 0; i < `N_LSQ_ENTRIES; i=i+1) begin
        if (~older_store_inst[1][i].ready && older_store_valid[1][i]) begin
            load_forward[1].stall = 1'b1;
            break;
        end
    end
end

// load forward data
logic [1:0][3:0][`N_LSQ_ENTRIES-1:0] byte_forward_valid, byte_forward_sel;
logic [7:0] dummy_wire; // for ps8 req_up
always_comb begin
    byte_forward_valid[0] = 0;
    byte_forward_valid[1] = 0;
    for (int i = 0; i < `N_LSQ_ENTRIES; i=i+1) begin
        if (older_store_valid[0][i] && (older_store_inst[0][i].addr == load_lookup[0].addr)) begin
            byte_forward_valid[0][0][i] = older_store_inst[0][i].usebytes[0];
            byte_forward_valid[0][1][i] = older_store_inst[0][i].usebytes[1];
            byte_forward_valid[0][2][i] = older_store_inst[0][i].usebytes[2];
            byte_forward_valid[0][3][i] = older_store_inst[0][i].usebytes[3];
        end
        if (older_store_valid[1][i] && (older_store_inst[1][i].addr == load_lookup[1].addr)) begin
            byte_forward_valid[1][0][i] = older_store_inst[1][i].usebytes[0];
            byte_forward_valid[1][1][i] = older_store_inst[1][i].usebytes[1];
            byte_forward_valid[1][2][i] = older_store_inst[1][i].usebytes[2];
            byte_forward_valid[1][3][i] = older_store_inst[1][i].usebytes[3];
        end
    end
end

ps8 ps8_0(.req(byte_forward_valid[0][0]), .en(1'b1), .gnt(byte_forward_sel[0][0]), .req_up(dummy_wire[0]));
ps8 ps8_1(.req(byte_forward_valid[0][1]), .en(1'b1), .gnt(byte_forward_sel[0][1]), .req_up(dummy_wire[1]));
ps8 ps8_2(.req(byte_forward_valid[0][2]), .en(1'b1), .gnt(byte_forward_sel[0][2]), .req_up(dummy_wire[2]));
ps8 ps8_3(.req(byte_forward_valid[0][3]), .en(1'b1), .gnt(byte_forward_sel[0][3]), .req_up(dummy_wire[3]));

ps8 ps8_4(.req(byte_forward_valid[1][0]), .en(1'b1), .gnt(byte_forward_sel[1][0]), .req_up(dummy_wire[4]));
ps8 ps8_5(.req(byte_forward_valid[1][1]), .en(1'b1), .gnt(byte_forward_sel[1][1]), .req_up(dummy_wire[5]));
ps8 ps8_6(.req(byte_forward_valid[1][2]), .en(1'b1), .gnt(byte_forward_sel[1][2]), .req_up(dummy_wire[6]));
ps8 ps8_7(.req(byte_forward_valid[1][3]), .en(1'b1), .gnt(byte_forward_sel[1][3]), .req_up(dummy_wire[7]));

always_comb begin
    load_forward[0].data = 0;
    load_forward[1].data = 0;
    for (int i = 0; i < `N_LSQ_ENTRIES; i=i+1) begin
        if (byte_forward_sel[0][0][i])
            load_forward[0].data[7:0] = older_store_inst[0][i].data[7:0];
        if (byte_forward_sel[0][1][i])
            load_forward[0].data[15:8] = older_store_inst[0][i].data[15:8];
        if (byte_forward_sel[0][2][i])
            load_forward[0].data[23:16] = older_store_inst[0][i].data[23:16];
        if (byte_forward_sel[0][3][i])
            load_forward[0].data[31:24] = older_store_inst[0][i].data[31:24];

        if (byte_forward_sel[1][0][i])
            load_forward[1].data[7:0] = older_store_inst[1][i].data[7:0];
        if (byte_forward_sel[1][1][i])
            load_forward[1].data[15:8] = older_store_inst[1][i].data[15:8];
        if (byte_forward_sel[1][2][i])
            load_forward[1].data[23:16] = older_store_inst[1][i].data[23:16];
        if (byte_forward_sel[1][3][i])
            load_forward[1].data[31:24] = older_store_inst[1][i].data[31:24];
    end
end

// load forward usebyte
always_comb begin
    for (int i = 0; i < 4; i=i+1) begin
        load_forward[0].usebytes[i] = |byte_forward_valid[0][i];
        load_forward[1].usebytes[i] = |byte_forward_valid[1][i];
    end
end

`ifdef TEST_MODE
assign sq_reg_display = sq_reg;
assign head_display = head;
assign tail_display = tail;
assign filled_entries_num_display = filled_entries_num;
assign empty_entries_num_display = empty_entries_num;
assign num_dispatch_store_display = num_dispatch_store;
assign num_retire_store_display = num_retire_store;
assign older_store_display = older_store_inst[0];
assign older_store_valid_display = older_store_valid[0];
`endif

endmodule  // sq