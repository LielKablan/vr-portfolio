#include <stdio.h>
#include <string.h>

int main() {
    char input[64];
    // "secret" XORed with 0x55:
    // 's'^0x55=0x26, 'e'^0x55=0x30, 'c'^0x55=0x36, 'r'^0x55=0x27, 'e'^0x55=0x30, 't'^0x55=0x21
    unsigned char encrypted[] = {0x26, 0x30, 0x36, 0x27, 0x30, 0x21, 0x00};
    
    printf("Enter Password: ");
    if (scanf("%63s", input) != 1) {
        return 1;
    }

    int match = 1;
    int len = strlen(input);

    if (len != 6) {
        match = 0;
    } else {
        for (int i = 0; i < len; i++) {
            if ((input[i] ^ 0x55) != encrypted[i]) {
                match = 0;
                break;
            }
        }
    }

    if (match) {
        puts("Correct! Flag: entrypoint{xor_loop_master}");
    } else {
        puts("Wrong password.");
    }

    return 0;
} 
