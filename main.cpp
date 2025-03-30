#include <cstdio>

extern "C" void My_printf(const char *a, ...);

int main () {
    My_printf("%c %c %c %c %c %c %c\n", '1', '2', '3', '4', '5', '6', '9');
    printf ("hello\n");
    return 0;
}