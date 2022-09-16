#pragma once

#include <cstdint>

extern "C" {
/** Print a string with n chars to stdout
 * @param str       the string
 * @param len       the length of the input string
 * @return the number of characters written
 */
uint64_t _print_out_n(const char* str, uint64_t len);
/** Print a null terminated string to stdout
 * @param str       the string
 * @return the number of characters written
 */
uint64_t _print_out_z(const char* str);
/** Print a string with n chars to stderr
 * @param str       the string
 * @param len       the length of the input string
 * @return the number of characters written
 */
uint64_t _print_err_n(const char* str, uint64_t len);
/** Print a null terminated string to stderr
 * @param str       the string
 * @return the number of characters written
 */
uint64_t _print_err_z(const char* str);
/** Break the line in stdout
 * @return number of characters printed (1)
 */
uint64_t _brk_ln_out();
/** Break the line in stderr
 * @return number of characters printed (1)
 */
uint64_t _brk_ln_err();
}
