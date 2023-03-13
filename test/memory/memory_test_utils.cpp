#include "memory_test_utils.h"

#include <algorithm>
#include <iomanip>
#include <iostream>
#include <sstream>

namespace memory {
std::mt19937 Utils::gen_(std::random_device{}());

std::string Utils::ToString(const std::vector<uint8_t>& buffer) {
    std::stringstream out;
    for (auto c : buffer) {
        out << ' ' << std::hex << std::setfill('0') << std::setw(2) << int(c);
    }
    return out.str();
}

std::vector<uint8_t> Utils::RandomVector(size_t size) {
    std::vector<uint8_t> res(size, ' ');
    std::generate(res.begin(), res.end(), []() { return RandomValue<uint8_t>(); });
    return res;
}

std::vector<uint8_t> Utils::RandomVector(size_t size, uint8_t min, uint8_t max) {
    std::vector<uint8_t> res(size, ' ');
    std::generate(res.begin(), res.end(), [=]() { return RandomValue<uint8_t>(min, max); });
    return res;
}

void Utils::Print(std::ostream& out, const uint8_t* pmem, size_t size) {
    for (size_t i = 0; i < size; ++i) {
        out << std::setfill('0') << std::hex << std::setw(2) << int(pmem[i]) << " ";
    }
}

void Utils::Print(const uint8_t* pmem, size_t size) {
    Print(std::cout, pmem, size);
    std::cout << '\n';
}

void MemoryTestBase::SetUp() {
    std::fill(std::begin(pool_), std::end(pool_), 'x');
    _mem_pbase = pool_;
    _mem_size = sizeof(pool_);
}

void MemoryTestBase::TearDown() {
    EXPECT_EQ(_mem_pbase, pool_);
    EXPECT_EQ(_mem_size, sizeof(pool_));
}

}
