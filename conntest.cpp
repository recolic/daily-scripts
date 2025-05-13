#include <rlib/stdio.hpp>
#include <rlib/sys/sio.hpp>
#include <rlib/opt.hpp>
#include <chrono>

using namespace std::chrono;
using namespace std::chrono_literals;

void s_func(rlib::opt_parser &args) {
    auto port = args.getValueArg("--port", "-p").as<uint16_t>();
    auto listenfd = rlib::quick_listen("::0", port);
    rlib::println("S: Listening", port);

    auto cter = 0;
    auto next_report_time = system_clock::now() + 10s;
    while (true) {
        auto connfd = rlib::quick_accept(listenfd);
        close(connfd); // TODO async close
        ++cter;

        if (cter % 100 == 0 && system_clock::now() > next_report_time) {
            next_report_time = system_clock::now() + 10s;
            rlib::println("cter=", cter);
        }
    }
}

void c_func(rlib::opt_parser &args) {
    auto addr = args.getValueArg("--addr", "-a");
    auto port = args.getValueArg("--port", "-p").as<uint16_t>();
    rlib::println("C: connecting", addr, port);

    auto cter = 0;
    auto next_report_time = system_clock::now() + 10s;
    while (true) {
        try {
            auto connfd = rlib::quick_connect(addr, port);
            close(connfd); // TODO async close
        }
        catch (...) {
            continue;
        }
        ++cter;

        if (cter % 100 == 0 && system_clock::now() > next_report_time) {
            next_report_time = system_clock::now() + 10s;
            rlib::println("cter=", cter);
        }
    }
}

int main(int argc, char **argv) {
    rlib::opt_parser args(argc, argv);
    auto role = args.getValueArg("--role", "-r");
    if (role == "c") {
        c_func(args);
    }
    else if (role == "s") {
        s_func(args);
    }
    else {
        rlib::println("set role to c/s");
    }
}
