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

          m_seq1..m_seq7
                │
                ▼
          m_sqr (sequencer)
                │  seq_item_port / seq_item_export
                ▼
            m_drv (driver)
                │  drives AW/W/B or AR/R
                ▼
         ┌───────────────┐
         │  intf (AXI4)  │◄──────────────┐
         └───────────────┘               │
                │                        │
                ▼                        │
         s_resp (slave response model)   │
                                         │
                axi_mon (monitor) ───────┘
                │           │
          wr_ap │           │ rd_ap
                ▼           ▼
      ┌─────────────┐ ┌─────────────┐
      │  axi_sbd    │ │ wr_cov/rd_cov│
      │(scoreboard) │ │  (coverage)  │
      └─────────────┘ └─────────────┘

Data flow: **Sequence → Sequencer → Driver → Interface → Slave Response Model**, with the **Monitor** independently observing the interface and fanning transactions out to the **Scoreboard** and **Functional Coverage**.

## Test Scenarios

| Test | Sequence | Purpose | Stimulus | Expected Result |
|---|---|---|---|---|
| `test1` | `m_seq1` | Basic sanity | 1 randomized write | Write completes; no read is issued, so the scoreboard is not exercised in this test |
| `test2` | `m_seq2` | Burst write stress | 5 randomized writes | All 5 writes complete without protocol stall |
| `test3` | `m_seq3` | Write-then-read data integrity | 5 randomized writes (cloned and queued), followed by 5 reads targeting the same addresses | Scoreboard reports matching data for each read |
| `test4` | `m_seq4` | Parameterized write/read (count = `` `N ``, currently 1) | `` `N `` writes, then `` `N `` reads to the same addresses, in order | Scoreboard match count increments accordingly |
| `test5` | `m_seq5` | Out-of-program-order read | Same as `test4`, but the write queue is shuffled before reads are issued | Scoreboard must still match reads against the correct (shuffled) write addresses |
| `test6` | `m_seq6` | FIXED burst addressing | `` `N `` writes/reads constrained to `burst_type == FIXED` | Address does not increment across beats; data matches |
| `test7` | `m_seq7` | WRAP burst addressing | `` `N `` writes/reads constrained to `burst_type == WRAP` | Address wraps at the burst boundary; **see Known Limitations** below regarding scoreboard address tracking for WRAP |

`top.sv` runs **`test6`** by default (`run_test("test6")`), with the other test names commented for manual selection.

## Assertions

No SystemVerilog Assertions (SVA) are present in the current files. This is listed under **Future Improvements** below — candidates would include AXI4 handshake stability checks (e.g., `valid` held until `ready`), one-hot/legal burst-type checks, and `wlast`/`rlast` alignment with burst length.

## Functional Coverage

Implemented in `cov.sv` via a `uvm_subscriber#(axi_tx)` sampling a covergroup on every transaction:

```systemverilog
covergroup axi_cg;
    cp_addr: coverpoint tx.addr {
        bins low    = {[0          : 32'h3FFF_FFFF]};
        bins mid    = {[32'h4000_0000 : 32'h7FFF_FFFF]};
        bins high   = {[32'h8000_0000 : 32'hFFFF_FFFF]};
    }
    cp_len: coverpoint tx.burst_len {
        bins single = {0};
        bins short  = {[1:4]};
        bins long   = {[5:15]};
    }
    cp_size: coverpoint tx.burst_size {
        bins byte1  = {0}; bins byte2 = {1}; bins byte4 = {2}; bins byte8 = {3};
    }
    cp_burst: coverpoint tx.burst_type {
        bins FIXED = {0}; bins INCR = {1}; bins WRAP = {2};
    }
    cp_dir: coverpoint tx.wr_rd {
        bins WRITE = {1}; bins READ = {0};
    }
    cx_len_x_burst: cross cp_len, cp_burst;
    cx_dir_x_len:   cross cp_dir, cp_len;
    cx_dir_x_burst: cross cp_dir, cp_burst;
endgroup
```

Two instances (`wr_cov`, `rd_cov`) are connected separately to the monitor's write and read analysis ports, so write and read traffic are tracked independently.

**Coverage goals/results:** No coverage database or report (`.ucdb`, HTML report, etc.) was provided, so actual coverage percentages cannot be stated here. Add a coverage report under `docs/` once you've run regression, and update this section with real numbers.

## Simulation and Tools

- **Simulator:** QuestaSim / ModelSim (inferred from `vlib`, `vlog`, `vsim` in `run.do`)
- **Language:** SystemVerilog
- **Methodology library:** UVM 1.2
- **OS used for the provided script:** Windows (see paths in `run.do` — flagged below for portability)

## How to Run the Project

> The exact commands below are taken directly from `run.do`. Paths are placeholders you must update for your own machine — see the warning under item 9.

1. **Required tools:** QuestaSim/ModelSim with a UVM 1.2 library installed.
2. **Compile:**
3. **Simulate:**
4. **Run a specific test:** edit `run_test("testN")` in `top.sv` (`test1`–`test7`) before compiling, or override at the `vsim` command line with `+UVM_TESTNAME=testN`.
5. **View waveforms:**
6. **Coverage generation:** *(placeholder — not present in the provided `run.do`)*. Add `-cover` to `vlog`/`vsim` and use `vcover report` if you want a Questa coverage database.

## Results

No simulation transcript, pass/fail log, or coverage report was included in the provided files, so actual results cannot be reported here. The scoreboard (`sbd.sv`) prints `"TEST PASSED"` or `"TEST FAILED"` in `check_phase` based on its internal match/mismatch counters — capture and paste that output (and a coverage summary) here after running regression.

## Project Files

| File/Directory | Description |
|---|---|
| `tb/top.sv` | Top module: clock/reset generation, interface instantiation, `uvm_config_db` virtual interface set, `run_test` call |
| `tb/common.sv` | Constructor macros and width/parameter defines |
| `tb/intf.sv` | AXI4 signal interface |
| `tb/axi_tx.sv` | AXI4 transaction item with randomization constraints |
| `tb/agents/master/m_sqr.sv` | Master sequencer typedef |
| `tb/agents/master/m_drv.sv` | Master driver (drives all 5 AXI4 channels) |
| `tb/agents/master/m_agent.sv` | Master agent (sequencer + driver) |
| `tb/agents/slave/s_resp.sv` | Reactive slave response model (memory + burst addressing) |
| `tb/agents/slave/s_agent.sv` | Slave agent wrapper |
| `tb/sequences/m_seq.sv` | Base sequence + 7 derived sequences |
| `tb/monitor/m_mon.sv` | Passive monitor (write/read analysis ports) |
| `tb/scoreboard/sbd.sv` | Self-checking scoreboard |
| `tb/coverage/cov.sv` | Functional coverage subscriber |
| `tb/env/env.sv` | Environment: instantiates and connects all components |
| `tb/tests/test.sv` | Base test + `test1`–`test7` |
| `sim/run.do` | QuestaSim/ModelSim compile & simulate script |

## Key Learnings

- Structuring a layered UVM environment: transaction → sequence → sequencer → driver → monitor → scoreboard/coverage
- Modeling a full AXI4 channel set and burst-addressing rules (FIXED/INCR/WRAP) at the signal level
- Using `uvm_analysis_imp_decl` to create typed analysis implementation ports for multiple imports (write/read) on one component
- Splitting a single monitor's output into independent write/read coverage instances via separate analysis ports
- Avoiding race conditions between a `forever` sampling loop and `fork...join_none` response tasks by capturing signal values into local variables before forking (see `s_resp.sv`)

## Challenges and Solutions

- **Race conditions in the reactive slave model:** driving `bready`/`rready` handshakes from `fork...join_none` tasks while the main `forever` loop continues advancing risked using stale/overwritten shared variables. This was addressed in `s_resp.sv` by capturing `araddr`, `arlen`, `arsize`, `arid`, and `wid` into local variables before forking each response task.
- **WRAP burst addressing:** implemented independently in the slave response model (`s_resp.sv`) using lower/upper wrap-boundary calculation, but **not** mirrored in the scoreboard's memory-indexing logic (`sbd.sv`), which increments addresses linearly from the transaction's base address. This means `test7` (WRAP) may not scoreboard-check addresses correctly across a wrap boundary — worth fixing before treating WRAP coverage as verified.

## Future Improvements

- Integrate an actual synthesizable AXI4 slave RTL DUT in place of `s_resp.sv`
- Add SystemVerilog Assertions for protocol-level checks (handshake stability, burst/`last` alignment, legal burst-type encoding)
- Fix scoreboard address tracking to correctly handle WRAP bursts
- Make the scoreboard strobe-aware (currently compares full words rather than per-byte using `wstrb`)
- Parameterize and increase `` `N `` for more meaningful constrained-random regression length
- Add a virtual sequence layer and a test configuration/factory-override mechanism
- Generate and publish actual coverage reports and simulation logs
- Replace the hardcoded Windows paths in `run.do` with relative/environment-variable paths for portability

## Skills Demonstrated

- [x] SystemVerilog (interfaces, classes, constraints, queues)
- [x] UVM (agents, sequencer, driver, monitor, scoreboard, coverage subscriber, environment, test, factory)
- [x] TLM (analysis ports/exports/imps, `uvm_config_db`)
- [x] Constrained-random verification
- [x] Functional coverage modeling (coverpoints + cross coverage)
- [x] AXI4 protocol knowledge (burst types, channels, handshakes)
- [x] Self-checking testbench design
- [x] Race-condition-aware concurrent SystemVerilog coding
- [x] QuestaSim/ModelSim simulation flow

## Author

**SANTHOSHKUMAR M**
VLSI Design Verification Engineer
[https://www.linkedin.com/in/santhoshkumar-m-b3319426a/] 
[https://github.com/msanthoshkumar28] 
[mrsanthosh2804@gmail.com]      

