#include <stdio.h>

int main(void) {
    char first[8];
    char second[20];

    printf("first: %p\n", (void *)first);
    printf("second: %p\n", (void *)second);

    return 0;
}
