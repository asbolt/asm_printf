#include <cstdio>

extern "C" int My_printf(const char *a, ...);

int main () {
    My_printf("\n", 123456);

    return 0;
}