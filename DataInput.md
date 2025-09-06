# Common Hardware Data-Flow Patterns

This document summarizes common data-flow motifs in hardware design (DSP, ML, graphics, crypto, etc.), with intuition, use cases, and hardware notes.

---

## Table of Patterns

| Pattern | Intuition / What it does | Typical uses | Latency & throughput shape | Common HW tricks |
|---|---|---|---|---|
| **Butterfly network** | Pairwise combine/swap across log₂N stages with permutations between | FFT/IFFT, NTT, FEC (LDPC/Turbo interleavers) | ~log₂N stages; 1 sample/cycle with full pipelining | In-place SRAM with banked access; bit-reversal or digit-reversal addressing; twiddle ROM; stride-k shuffles |
| **Adder/Reduce tree** | Fan-in reduction (sum/min/max) with tree of operators | FIR accumulation, dot products, popcount, pooling | ~⌈log₂N⌉ stage latency; 1/cycle throughput | Wallace/Dadda trees, carry-save, compressor trees, pipeline every level |
| **Prefix/Scan network** | Inclusive/exclusive prefix op via Ladner–Fischer / Kogge–Stone style networks | Cumulative sums, histograms, carry lookahead | O(log N) latency; 1/cycle with pipelining | Balanced prefix graph; SRAM ping-pong when streaming |
| **Systolic array (1D/2D)** | Local neighbor data moves; MACs “pulse” through fabric | GEMM/conv, beamforming, Viterbi | Latency ≈ array dimension; steady-state 1 result/cycle/PE | Weight-stationary / output-stationary / row-stationary dataflows; double-buffer on array edges |
| **Sliding window / Line buffer** | Maintain k×k window over a stream with limited memory | 2D conv, Sobel, optical flow | 1 per cycle after fill; latency ~ window height | BRAM line buffers, shift registers; banked reads for taps |
| **Stencil (n-neighbor)** | Exchange with fixed neighborhood each step | PDEs, heat eq., cellular automata | O(radius) per step; 1/cycle steady | On-chip halos, torus wrap; time tiling |
| **Transpose / Blocked transpose** | Swap matrix axes with banked memory to avoid conflicts | Im2col, FFT stage reshapes, attention | Dependent on tile; 1/cycle if banks ≥ width | Multi-bank crossbars, address swizzles, ping-pong scratchpads |
| **Bit-reversal / Permuter** | Deterministic permutation of indices | FFT ordering, interleavers, Morton/Z-order | Pure reindex; 0 compute; mem-bound | Bit-reverse counters; butterfly-friendly strides; Benes/Clos networks for general perms |
| **Benes / Clos / Sorting networks** | Rearrangeable interconnect (O(N log N)) | General permutation, packet switch, radix sort | O(log N) stages; 1/cycle pipelined | 2×2 switches; route-compute vs preprogrammed patterns |
| **Barrel shifter / Rotator** | Variable shift/rotate in log steps | Align, normalization (FP), crypto | O(log W) stages | Multiplexer tree; mask-and-OR scheme |
| **CORDIC pipeline** | Iterative shift-add micro-rotations | sin/cos, atan2, vector/rot conversions | ~iterations stages; 1/cycle pipelined | Scale compensation constant; radix-4 variants |
| **Polyphase / Noble identities** | Split stream into phases to reduce rate before heavy ops | Multirate filters, channelizers | Smaller per-phase rate; steady 1/cycle per phase | Phase-bank FIRs, commutators, decimators/interpolators |
| **Merge / Bitonic / Odd-even sorters** | Fixed-pattern compare-exchange | Top-k, NMS, scheduler heaps | O(log²N) (bitonic) or O(N log N) depth | Compare-exchange cells; early-exit pruning |
| **Scatter/Gather streamers** | Bring non-contiguous data to contiguous compute | Sparse ops, attention K/V fetch | Latency dominated by memory | Coalescing DMA, request reordering, MSHRs |
| **Producer–consumer FIFOs** | Elastic decoupling with back-pressure | Any pipeline boundary | Adds queue latency; smooths bursts | Skid buffers, valid/ready; credit-based NoCs |
| **DMA tiling / Double buffering** | Overlap transfer with compute via ping-pong tiles | Any memory-bound kernel | Hide transfer latency | 2–3 buffers per tensor; prefetch + writeback streams |
| **Tree (fan-out)** | Broadcast then local ops | Winograd, BFS frontiers | O(log N) to fill; 1/cycle steady | Balanced buffer trees; clock-gating fanouts |

---

## Practical FPGA/ASIC Tips

- **Banking & addressing:** Derive strides to avoid n-way conflicts. Example: for FFT, bank = index[low bits], address = index[high bits] ⊕ stage_mask.  
- **Elasticity:** Wrap stage boundaries with `valid/ready` and small skid FIFOs.  
- **Pipelining:** Register at every adder/comparator or exchange stage for 1 result/cycle throughput.  
- **Arithmetic choice:** Use carry-save and compressors in reductions; DSP blocks for MACs; CORDIC if multipliers scarce.  
- **Tiling:** Tile to fit on-chip SRAM and overlap `prefetch → compute → writeback`.  
- **Deterministic control:** Encode as counters + ROM’d strides, not microcode (unless flexibility is required).

---
