#include <utility>
#define ERRMSG "float must be positive power of 0.5."

// Last character is str_last<0, str...>
template <size_t which, char c, char... str>
struct str_last
{
    static constexpr char value() {
        if constexpr(sizeof...(str) == which)
            return c;
        else
            return str_last<which, str...>::value();
    }
};

// First character is str_first<0, str...>
template <size_t which, char... str>
struct str_first {
    static constexpr char value() {
        return str_last<sizeof...(str) - which - 1, str ...>::value();
    }
};

template <size_t which, size_t carry, char... str>
struct check_one_bit {
    static constexpr bool value() {
        constexpr size_t len = sizeof...(str);
        if constexpr(which == 1) {
            static_assert(carry == 1, ERRMSG);
            static_assert(str_first<which, str...>::value() == '.', ERRMSG);
            return check_one_bit<which - 1, 0, str...>::value();
        }
        else if constexpr(which == 0) {
            static_assert(str_first<which, str...>::value() == '0', ERRMSG);
            return true;
        }
        else {
            constexpr size_t curr = str_first<which, str...>::value() - '0';
            static_assert(curr <= 9, ERRMSG);

            constexpr size_t magic = ((curr << (len - which - 1)) + carry) * 2;
            static_assert(magic % 10 == 0, ERRMSG);

            return check_one_bit<which - 1, magic / 10, str...>::value();
        }
    }
};

template <char... str>
constexpr long double operator ""_ld() {
    constexpr size_t len = sizeof...(str);
    static_assert(check_one_bit<len - 1, 0, str...>::value(), ERRMSG);
    if constexpr(len > 33)
        return 0.0;
    else
        return 1.0 / (1 << (len - 2));
}

// 0.5
// 0.25
// 0.125
// 0.0625
// 0.03125
// 0.015625
// 0.0078125
// 0.00390625
// 0.001953125 

#include <iostream>
int main() {
    auto i = 0.001953125_ld;
    auto j = 0.00000000023283064365386962890625_ld;
    std::cout << i << ' ' << j << std::endl;
    return 0;
}
