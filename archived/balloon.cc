#include <iostream>
#include <fstream>
#include <thread>
#include <chrono>

int main() {
    char* buf = nullptr;
    size_t curSize = 0;

    while (true) {
        std::ifstream fin("/tmp/b.txt");
        size_t newSize;
        if (fin >> newSize) {
            if (newSize != curSize) {
                delete[] buf;
                curSize = newSize;
                buf = new char[curSize];
                std::fill(buf, buf + curSize, '1'); // fill with '1'
                std::cout << "Allocated " << curSize << " bytes\n";
            }
        }
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
}

