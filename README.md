# Day 24 — 8×8 Register File Design and Verification

<p align="center">
  <b>Digital VLSI • Verilog RTL • Register File Architecture • Functional Verification • ASIC Synthesis</b>
</p>

<p align="center">
  <code>Specification → RTL → Testbench → Simulation → Synthesis → Technology Mapping → Area → Power → Timing → PPA Review</code>
</p>

<p align="center">
  <img alt="Project" src="https://img.shields.io/badge/Project-8%C3%978%20Register%20File-blue">
  <img alt="HDL" src="https://img.shields.io/badge/HDL-Verilog-8A2BE2">
  <img alt="Synthesis" src="https://img.shields.io/badge/Synthesis-Cadence%20Genus-orange">
  <img alt="Verification" src="https://img.shields.io/badge/Verification-292%20Checks%20%7C%200%20Errors-success">
</p>

---

## 1. Project Information

| Parameter | Details |
|---|---|
| **Project** | Day 24 — Register File Design and Verification |
| **Author** | Omkar Kalmesh Hadapad |
| **Domain** | Digital VLSI / RTL Design / Functional Verification |
| **Design Type** | Multi-register storage with dual asynchronous read ports |
| **HDL** | Verilog HDL |
| **Memory Configuration** | 8 words × 8 bits |
| **Storage Capacity** | 64 bits (8 bytes) |
| **Address Width** | 3 bits for eight register locations |
| **Data Width** | 8 bits |
| **Write Ports** | 1 synchronous write port |
| **Read Ports** | 2 asynchronous read ports |
| **Reset** | Active-high synchronous reset; reset takes priority over write |
| **Simulation Tool** | Cadence NCSim |
| **Synthesis Tool** | Cadence Genus 21.14-s082_1 |
| **Technology Library** | `tsmc18` |
| **Top Module** | `register_file_top` |
| **Reported Functional Checks** | 292 checks, 0 errors |
| **Simulation Completion** | `$finish` at 392 ns |
| **Mapped Standard-Cell Instances** | 314 |
| **Reported Cell Area** | 7328.059 library area units |
| **Estimated Total Power** | 529.367 µW |
| **Reported Setup Slack** | +6526 ps (6.526 ns) for the cited path |
| **Physical-Design Status** | Post-route PPA closure is not established by the available reports |

> **Measurement note:** The area unit is not explicitly confirmed by the supplied report context, so it is reported as *library area units*, not assumed to be µm². The power result is associated with activity frame `/stim#0/frame#0`. The cited setup path is a synthesis-stage timing result; it does not prove that every path meets timing or that post-route closure is complete.

---

## 2. Project Overview

A register file is a small, addressable bank of registers used to store data for a digital system. This project implements an 8-word × 8-bit register file with one synchronous write port and two asynchronous read ports.

The reported simulation checks reset behavior, register writes, data retention, read-port behavior, address coverage, data patterns, reset priority, and reading the same address from both read ports. The NCSim transcript reports **292 checks, zero errors, and a clean `$finish` at 392 ns**.

The project also includes Cadence Genus synthesis analysis: mapped cell count, cell-area distribution, hierarchy area, estimated power, and a setup timing path.

### Main design features

- Eight independently addressable 8-bit registers.
- One write interface controlled by `we`.
- Two read interfaces: `read_addr_a`/`read_data_a` and `read_addr_b`/`read_data_b`.
- Synchronous active-high reset.
- Reset priority over a simultaneous write request.
- Register-bank, decoder, and read-multiplexer hierarchy.
- Self-checking simulation and synthesis-stage PPA review.

---

## 3. Objectives

1. Understand register-file architecture and storage capacity.
2. Implement an 8 × 8 register bank.
3. Understand address decoding for a synchronous write.
4. Understand two independent asynchronous read ports.
5. Verify reset and reset-versus-write priority.
6. Verify data retention when write enable is inactive.
7. Verify address coverage for locations 0 through 7.
8. Exercise representative 8-bit data patterns.
9. Run a self-checking Verilog testbench in Cadence NCSim.
10. Inspect the design hierarchy and mapped standard cells.
11. Analyze total cell area and hierarchical area contribution.
12. Interpret internal, switching, and leakage power.
13. Calculate setup slack from the supplied timing path.
14. Identify what remains necessary for timing and physical-design closure.

---

## 4. Register File Architecture

### Conceptual block diagram

```text
                       register_file_top
                              |
             +----------------+----------------+
             |                |                |
             v                v                v
       Write interface   Read port A      Read port B
       we, write_addr    read_addr_a      read_addr_b
       write_data             |                |
             |                v                v
             v          +-----------+    +-----------+
       +-------------+  | Read mux  |    | Read mux  |
       | 3-to-8 write|  |   8-to-1  |    |   8-to-1  |
       | decoder     |  +-----+-----+    +-----+-----+
       +------+------+        |                |
              |               v                v
              v          read_data_a      read_data_b
       +-------------------------------------------+
       |       Register bank: 8 × 8-bit             |
       |   R0  R1  R2  R3  R4  R5  R6  R7           |
       +-------------------------------------------+
                    ^                 ^
                    |                 |
                   clk              reset
```

This is a conceptual diagram of the reported architecture. Exact connectivity and implementation details should be confirmed against the RTL and mapped netlist.

### Storage capacity

\[
8\ \text{words} \times 8\ \text{bits/word} = 64\ \text{bits}
\]

The address width required to select one of eight registers is:

\[
\lceil \log_2(8) \rceil = 3\ \text{bits}
\]

### Reported hierarchy

```text
register_file_top
├── u_read_mux_a       (read_mux_8x1)
├── u_read_mux_b       (read_mux_8x1_238)
└── u_register_bank    (register_bank_8x8)
    ├── GEN_REG[0..7].u_register (register_8bit)
    │   └── GEN_DFF[0..7].u_dff (dff_reset_enable)
    └── u_write_decoder (decoder_3to8)
```

### Hierarchy block summary

| Instance / module | Function indicated by the report |
|---|---|
| `register_file_top` | Top-level integration |
| `u_read_mux_a` | Read-port A, 8-to-1 selection |
| `u_read_mux_b` | Read-port B, 8-to-1 selection |
| `u_register_bank` | Eight 8-bit storage registers and write-control hierarchy |
| `GEN_REG[0..7].u_register` | One 8-bit register per generated register-bank entry |
| `GEN_DFF[0..7].u_dff` | D flip-flop/reset/enable implementation hierarchy |
| `u_write_decoder` | 3-to-8 write-address decoding |

The hierarchy names support the architecture summary, but the RTL and netlist remain the authoritative sources for exact signal connectivity and behavior.

---

## 5. Register File Operation

### Synchronous write

The write operation is controlled by the write enable and write address. The simulation specification states that reset is active-high and synchronous, with reset priority over write.

Conceptually, at the active clock edge:

```text
if reset:
    clear all register locations
else if we:
    register_bank[write_addr] = write_data
else:
    retain the previous contents
```

This pseudocode summarizes the reported behavior; consult the RTL for the exact implementation.

### Asynchronous reads

The testbench explicitly checks that changing a read address updates the corresponding read data without requiring a rising clock edge.

```text
read_addr_a ──► 8-to-1 read mux ──► read_data_a
read_addr_b ──► 8-to-1 read mux ──► read_data_b
```

Each read port selects one of the eight stored bytes. The two ports can select different addresses, or the same address, independently.

### Reset and write priority

| `reset` | `we` | At rising clock edge | Expected behavior |
|---:|---:|---|---|
| 1 | 0 | Yes | Clear the register bank |
| 1 | 1 | Yes | Reset takes priority; clear the bank |
| 0 | 1 | Yes | Write `write_data` to `write_addr` |
| 0 | 0 | Yes | Preserve stored contents |

The table reflects the behavior stated by the simulation specification.

---

## 6. Functional Verification

### NCSim regression result

| Metric | Reported result |
|---|---:|
| Checks performed | **292** |
| Errors detected | **0** |
| Final status | **PASS — ALL CHECKS PASSED** |
| Simulation completion | **392 ns** |
| Simulator termination | `$finish` |

### Tests reported by the transcript

| Test | Purpose | Reported result |
|---|---|---|
| T01 | Synchronous reset and full-bank scan | Pass |
| T02 | Write `0xA5` to address 2 | Pass |
| T03 | Write `0x3C` to address 5 | Pass |
| T04 | Disable writes and check data retention | Pass |
| T05 | Verify asynchronous dual reads without a rising edge | Pass |
| T06 | Exercise addresses 0 through 7 using values `0x10`–`0x17` | Pass |
| T07 | Exercise data patterns including `0x00`, `0xFF`, `0xA5`, and `0x3C` | Pass |
| T08 | Verify reset priority when `we=1` | Pass |
| T09 | Read the same address through both read ports | Pass |

### Representative checks from the log

- After writing `0xA5` to address 2, the register-bank scan reads back `0xA5`.
- After writing `0x3C` to address 5, the scan reads back `0x3C`.
- With write enable disabled, the existing values are retained.
- The read ports return the stored values when their addresses change without a rising clock edge.
- Address coverage exercises all eight register locations.
- The final regression summary reports 292 checks and zero errors.

### Verification limitations

The log establishes that the reported testbench checks passed. It does not by itself prove exhaustive correctness for every possible input sequence, formal equivalence, gate-level timing correctness, or silicon behavior.

For stronger verification, consider adding explicit tests for unknown (`X`) values, reset assertion/deassertion around clock edges, simultaneous write and read to the same address, repeated writes to one address, and any read-during-write behavior required by the design specification.

---

## 7. Genus Synthesis Results

The supplied Cadence Genus reports give the following top-level results.

| Metric | Reported value |
|---|---:|
| Top module | `register_file_top` |
| Mapped standard-cell instances | **314** |
| Total reported cell area | **7328.059 library area units** |
| Technology library | `tsmc18` |
| Synthesis tool | Cadence Genus 21.14-s082_1 |
| Timing clock period in cited path report | 10,000 ps (10 ns) |
| Cited setup slack | +6526 ps (6.526 ns) |

These are synthesis-report values. They should not be presented as post-route or extracted-parasitic results without the corresponding physical-design reports.

---

## 8. Standard-Cell Mapping and Area Analysis

### Cell breakdown

| Standard cell | Instances | Reported area |
|---|---:|---:|
| `AND2X2` | 8 | 106.445 |
| `AOI22X1` | 64 | 1064.448 |
| `DFFHQX1` | 64 | 3406.234 |
| `INVX1` | 4 | 26.611 |
| `MXI2X1` | 64 | 1490.227 |
| `NAND2BX1` | 5 | 66.528 |
| `NAND2X1` | 4 | 39.917 |
| `NAND4X1` | 16 | 266.112 |
| `NOR2BX1` | 4 | 53.222 |
| `NOR2X1` | 81 | 808.315 |
| **Total** | **314** | **7328.059** |

### Area by category

| Category | Reported area | Share of total |
|---|---:|---:|
| Sequential | 3406.234 | 46.5% |
| Inverter | 26.611 | 0.4% |
| Logic | 3895.214 | 53.2% |
| Physical cells | 0.000 | 0.0% |
| **Total** | **7328.059** | **100% approximately** |

### Interpretation

- The 64 reported `DFFHQX1` instances are consistent with 64 bits of storage for an 8 × 8 register file.
- Sequential cells account for approximately 46.5% of the reported cell area.
- Combinational logic accounts for approximately 53.2%, including address selection, write control, and read-multiplexer logic.
- `MXI2X1` and `AOI22X1` are prominent mapped cell categories; the exact logic role of each instance should be verified in the mapped netlist and library documentation.
- The area report describes mapped cell area. It is not a die-area or core-area report.

The reported category totals and individual cell rows may show small rounding differences because the report displays finite decimal precision.

---

## 9. Hierarchical Area Analysis

| Hierarchy block | Cell count | Reported area | Approximate share |
|---|---:|---:|---:|
| `register_file_top` | 314 | 7328.059 | 100.00% |
| `u_read_mux_a` | 53 | 804.989 | 10.98% |
| `u_read_mux_b` | 53 | 804.989 | 10.98% |
| `u_register_bank` | 208 | 5718.082 | 78.03% |
| Each `GEN_REG[i].u_register` | 24 | 691.891 | — |
| `u_write_decoder` | 16 | 182.952 | — |

### Main observations

- The register bank is the largest hierarchical block, at approximately **78.03%** of the total reported area.
- The two read multiplexers together account for approximately **21.96%** of total area.
- The write decoder is part of the register-bank hierarchy and should not be added again to the top-level total.
- Eight 8-bit register modules are reported under the register bank.

Parent and child hierarchy areas describe overlapping levels of the same design. Do not add them all together as independent blocks. Small last-digit differences between hierarchical totals can arise from displayed precision.

---

## 10. Power Analysis

The supplied power report is associated with:

```text
Instance: /register_file_top
Power Unit: W
PDB Frame: /stim#0/frame#0
```

### Power by category

| Category | Total power | Share |
|---|---:|---:|
| Register | 385.817 µW | 72.88% |
| Logic | 94.8414 µW | 17.92% |
| Clock | 48.7089 µW | 9.20% |
| **Total** | **529.367 µW** | **100% approximately** |

### Internal, switching and leakage power

| Component | Reported power | Share |
|---|---:|---:|
| Internal | 410.609 µW | 77.57% |
| Switching | 118.502 µW | 22.39% |
| Leakage | 0.255739 µW | 0.05% |
| **Total** | **529.367 µW** | **100% approximately** |

### Interpretation

- The reported register category is the largest contributor, at approximately 72.88% of total power.
- Internal power accounts for approximately 77.57% of the total estimate.
- Switching power depends on signal activity, capacitance, and the assumptions used by the power analysis.
- Leakage is a small fraction of the reported total.
- These values are associated with the stated activity frame and analysis setup. They should not be treated as measured silicon power or final post-route power.

For a meaningful comparison between RTL versions, keep the library, operating conditions, constraints, activity assumptions, and analysis settings consistent.

---

## 11. Setup Timing Analysis

The supplied setup timing report contains this path:

| Timing item | Reported value |
|---|---|
| Path status | **MET** |
| Startpoint | `write_addr[0]` |
| Endpoint | `u_register_bank/GEN_REG[6].u_register/GEN_DFF[7].u_dff/q_reg/D` |
| Clock period | 10,000 ps (10 ns) |
| Setup time | 323 ps |
| Clock uncertainty | 1000 ps |
| Input delay | 1000 ps |
| Data-path delay | 1151 ps |
| Arrival time | 2151 ps |
| Required time | 8677 ps |
| Slack | **+6526 ps (6.526 ns)** |

### Reported path stages

```text
write_addr[0]
    |
    v
NAND2BX1
    |
    v
NOR2X1   (reported cell delay 1045 ps, net delay 626 ps)
    |
    v
MXI2X1
    |
    v
NOR2X1
    |
    v
DFFHQX1 D input
```

### Slack calculation

The reported required time is:

\[
T_{\text{required}} = T_{\text{period}} - T_{\text{setup}} - T_{\text{uncertainty}}
\]

\[
= 10000 - 323 - 1000 = 8677\ \text{ps}
\]

The arrival time is:

\[
T_{\text{arrival}} = T_{\text{input delay}} + T_{\text{data path}}
\]

\[
= 1000 + 1151 = 2151\ \text{ps}
\]

Therefore:

\[
\text{Slack} = T_{\text{required}} - T_{\text{arrival}}
\]

\[
= 8677 - 2151 = 6526\ \text{ps} = 6.526\ \text{ns}
\]

### Timing interpretation

- The cited path is marked **MET** and has positive setup slack.
- The listed NOR2X1 stage with 1045 ps cell delay and 626 ps net delay is the largest reported stage contribution in this path.
- This is evidence for the cited path only. It does not establish that every setup and hold path is clean.
- The report uses synthesis-stage timing and a wireload-based context; it is not a substitute for placed-and-routed timing with extracted parasitics.

**Timing closure is not established for the complete physical design by this path alone.**

---

## 12. Recommended Verification and PPA Follow-Up

| Priority | Follow-up | Reason |
|---|---|---|
| 1 | Review simultaneous read/write to the same address | Clarify read-during-write semantics |
| 2 | Add explicit `X`/unknown-state checks | Detect uninitialized or invalid behavior |
| 3 | Check reset assertion and release around clock edges | Confirm synchronous-reset behavior |
| 4 | Inspect the mapped netlist and cell library | Confirm the function of mapped cells |
| 5 | Validate the SDC and all timing paths | A single MET path is not complete timing closure |
| 6 | Re-run power with documented activity and constraints | Make comparisons reproducible |
| 7 | Run physical implementation and extracted-parasitic analysis if available | Establish post-route area, timing, and power |

Optimization should preserve the required write behavior, read-port semantics, reset priority, and storage contents.

---

## 13. Overall Results Summary

| Metric | Result | Qualification |
|---|---|---|
| Functional simulation | **292 checks, 0 errors** | Reported NCSim testbench |
| Simulation completion | `$finish` at 392 ns | Shown in the transcript |
| Storage capacity | 64 bits | 8 words × 8 bits |
| Mapped cell count | 314 | Genus synthesis report |
| Reported cell area | 7328.059 area units | Physical unit not confirmed |
| Estimated total power | 529.367 µW | Activity-frame-based estimate |
| Largest hierarchy block | Register bank | 5718.082 area units |
| Largest power category | Register | 385.817 µW |
| Cited setup path | +6.526 ns slack | Path marked MET |
| Full setup/hold closure | Not established | All-path reports not supplied here |
| Post-route PPA closure | Not established | Physical implementation evidence not supplied |

---

## 14. Suggested Repository Structure

```text
day24-register-file/
├── README.md
├── rtl/
│   ├── register_file_top.v
│   ├── register_bank_8x8.v
│   ├── register_8bit.v
│   ├── dff_reset_enable.v
│   ├── decoder_3to8.v
│   └── read_mux_8x1.v
├── tb/
│   └── tb_register_file_top.v
├── sim/
│   ├── simulation.log
│   └── waves.shm/
├── genus/
│   ├── constraints.sdc
│   ├── reports/
│   │   ├── hierarchy.rpt
│   │   ├── area.rpt
│   │   ├── power.rpt
│   │   └── timing.rpt
│   ├── mapped_netlist.v
│   └── synthesis.log
└── docs/
    └── ppa_analysis.md
```

This is a suggested structure only. Keep files and paths that exist in the repository, and rename the examples to match the actual source files.

---

## 15. Industry Relevance

This project demonstrates concepts relevant to:

- Synthesizable Verilog RTL.
- Register-bank and register-file architecture.
- Address decoding and data selection.
- Synchronous write and asynchronous read behavior.
- Self-checking functional verification.
- Cadence NCSim simulation.
- Cadence Genus synthesis and technology mapping.
- Standard-cell area and hierarchy analysis.
- Power-report interpretation.
- Setup timing and slack calculation.
- Technical documentation and evidence-based PPA reporting.

These skills are relevant to entry-level RTL Design, ASIC Design, Design Verification, FPGA Design, and Digital VLSI roles.

---

## 16. Interview Questions

1. What is a register file, and where is it used?
2. What is the storage capacity of an 8 × 8 register file?
3. Why are three address bits sufficient to select eight registers?
4. What is the difference between synchronous write and asynchronous read?
5. What is the role of a 3-to-8 decoder?
6. How can two read ports access different register locations at the same time?
7. What should happen when reset and write enable are both asserted?
8. What is read-during-write behavior, and why should it be specified?
9. Why might synthesis map a register file into standard-cell flip-flops rather than a memory macro?
10. What does technology mapping do?
11. How is cell area different from core area?
12. What are internal, switching, and leakage power?
13. What does setup slack represent?
14. How is the reported 6.526 ns slack calculated?
15. Why does one MET timing path not prove complete timing closure?
16. What additional evidence is needed to claim post-route PPA closure?

---

## 17. Project Status

| Stage | Status |
|---|---|
| RTL/testbench regression | 292 checks, 0 errors reported |
| Simulation completion | Completed at 392 ns |
| Hierarchy report | Reviewed |
| Standard-cell area report | Reviewed |
| Hierarchical area report | Reviewed |
| Power report | Reviewed; activity assumptions should be documented |
| Cited setup timing path | MET, +6.526 ns slack |
| All-path setup/hold closure | Not established by the cited path alone |
| Post-route physical implementation | Not established |
| Final physical PPA closure | Pending further analysis |

---

## 18. Author

**Omkar Kalmesh Hadapad**  
Electronics and Communication Engineering

Digital VLSI • Verilog RTL • Functional Verification • Cadence Genus

---

<p align="center">
  <b>Day 24 — Register File Design, Functional Verification and Synthesis Analysis</b>
</p>
'''

out = Path("/mnt/data/README_Day24_Register_File_Clean.md")
pypandoc.convert_text(content, to="md", format="md", outputfile=str(out), extra_args=["--standalone"])
print(f"Created clean Markdown README: {out}")
print(f"Size: {out.stat().st_size:,} bytes")
from pathlib import Path

content = r'''# Day 24 — 8×8 Register File Design and Verification

<p align="center">
  <b>Digital VLSI • Verilog RTL • Register File Architecture • Functional Verification • ASIC Synthesis</b>
</p>

<p align="center">
  <code>Specification → RTL → Testbench → Simulation → Synthesis → Technology Mapping → Area → Power → Timing → PPA Review</code>
</p>

<p align="center">
  <img alt="Project" src="https://img.shields.io/badge/Project-8%C3%978%20Register%20File-blue">
  <img alt="HDL" src="https://img.shields.io/badge/HDL-Verilog-8A2BE2">
  <img alt="Synthesis" src="https://img.shields.io/badge/Synthesis-Cadence%20Genus-orange">
  <img alt="Verification" src="https://img.shields.io/badge/Verification-292%20Checks%20%7C%200%20Errors-success">
</p>

---

## 1. Project Information

| Parameter | Details |
|---|---|
| **Project** | Day 24 — Register File Design and Verification |
| **Author** | Omkar Kalmesh Hadapad |
| **Domain** | Digital VLSI / RTL Design / Functional Verification |
| **Design Type** | Multi-register storage with dual asynchronous read ports |
| **HDL** | Verilog HDL |
| **Memory Configuration** | 8 words × 8 bits |
| **Storage Capacity** | 64 bits (8 bytes) |
| **Address Width** | 3 bits for eight register locations |
| **Data Width** | 8 bits |
| **Write Ports** | 1 synchronous write port |
| **Read Ports** | 2 asynchronous read ports |
| **Reset** | Active-high synchronous reset; reset takes priority over write |
| **Simulation Tool** | Cadence NCSim |
| **Synthesis Tool** | Cadence Genus 21.14-s082_1 |
| **Technology Library** | `tsmc18` |
| **Top Module** | `register_file_top` |
| **Reported Functional Checks** | 292 checks, 0 errors |
| **Simulation Completion** | `$finish` at 392 ns |
| **Mapped Standard-Cell Instances** | 314 |
| **Reported Cell Area** | 7328.059 library area units |
| **Estimated Total Power** | 529.367 µW |
| **Reported Setup Slack** | +6526 ps (6.526 ns) for the cited path |
| **Physical-Design Status** | Post-route PPA closure is not established by the available reports |

> **Measurement note:** The area unit is not explicitly confirmed by the supplied report context, so it is reported as *library area units*, not assumed to be µm². The power result is associated with activity frame `/stim#0/frame#0`. The cited setup path is a synthesis-stage timing result; it does not prove that every path meets timing or that post-route closure is complete.

---

## 2. Project Overview

A register file is a small, addressable bank of registers used to store data for a digital system. This project implements an 8-word × 8-bit register file with one synchronous write port and two asynchronous read ports.

The reported simulation checks reset behavior, register writes, data retention, read-port behavior, address coverage, data patterns, reset priority, and reading the same address from both read ports. The NCSim transcript reports **292 checks, zero errors, and a clean `$finish` at 392 ns**.

The project also includes Cadence Genus synthesis analysis: mapped cell count, cell-area distribution, hierarchy area, estimated power, and a setup timing path.

### Main design features

- Eight independently addressable 8-bit registers.
- One write interface controlled by `we`.
- Two read interfaces: `read_addr_a`/`read_data_a` and `read_addr_b`/`read_data_b`.
- Synchronous active-high reset.
- Reset priority over a simultaneous write request.
- Register-bank, decoder, and read-multiplexer hierarchy.
- Self-checking simulation and synthesis-stage PPA review.

---

## 3. Objectives

1. Understand register-file architecture and storage capacity.
2. Implement an 8 × 8 register bank.
3. Understand address decoding for a synchronous write.
4. Understand two independent asynchronous read ports.
5. Verify reset and reset-versus-write priority.
6. Verify data retention when write enable is inactive.
7. Verify address coverage for locations 0 through 7.
8. Exercise representative 8-bit data patterns.
9. Run a self-checking Verilog testbench in Cadence NCSim.
10. Inspect the design hierarchy and mapped standard cells.
11. Analyze total cell area and hierarchical area contribution.
12. Interpret internal, switching, and leakage power.
13. Calculate setup slack from the supplied timing path.
14. Identify what remains necessary for timing and physical-design closure.

---

## 4. Register File Architecture

### Conceptual block diagram

```text
                       register_file_top
                              |
             +----------------+----------------+
             |                |                |
             v                v                v
       Write interface   Read port A      Read port B
       we, write_addr    read_addr_a      read_addr_b
       write_data             |                |
             |                v                v
             v          +-----------+    +-----------+
       +-------------+  | Read mux  |    | Read mux  |
       | 3-to-8 write|  |   8-to-1  |    |   8-to-1  |
       | decoder     |  +-----+-----+    +-----+-----+
       +------+------+        |                |
              |               v                v
              v          read_data_a      read_data_b
       +-------------------------------------------+
       |       Register bank: 8 × 8-bit             |
       |   R0  R1  R2  R3  R4  R5  R6  R7           |
       +-------------------------------------------+
                    ^                 ^
                    |                 |
                   clk              reset
```

This is a conceptual diagram of the reported architecture. Exact connectivity and implementation details should be confirmed against the RTL and mapped netlist.

### Storage capacity

\[
8\ \text{words} \times 8\ \text{bits/word} = 64\ \text{bits}
\]

The address width required to select one of eight registers is:

\[
\lceil \log_2(8) \rceil = 3\ \text{bits}
\]

### Reported hierarchy

```text
register_file_top
├── u_read_mux_a       (read_mux_8x1)
├── u_read_mux_b       (read_mux_8x1_238)
└── u_register_bank    (register_bank_8x8)
    ├── GEN_REG[0..7].u_register (register_8bit)
    │   └── GEN_DFF[0..7].u_dff (dff_reset_enable)
    └── u_write_decoder (decoder_3to8)
```

### Hierarchy block summary

| Instance / module | Function indicated by the report |
|---|---|
| `register_file_top` | Top-level integration |
| `u_read_mux_a` | Read-port A, 8-to-1 selection |
| `u_read_mux_b` | Read-port B, 8-to-1 selection |
| `u_register_bank` | Eight 8-bit storage registers and write-control hierarchy |
| `GEN_REG[0..7].u_register` | One 8-bit register per generated register-bank entry |
| `GEN_DFF[0..7].u_dff` | D flip-flop/reset/enable implementation hierarchy |
| `u_write_decoder` | 3-to-8 write-address decoding |

The hierarchy names support the architecture summary, but the RTL and netlist remain the authoritative sources for exact signal connectivity and behavior.

---

## 5. Register File Operation

### Synchronous write

The write operation is controlled by the write enable and write address. The simulation specification states that reset is active-high and synchronous, with reset priority over write.

Conceptually, at the active clock edge:

```text
if reset:
    clear all register locations
else if we:
    register_bank[write_addr] = write_data
else:
    retain the previous contents
```

This pseudocode summarizes the reported behavior; consult the RTL for the exact implementation.

### Asynchronous reads

The testbench explicitly checks that changing a read address updates the corresponding read data without requiring a rising clock edge.

```text
read_addr_a ──► 8-to-1 read mux ──► read_data_a
read_addr_b ──► 8-to-1 read mux ──► read_data_b
```

Each read port selects one of the eight stored bytes. The two ports can select different addresses, or the same address, independently.

### Reset and write priority

| `reset` | `we` | At rising clock edge | Expected behavior |
|---:|---:|---|---|
| 1 | 0 | Yes | Clear the register bank |
| 1 | 1 | Yes | Reset takes priority; clear the bank |
| 0 | 1 | Yes | Write `write_data` to `write_addr` |
| 0 | 0 | Yes | Preserve stored contents |

The table reflects the behavior stated by the simulation specification.

---

## 6. Functional Verification

### NCSim regression result

| Metric | Reported result |
|---|---:|
| Checks performed | **292** |
| Errors detected | **0** |
| Final status | **PASS — ALL CHECKS PASSED** |
| Simulation completion | **392 ns** |
| Simulator termination | `$finish` |

### Tests reported by the transcript

| Test | Purpose | Reported result |
|---|---|---|
| T01 | Synchronous reset and full-bank scan | Pass |
| T02 | Write `0xA5` to address 2 | Pass |
| T03 | Write `0x3C` to address 5 | Pass |
| T04 | Disable writes and check data retention | Pass |
| T05 | Verify asynchronous dual reads without a rising edge | Pass |
| T06 | Exercise addresses 0 through 7 using values `0x10`–`0x17` | Pass |
| T07 | Exercise data patterns including `0x00`, `0xFF`, `0xA5`, and `0x3C` | Pass |
| T08 | Verify reset priority when `we=1` | Pass |
| T09 | Read the same address through both read ports | Pass |

### Representative checks from the log

- After writing `0xA5` to address 2, the register-bank scan reads back `0xA5`.
- After writing `0x3C` to address 5, the scan reads back `0x3C`.
- With write enable disabled, the existing values are retained.
- The read ports return the stored values when their addresses change without a rising clock edge.
- Address coverage exercises all eight register locations.
- The final regression summary reports 292 checks and zero errors.

### Verification limitations

The log establishes that the reported testbench checks passed. It does not by itself prove exhaustive correctness for every possible input sequence, formal equivalence, gate-level timing correctness, or silicon behavior.

For stronger verification, consider adding explicit tests for unknown (`X`) values, reset assertion/deassertion around clock edges, simultaneous write and read to the same address, repeated writes to one address, and any read-during-write behavior required by the design specification.

---

## 7. Genus Synthesis Results

The supplied Cadence Genus reports give the following top-level results.

| Metric | Reported value |
|---|---:|
| Top module | `register_file_top` |
| Mapped standard-cell instances | **314** |
| Total reported cell area | **7328.059 library area units** |
| Technology library | `tsmc18` |
| Synthesis tool | Cadence Genus 21.14-s082_1 |
| Timing clock period in cited path report | 10,000 ps (10 ns) |
| Cited setup slack | +6526 ps (6.526 ns) |

These are synthesis-report values. They should not be presented as post-route or extracted-parasitic results without the corresponding physical-design reports.

---

## 8. Standard-Cell Mapping and Area Analysis

### Cell breakdown

| Standard cell | Instances | Reported area |
|---|---:|---:|
| `AND2X2` | 8 | 106.445 |
| `AOI22X1` | 64 | 1064.448 |
| `DFFHQX1` | 64 | 3406.234 |
| `INVX1` | 4 | 26.611 |
| `MXI2X1` | 64 | 1490.227 |
| `NAND2BX1` | 5 | 66.528 |
| `NAND2X1` | 4 | 39.917 |
| `NAND4X1` | 16 | 266.112 |
| `NOR2BX1` | 4 | 53.222 |
| `NOR2X1` | 81 | 808.315 |
| **Total** | **314** | **7328.059** |

### Area by category

| Category | Reported area | Share of total |
|---|---:|---:|
| Sequential | 3406.234 | 46.5% |
| Inverter | 26.611 | 0.4% |
| Logic | 3895.214 | 53.2% |
| Physical cells | 0.000 | 0.0% |
| **Total** | **7328.059** | **100% approximately** |

### Interpretation

- The 64 reported `DFFHQX1` instances are consistent with 64 bits of storage for an 8 × 8 register file.
- Sequential cells account for approximately 46.5% of the reported cell area.
- Combinational logic accounts for approximately 53.2%, including address selection, write control, and read-multiplexer logic.
- `MXI2X1` and `AOI22X1` are prominent mapped cell categories; the exact logic role of each instance should be verified in the mapped netlist and library documentation.
- The area report describes mapped cell area. It is not a die-area or core-area report.

The reported category totals and individual cell rows may show small rounding differences because the report displays finite decimal precision.

---

## 9. Hierarchical Area Analysis

| Hierarchy block | Cell count | Reported area | Approximate share |
|---|---:|---:|---:|
| `register_file_top` | 314 | 7328.059 | 100.00% |
| `u_read_mux_a` | 53 | 804.989 | 10.98% |
| `u_read_mux_b` | 53 | 804.989 | 10.98% |
| `u_register_bank` | 208 | 5718.082 | 78.03% |
| Each `GEN_REG[i].u_register` | 24 | 691.891 | — |
| `u_write_decoder` | 16 | 182.952 | — |

### Main observations

- The register bank is the largest hierarchical block, at approximately **78.03%** of the total reported area.
- The two read multiplexers together account for approximately **21.96%** of total area.
- The write decoder is part of the register-bank hierarchy and should not be added again to the top-level total.
- Eight 8-bit register modules are reported under the register bank.

Parent and child hierarchy areas describe overlapping levels of the same design. Do not add them all together as independent blocks. Small last-digit differences between hierarchical totals can arise from displayed precision.

---

## 10. Power Analysis

The supplied power report is associated with:

```text
Instance: /register_file_top
Power Unit: W
PDB Frame: /stim#0/frame#0
```

### Power by category

| Category | Total power | Share |
|---|---:|---:|
| Register | 385.817 µW | 72.88% |
| Logic | 94.8414 µW | 17.92% |
| Clock | 48.7089 µW | 9.20% |
| **Total** | **529.367 µW** | **100% approximately** |

### Internal, switching and leakage power

| Component | Reported power | Share |
|---|---:|---:|
| Internal | 410.609 µW | 77.57% |
| Switching | 118.502 µW | 22.39% |
| Leakage | 0.255739 µW | 0.05% |
| **Total** | **529.367 µW** | **100% approximately** |

### Interpretation

- The reported register category is the largest contributor, at approximately 72.88% of total power.
- Internal power accounts for approximately 77.57% of the total estimate.
- Switching power depends on signal activity, capacitance, and the assumptions used by the power analysis.
- Leakage is a small fraction of the reported total.
- These values are associated with the stated activity frame and analysis setup. They should not be treated as measured silicon power or final post-route power.

For a meaningful comparison between RTL versions, keep the library, operating conditions, constraints, activity assumptions, and analysis settings consistent.

---

## 11. Setup Timing Analysis

The supplied setup timing report contains this path:

| Timing item | Reported value |
|---|---|
| Path status | **MET** |
| Startpoint | `write_addr[0]` |
| Endpoint | `u_register_bank/GEN_REG[6].u_register/GEN_DFF[7].u_dff/q_reg/D` |
| Clock period | 10,000 ps (10 ns) |
| Setup time | 323 ps |
| Clock uncertainty | 1000 ps |
| Input delay | 1000 ps |
| Data-path delay | 1151 ps |
| Arrival time | 2151 ps |
| Required time | 8677 ps |
| Slack | **+6526 ps (6.526 ns)** |

### Reported path stages

```text
write_addr[0]
    |
    v
NAND2BX1
    |
    v
NOR2X1   (reported cell delay 1045 ps, net delay 626 ps)
    |
    v
MXI2X1
    |
    v
NOR2X1
    |
    v
DFFHQX1 D input
```

### Slack calculation

The reported required time is:

\[
T_{\text{required}} = T_{\text{period}} - T_{\text{setup}} - T_{\text{uncertainty}}
\]

\[
= 10000 - 323 - 1000 = 8677\ \text{ps}
\]

The arrival time is:

\[
T_{\text{arrival}} = T_{\text{input delay}} + T_{\text{data path}}
\]

\[
= 1000 + 1151 = 2151\ \text{ps}
\]

Therefore:

\[
\text{Slack} = T_{\text{required}} - T_{\text{arrival}}
\]

\[
= 8677 - 2151 = 6526\ \text{ps} = 6.526\ \text{ns}
\]

### Timing interpretation

- The cited path is marked **MET** and has positive setup slack.
- The listed NOR2X1 stage with 1045 ps cell delay and 626 ps net delay is the largest reported stage contribution in this path.
- This is evidence for the cited path only. It does not establish that every setup and hold path is clean.
- The report uses synthesis-stage timing and a wireload-based context; it is not a substitute for placed-and-routed timing with extracted parasitics.

**Timing closure is not established for the complete physical design by this path alone.**

---

## 12. Recommended Verification and PPA Follow-Up

| Priority | Follow-up | Reason |
|---|---|---|
| 1 | Review simultaneous read/write to the same address | Clarify read-during-write semantics |
| 2 | Add explicit `X`/unknown-state checks | Detect uninitialized or invalid behavior |
| 3 | Check reset assertion and release around clock edges | Confirm synchronous-reset behavior |
| 4 | Inspect the mapped netlist and cell library | Confirm the function of mapped cells |
| 5 | Validate the SDC and all timing paths | A single MET path is not complete timing closure |
| 6 | Re-run power with documented activity and constraints | Make comparisons reproducible |
| 7 | Run physical implementation and extracted-parasitic analysis if available | Establish post-route area, timing, and power |

Optimization should preserve the required write behavior, read-port semantics, reset priority, and storage contents.

---

## 13. Overall Results Summary

| Metric | Result | Qualification |
|---|---|---|
| Functional simulation | **292 checks, 0 errors** | Reported NCSim testbench |
| Simulation completion | `$finish` at 392 ns | Shown in the transcript |
| Storage capacity | 64 bits | 8 words × 8 bits |
| Mapped cell count | 314 | Genus synthesis report |
| Reported cell area | 7328.059 area units | Physical unit not confirmed |
| Estimated total power | 529.367 µW | Activity-frame-based estimate |
| Largest hierarchy block | Register bank | 5718.082 area units |
| Largest power category | Register | 385.817 µW |
| Cited setup path | +6.526 ns slack | Path marked MET |
| Full setup/hold closure | Not established | All-path reports not supplied here |
| Post-route PPA closure | Not established | Physical implementation evidence not supplied |

---

## 14. Suggested Repository Structure

```text
day24-register-file/
├── README.md
├── rtl/
│   ├── register_file_top.v
│   ├── register_bank_8x8.v
│   ├── register_8bit.v
│   ├── dff_reset_enable.v
│   ├── decoder_3to8.v
│   └── read_mux_8x1.v
├── tb/
│   └── tb_register_file_top.v
├── sim/
│   ├── simulation.log
│   └── waves.shm/
├── genus/
│   ├── constraints.sdc
│   ├── reports/
│   │   ├── hierarchy.rpt
│   │   ├── area.rpt
│   │   ├── power.rpt
│   │   └── timing.rpt
│   ├── mapped_netlist.v
│   └── synthesis.log
└── docs/
    └── ppa_analysis.md
```

This is a suggested structure only. Keep files and paths that exist in the repository, and rename the examples to match the actual source files.

---

## 15. Industry Relevance

This project demonstrates concepts relevant to:

- Synthesizable Verilog RTL.
- Register-bank and register-file architecture.
- Address decoding and data selection.
- Synchronous write and asynchronous read behavior.
- Self-checking functional verification.
- Cadence NCSim simulation.
- Cadence Genus synthesis and technology mapping.
- Standard-cell area and hierarchy analysis.
- Power-report interpretation.
- Setup timing and slack calculation.
- Technical documentation and evidence-based PPA reporting.

These skills are relevant to entry-level RTL Design, ASIC Design, Design Verification, FPGA Design, and Digital VLSI roles.

---

## 16. Interview Questions

1. What is a register file, and where is it used?
2. What is the storage capacity of an 8 × 8 register file?
3. Why are three address bits sufficient to select eight registers?
4. What is the difference between synchronous write and asynchronous read?
5. What is the role of a 3-to-8 decoder?
6. How can two read ports access different register locations at the same time?
7. What should happen when reset and write enable are both asserted?
8. What is read-during-write behavior, and why should it be specified?
9. Why might synthesis map a register file into standard-cell flip-flops rather than a memory macro?
10. What does technology mapping do?
11. How is cell area different from core area?
12. What are internal, switching, and leakage power?
13. What does setup slack represent?
14. How is the reported 6.526 ns slack calculated?
15. Why does one MET timing path not prove complete timing closure?
16. What additional evidence is needed to claim post-route PPA closure?

---

## 17. Project Status

| Stage | Status |
|---|---|
| RTL/testbench regression | 292 checks, 0 errors reported |
| Simulation completion | Completed at 392 ns |
| Hierarchy report | Reviewed |
| Standard-cell area report | Reviewed |
| Hierarchical area report | Reviewed |
| Power report | Reviewed; activity assumptions should be documented |
| Cited setup timing path | MET, +6.526 ns slack |
| All-path setup/hold closure | Not established by the cited path alone |
| Post-route physical implementation | Not established |
| Final physical PPA closure | Pending further analysis |

---

## 18. Author

**Omkar Kalmesh Hadapad**  
Electronics and Communication Engineering

Digital VLSI • Verilog RTL • Functional Verification • Cadence Genus

---

<p align="center">
  <b>Day 24 — Register File Design, Functional Verification and Synthesis Analysis</b>
</p>
'''
