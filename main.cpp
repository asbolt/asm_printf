#include <cstdio>

extern "C" void My_printf(const char *a, ...);

int main () {
    My_printf("%d %d %d %d %c %c %c %c\n", 1, 2, 3, 4, 'a', 'b', 'c', 'e');
    printf ("hello\n");
    return 0;
}