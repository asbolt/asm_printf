#include <cstdio>

extern "C" int miu(const char *a, ...);

int main () {
    miu("моя мама моет тарелки %x в \n день, а мой папа %b капец hhh\n", 17, 52);

    return 0;
}