#include "tensorv.h"
static volatile uint32_t values[4] = {3, 5, 8, 13};
int main(void) {
    uint32_t sum = 0;
    for (unsigned i = 0; i < 4; ++i) sum += values[i];
    report(0, sum);
    return sum != 29;
}
