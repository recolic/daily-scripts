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

RL_UNUSED static void log_to_file(const char *message) {
#if defined(_WIN32) && defined(NTDDI_VERSION)
    // Windows kernel-mode
    size_t messageLen = strlen(message);
    size_t maxConvertLength = RL_LOG_BUFFER_SIZE - 1; // Leave space for null terminator

    if (messageLen > maxConvertLength) {
        messageLen = maxConvertLength; // Truncate if message is too long
    }

    // Manually convert char* to WCHAR* by iterating through the string
    for (size_t i = 0; i < messageLen; ++i) {
        wideBuffer[i] = (WCHAR)message[i]; // Cast each char to WCHAR
    }
    wideBuffer[messageLen] = L'\0'; // Null-terminate the wide string

    // Log the wide string
    TraceDtlsMiscTraceOnPort(NULL, wideBuffer);
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

