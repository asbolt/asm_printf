#include <cstdio>

extern "C" void My_printf(const char *a, ...);

int main () {
    My_printf("%b\n", -10);
    printf ("hello\n");
    return 0;
}