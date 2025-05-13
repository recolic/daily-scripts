#include <iostream>
#include <iomanip>
#include <sstream>
#include <cstring>

void importMemoryDump(const char* memoryDump, char* binaryBuffer, size_t bufferSize) {
    std::istringstream iss(memoryDump);
    std::string line;

    size_t bytesCopied = 0;

    while (std::getline(iss, line)) {
        std::istringstream lineStream(line);
        std::string addressPart;
        lineStream >> addressPart; // Ignore the address part

        std::string hexByte;
        while (lineStream >> hexByte) {
            if (bytesCopied >= bufferSize) {
                std::cerr << "Buffer size is too small for the memory dump." << std::endl;
                return;
            }

            std::stringstream ss;
            ss << std::hex << hexByte;
            unsigned int byteValue;
            ss >> byteValue;
            binaryBuffer[bytesCopied++] = static_cast<char>(byteValue);
        }
    }
}

int main() {
    const char* memoryDump = "ffffc301`62efb000 44 07 00 00 30 82 07 40-30 82 06 28 a0 03 02 01 D...0..@0..(....";
    char binaryBuffer[100];
    importMemoryDump(memoryDump, binaryBuffer, sizeof(binaryBuffer));

    // Now binaryBuffer contains the imported data
    // You can use it as needed, for example:
    for (size_t i = 0; i < strlen(memoryDump) / 3; ++i) {
        std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)(unsigned char)binaryBuffer[i] << " ";
    }
    std::cout << std::endl;

    return 0;
}
