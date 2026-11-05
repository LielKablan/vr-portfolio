#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void gadget(void) {
    __asm__("pop %rdi; ret");
}

void win(int code) {
    if (code == 0x1337) {
        puts("[+] Access granted. Code matches 0x1337!");
        system("/bin/sh");
    } else {
        printf("[-] Wrong code: 0x%x\n", code);
    }
}

void vulnerable(void) {
    char buffer[128];
    puts("Enter data:");
    read(0, buffer, 256);
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    vulnerable();
    return 0;
}
