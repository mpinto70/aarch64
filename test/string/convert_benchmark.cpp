#include "sorting/utils.h"
#include "string/convert.h"

#include <benchmark/benchmark.h>

#include <algorithm>
#include <numeric>
#include <random>
#include <vector>

namespace {

typedef const char* (*StrToIntFUT)(const char*, uint64_t, uint64_t*);

void BenchmarkStrToInt(benchmark::State& state, StrToIntFUT fut, const std::string& value) {
    uint64_t out;
    for (auto _ : state) {
        fut(value.c_str(), value.size(), &out);
    }
}

void BM_StrToUint64(benchmark::State& state) {
    BenchmarkStrToInt(state, _str_to_uint64, "98520192346");
}

void BM_HexToUint64(benchmark::State& state) {
    BenchmarkStrToInt(state, _hex_to_uint64, "95ab20ca136");
}

BENCHMARK(BM_StrToUint64);
BENCHMARK(BM_HexToUint64);

typedef const char* (*StrzToIntFUT)(const char*, uint64_t*);

void BenchmarkStrzToInt(benchmark::State& state, StrzToIntFUT fut, const std::string& value) {
    uint64_t out;
    for (auto _ : state) {
        fut(value.c_str(), &out);
    }
}

void BM_StrzToUint64(benchmark::State& state) {
    BenchmarkStrzToInt(state, _strz_to_uint64, "98520192346");
}

void BM_HexzToUint64(benchmark::State& state) {
    BenchmarkStrzToInt(state, _hexz_to_uint64, "95AB20CA136");
}

BENCHMARK(BM_StrzToUint64);
BENCHMARK(BM_HexzToUint64);

typedef uint64_t (*IntToStrFUT)(uint64_t, char*, uint64_t);

void BenchmarkIntToStr(benchmark::State& state, IntToStrFUT fut, uint64_t value) {
    char buffer[32];
    for (auto _ : state) {
        fut(value, buffer, sizeof(buffer));
    }
}

void BM_Uint64ToStr(benchmark::State& state) {
    BenchmarkIntToStr(state, _uint64_to_str, 8521214457);
}

void BM_Uint64ToHex(benchmark::State& state) {
    BenchmarkIntToStr(state, _uint64_to_hex, 7522115478);
}

void BM_Uint64ToStrz(benchmark::State& state) {
    BenchmarkIntToStr(state, _uint64_to_strz, 935173157);
}

void BM_Uint64ToHexz(benchmark::State& state) {
    BenchmarkIntToStr(state, _uint64_to_hexz, 311510154);
}

BENCHMARK(BM_Uint64ToStr);
BENCHMARK(BM_Uint64ToHex);
BENCHMARK(BM_Uint64ToStrz);
BENCHMARK(BM_Uint64ToHexz);

}