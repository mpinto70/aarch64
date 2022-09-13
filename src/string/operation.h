#pragma once

#include <cstdint>

extern "C" {
/** Return the length of the null terminated string.
 * @param str   the null terminated string
 * @return the length of the string
 */
uint64_t _strz_len(const char* str);
}
