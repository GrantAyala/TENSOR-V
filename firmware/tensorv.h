#ifndef TENSORV_H
#define TENSORV_H
#include <stdint.h>
static inline int32_t tensorv_dot4(uint32_t a, uint32_t b) {
    int32_t result;
    __asm__ volatile (".insn r 0x0b, 0, 0, %0, %1, %2"
                      : "=r"(result) : "r"(a), "r"(b));
    return result;
}
static inline uint32_t cycles(void) {
    uint32_t n;
    __asm__ volatile ("rdcycle %0" : "=r"(n) :: "memory");
    return n;
}
static inline uint32_t instructions(void) {
    uint32_t n;
    __asm__ volatile ("rdinstret %0" : "=r"(n) :: "memory");
    return n;
}
static inline void report(unsigned index, uint32_t value) {
    ((volatile uint32_t *)0x10000010)[index] = value;
}
#endif
