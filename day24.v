
`timescale 1ns/1ps

//============================================================
// 1. Active-high 3-to-8 one-hot decoder
//============================================================
module decoder_3to8 (
    input  wire       enable,
    input  wire [2:0] addr,
    output reg  [7:0] sel
);
    always @* begin
        sel = 8'b0000_0000;
        if (enable)
            sel[addr] = 1'b1;
    end
endmodule


//============================================================
// 2. D flip-flop with synchronous reset and enable
// Reset has priority over enable.
//============================================================
module dff_reset_enable (
    input  wire clk,
    input  wire reset,
    input  wire enable,
    input  wire d,
    output reg  q
);
    always @(posedge clk) begin
        if (reset)
            q <= 1'b0;
        else if (enable)
            q <= d;
    end
endmodule


//============================================================
// 3. One-bit 2-to-1 multiplexer
//============================================================
module mux2_1bit (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);
    assign y = sel ? b : a;
endmodule


//============================================================
// 4. Structural 8-to-1 asynchronous read mux, 8 bits wide
// Seven 2:1 muxes per output bit; 56 per read port.
//============================================================
module read_mux_8x1 (
    input  wire [63:0] regs_flat,
    input  wire [2:0]  read_addr,
    output wire [7:0]  read_data
);
    wire [7:0] level1 [0:3];
    wire [7:0] level2 [0:1];

    genvar b;
    generate
        for (b = 0; b < 8; b = b + 1) begin : GEN_MUX_BIT

            // Level 1: select within adjacent register pairs
            mux2_1bit u_l1_0 (
                .a(regs_flat[0*8+b]),
                .b(regs_flat[1*8+b]),
                .sel(read_addr[0]),
                .y(level1[0][b])
            );

            mux2_1bit u_l1_1 (
                .a(regs_flat[2*8+b]),
                .b(regs_flat[3*8+b]),
                .sel(read_addr[0]),
                .y(level1[1][b])
            );

            mux2_1bit u_l1_2 (
                .a(regs_flat[4*8+b]),
                .b(regs_flat[5*8+b]),
                .sel(read_addr[0]),
                .y(level1[2][b])
            );

            mux2_1bit u_l1_3 (
                .a(regs_flat[6*8+b]),
                .b(regs_flat[7*8+b]),
                .sel(read_addr[0]),
                .y(level1[3][b])
            );

            // Level 2: select between register pairs
            mux2_1bit u_l2_0 (
                .a(level1[0][b]),
                .b(level1[1][b]),
                .sel(read_addr[1]),
                .y(level2[0][b])
            );

            mux2_1bit u_l2_1 (
                .a(level1[2][b]),
                .b(level1[3][b]),
                .sel(read_addr[1]),
                .y(level2[1][b])
            );

            // Level 3: final selection
            mux2_1bit u_l3 (
                .a(level2[0][b]),
                .b(level2[1][b]),
                .sel(read_addr[2]),
                .y(read_data[b])
            );

        end
    endgenerate
endmodule


//============================================================
// 5. 8-bit register built from eight D flip-flops
//============================================================
module register_8bit (
    input  wire       clk,
    input  wire       reset,
    input  wire       enable,
    input  wire [7:0] d,
    output wire [7:0] q
);
    genvar bit_index;
    generate
        for (bit_index = 0; bit_index < 8;
             bit_index = bit_index + 1) begin : GEN_DFF

            dff_reset_enable u_dff (
                .clk    (clk),
                .reset  (reset),
                .enable (enable),
                .d      (d[bit_index]),
                .q      (q[bit_index])
            );

        end
    endgenerate
endmodule


//============================================================
// 6. Register bank: eight 8-bit registers
// regs_flat[8*i +: 8] represents register i.
//============================================================
module register_bank_8x8 (
    input  wire        clk,
    input  wire        reset,
    input  wire        we,
    input  wire [2:0]  write_addr,
    input  wire [7:0]  write_data,
    output wire [63:0] regs_flat
);
    wire [7:0] write_select;

    decoder_3to8 u_write_decoder (
        .enable (we),
        .addr   (write_addr),
        .sel    (write_select)
    );

    genvar reg_index;
    generate
        for (reg_index = 0; reg_index < 8;
             reg_index = reg_index + 1) begin : GEN_REG

            register_8bit u_register (
                .clk    (clk),
                .reset  (reset),
                .enable (write_select[reg_index]),
                .d      (write_data),
                .q      (regs_flat[reg_index*8 +: 8])
            );

        end
    endgenerate
endmodule


//============================================================
// 7. TOP MODULE: 8 x 8 register file
// One synchronous write port and two asynchronous read ports.
//============================================================
module register_file_top (
    input  wire       clk,
    input  wire       reset,
    input  wire       we,
    input  wire [2:0] write_addr,
    input  wire [7:0] write_data,
    input  wire [2:0] read_addr_a,
    input  wire [2:0] read_addr_b,
    output wire [7:0] read_data_a,
    output wire [7:0] read_data_b
);
    wire [63:0] regs_flat;

    // Register storage and write path
    register_bank_8x8 u_register_bank (
        .clk        (clk),
        .reset      (reset),
        .we         (we),
        .write_addr (write_addr),
        .write_data (write_data),
        .regs_flat  (regs_flat)
    );

    // Asynchronous read port A
    read_mux_8x1 u_read_mux_a (
        .regs_flat (regs_flat),
        .read_addr (read_addr_a),
        .read_data (read_data_a)
    );

    // Asynchronous read port B
    read_mux_8x1 u_read_mux_b (
        .regs_flat (regs_flat),
        .read_addr (read_addr_b),
        .read_data (read_data_b)
    );
endmodule
