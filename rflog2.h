// GPT-4o generated. NOT thread safe.
// v2502.1
#ifndef SIMPLE_LOGGER_H
#define SIMPLE_LOGGER_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(_WIN32) && defined(NTDDI_VERSION)
#include <ntddk.h>
#include <ntstrsafe.h>  // For RtlStringCbPrintfA
#include <wdf.h> // For TCP conn
#include <winsock2.h> // For TCP conn
#define RL_SNPRINTF_FUNC RtlStringCbPrintfA
#define RL_LOG_FILE_PATH "N/A"
#elif defined(_WIN32)
#include <windows.h>
#define RL_SNPRINTF_FUNC snprintf
#define RL_LOG_FILE_PATH "C:\\rflog.txt"
#else
#include <sys/time.h>
#define RL_SNPRINTF_FUNC snprintf
#define RL_LOG_FILE_PATH "/tmp/rflog.txt"
#endif

#ifdef __GNUC__
#define RL_THREAD_LOC __thread
#define RL_UNUSED __attribute__ ((unused))
#else
#define RL_THREAD_LOC /*__declspec( thread ) Not Supported*/
#define RL_UNUSED
#endif

// Define static buffers
#define RL_DATETIME_BUFFER_SIZE 64
#define RL_LOG_BUFFER_SIZE 512

// Static buffers for reduced memory allocation. NOT THREAD SAFE!!
static RL_THREAD_LOC char datetime_buffer[RL_DATETIME_BUFFER_SIZE];
static RL_THREAD_LOC char log_buffer[RL_LOG_BUFFER_SIZE];
#if defined(_WIN32) && defined(NTDDI_VERSION)
static RL_THREAD_LOC WCHAR wideBuffer[RL_LOG_BUFFER_SIZE];
#endif

RL_UNUSED static const char *get_current_datetime() {
#if defined(_WIN32) && defined(NTDDI_VERSION)
    // Windows kernel-mode implementation
    LARGE_INTEGER system_time, local_time;
    TIME_FIELDS time_fields;

    KeQuerySystemTime(&system_time);
    ExSystemTimeToLocalTime(&system_time, &local_time);
    RtlTimeToTimeFields(&local_time, &time_fields);

    // Format the datetime string
    RL_SNPRINTF_FUNC (datetime_buffer, RL_DATETIME_BUFFER_SIZE,
                       "%04d-%02d-%02d %02d:%02d:%02d.%03d",
                       time_fields.Year, time_fields.Month, time_fields.Day,
                       time_fields.Hour, time_fields.Minute, time_fields.Second, 0); // No millisecond precision in kernel
#else
    // User-mode implementation
    #ifdef _WIN32
        SYSTEMTIME st;
        GetLocalTime(&st);
        snprintf(datetime_buffer, RL_DATETIME_BUFFER_SIZE, "%04d-%02d-%02d %02d:%02d:%02d.%03d",
                 st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
    #else
        // Linux or other Unix-like systems
        struct timeval tv;
        struct tm *tm_info;
        gettimeofday(&tv, NULL);
        tm_info = localtime(&tv.tv_sec);
        snprintf(datetime_buffer, RL_DATETIME_BUFFER_SIZE, "%04d-%02d-%02d %02d:%02d:%02d.%03ld",
                 tm_info->tm_year + 1900, tm_info->tm_mon + 1, tm_info->tm_mday,
                 tm_info->tm_hour, tm_info->tm_min, tm_info->tm_sec, tv.tv_usec / 1000);
    #endif
#endif
    return datetime_buffer;
}

#if defined(_WIN32) && defined(NTDDI_VERSION)
static SOCKET TcpTryConnect(int _close) {
    static SOCKET sock = INVALID_SOCKET;
    if (_close == 1) { // We want to close(), not connect()
        closesocket(sock);
        return (sock = INVALID_SOCKET);
    }
    if (sock != INVALID_SOCKET)
        return sock;  // Already connected

    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0)
        return sock;

    sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock == INVALID_SOCKET) {
        WSACleanup();
        return sock;
    }

    struct sockaddr_in sa;
    sa.sin_family = AF_INET;
    sa.sin_port = htons(30410);
    sa.sin_addr.s_addr = inet_addr("127.0.0.1");

    if (connect(sock, (struct sockaddr*)&sa, sizeof(sa)) == SOCKET_ERROR) {
        closesocket(sock);
        sock = INVALID_SOCKET;
        WSACleanup();
    }
    return sock;
}
// Windows kernel-mode only
static size_t NaiveStrlen(const char *str) {
    if (!str) return 0;
    size_t len = 0;
    while (str[len]) len++;
    return len;
}
#endif

RL_UNUSED static void log_to_file(const char *message) {
#if defined(_WIN32) && defined(NTDDI_VERSION)
    // Windows kernel-mode: rfloga
    SOCKET conn = TcpTryConnect(0);
    if (conn == INVALID_SOCKET) {
        TraceDtlsMiscTraceOnPort(NULL, L"rfloga_send: conn fail");
        return;
    }

    uint64_t len = (uint64_t)NaiveStrlen(msg);
    if (send(conn, (char*)&len, sizeof(len), 0) == SOCKET_ERROR || send(conn, msg, (int)len, 0) == SOCKET_ERROR) {
        TraceDtlsMiscTraceOnPort(NULL, L"rfloga_send: send fail");
        TcpTryConnect(1);
    }
#else
    // User mode
    FILE *file = fopen(RL_LOG_FILE_PATH, "a");
    if (file) {
        fprintf(file, "%s\n", message);
        fclose(file);
    } else {
        fprintf(stderr, "Failed to open log file: %s\n", RL_LOG_FILE_PATH);
    }
#endif
}


RL_UNUSED static void rflogs(const char *message) {
    RL_SNPRINTF_FUNC(log_buffer, RL_LOG_BUFFER_SIZE, "[%s] %s", get_current_datetime(), message);
    log_to_file(log_buffer);
}
RL_UNUSED static void rflogsi(const char *message, int value) {
    RL_SNPRINTF_FUNC(log_buffer, RL_LOG_BUFFER_SIZE, "[%s] %s: %d", get_current_datetime(), message, value);
    log_to_file(log_buffer);
}
RL_UNUSED static void rflogsii(const char *message, int value, int i2) {
    RL_SNPRINTF_FUNC(log_buffer, RL_LOG_BUFFER_SIZE, "[%s] %s: %d, %d", get_current_datetime(), message, value, i2);
    log_to_file(log_buffer);
}
RL_UNUSED static void rflogsiip(const char *message, int value, int i2, void *ptr) {
    RL_SNPRINTF_FUNC(log_buffer, RL_LOG_BUFFER_SIZE, "[%s] %s: %d, %d, %p", get_current_datetime(), message, value, i2, ptr);
    log_to_file(log_buffer);
}
RL_UNUSED static void rflogss(const char *message1, const char *message2) {
    RL_SNPRINTF_FUNC(log_buffer, RL_LOG_BUFFER_SIZE, "[%s] %s: %s", get_current_datetime(), message1, message2);
    log_to_file(log_buffer);
}

#endif // SIMPLE_LOGGER_H

