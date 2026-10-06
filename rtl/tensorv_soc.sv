`timescale 1ns/1ps
module tensorv_soc (
    input wire clk, resetn, enable_dot4,
    output wire trap,
    output wire mem_valid, mem_instr,
    input wire mem_ready,
    output wire [31:0] mem_addr, mem_wdata,
    output wire [3:0] mem_wstrb,
    input wire [31:0] mem_rdata,
    output wire dot4_retired
);
    wire valid, wr, wait_req, ready;
    wire [31:0] insn, rs1, rs2, rd;
    picorv32 #(
        .ENABLE_PCPI(1), .ENABLE_MUL(0), .ENABLE_DIV(0),
        .COMPRESSED_ISA(0), .ENABLE_IRQ(0),
        .PROGADDR_RESET(32'h0), .STACKADDR(32'h00010000)
    ) cpu (
        .clk(clk), .resetn(resetn), .trap(trap),
        .mem_valid(mem_valid), .mem_instr(mem_instr), .mem_ready(mem_ready),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata), .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .pcpi_valid(valid), .pcpi_insn(insn), .pcpi_rs1(rs1), .pcpi_rs2(rs2),
        .pcpi_wr(wr), .pcpi_rd(rd), .pcpi_wait(wait_req), .pcpi_ready(ready),
        .irq(32'b0), .eoi(), .trace_valid(), .trace_data(),
        .mem_la_read(), .mem_la_write(), .mem_la_addr(),
        .mem_la_wdata(), .mem_la_wstrb()
    );
    tensorv_dot4 dot4 (
        .clk(clk), .resetn(resetn), .pcpi_valid(valid && enable_dot4),
        .pcpi_insn(insn), .pcpi_rs1(rs1), .pcpi_rs2(rs2),
        .pcpi_wr(wr), .pcpi_rd(rd), .pcpi_wait(wait_req), .pcpi_ready(ready)
    );
    assign dot4_retired = valid && ready && wr;
endmodule
