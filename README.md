# 3-Way Superscalar Out-of-Order Processor in R10K Architecture

We implemented the Out-of-Order R10K processor based on VeriSimpleV RISC-V. It utilizes a 3-Way Superscalar architecture, which allows it to manage up to three instructions in each of the fetch, dispatch, complete, and retire stages simultaneously. This allows the processor to significantly improve its performance and increase the speed at which it can complete tasks. Additionally, our R10K processor includes out-of-order execution and capabilities, further improving its ability to execute instructions efficiently.

The motivation for R10K over P6 is that we would like to achieve fast implementation and avoid the memory overhead of copy-based register renaming like P6. Meanwhile, to compensate for the strain on the main memory, we integrate Store Queue, I-Cache, and D-Cache, into our memory hierarchy. To the best of our knowledge, this design has the potential to improve performance and efficiency significantly.
