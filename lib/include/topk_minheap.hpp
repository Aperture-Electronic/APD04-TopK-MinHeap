#ifndef __TOPK_MINHEAP_HPP__
#define __TOPK_MINHEAP_HPP__

#include <vector>
#include <functional>

template <typename T>
static void sift_up(T* heap, int index)
{
    while (index > 0) 
    {
        int parent = (index - 1) >> 1;
        if (std::less<T>()(heap[index], heap[parent]))
        {
            // Swap the node
            std::swap(heap[index], heap[parent]);

            index = parent; // Move up to the parent
        }
        else
        {
            break; // The heap property is satisfied
        }
    }
}

template <typename T>
static void sift_down(T* heap, int index, int size)
{
    auto current = index;
    while ((current << 1) + 1 < size)
    {
        auto left = (current << 1) + 1;
        auto right = (current << 1) + 2;

        // Select the smallest child from the left and right leaf
        auto smallest = (right < size && std::less<T>()(heap[right], heap[left])) ? right : left;

        if (std::less<T>()(heap[smallest], heap[current]))
        {
            // Swap the current node with the smallest child
            std::swap(heap[smallest], heap[current]);

            current = smallest; // Move down to the smallest child
        }
        else 
        {
            break; // The heap property is satisfied
        }
    }
}

template <typename T>
std::vector<T> topk_minheap(std::vector<T> arr, int k)
{
    // Check if k is greater than the size of the array
    // If not, return the entire array
    auto n = arr.size();

    if (k >= n) {
        return arr;
    }

    // Create a min-heap with capacity k
    auto min_heap = new T[k];

    int heap_ptr = 0;

    for (auto i = 0; i < n; i++)
    {
        auto x = arr.at(i);

        if (heap_ptr < k)
        {
            // Heap is not full, insert the element
            // and do the sift up operation
            min_heap[heap_ptr] = x;
            sift_up(min_heap, heap_ptr);
            heap_ptr++;
        }
        else 
        {
            // Heap is full, check if the current element is larger than the root
            // and do the sift down operation if necessary
            if (x > min_heap[0])
            {
                min_heap[0] = x; // Replace the root with the new element
                sift_down(min_heap, 0, k); // Sift down to maintain the min-heap property
            }
        }
    }

    // Convert the min-heap to a vector for the result
    std::vector<T> result(min_heap, min_heap + k);

    // Clean up the allocated memory
    delete[] min_heap; 

    return result;
}

#endif // __TOPK_MINHEAP_HPP__
