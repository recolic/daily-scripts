#include <rlib/sys/unix_handy.hpp>
#include <rlib/opt.hpp>

int main(int argc, char **argv) {
    rlib::opt_parser args(argc, argv);
    auto keyFile = args.getValueArg("-k", false, "");

    setuid(geteuid());
    setgid(getegid());

    rlib::execs("/bin/bash", std::vector<std::string>{"runas.impl.sh", keyFile});
}

