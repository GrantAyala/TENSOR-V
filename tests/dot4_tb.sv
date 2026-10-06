`timescale 1ns/1ps
module dot4_tb;
    reg clk = 0;
    always #5 clk = !clk;
    reg resetn = 0, valid = 0;
    reg [31:0] insn = 0, a = 0, b = 0;
    wire wr, wait_req, ready;
    wire [31:0] rd;
    integer fd, rc, count = 0, bit_index;
    reg [31:0] expected;
    tensorv_dot4 dut(clk, resetn, valid, insn, a, b, wr, rd, wait_req, ready);

    task reject(input [31:0] bad_insn);
        begin
            @(negedge clk); valid = 1; insn = bad_insn;
            repeat (3) begin
                @(posedge clk); #1;
                if (ready || wr || wait_req) $fatal(1, "Accepted invalid encoding %h", insn);
            end
            @(negedge clk); valid = 0;
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        if (ready || wr || wait_req) $fatal(1, "Outputs asserted in reset");
        resetn = 1;
        // All fixed encoding bits independently flipped.
        for (bit_index = 0; bit_index < 32; bit_index = bit_index + 1)
            if (bit_index < 7 || (bit_index >= 12 && bit_index <= 14) || bit_index >= 25)
                reject(32'h0000000b ^ (32'b1 << bit_index));
        fd = $fopen("build/vectors.txt", "r");
        if (!fd) $fatal(1, "Missing golden vectors");
        while (!$feof(fd)) begin
            @(negedge clk);
            rc = $fscanf(fd, "%h %h %h\n", a, b, expected);
            if (rc == 3) begin
                // Exercise all register index fields without changing decode.
                insn = 32'h0000000b | ((count & 31) << 7) |
                       (((count >> 5) & 31) << 15) | (((count >> 10) & 31) << 20);
                valid = 1; #1;
                if (!wait_req || ready || wr) $fatal(1, "Missing PCPI wait");
                @(posedge clk); #1;
                if (!ready || !wr || wait_req || rd !== expected)
                    $fatal(1, "Vector %0d: %h * %h got %h expected %h", count, a, b, rd, expected);
                // Hold valid until the core consumes ready on the following edge.
                @(posedge clk); #1;
                if (ready || wr) $fatal(1, "Ready must clear after consumption");
                @(negedge clk); valid = 0;
                count = count + 1;
            end else if (rc != -1) $fatal(1, "Malformed vector");
        end
        $fclose(fd);
        // Reset cancels a result before it can be consumed.
        @(negedge clk); valid = 1; insn = 32'h0b;
        @(posedge clk); #1;
        if (!ready) $fatal(1, "No result before reset");
        @(negedge clk); resetn = 0;
        @(posedge clk); #1;
        if (ready || wr || wait_req) $fatal(1, "Reset failed to cancel transaction");
        @(negedge clk); valid = 0; resetn = 1;
        @(posedge clk); #1;
        if (ready || wr || wait_req) $fatal(1, "Stale transaction after reset");
        if (count != 272193) $fatal(1, "Incorrect vector count %0d", count);
        $display("PASS: %0d vectors, encoding rejection, handshake, reset", count);
        $finish;
    end
    initial begin #20000000; $fatal(1, "Unit test timeout"); end
endmodule
