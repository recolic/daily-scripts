#include <unistd.h>
#include <fcntl.h>
#include <cstring>
#include <cstdio>
#include <cerrno>

static inline unsigned char mask_for(size_t i) {
    return (unsigned char)((i * 73) ^ (i >> 1));
}

void process(int fdin, int fdout, bool seekable) {
    const size_t N = 1024;
    unsigned char buf[N];

    ssize_t n = read(fdin, buf, N);
    if (n < 0) return;

    for (ssize_t i = 0; i < n; i++)
        buf[i] ^= mask_for(i);

    if (seekable) lseek(fdout, 0, SEEK_SET);
    write(fdout, buf, n);
    if (seekable) return;

    ssize_t m;
    while ((m = read(fdin, buf, N)) > 0)
        write(fdout, buf, m);
}

int main(int argc, char** argv) {
    if (argc == 2) {
        int fd = open(argv[1], O_RDWR);
        if (fd < 0) {fprintf(stderr, "open file failed, %s\n", strerror(errno)); return 1; }
        process(fd, fd, true);
        close(fd);
        return 0;
    }
    process(STDIN_FILENO, STDOUT_FILENO, false);
    return 0;
}

