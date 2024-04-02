#include <iostream>
template<typename Iterable, typename Printable>
void print_iter(Iterable arg, Printable spliter)
{
    for(const auto & i : arg)
        ::std::cout << i << spliter;
}
template<typename Iterable, typename Printable>
void println_iter(Iterable arg, Printable spliter)
{
    print_iter(arg, spliter);
    ::std::cout << ::std::endl;
}
template<typename Iterable>
void print_iter(Iterable arg)
{
    for(const auto & i : arg)
        ::std::cout << i << ' ';
}
template<typename Iterable>
void println_iter(Iterable arg)
{
    print_iter(arg);
    ::std::cout << ::std::endl;
}

#include <vector>
#include <tuple>

template<class Tuple, std::size_t... I>
auto repeat_tuple_ele_helper(size_t X, Tuple &&tup, std::index_sequence<I ...>)
{
    return std::make_tuple(std::vector<std::remove_reference_t<decltype(std::get<I>(tup))>>(X, std::get<I>(tup)) ...);
}

template <class Tuple>
auto repeat_tuple_ele(size_t time, Tuple &&tup)
{
    return repeat_tuple_ele_helper(time, std::move(tup), std::make_index_sequence<std::tuple_size<std::remove_reference_t<Tuple>>::value>{});
}

int main (){
    auto res = repeat_tuple_ele(6, std::make_tuple(1,"foo", 0.5));
    println_iter(std::get<0>(res));
    println_iter(std::get<1>(res));
    println_iter(std::get<2>(res));
    return 0;
}

