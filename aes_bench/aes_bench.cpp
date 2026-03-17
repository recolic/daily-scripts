/*
 * AES-256-CBC 256B decrypt benchmark. Single core.
 * Build: g++ -O2 -Wall -o aes_bench aes_bench.cpp -lssl -lcrypto
 */
#include "aes256_easy.hpp"
#include <chrono>
#include <cstdio>

static const size_t BLOCK = 256;
static const unsigned char KEY[32] = {};
static const unsigned char IV[16] = {};

int main() {
    std::string plain(BLOCK, 0x41);
    std::string cipher = aes256_cbc_enc(KEY, IV, plain.data(), plain.size());

    const unsigned N = 500000;
    auto t0 = std::chrono::steady_clock::now();
    for (unsigned i = 0; i < N; i++)
        (void)aes256_cbc_dec(KEY, IV, cipher.data(), cipher.size());
    auto t1 = std::chrono::steady_clock::now();

    double sec = std::chrono::duration<double>(t1 - t0).count();
    double ms_per_op = (sec * 1000.0) / N;
    double bytes_per_sec = (N * BLOCK) / sec;

    printf("256B decrypt (single core, %u iters)\n", N);
    printf("  Latency:   %.4f ms per op\n", ms_per_op);
    printf("  Bandwidth: %.0f bytes/s (%.2f MB/s)\n", bytes_per_sec, bytes_per_sec / (1024 * 1024));
    return 0;
}
