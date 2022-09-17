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
/** Convert an array of null terminated strings to array of integers
 * @param strs      the strings
 * @param len       number of strings
 * @param[out] out  a pointer to begin of an array of at least \b len elements
 * @return nullptr if successful
 * @return pointer to first str that is not a number
 */
const char* _strsz_to_uint64s(const char** strs, uint64_t len, uint64_t* out);
/** Convert the value to a string
 * @param val       the value to be converted
 * @param[out] out  a pointer to a buffer that will receive the string
 * @param out_len   space available in output buffer
 * @return number of characters converted
 * @return 0 if value does not fit in buffer
 */
uint64_t _uint64_to_str(uint64_t val, char* out, uint64_t out_len);
/** Convert the value to a hex string
 * @param val       the value to be converted
 * @param[out] out  a pointer to a buffer that will receive the string
 * @param out_len   space available in output buffer
 * @return number of characters converted
 * @return 0 if value does not fit in buffer
 */
uint64_t _uint64_to_hex(uint64_t val, char* out, uint64_t out_len);
/** Convert the value to a null terminated string
 * @param val       the value to be converted
 * @param[out] out  a pointer to a buffer that will receive the string
 * @param out_len   space available in output buffer
 * @return number of characters converted (not including the null terminator)
 * @return 0 if value does not fit in buffer
 */
uint64_t _uint64_to_strz(uint64_t val, char* out, uint64_t out_len);
/** Convert the value to a null terminated hex string
 * @param val       the value to be converted
 * @param[out] out  a pointer to a buffer that will receive the string
 * @param out_len   space available in output buffer
 * @return number of characters converted (not including the null terminator)
 * @return 0 if value does not fit in buffer
 */
uint64_t _uint64_to_hexz(uint64_t val, char* out, uint64_t out_len);
}
