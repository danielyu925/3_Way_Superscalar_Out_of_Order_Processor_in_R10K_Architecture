/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Module Name :  ps.sv                                               //
//                                                                     //
//  Description :  priority selector                                   // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module ps #(parameter NUM_BITS = 16) (
    input  [NUM_BITS-1:0] req,
    input                 en,
    output [NUM_BITS-1:0] gnt,
    output                req_up
);
    wire   [NUM_BITS-2:0] req_ups;
    wire   [NUM_BITS-2:0] enables;

    assign req_up = req_ups[NUM_BITS-2];
    assign enables[NUM_BITS-2] = en;

    genvar i; generate
        if (NUM_BITS == 2) begin
            ps2 ps2_0 (
                .req(req),
                .en(en),
                .gnt(gnt),
                .req_up(req_up)
            );
        end  // if (NUM_BITS == 2)
        else begin
            for (i = 0; i < (NUM_BITS / 2); i++) begin : base
                ps2 ps2_0 ( 
                    .req(req[(2*i)+1:2*i]),
                    .en(enables[i]),
                    .gnt(gnt[(2*i)+1:2*i]),
                    .req_up(req_ups[i])
                );
            end  // for each base ps2 submodule
            for (i = (NUM_BITS / 2); i < (NUM_BITS - 1); i++) begin : top
                ps2 ps2_0 (
                    .req(req_ups[((2*i)-NUM_BITS)+1:(2*i)-NUM_BITS]),
                    .en(enables[i]),
                    .gnt(enables[((2*i)-NUM_BITS)+1:(2*i)-NUM_BITS]),
                    .req_up(req_ups[i])
                );
            end  // for each top ps2 submodule
        end  // if (NUM_BITS != 2)
    endgenerate  // generate ps2 submodules
endmodule  // ps

module ps_freelist #(parameter NUM_BITS = `N_PHYS_REG) (
    input  [NUM_BITS-1:0] req,
    input                 en,
    output [NUM_BITS-1:0] gnt,
    output                req_up
);
    wire   [NUM_BITS-2:0] req_ups;
    wire   [NUM_BITS-2:0] enables;

    assign req_up = req_ups[NUM_BITS-2];
    assign enables[NUM_BITS-2] = en;

    genvar i; generate
        if (NUM_BITS == 2) begin
            ps2 ps2_0 (
                .req(req),
                .en(en),
                .gnt(gnt),
                .req_up(req_up)
            );
        end  // if (NUM_BITS == 2)
        else begin
            for (i = 0; i < (NUM_BITS / 2); i++) begin : base
                ps2 ps2_0 ( 
                    .req(req[(2*i)+1:2*i]),
                    .en(enables[i]),
                    .gnt(gnt[(2*i)+1:2*i]),
                    .req_up(req_ups[i])
                );
            end  // for each base ps2 submodule
            for (i = (NUM_BITS / 2); i < (NUM_BITS - 1); i++) begin : top
                ps2 ps2_0 (
                    .req(req_ups[((2*i)-NUM_BITS)+1:(2*i)-NUM_BITS]),
                    .en(enables[i]),
                    .gnt(enables[((2*i)-NUM_BITS)+1:(2*i)-NUM_BITS]),
                    .req_up(req_ups[i])
                );
            end  // for each top ps2 submodule
        end  // if (NUM_BITS != 2)
    endgenerate  // generate ps2 submodules
endmodule  // ps_freelist

module ps_rs #(parameter NUM_BITS = `N_RS_ENTRIES) (
    input  [NUM_BITS-1:0] req,
    input                 en,
    output [NUM_BITS-1:0] gnt,
    output                req_up
);
    wire   [NUM_BITS-2:0] req_ups;
    wire   [NUM_BITS-2:0] enables;

    assign req_up = req_ups[NUM_BITS-2];
    assign enables[NUM_BITS-2] = en;

    genvar i; generate
        if (NUM_BITS == 2) begin
            ps2 ps2_0 (
                .req(req),
                .en(en),
                .gnt(gnt),
                .req_up(req_up)
            );
        end  // if (NUM_BITS == 2)
        else begin
            for (i = 0; i < (NUM_BITS / 2); i++) begin : base
                ps2 ps2_0 ( 
                    .req(req[(2*i)+1:2*i]),
                    .en(enables[i]),
                    .gnt(gnt[(2*i)+1:2*i]),
                    .req_up(req_ups[i])
                );
            end  // for each base ps2 submodule
            for (i = (NUM_BITS / 2); i < (NUM_BITS - 1); i++) begin : top
                ps2 ps2_0 (
                    .req(req_ups[((2*i)-NUM_BITS)+1:(2*i)-NUM_BITS]),
                    .en(enables[i]),
                    .gnt(enables[((2*i)-NUM_BITS)+1:(2*i)-NUM_BITS]),
                    .req_up(req_ups[i])
                );
            end  // for each top ps2 submodule
        end  // if (NUM_BITS != 2)
    endgenerate  // generate ps2 submodules
endmodule  // ps_rs

module ps2 (
    input     [1:0] req,
    input           en,
    output    [1:0] gnt,
    output          req_up
);
    assign gnt[1] = (en & req[1]);
    assign gnt[0] = (en & req[0] & ~req[1]);
    assign req_up = (req[1] | req[0]);
endmodule  // ps2