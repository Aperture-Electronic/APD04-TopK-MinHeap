#include <gtest/gtest.h>
#include <vector>
#include <algorithm>
#include <random>

// DUT
#include "topk_minheap.hpp"

template<typename T>
std::vector<T> reference_topk(std::vector<T> arr, int k) 
{
    std::sort(arr.begin(), arr.end(), std::greater<T>());

    if (k > arr.size())
    {
        return arr;
    }

    return std::vector<T>(arr.begin(), arr.begin() + k);
}

TEST(utest_topk_minheap, EmptyInput) 
{
    std::vector<uint32_t> input;
    int k = 3;
    auto result = topk_minheap(input, k);
    EXPECT_TRUE(result.empty());
}

TEST(utest_topk_minheap, KGreaterThanInputSize) {
    std::vector<uint32_t> input = {3, 1, 4};
    int k = 5;
    auto result = topk_minheap(input, k);
    auto expected = reference_topk(input, k);
    std::sort(result.begin(), result.end(), std::greater<uint32_t>());
    EXPECT_EQ(result, expected);
}

TEST(utest_topk_minheap, KEqualOne) {
    std::vector<uint32_t> input = {7, 2, 9, 4};
    int k = 1;
    auto result = topk_minheap(input, k);
    auto expected = reference_topk(input, k);
    std::sort(result.begin(), result.end(), std::greater<uint32_t>());
    EXPECT_EQ(result, expected);
}

TEST(utest_topk_minheap, KEqualToInputSize) {
    std::vector<uint32_t> input = {1, 2, 3, 4, 5};
    int k = (int)input.size();
    auto result = topk_minheap(input, k);
    auto expected = reference_topk(input, k);
    std::sort(result.begin(), result.end(), std::greater<uint32_t>());
    EXPECT_EQ(result, expected);
}

TEST(utest_topk_minheap, KMidRange) {
    std::vector<uint32_t> input = {5, 1, 9, 3, 14, 7, 2};
    int k = 3;
    auto result = topk_minheap(input, k);
    auto expected = reference_topk(input, k);
    std::sort(result.begin(), result.end(), std::greater<uint32_t>());
    EXPECT_EQ(result, expected);
}

TEST(utest_topk_minheap, LargeRandomInput) {
    std::mt19937 rng(42);
    std::uniform_int_distribution<uint32_t> dist(0, 4294967295);

    std::vector<uint32_t> input(4096);
    for (auto& x : input) x = dist(rng);

    int k = 128;

    GTEST_LOG_(INFO) << "Generated " << input.size() << " values for testing.";
    GTEST_LOG_(INFO) << "Top " << k << " elements will be extracted.";

    auto result = topk_minheap(input, k);
    auto expected = reference_topk(input, k);
    std::sort(result.begin(), result.end(), std::greater<uint32_t>());
    EXPECT_EQ(result, expected);
}
