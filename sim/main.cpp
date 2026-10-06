#include "Vtensorv_soc.h"
#include "verilated.h"
#include <cstdint>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
#include <vector>

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    if (argc < 2) { std::cerr << "usage: sim firmware.bin [--no-dot4] [--expect-trap] [--stalls]\n"; return 2; }
    bool enabled = true, expect_trap = false, stalls = false;
    for (int i = 2; i < argc; ++i) {
        std::string arg(argv[i]);
        if (arg == "--no-dot4") enabled = false;
        else if (arg == "--expect-trap") expect_trap = true;
        else if (arg == "--stalls") stalls = true;
        else { std::cerr << "unknown option\n"; return 2; }
    }
    std::ifstream file(argv[1], std::ios::binary);
    if (!file) { std::cerr << "cannot open firmware\n"; return 2; }
    std::vector<uint8_t> ram((std::istreambuf_iterator<char>(file)), {});
    if (ram.empty() || ram.size() > 65536) { std::cerr << "bad firmware size\n"; return 2; }
    ram.resize(65536, 0);
    Vtensorv_soc top;
    top.enable_dot4 = enabled;
    top.resetn = 0; top.mem_ready = 0; top.mem_rdata = 0;
    for (unsigned n = 0; n < 8; ++n) {
        top.clk = 0; top.eval(); top.clk = 1; top.eval();
    }
    top.resetn = 1;
    uint64_t dot4_count = 0;
    for (uint64_t cycle = 0; cycle < 20000000; ++cycle) {
        top.clk = 0; top.mem_ready = 0; top.mem_rdata = 0; top.eval();
        bool done = false; uint32_t exit_code = 0;
        if (top.mem_valid && (!stalls || cycle % 4 == 0)) {
            uint32_t addr = top.mem_addr;
            if (addr < ram.size()) {
                uint32_t base = addr & ~3u;
                uint32_t word = 0;
                for (unsigned b = 0; b < 4; ++b) word |= uint32_t(ram[base+b]) << (8*b);
                top.mem_rdata = word;
                for (unsigned b = 0; b < 4; ++b)
                    if (top.mem_wstrb & (1u << b)) ram[base+b] = top.mem_wdata >> (8*b);
            } else if (addr == 0x10000004 && top.mem_wstrb == 15) {
                done = true; exit_code = top.mem_wdata;
            } else if (addr >= 0x10000010 && addr < 0x10000030 &&
                       (addr & 3) == 0 && top.mem_wstrb == 15) {
                std::cout << "metric[" << (addr-0x10000010)/4 << "]=" << top.mem_wdata << "\n";
            } else { std::cerr << "invalid memory access at " << std::hex << addr << "\n"; return 1; }
            top.mem_ready = 1;
        }
        top.eval();
        if (top.dot4_retired) ++dot4_count;
        top.clk = 1; top.eval();
        if (done) {
            std::cout << "exit=" << exit_code << " cycles=" << cycle+1 << " dot4=" << dot4_count << "\n";
            return exit_code == 0 && !expect_trap ? 0 : 1;
        }
        if (top.trap) {
            std::cout << "trap cycles=" << cycle+1 << " dot4=" << dot4_count << "\n";
            return expect_trap ? 0 : 1;
        }
    }
    std::cerr << "simulation timeout\n";
    return 1;
}
