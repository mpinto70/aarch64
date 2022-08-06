#include "sorting/quick.h"

#include <benchmark/benchmark.h>

#include <algorithm>
#include <numeric>
#include <random>
#include <vector>

namespace {

constexpr size_t NUM_ELEMENTS = 100'000;

std::vector<uint64_t> randomVector() {
    std::vector<uint64_t> values(NUM_ELEMENTS, 0);
    std::iota(values.begin(), values.end(), 0);

    std::random_device rd;
    std::mt19937 g(rd());
    std::shuffle(values.begin(), values.end(), g);
    return values;
}

std::vector<uint64_t> sortedVector() {
    std::vector<uint64_t> values(NUM_ELEMENTS, 0);
    std::iota(values.begin(), values.end(), 0);
    return values;
}

std::vector<uint64_t> invertedVector() {
    std::vector<uint64_t> values(NUM_ELEMENTS, 0);
    std::iota(values.rbegin(), values.rend(), 0);
    return values;
}

std::vector<uint64_t> constantVector() {
    return std::vector<uint64_t>(NUM_ELEMENTS, 7);
}

typedef std::vector<uint64_t> (*vector_f)();

void BenchmarkQuickSort(benchmark::State& state, vector_f vectorF, pivot_f pivotF) {
    const auto original = vectorF();
    auto values = original;
    for (auto _ : state) {
        values = original;
        _quick_sort(values.data(), values.data() + values.size(), pivotF);
    }
}

void BM_QuickSort_RandomValues_LeftPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, randomVector, _left_pivot);
}

void BM_QuickSort_RandomValues_RightPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, randomVector, _right_pivot);
}

void BM_QuickSort_RandomValues_MiddlePivot(benchmark::State& state) {
    BenchmarkQuickSort(state, randomVector, _middle_pivot);
}

void BM_QuickSort_RandomValues_RandomPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, randomVector, _random_pivot);
}

void BM_QuickSort_RandomValues_SemiRandomPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, randomVector, _semi_random_pivot);
}

BENCHMARK(BM_QuickSort_RandomValues_LeftPivot);
BENCHMARK(BM_QuickSort_RandomValues_RightPivot);
BENCHMARK(BM_QuickSort_RandomValues_MiddlePivot);
BENCHMARK(BM_QuickSort_RandomValues_RandomPivot);
BENCHMARK(BM_QuickSort_RandomValues_SemiRandomPivot);

void BM_QuickSort_SortedValues_LeftPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, sortedVector, _left_pivot);
}

void BM_QuickSort_SortedValues_RightPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, sortedVector, _right_pivot);
}

void BM_QuickSort_SortedValues_MiddlePivot(benchmark::State& state) {
    BenchmarkQuickSort(state, sortedVector, _middle_pivot);
}

void BM_QuickSort_SortedValues_RandomPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, sortedVector, _random_pivot);
}

void BM_QuickSort_SortedValues_SemiRandomPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, sortedVector, _semi_random_pivot);
}

BENCHMARK(BM_QuickSort_SortedValues_LeftPivot);
BENCHMARK(BM_QuickSort_SortedValues_RightPivot);
BENCHMARK(BM_QuickSort_SortedValues_MiddlePivot);
BENCHMARK(BM_QuickSort_SortedValues_RandomPivot);
BENCHMARK(BM_QuickSort_SortedValues_SemiRandomPivot);

void BM_QuickSort_InvertedValues_LeftPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, invertedVector, _left_pivot);
}

void BM_QuickSort_InvertedValues_RightPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, invertedVector, _right_pivot);
}

void BM_QuickSort_InvertedValues_MiddlePivot(benchmark::State& state) {
    BenchmarkQuickSort(state, invertedVector, _middle_pivot);
}

void BM_QuickSort_InvertedValues_RandomPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, invertedVector, _random_pivot);
}

void BM_QuickSort_InvertedValues_SemiRandomPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, invertedVector, _semi_random_pivot);
}

BENCHMARK(BM_QuickSort_InvertedValues_LeftPivot);
BENCHMARK(BM_QuickSort_InvertedValues_RightPivot);
BENCHMARK(BM_QuickSort_InvertedValues_MiddlePivot);
BENCHMARK(BM_QuickSort_InvertedValues_RandomPivot);
BENCHMARK(BM_QuickSort_InvertedValues_SemiRandomPivot);

void BM_QuickSort_ConstantValues_LeftPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, constantVector, _left_pivot);
}

void BM_QuickSort_ConstantValues_RightPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, constantVector, _right_pivot);
}

void BM_QuickSort_ConstantValues_MiddlePivot(benchmark::State& state) {
    BenchmarkQuickSort(state, constantVector, _middle_pivot);
}

void BM_QuickSort_ConstantValues_RandomPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, constantVector, _random_pivot);
}

void BM_QuickSort_ConstantValues_SemiRandomPivot(benchmark::State& state) {
    BenchmarkQuickSort(state, constantVector, _semi_random_pivot);
}

BENCHMARK(BM_QuickSort_ConstantValues_LeftPivot);
BENCHMARK(BM_QuickSort_ConstantValues_RightPivot);
BENCHMARK(BM_QuickSort_ConstantValues_MiddlePivot);
BENCHMARK(BM_QuickSort_ConstantValues_RandomPivot);
BENCHMARK(BM_QuickSort_ConstantValues_SemiRandomPivot);
} // namespace
