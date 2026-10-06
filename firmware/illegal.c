int main(void) {
    // Wrong funct3: must trap, never silently execute DOT4.
    __asm__ volatile (".insn r 0x0b, 1, 0, x0, x0, x0");
    return 1;
}
