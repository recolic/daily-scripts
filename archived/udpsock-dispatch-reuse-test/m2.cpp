#include <iostream>
#include <cstring>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/epoll.h>
#include <rlib/stdio.hpp>

constexpr int MAX_EVENTS = 16;

struct die_impl {
    explicit die_impl(int hint_str) : msg(std::to_string(hint_str)) {}
    auto operator=(const long &syscall_res) const {
        if(syscall_res < 0)
            throw std::runtime_error(rlib::string("[LINE{}] System call returns {}, errno={}, strerror={}").format(msg, syscall_res, errno,
                                                                                                                   strerror(errno)));
    }
    std::string msg;
};
#define die_on_fail die_impl(__LINE__) =

void handle_data(int sockfd) {
    struct sockaddr_in client_addr;
    socklen_t addr_len = sizeof(client_addr);
    char buffer[1024];

    ssize_t bytes_received = recvfrom(sockfd, buffer, sizeof(buffer), 0,
                                      reinterpret_cast<struct sockaddr*>(&client_addr), &addr_len);

    if (bytes_received > 0) {
        std::cout << "Received data from " << inet_ntoa(client_addr.sin_addr) << ": "
                  << std::string(buffer, buffer + bytes_received) << std::endl;
    }
}

int main() {
    int sock1 = socket(AF_INET, SOCK_DGRAM, 0);
    die_on_fail sock1;

    // Set REUSEADDR option for each socket
    int reuseaddr = 1;
    die_on_fail setsockopt(sock1, SOL_SOCKET, SO_REUSEADDR, &reuseaddr, sizeof(reuseaddr));

    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    auto rpstr = getenv("RP");
    if (!rpstr) {
        rlib::println("usage: env LP=1234 RP=12345 ./this_program # To send UDP msg from ::1:1234 to ::1:12345");
        return 1;
    }
    server_addr.sin_port = htons(rlib::string(rpstr).as<int>());

    // Bind each socket to the same local address (A)
    die_on_fail bind(sock1, reinterpret_cast<struct sockaddr*>(&server_addr), sizeof(server_addr));

    struct sockaddr_in RA1, RA2, RA3;
    memset(&RA1, 0, sizeof(RA1));
    memset(&RA2, 0, sizeof(RA2));
    memset(&RA3, 0, sizeof(RA3));

    RA1.sin_family = AF_INET;
    RA1.sin_addr.s_addr = inet_addr("127.0.0.1"); // Replace with your actual address
    auto lpstr = getenv("LP");
    if(lpstr)
        RA1.sin_port = htons(rlib::string(lpstr).as<int>());
    else
        RA1.sin_port = htons(1234);
    rlib::println("sending from ", lpstr ? lpstr : "1234" , "TO ", rpstr);

    // Connect each socket to the corresponding remote address
    die_on_fail connect(sock1, reinterpret_cast<struct sockaddr*>(&RA1), sizeof(RA1));

    die_on_fail write(sock1, "TEST!", 6);
    printf("sent msg\n");

    // Set up epoll event loop
    int epoll_fd = epoll_create1(0);

    struct epoll_event event;
    event.events = EPOLLIN;

    event.data.fd = sock1;
    epoll_ctl(epoll_fd, EPOLL_CTL_ADD, sock1, &event);

    struct epoll_event events[MAX_EVENTS];
    printf("INTO Loop\n");

    // Event loop
    while (true) {
        int num_events = epoll_wait(epoll_fd, events, MAX_EVENTS, -1);

        for (int i = 0; i < num_events; ++i) {
            if (events[i].events & EPOLLIN) {
                if (events[i].data.fd == sock1) {
                    handle_data(sock1);
                }
            }
        }
    }

    close(sock1);

    return 0;
}
