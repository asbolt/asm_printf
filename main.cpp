#include <cstdio>

extern "C" int miu(const char *a, ...);

int main () {
    char u = 'k';
    miu("uuu%s", "aaa");

    return 0;
}