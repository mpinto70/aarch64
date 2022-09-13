#include "string/operation.h"

#include <gtest/gtest.h>

#include <string>

namespace {

TEST(operationTest, strz_len) {
    EXPECT_EQ(_strz_len(""), 0);
    EXPECT_EQ(_strz_len("123"), 3);
    EXPECT_EQ(_strz_len("Hello, world!"), 13);
}

} // namespace
