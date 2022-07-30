
#include <algorithm>
#include <cstdint>
#include <iostream>
#include <numeric>
#include <random>
#include <string>
#include <vector>

extern "C" {
void _quick_sort(uint64_t* begin, uint64_t* end);
void _bubble_sort(uint64_t* begin, uint64_t num_elements);
}

void print(const std::vector<uint64_t>& values) {
    for (auto value : values) {
        std::cout << value << " ";
    }
    std::cout << "\n";
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cout << "Invalid number of arguments\n";
        return 1;
    }
    const size_t num_elements = std::stoi(argv[1]);
    std::vector<uint64_t> values(num_elements, 0);
    std::iota(values.begin(), values.end(), 0);
    const auto verify = values; // sorted

    std::random_device rd;
    std::mt19937 g(rd());
    std::shuffle(values.begin(), values.end(), g);

    //print(values);
    _quick_sort(values.data(), values.data() + values.size());
    //print(values);

    if (values != verify) {
        std::cout << "NOT OK!!!\n";
    } else {
        std::cout << "OK!\n";
    }

    std::shuffle(values.begin(), values.end(), g);

    //print(values);
    _bubble_sort(values.data(), values.size());
    //print(values);

    if (values != verify) {
        std::cout << "NOT OK!!!\n";
    } else {
        std::cout << "OK!\n";
    }
}