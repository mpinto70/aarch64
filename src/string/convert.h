#pragma once

#include <cstdint>

extern "C" {
/** Convert the number that is expressed in the string \b str of length \b len
 * @param str       the string
 * @param len       the length of the input string
 * @param[out] out  a pointer to a uint64_t to receive the value converted
 * @return nullptr if successful
 * @return pointer to first char that is not a digit
 */
const char* _str_to_uint64(const char* str, uint64_t len, uint64_t* out);
/** Convert the number that is expressed in the null terminated string \b str
 * @param str       the string
 * @param[out] out  a pointer to a uint64_t to receive the value converted
 * @return nullptr if successful
 * @return pointer to first char that is not a digit
 */
const char* _strz_to_uint64(const char* str, uint64_t* out);
/** Convert the value to a string
 * @param val       the value to be converted
 * @param[out] out  a pointer to a buffer that will receive the string
 * @param out_len   space available in output buffer
 * @return number of characters converted (0 means value does not fit in buffer)
 */
uint64_t _uint64_to_str(uint64_t val, char* out, uint64_t out_len);
/** Convert the value to a hex string
 * @param val       the value to be converted
 * @param[out] out  a pointer to a buffer that will receive the string
 * @param out_len   space available in output buffer
 * @return number of characters converted (0 means value does not fit in buffer)
 */
uint64_t _uint64_to_hex(uint64_t val, char* out, uint64_t out_len);
}
