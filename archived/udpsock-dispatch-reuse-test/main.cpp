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
    template <typename IntType>
    auto operator=(IntType syscall_res) const {
        if(syscall_res < 0)
            throw std::runtime_error(rlib::string("[LINE{}] System call returns {}, errno={}, strerror={}").format(msg, syscall_res, errno,
                                                                                                                   strerror(errno)));
    }
    auto operator=(bool what) const {
        *this= what ? 1 : -1;
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
    int sock2 = socket(AF_INET, SOCK_DGRAM, 0);
    int sock3 = socket(AF_INET, SOCK_DGRAM, 0);
    int sock4 = socket(AF_INET, SOCK_DGRAM, 0);

    die_on_fail sock1>0 && sock2>0 && sock3>0 && sock4>0;

    // Set REUSEADDR option for each socket
    int reuseaddr = 1;
    die_on_fail setsockopt(sock1, SOL_SOCKET, SO_REUSEADDR, &reuseaddr, sizeof(reuseaddr));
    die_on_fail setsockopt(sock2, SOL_SOCKET, SO_REUSEADDR, &reuseaddr, sizeof(reuseaddr));
    die_on_fail setsockopt(sock3, SOL_SOCKET, SO_REUSEADDR, &reuseaddr, sizeof(reuseaddr));
    die_on_fail setsockopt(sock4, SOL_SOCKET, SO_REUSEADDR, &reuseaddr, sizeof(reuseaddr));

    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(1234);

    // Bind each socket to the same local address (A)
    die_on_fail bind(sock1, reinterpret_cast<struct sockaddr*>(&server_addr), sizeof(server_addr));
    die_on_fail bind(sock2, reinterpret_cast<struct sockaddr*>(&server_addr), sizeof(server_addr));
    die_on_fail bind(sock3, reinterpret_cast<struct sockaddr*>(&server_addr), sizeof(server_addr));
    die_on_fail bind(sock4, reinterpret_cast<struct sockaddr*>(&server_addr), sizeof(server_addr));

    struct sockaddr_in RA1, RA2, RA3;
    memset(&RA1, 0, sizeof(RA1));
    memset(&RA2, 0, sizeof(RA2));
    memset(&RA3, 0, sizeof(RA3));

    RA1.sin_family = AF_INET;
    RA1.sin_addr.s_addr = inet_addr("127.0.0.1"); // Replace with your actual address
    RA1.sin_port = htons(12345);

    RA2.sin_family = AF_INET;
    RA2.sin_addr.s_addr = inet_addr("127.0.0.1"); // Replace with your actual address
    RA2.sin_port = htons(12346);

    RA3.sin_family = AF_INET;
    RA3.sin_addr.s_addr = inet_addr("127.0.0.1"); // Replace with your actual address
    RA3.sin_port = htons(12347);

    // Connect each socket to the corresponding remote address
    die_on_fail connect(sock1, reinterpret_cast<struct sockaddr*>(&RA1), sizeof(RA1));
    die_on_fail connect(sock2, reinterpret_cast<struct sockaddr*>(&RA2), sizeof(RA2));
    die_on_fail connect(sock3, reinterpret_cast<struct sockaddr*>(&RA3), sizeof(RA3));

    // die_on_fail listen(sock4, 4);

    // Set up epoll event loop
    int epoll_fd = epoll_create1(0);

    struct epoll_event event;
    event.events = EPOLLIN;

    event.data.fd = sock1;
    epoll_ctl(epoll_fd, EPOLL_CTL_ADD, sock1, &event);

    event.data.fd = sock2;
    epoll_ctl(epoll_fd, EPOLL_CTL_ADD, sock2, &event);

    event.data.fd = sock3;
    epoll_ctl(epoll_fd, EPOLL_CTL_ADD, sock3, &event);

    event.data.fd = sock4;
    epoll_ctl(epoll_fd, EPOLL_CTL_ADD, sock4, &event);

    struct epoll_event events[MAX_EVENTS];
    printf("INTO Loop\n");

    // Event loop
    while (true) {
        int num_events = epoll_wait(epoll_fd, events, MAX_EVENTS, -1);

        for (int i = 0; i < num_events; ++i) {
            if (events[i].events & EPOLLIN) {
                if (events[i].data.fd == sock1) {
                    rlib::println("sock1 WU");
                    handle_data(sock1);
                } else if (events[i].data.fd == sock2) {
                    rlib::println("sock2 WU");
                    handle_data(sock2);
                } else if (events[i].data.fd == sock3) {
                    rlib::println("sock3 WU");
                    handle_data(sock3);
                } else if (events[i].data.fd == sock4) {
                    rlib::println("sock4 LI WU");
                    handle_data(sock4);
                }
            }
        }
    }

    close(sock1);
    close(sock2);
    close(sock3);

    return 0;
}
