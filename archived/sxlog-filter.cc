#include <cstdint>
#include <rlib/stdio.hpp>
#include <unordered_set>
#include <vector>
#include <string>
#include <ctime>

int main() {
    std::vector<std::string> lines;
    while(true) {
        auto line = rlib::scanln();
        if (line.strip() == "")
            break;

        lines.emplace_back(line);
    }
    rlib::printfln(std::cerr, "read {} lines", lines.size());

    long lptime = 0;
    std::unordered_set<std::string> freed;
    std::vector<std::string> leaked_lines_rev;

    for (auto i = 0; i < lines.size(); ++i) {
        auto currtime = std::time(nullptr);
        if (currtime > lptime + 20) {
            lptime = currtime;
            rlib::println(std::cerr, i, "lines processed");
        }

        auto &line = lines[lines.size()-i-1];
        auto pos = line.find("PtP/SId=");
        if (pos == std::string::npos) {
            continue;
        }
        auto ptr = line.substr(pos+std::string("PtP/SId=").size());
        if (line.find("SxFreePortContext called") == std::string::npos) {
            if (!freed.contains(ptr)) {
                leaked_lines_rev.emplace_back(std::move(line));
            }
        }
        else {
            // rlib::println(std::cerr, "free ins", ptr);
            freed.insert(ptr);
        }
    }

    rlib::println(std::cerr, "freed port: ", freed.size());
    for (auto i = 0; i < leaked_lines_rev.size(); ++i) {
        auto &line = leaked_lines_rev[leaked_lines_rev.size()-i-1];
        rlib::println(line);
    }
}

