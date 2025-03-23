#include <cstdio>

extern "C" int My_printf(const char *a, ...);

int main () {
    My_printf("123456789%d", 70);

    return 0;
}