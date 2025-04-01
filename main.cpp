#include <cstdio>

extern "C" void My_printf(const char *a, ...);

int main () {
    My_printf("%d %b %o %c %s %u %x\n", -11, 5, 52, 'k', "hui", 56, 0xa);
    printf ("hello\n");
    return 0;
}