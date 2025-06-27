# APD04 Top-K Min-Heap

## Introduction
The APD04 is an IP core which implement the top-K sorter by min-heap algorithm.  

This IP can receive a group of data (any count of data, ended by TLAST signal) by stream interface, and extract the top K (parameterized)
 values from it, and output these values by an other stream interface.  

This IP using AXI4-Stream interface.

## Min-Heap Algorithm
> TODO

## Roadmap

- [x] Basic function (/w simple testbench)
- [ ] UVM testbench (In processnig)
- [ ] Completed documentation
- [ ] Performance optimazation 
