`timescale 1ns/1ps

//======================================================================
// DAY 24: SELF-CHECKING TOP-LEVEL TESTBENCH
// DUT required: register_file_top
// Write: synchronous, positive clock edge
// Read: asynchronous, two independent read ports
// Reset: active-high synchronous; reset has priority over write enable
//======================================================================
module tb_register_file_top;

    reg clk, reset, we;
    reg [2:0] write_addr, read_addr_a, read_addr_b;
    reg [7:0] write_data;
    wire [7:0] read_data_a, read_data_b;

    reg [7:0] expected [0:7];
    integer i, errors, checks;

    register_file_top dut (
        .clk(clk),
        .reset(reset),
        .we(we),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .read_data_a(read_data_a),
        .read_data_b(read_data_b)
    );

    // 10 ns clock period.
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Check both asynchronous read ports against the reference model.
    // This task intentionally samples after combinational logic settles.
    task check_reads;
        input [8*64-1:0] test_name;
        begin
            #1;
            checks = checks + 2;

            if (read_data_a !== expected[read_addr_a]) begin
                $display("[FAIL][TOP] %0s | Port A addr=%0d expected=0x%02h actual=0x%02h",
                         test_name, read_addr_a,
                         expected[read_addr_a], read_data_a);
                errors = errors + 1;
            end
            else begin
                $display("[PASS][TOP] %0s | Port A addr=%0d data=0x%02h",
                         test_name, read_addr_a, read_data_a);
            end

            if (read_data_b !== expected[read_addr_b]) begin
                $display("[FAIL][TOP] %0s | Port B addr=%0d expected=0x%02h actual=0x%02h",
                         test_name, read_addr_b,
                         expected[read_addr_b], read_data_b);
                errors = errors + 1;
            end
            else begin
                $display("[PASS][TOP] %0s | Port B addr=%0d data=0x%02h",
                         test_name, read_addr_b, read_data_b);
            end
        end
    endtask

    // Scan all registers using different addresses on the two read ports.
    task check_all_registers;
        integer j;
        begin
            for (j = 0; j < 8; j = j + 1) begin
                read_addr_a = j;
                read_addr_b = 7 - j;
                check_reads("full-bank scan / retention check");
            end
        end
    endtask

    // Drive write controls on a falling edge; sample after the next rising
    // edge. Update the model only after the DUT has captured the write.
    task write_reg;
        input [2:0] addr;
        input [7:0] data;
        begin
            @(negedge clk);
            reset      = 1'b0;
            we         = 1'b1;
            write_addr = addr;
            write_data = data;

            @(posedge clk);
            #1;
            expected[addr] = data;
            we = 1'b0;

            $display("[INFO][TOP] WRITE addr=%0d data=0x%02h",
                     addr, data);
            check_all_registers;
        end
    endtask

    initial begin
        errors = 0;
        checks = 0;

        reset = 1'b1;
        we = 1'b0;
        write_addr = 3'd0;
        write_data = 8'h00;
        read_addr_a = 3'd0;
        read_addr_b = 3'd1;

        for (i = 0; i < 8; i = i + 1)
            expected[i] = 8'h00;

        $display("");
        $display("==============================================================");
        $display(" DAY 24 REGISTER FILE - SELF-CHECKING TOP-LEVEL REGRESSION");
        $display(" Spec: 8 x 8 | 1 synchronous write | 2 asynchronous read ports");
        $display(" Reset: active-high synchronous | reset priority over write");
        $display("==============================================================");

        // T01: Assert reset across a rising edge and verify all registers.
        $display("");
        $display("[TEST T01] Synchronous reset");
        @(posedge clk);
        #1;
        for (i = 0; i < 8; i = i + 1)
            expected[i] = 8'h00;
        check_all_registers;
        @(negedge clk);
        reset = 1'b0;
        $display("[TEST T01] Completed");

        // T02/T03: Normal writes and register isolation.
        $display("");
        $display("[TEST T02] Write address 2 with A5");
        write_reg(3'd2, 8'hA5);

        $display("");
        $display("[TEST T03] Write address 5 with 3C");
        write_reg(3'd5, 8'h3C);

        // T04: A disabled write must not alter the selected register.
        $display("");
        $display("[TEST T04] Write disabled: data must not change");
        @(negedge clk);
        reset = 1'b0;
        we = 1'b0;
        write_addr = 3'd2;
        write_data = 8'hFF;
        @(posedge clk);
        #1;
        check_all_registers;
        $display("[TEST T04] Completed");

        // T05: Change read addresses between active clock edges.
        $display("");
        $display("[TEST T05] Asynchronous dual read");
        @(negedge clk);
        read_addr_a = 3'd2;
        read_addr_b = 3'd5;
        check_reads("read address changed without a rising edge");
        $display("[TEST T05] Completed");

        // T06: Exercise every write address, including address zero.
        $display("");
        $display("[TEST T06] Address coverage: 0 through 7");
        for (i = 0; i < 8; i = i + 1)
            write_reg(i[2:0], 8'h10 + i);
        $display("[TEST T06] Completed");

        // T07: Exercise boundary and mixed data patterns.
        $display("");
        $display("[TEST T07] Data-pattern coverage");
        write_reg(3'd1, 8'h00);
        write_reg(3'd2, 8'hFF);
        write_reg(3'd3, 8'hA5);
        write_reg(3'd4, 8'h3C);
        $display("[TEST T07] Completed");

        // T08: Reset must clear every register even when we is high.
        $display("");
        $display("[TEST T08] Reset priority when we=1");
        @(negedge clk);
        reset = 1'b1;
        we = 1'b1;
        write_addr = 3'd3;
        write_data = 8'h77;

        @(posedge clk);
        #1;
        for (i = 0; i < 8; i = i + 1)
            expected[i] = 8'h00;
        we = 1'b0;
        check_all_registers;

        @(negedge clk);
        reset = 1'b0;
        $display("[TEST T08] Completed");

        // T09: Verify register zero can be written and both read ports
        // can select the same address at the same time.
        $display("");
        $display("[TEST T09] Register 0 and same-address dual read");
        write_reg(3'd0, 8'hC3);

        @(negedge clk);
        read_addr_a = 3'd0;
        read_addr_b = 3'd0;
        check_reads("same address on both read ports");

        // Final summary: PASS only if no mismatch was found.
        $display("");
        $display("==============================================================");
        $display(" DAY 24 REGRESSION SUMMARY");
        $display(" Checks performed : %0d", checks);
        $display(" Errors detected  : %0d", errors);

        if (errors == 0)
            $display(" FINAL STATUS      : PASS - ALL CHECKS PASSED");
        else
            $display(" FINAL STATUS      : FAIL - REVIEW FAIL MESSAGES");

        $display("==============================================================");
        #1;
        $finish;
    end

endmodule
