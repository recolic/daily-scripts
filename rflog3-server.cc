#include <windows.h>
#include <stdio.h>

#define PIPE_NAME "\\\\.\\pipe\\KernelLogPipe"

void ListenToKernelLogs() {
    HANDLE hPipe;
    char buffer[256];
    DWORD bytesRead;

    hPipe = CreateNamedPipeA(
        PIPE_NAME,
        PIPE_ACCESS_INBOUND,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
        1, 256, 256, 0, NULL
    );

    if (hPipe == INVALID_HANDLE_VALUE) {
        printf("Failed to create named pipe. Error: %d\n", GetLastError());
        return;
    }

    printf("Waiting for kernel connection...\n");
    ConnectNamedPipe(hPipe, NULL);

    while (ReadFile(hPipe, buffer, sizeof(buffer) - 1, &bytesRead, NULL)) {
        buffer[bytesRead] = '\0';
        printf("Kernel Log: %s\n", buffer);
    }

    CloseHandle(hPipe);
}

int main() {
    ListenToKernelLogs();
    return 0;
}
