# Next milestones

## Completed: establish the hardware/software path

- Install a working WSL toolchain and retain reproducible setup/build commands.
- Pin and credit PicoRV32; compile and execute bare-metal RV32I C firmware.
- Implement and integrate a synthesizable signed INT8 DOT4 instruction.
- Test arithmetic, decode, handshake, reset, illegal instructions, and memory stalls.
- Collect cycle/instruction counts and a generic synthesis report.

## Next: integer neural-network reference

1. Add project-local pinned Python ML dependencies.
2. Load sklearn digits and establish deterministic, stratified train/validation/test splits.
3. Train the agreed 64-input, 16-hidden-unit, 10-class ReLU MLP.
4. Specify symmetric INT8 weights/activations, INT32 bias/accumulation, scales,
   rounding, and saturation. Calibrate using training/validation data only.
5. Implement an integer reference, measure held-out float and quantized accuracy,
   and export weights, scales, inputs, labels, and golden intermediate activations.

## Then: processor inference and controlled evaluation

1. Implement scalar inference and match every layer to the integer reference.
2. Replace dot-product loops with DOT4 and validate exact integer equivalence.
3. Measure both complete inference and individual kernels on identical inputs.
4. Tune the scalar baseline and include an RV32IM hardware-multiply comparison.
5. Measure and report packing, memory, bias, activation, and quantization overhead.
6. Add waveform tracing and/or cocotb as needed for broader integration tests.
7. Synthesize baseline and accelerated configurations under an explicit target
   before reporting incremental resource use. Timing/power remain separate work.

## Presentation after inference is verified

Create a short reproducible demo and report accuracy, cycles per inference,
instructions, tested sample count, and the precisely named baseline. Write resume
bullets only from those measured results. FPGA deployment is optional future work.
