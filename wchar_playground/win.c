#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

PCWSTR binary_to_hex(const unsigned char* buffer, size_t size) {
    wchar_t* hex_string = (wchar_t*)malloc((size * 2 + 1) * sizeof(wchar_t)); // Each byte in binary becomes 2 hex characters + null terminator
    if (hex_string == NULL) {
        fprintf(stderr, "Memory allocation failed.\n");
        return NULL;
    }

    for (size_t i = 0; i < size; i++) {
        swprintf(hex_string + i * 2, 3, L"%02X", buffer[i]); // Convert each byte to its hex representation
    }
    hex_string[size * 2] = L'\0'; // Null-terminate the string
    return hex_string;
}

int main() {
    unsigned char buffer[] = {0x01, 0xAB, 0xFF, 0x42};
    size_t buffer_size = sizeof(buffer) / sizeof(buffer[0]);

    PCWSTR hex_string = binary_to_hex(buffer, buffer_size);
    if (hex_string != NULL) {
        wprintf(L"Hex representation: %ls\n", hex_string);
        free((wchar_t*)hex_string); // Don't forget to free the allocated memory
    }

    return 0;
}
