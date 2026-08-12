/*
 * One-shot AES-256-CBC. OpenSSL 1.1.1 / 3.x.
 * Build (any .cpp that includes this): g++ -O2 -Wall -o out out.cpp -lssl -lcrypto
 */
#ifndef AES256_EASY_HPP
#define AES256_EASY_HPP

#include <openssl/evp.h>
#include <string>
#include <stdexcept>

inline std::string aes256_cbc_enc(const unsigned char* key, const unsigned char* iv,
                                  const void* plain, size_t plain_len) {
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) throw std::runtime_error("EVP_CIPHER_CTX_new");
    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, key, iv) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        throw std::runtime_error("EVP_EncryptInit_ex");
    }
    std::string out;
    out.resize(plain_len + 16);
    int n = 0, m = 0;
    if (EVP_EncryptUpdate(ctx, (unsigned char*)&out[0], &n, (const unsigned char*)plain, (int)plain_len) != 1 ||
        EVP_EncryptFinal_ex(ctx, (unsigned char*)&out[0] + n, &m) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        throw std::runtime_error("EVP_Encrypt");
    }
    EVP_CIPHER_CTX_free(ctx);
    out.resize(n + m);
    return out;
}

inline std::string aes256_cbc_dec(const unsigned char* key, const unsigned char* iv,
                                  const void* cipher, size_t cipher_len) {
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
    if (!ctx) throw std::runtime_error("EVP_CIPHER_CTX_new");
    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), nullptr, key, iv) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        throw std::runtime_error("EVP_DecryptInit_ex");
    }
    std::string out;
    out.resize(cipher_len);
    int n = 0, m = 0;
    if (EVP_DecryptUpdate(ctx, (unsigned char*)&out[0], &n, (const unsigned char*)cipher, (int)cipher_len) != 1 ||
        EVP_DecryptFinal_ex(ctx, (unsigned char*)&out[0] + n, &m) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        throw std::runtime_error("EVP_Decrypt");
    }
    EVP_CIPHER_CTX_free(ctx);
    out.resize(n + m);
    return out;
}

inline std::string aes256_cbc_enc(const std::string& key, const std::string& iv, const std::string& plain) {
    unsigned char k[32] = {}, v[16] = {};
    for (size_t i = 0; i < key.size() && i < 32; i++) k[i] = (unsigned char)key[i];
    for (size_t i = 0; i < iv.size() && i < 16; i++) v[i] = (unsigned char)iv[i];
    return aes256_cbc_enc(k, v, plain.data(), plain.size());
}

inline std::string aes256_cbc_dec(const std::string& key, const std::string& iv, const std::string& cipher) {
    unsigned char k[32] = {}, v[16] = {};
    for (size_t i = 0; i < key.size() && i < 32; i++) k[i] = (unsigned char)key[i];
    for (size_t i = 0; i < iv.size() && i < 16; i++) v[i] = (unsigned char)iv[i];
    return aes256_cbc_dec(k, v, cipher.data(), cipher.size());
}

#endif
