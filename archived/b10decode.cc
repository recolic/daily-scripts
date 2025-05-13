// https://stackoverflow.com/questions/73224907/what-information-does-fido2-url-contain-and-how-can-we-decode-it-in-swift
// Translated to cpp by GPT.

#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <stdexcept>
#include <iterator>
#include <algorithm>
#include <cstdint>

// Helper function to convert a number to a little-endian byte array
std::vector<uint8_t> to_le_bytes(uint64_t value, size_t byte_count) {
    std::vector<uint8_t> bytes(byte_count);
    for (size_t i = 0; i < byte_count; ++i) {
        bytes[i] = value & 0xFF;
        value >>= 8;
    }
    return bytes;
}

// Main decoding function
std::vector<uint8_t> decode_base10_encoded(const std::string& input) {
    std::vector<uint8_t> result;
    
    // Process input in chunks of 17 digits
    for (size_t i = 0; i < input.size(); i += 17) {
        // Get the chunk of up to 17 characters
        std::string chunk = input.substr(i, std::min(static_cast<size_t>(17), input.size() - i));

        // Determine the number of bytes we expect based on the chunk size
        size_t n;
        switch (chunk.size()) {
            case 3:  n = 1; break;
            case 5:  n = 2; break;
            case 8:  n = 3; break;
            case 10: n = 4; break;
            case 13: n = 5; break;
            case 15: n = 6; break;
            case 17: n = 7; break;
            default: throw std::runtime_error("Invalid chunk size");
        }

        // Convert the chunk into a 64-bit integer
        uint64_t number = std::stoull(chunk);

        // Convert the number to little-endian bytes and take the required number of bytes
        std::vector<uint8_t> bytes = to_le_bytes(number, n);
        result.insert(result.end(), bytes.begin(), bytes.end());
    }
    
    return result;
}

int main() {
    std::string input = "13086400838107303667332719012595115747821895775708323189557153075146383351399743589971313508078026948312026786722471666005727649643501784024544726574771401798171307406596245"; // Example input
    std::vector<uint8_t> decoded = decode_base10_encoded(input);

    // Print the result
    std::cout << "Decoded bytes: ";
    for (uint8_t byte : decoded) {
        std::cout << std::hex << static_cast<int>(byte) << " ";
    }
    std::cout << std::endl;

    return 0;
}

