// GPT-4o generated.
// v2502.3
#ifndef RFLOG_H
#define RFLOG_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdarg.h>

#define RL_WIN_KERNEL 101
#define RL_WIN_USER   102
#define RL_LINUX_USER 103
#if defined(_WIN32) && defined(NTDDI_VERSION)
#define RL_MODE RL_WIN_KERNEL
#elif defined(_WIN32)
#define RL_MODE RL_WIN_USER
#else
#define RL_MODE RL_LINUX_USER
#endif

#if RL_MODE == RL_WIN_KERNEL
#include <ntddk.h>
#include <ntstrsafe.h>  // RtlStringCbPrintfA
#define RL_SNPRINTF_FUNC RtlStringCbPrintfA
#define RL_LOG_FILE_PATH "__SysInternal_DebugView_Tool__"
#elif RL_MODE == RL_WIN_USER
#include <windows.h>
#define RL_SNPRINTF_FUNC snprintf
#define RL_LOG_FILE_PATH "C:\\rflog.txt"
#elif RL_MODE == RL_LINUX_USER
#include <sys/time.h>
#define RL_SNPRINTF_FUNC snprintf
#define RL_LOG_FILE_PATH "/tmp/rflog.txt"
#endif

#ifdef __GNUC__
#define RL_THREAD_LOC __thread
#define RL_UNUSED __attribute__ ((unused))
#elif RL_MODE == RL_WIN_KERNEL
#define RL_THREAD_LOC // TLS not supported. Avoid get_current_datatime() because it's not thread-safe.
#define RL_UNUSED
#else
#define RL_THREAD_LOC __declspec( thread )
#define RL_UNUSED
#endif

// Define static buffers
#define RL_DATETIME_BUFFER_SIZE 64
#define RL_LOG_BUFFER_SIZE 512

RL_UNUSED static const char *get_current_datetime() {
    static RL_THREAD_LOC char datetime_buffer[RL_DATETIME_BUFFER_SIZE];

#if RL_MODE == RL_WIN_KERNEL
    // Tested, but not in use
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
#elif RL_MODE == RL_WIN_USER
        SYSTEMTIME st;
        GetLocalTime(&st);
        snprintf(datetime_buffer, RL_DATETIME_BUFFER_SIZE, "%04d-%02d-%02d %02d:%02d:%02d.%03d",
                 st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
#elif RL_MODE == RL_LINUX_USER
        struct timeval tv;
        struct tm *tm_info;
        gettimeofday(&tv, NULL);
        tm_info = localtime(&tv.tv_sec);
        snprintf(datetime_buffer, RL_DATETIME_BUFFER_SIZE, "%04d-%02d-%02d %02d:%02d:%02d.%03ld",
                 tm_info->tm_year + 1900, tm_info->tm_mon + 1, tm_info->tm_mday,
                 tm_info->tm_hour, tm_info->tm_min, tm_info->tm_sec, tv.tv_usec / 1000);
#endif
    return datetime_buffer;
}

RL_UNUSED static void log_to_file(const char *message) {
#if RL_MODE == RL_WIN_KERNEL
    // DebugView already has timestamp, but newline is still necessary.
    DbgPrint("%s\n", message);
    // DbgPrintEx(DPFLTR_DEFAULT_ID, DPFLTR_ERROR_LEVEL, "%s\n", message);
#else
    FILE *file = fopen(RL_LOG_FILE_PATH, "a");
    if (file) {
        fprintf(file, "[%s] %s\n", get_current_datetime(), message);
        fclose(file);
    } else {
        fprintf(stderr, "Failed to open log file: %s\n", RL_LOG_FILE_PATH);
    }
#endif
}

RL_UNUSED static void rflogv(const char *fmt, ...) {
    static RL_THREAD_LOC char log_buffer[RL_LOG_BUFFER_SIZE];

    va_list args;
    va_start(args, fmt);

    RL_SNPRINTF_FUNC(log_buffer, RL_LOG_BUFFER_SIZE, fmt, args);
    log_to_file(log_buffer);

    va_end(args);
}

#endif // RFLOG_H