# AXI4 UVM Verification Environment

## Overview

This project is a SystemVerilog/UVM verification environment built to exercise and self-check **AXI4 protocol** read and write burst transactions. It was developed to practice building a complete, layered UVM testbench: transaction modeling, constrained-random sequence generation, driver/monitor implementation, a self-checking scoreboard, and functional coverage — the core skill set of a VLSI Design Verification engineer.

**Important note on scope:** This repository does **not** include a synthesizable AXI4 slave RTL design. Instead, the "slave side" of the environment (`s_resp.sv`) is a signal-level reactive response model that behaves like an AXI4 slave (accepts write/read addresses, applies FIXED/INCR/WRAP address stepping, stores/returns byte-addressable memory data). This lets the full master-side UVM environment (sequences, driver, monitor, scoreboard, coverage) be built and exercised end-to-end without a DUT. If you intend to verify actual RTL, replace `s_resp.sv` with your DUT and connect it to the same `intf` interface.

## Features

- Constrained-random AXI4 transaction generation (`axi_tx`) covering write/read direction, burst type, burst length, burst size, address, data, and write-strobes
- Master-side active agent (sequencer + driver) driving all five AXI4 channels (AW, W, B, AR, R)
- Reactive slave response model supporting FIXED, INCR, and WRAP burst addressing
- Single global monitor observing write and read transactions independently
- Self-checking scoreboard comparing written data against subsequent reads
- Functional coverage with 5 coverpoints and 3 cross-coverage groups, split into separate write/read coverage instances
- 7 test scenarios exercising single writes, burst writes, write-then-read, shuffled ordering, and fixed/wrap burst types

## Protocol / Design Details

The environment models the **AXI4** protocol's five channels:

| Channel | Signals |
|---|---|
| Write Address (AW) | `awvalid`, `awready`, `awid`, `awaddr`, `awlen`, `awsize`, `awburst` |
| Write Data (W) | `wvalid`, `wready`, `wid`, `wdata`, `wstrb`, `wlast` |
| Write Response (B) | `bvalid`, `bready`, `bid`, `bresp` |
| Read Address (AR) | `arvalid`, `arready`, `arid`, `araddr`, `arlen`, `arsize`, `arburst` |
| Read Data (R) | `rvalid`, `rready`, `rid`, `rdata`, `rlast`, `rresp` |

Supported burst types: `FIXED`, `INCR`, `WRAP` (`RSVD` is excluded by constraint). Data width and address width are both 32 bits (`DATA_WIDTH`, `ADDR_WIDTH` in `common.sv`), with strobe width derived as `DATA_WIDTH/8`.

Key transaction constraints (`axi_tx.sv`):
- `dataQ` size matches `burst_len + 1` for writes, empty for reads (populated by driver from that queue)
- `strbQ` sized to `burst_len + 1`, softly defaulting to a full-width strobe
- WRAP bursts constrained to lengths `{1, 3, 7, 15}` and address alignment to the transfer size
- `burst_size` constrained to `$clog2(DATA_WIDTH/8)` (fixed to the full bus width in this environment)

## Verification Methodology

Built entirely in UVM (1.2, per `run.do`) using the standard factory and TLM connections:

- **Transaction (`axi_tx`):** `uvm_sequence_item` with `uvm_field_*` macros for automation (print, copy, compare)
- **Sequences (`m_seq`, `m_seq1`–`m_seq7`):** derived from a common base sequence, each modeling a distinct traffic pattern
- **Sequencer (`m_sqr`):** a `uvm_sequencer#(axi_tx)` typedef
- **Master Agent (`m_agent`):** active agent instantiating sequencer and driver, connected via `seq_item_port`
- **Master Driver (`m_drv`):** drives AW/W/B (write) or AR/R (read) channels cycle-by-cycle onto the virtual interface, pulled via `uvm_config_db`
- **Slave Agent (`s_agent`):** wraps the reactive slave response model
- **Slave Response Model (`s_resp`):** `uvm_component` reacting to AW/AR handshakes, applying FIXED/INCR/WRAP address stepping and returning write responses / read data
- **Monitor (`axi_mon`):** samples both write and read channels independently (`fork...join`) and broadcasts observed transactions on two analysis ports (`wr_ap`, `rd_ap`)
- **Scoreboard (`axi_sbd`):** `uvm_scoreboard` with `uvm_analysis_imp` write/read implementations; stores write data in an associative memory array and compares against subsequent reads, tracking match/mismatch counts and reporting pass/fail in `check_phase`
- **Coverage (`axi_cov`):** `uvm_subscriber#(axi_tx)`; two separate instances (`wr_cov`, `rd_cov`) are connected to the monitor's write and read analysis ports respectively
- **Environment (`env`):** instantiates and connects all of the above via `connect_phase`
- **Tests (`test`, `test1`–`test7`):** base test builds the environment; each derived test starts one sequence on the master sequencer

Component and object registration uses `uvm_component_utils` / `uvm_object_utils`, and constructors are standardized via the `NEW_COMP` / `NEW_OBJ` macros in `common.sv`.

## Testbench Architecture
