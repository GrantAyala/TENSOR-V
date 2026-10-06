#include "tensorv.h"
#define COUNT 256
static volatile uint32_t lhs[COUNT], rhs[COUNT];
static uint32_t random_word(uint32_t *s) {
    *s ^= *s << 13; *s ^= *s >> 17; *s ^= *s << 5;
    return *s;
}
__attribute__((noinline)) static int32_t scalar_dot4(uint32_t a, uint32_t b) {
    int32_t sum = 0;
    for (unsigned i = 0; i < 4; ++i) {
        int32_t x = (int32_t)((a >> (8*i)) & 255);
        int32_t y = (int32_t)((b >> (8*i)) & 255);
        if (x >= 128) x -= 256;
        if (y >= 128) y -= 256;
        sum += x*y;
    }
    return sum;
}
int main(void) {
    uint32_t seed = 0x54454e53;
    for (unsigned i = 0; i < COUNT; ++i) {
        lhs[i] = random_word(&seed); rhs[i] = random_word(&seed);
    }
    lhs[0] = rhs[0] = 0x80808080;
    lhs[1] = 0x80808080; rhs[1] = 0x7f7f7f7f;
    for (unsigned i = 0; i < COUNT; ++i)
        if (scalar_dot4(lhs[i], rhs[i]) != tensorv_dot4(lhs[i], rhs[i])) return 1;
    uint32_t scalar_sum = 0, accel_sum = 0;
    uint32_t c0 = cycles(), i0 = instructions();
    for (unsigned i = 0; i < COUNT; ++i)
        scalar_sum += (uint32_t)scalar_dot4(lhs[i], rhs[i]);
    uint32_t i1 = instructions(), c1 = cycles();
    uint32_t c2 = cycles(), i2 = instructions();
    for (unsigned i = 0; i < COUNT; ++i)
        accel_sum += (uint32_t)tensorv_dot4(lhs[i], rhs[i]);
    uint32_t i3 = instructions(), c3 = cycles();
    report(0, c1-c0); report(1, c3-c2);
    report(2, i1-i0); report(3, i3-i2);
    report(4, scalar_sum); report(5, accel_sum); report(6, COUNT);
    return scalar_sum != accel_sum;
}
