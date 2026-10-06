`timescale 1ns/1ps
// Four signed INT8 products, summed exactly and sign extended to XLEN.
module tensorv_dot4 (
    input wire clk,
    input wire resetn,
    input wire pcpi_valid,
    input wire [31:0] pcpi_insn,
    input wire [31:0] pcpi_rs1,
    input wire [31:0] pcpi_rs2,
    output wire pcpi_wr,
    output reg [31:0] pcpi_rd,
    output wire pcpi_wait,
    output reg pcpi_ready
);
    wire selected = pcpi_valid && pcpi_insn[6:0] == 7'h0b &&
                    pcpi_insn[14:12] == 3'b000 && pcpi_insn[31:25] == 7'b0;
    wire signed [15:0] p0 = $signed(pcpi_rs1[7:0]) * $signed(pcpi_rs2[7:0]);
    wire signed [15:0] p1 = $signed(pcpi_rs1[15:8]) * $signed(pcpi_rs2[15:8]);
    wire signed [15:0] p2 = $signed(pcpi_rs1[23:16]) * $signed(pcpi_rs2[23:16]);
    wire signed [15:0] p3 = $signed(pcpi_rs1[31:24]) * $signed(pcpi_rs2[31:24]);
    wire signed [17:0] sum = {{2{p0[15]}}, p0} + {{2{p1[15]}}, p1} +
                             {{2{p2[15]}}, p2} + {{2{p3[15]}}, p3};
    assign pcpi_wait = resetn && selected && !pcpi_ready;
    assign pcpi_wr = resetn && selected && pcpi_ready;
    always @(posedge clk) begin
        if (!resetn) begin
            pcpi_ready <= 0;
            pcpi_rd <= 0;
        end else begin
            pcpi_ready <= selected && !pcpi_ready;
            if (selected && !pcpi_ready)
                pcpi_rd <= {{14{sum[17]}}, sum};
        end
    end
endmodule
