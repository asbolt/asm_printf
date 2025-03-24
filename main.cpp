#include <cstdio>

extern "C" void My_printf(const char *a, ...);

int main () {
    My_printf("%d %d %d\n", 1, 2, 3);
    printf ("hello\n");
    return 0;
}