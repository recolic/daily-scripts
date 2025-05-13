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

#include <tuple>

#include <string>
#include <vector>
using namespace std::string_literals;

#ifdef Q3_ENABLE_GCCONLY_IMPL
// Do not use std::get<n>, but works on gcc only.
namespace impl1 {
    template <typename T, size_t _Idx, typename... Ele>
    constexpr T get_impl(std::_Tuple_impl<_Idx, T, Ele ...> &impl) {
        return impl._M_head(impl);
    }
    template <typename T, size_t _Idx, typename... Ele>
    constexpr T get_impl(std::_Tuple_impl<_Idx, Ele ...> &impl) {
        return get_impl<T>(static_cast<typename std::_Tuple_impl<_Idx, Ele...>::_Inherited>(impl));
    }
    
    template <typename T, typename Tuple>
    constexpr std::vector<T> get_vector(Tuple &tup) {
        return get_impl<std::vector<T> >(tup);
    }
}
using namespace impl1;
#endif

#ifdef Q3_ENABLE_GENERAL_IMPL
// Use std::get<n>, but works on all compilers.
namespace impl2 {
    template<typename T, int n,typename Tuple>
    auto get_impl(Tuple& t){
        if constexpr(std::is_same<T, typename std::tuple_element<n, Tuple>::type>::value){
            return std::get<n>(t);
        }
        else if constexpr(std::tuple_size<Tuple>::value > n){
            return get_impl<T, n+1>(t);
        }
    }
    
    template<typename T, typename Tuple>
    auto get_vector(Tuple& t){
        return get_impl<std::vector<T>, 0>(t); 
    }
}
using namespace impl2;
#endif

int main()
{
    auto tup = std::make_tuple(std::vector<int>{1,6,5,34,2,1}, std::vector<std::string>{"hello"s, "world"s, "boost"s}, std::vector<double>{7.77});
    println_iter(get_vector<int>(tup));
    auto result = get_vector<std::string>(tup);
    println_iter(result);
    result[1] = "hi"s;
    result.push_back("meow~");
    println_iter(result);
    return 0;
}
