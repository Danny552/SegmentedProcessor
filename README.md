# SegmentedProcessor

A 5-stage pipelined RISC-V-style processor written in SystemVerilog for an Intel/Altera **Cyclone V (DE0-CV)** FPGA, with a built-in **VGA debug monitor** that lets you watch the pipeline think.


### What it's about

A project for the **Computer Architecture** class. The goal wasn't just to make a processor execute instructions, but to be able to *watch* it do so: instead of relying only on the simulator, the design draws the state of every pipeline stage, the registers, and memory on a VGA screen while it runs on the board.

### Architecture

A classic five-stage pipeline, with the inter-stage registers in their own files:

```
 IF ──▶ InFe_InDe ──▶ ID ──▶ InDe_EX ──▶ EX ──▶ EX_MEM ──▶ MEM ──▶ MEM_WrBa ──▶ WB
```

| Module | What it does |
|---|---|
| `cpu_top.sv` | Wires everything together: stages, hazard logic, debug, and VGA |
| `pc.sv`, `instruction_memory.sv` | Program counter and instruction memory |
| `control_unit.sv`, `imm_generator.sv`, `register_unit.sv` | Decoding, immediates, and register file |
| `alu.sv`, `branch_unit.sv` | Arithmetic/logic operations and branch resolution |
| `ForwardUnit.sv` | Forwarding from EX/MEM and MEM/WB into EX |
| `HazardUnit.sv` | Load-use hazard detection: freezes PC and IF/ID and inserts a bubble |
| `InFe_InDe.sv`, `InDe_EX_reg.sv`, `EX_MEM.sv`, `MEM_WrBa.sv` | Pipeline registers |
| `font_rom.sv`, `font_renderer.sv`, `font8x16.hex`, `color.sv` | On-screen text using an 8×16 font |
| `hex7seg.sv` | 7-segment displays |
| `top_level.sv` | Top-level module synthesized onto the board |

**Design decisions worth knowing about:**

- **Branches resolve in EX.** When a branch, `jal`, or `jalr` is taken, IF/ID and ID/EX are flushed.
- **`ebreak` halts the pipeline.** Once it reaches WB, the PC and all pipeline registers freeze, so the final state stays visible on screen.
- **Selectable clock.** Switch `SW3` chooses between the manual `clk` (for single-stepping) and the 50 MHz clock.
- **Word-wide data memory access:** `funct3` is hard-wired to `3'b010` in the MEM stage.

### On-board debugging

**7-segment displays** (show the low 16 bits of the selected value):

| `SW2 SW1 SW0` | Value shown |
|---|---|
| `000` | Instruction in ID |
| `001` | ALU result (EX) |
| `010` | Memory read data (MEM) |
| `100` | Write-back data (WB) |

**LEDs**, left to right: `pc_write_enable`, `hazard_mux_sel`, `pc_src`, `jalr in EX`, `forward A active`, `forward B active`, (two unused), `ebreak in WB`.

**VGA monitor:** shows PC and instruction in IF and ID, the register values read and the immediate, stall status, ALU result and whether the branch was taken, forwarding A/B, MEM and WB data, the register file, a 128-byte window of data memory, and the instruction memory.

### Build and program

You need **Intel Quartus Prime** (with `quartus_sh` and `quartus_pgm` on your `PATH`), `make`, and a **DE0-CV** board connected over USB. The flow is automated with TCL scripts:

```bash
make build            # compile the project (riscvpc) → output_files/riscvpc.sof
make program          # program the FPGA with the existing .sof
make build-program    # both of the above in one step
make status           # check whether the .sof exists
make clean            # remove db/, incremental_db/, output_files/, and reports
make help             # list all targets
```

> ⚠️ The `program-direct` target uses the cable name `"DE-Soc"`. If your programmer shows up under a different name (on the DE0-CV it's usually a *USB-Blaster*), find it with `jtagconfig` and update the `Makefile`.

### Test programs

- `program.bin` / `output.bin`: program binaries.
- `memory.hex` and `data_init.hex`: initial contents of the instruction and data memories.

### Author

**Daniel Alejandro Henao** ([@Danny552](https://github.com/Danny552))
