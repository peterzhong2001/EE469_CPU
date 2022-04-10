# EE469_CPU

This is a 5-stage pipelined CPU implementing the 32-bit ARMv8 ISA. 

The datapath of the CPU is written only in structural Verilog. The CPU handles load/branch instructions with a delay slot.

The top-level module is "pipelined_cpu.sv". The data memory and instruction memory modules are ideal models provided by the course.
