#include <cstdio>

extern "C" void My_printf(const char *a, ...);

int main () {
    My_printf("%d aaaaaaaaa %b %x %s %c\n", -11, 5, 0xa, "hui", 'a');
    printf ("hello\n");
    return 0;
}