#include "string/convert.h"

#include <gtest/gtest.h>

#include <string>

namespace {

TEST(convertTest, str_to_uint64_ok) {
    const char number[] = "12345";
    uint64_t result = 0;

    EXPECT_EQ(_str_to_uint64(number, 1, &result), nullptr);
    EXPECT_EQ(result, 1);
    EXPECT_EQ(_str_to_uint64(number, 2, &result), nullptr);
    EXPECT_EQ(result, 12);
    EXPECT_EQ(_str_to_uint64(number, 3, &result), nullptr);
    EXPECT_EQ(result, 123);
    EXPECT_EQ(_str_to_uint64(number, 4, &result), nullptr);
    EXPECT_EQ(result, 1234);
    EXPECT_EQ(_str_to_uint64(number, 5, &result), nullptr);
    EXPECT_EQ(result, 12345);
}

TEST(convertTest, str_to_uint64_error) {
    uint64_t result = 0;
    const std::vector<char> invalid = { 'a', 'b', 'c', '-', '.', ' ' };
    for (const char c : invalid) {
        for (size_t i = 0; i < 6; ++i) {
            std::string str = "12345";
            str.insert(i, 1, c);
            EXPECT_EQ(_str_to_uint64(str.c_str(), str.size(), &result), &str[i]) << str;
        }
    }

    EXPECT_EQ(result, 0); // does not change
}

TEST(convertTest, strz_to_uint64_ok) {
    uint64_t result = 0;

    EXPECT_EQ(_strz_to_uint64("1", &result), nullptr);
    EXPECT_EQ(result, 1);
    EXPECT_EQ(_strz_to_uint64("12", &result), nullptr);
    EXPECT_EQ(result, 12);
    EXPECT_EQ(_strz_to_uint64("123", &result), nullptr);
    EXPECT_EQ(result, 123);
}

TEST(convertTest, strz_to_uint64_error) {
    uint64_t result = 0;
    const std::vector<char> invalid = { 'a', 'b', 'c', '-', '.', ' ' };
    for (const char c : invalid) {
        for (size_t i = 0; i < 6; ++i) {
            std::string str = "12345";
            str.insert(i, 1, c);
            EXPECT_EQ(_strz_to_uint64(str.c_str(), &result), &str[i]) << str;
        }
    }

    EXPECT_EQ(result, 0); // does not change
}

TEST(convertTest, uint64_to_str_ok) {
    char value[50] = {};
    EXPECT_EQ(_uint64_to_str(12345, value, sizeof(value)), 5);
    EXPECT_EQ(std::string("12345"), value);
    EXPECT_EQ(_uint64_to_str(987654321, value, sizeof(value)), 9);
    EXPECT_EQ(std::string("987654321"), value);
}

TEST(convertTest, uint64_to_str_error) {
    char value[50] = {};
    EXPECT_EQ(_uint64_to_str(12345, value, 0), 0);
    EXPECT_EQ(_uint64_to_str(12345, value, 1), 0);
    EXPECT_EQ(_uint64_to_str(12345, value, 2), 0);
    EXPECT_EQ(_uint64_to_str(12345, value, 3), 0);
    EXPECT_EQ(_uint64_to_str(12345, value, 4), 0);

    EXPECT_EQ(_uint64_to_str(12345, value, 5), 5);
    EXPECT_EQ(std::string("12345"), value);
}

TEST(convertTest, uint64_to_hex_ok) {
    char value[50] = {};
    EXPECT_EQ(_uint64_to_hex(0x12345, value, sizeof(value)), 5);
    EXPECT_EQ(std::string("12345"), value);
    EXPECT_EQ(_uint64_to_hex(0xabcdef0123456789, value, sizeof(value)), 16);
    EXPECT_EQ(std::string("abcdef0123456789"), value);
    EXPECT_EQ(_uint64_to_hex(-1, value, sizeof(value)), 16);
    EXPECT_EQ(std::string("ffffffffffffffff"), value);
}

TEST(convertTest, uint64_to_hex_error) {
    char value[50] = {};
    EXPECT_EQ(_uint64_to_hex(0x12345, value, 0), 0);
    EXPECT_EQ(_uint64_to_hex(0x12345, value, 1), 0);
    EXPECT_EQ(_uint64_to_hex(0x12345, value, 2), 0);
    EXPECT_EQ(_uint64_to_hex(0x12345, value, 3), 0);
    EXPECT_EQ(_uint64_to_hex(0x12345, value, 4), 0);

    EXPECT_EQ(_uint64_to_hex(0x12345, value, 5), 5);
    EXPECT_EQ(std::string("12345"), value);
}

} // namespace