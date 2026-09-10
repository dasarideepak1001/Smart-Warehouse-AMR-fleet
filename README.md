# Smart Warehouse AMR Fleet Coordination System

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021a%20--%20R2026a-blue.svg?logo=mathworks)](https://www.mathworks.com/)
[![Architecture](https://img.shields.io/badge/Architecture-Distributed%20Edge--AI%20%26%20MAS-emerald.svg)](#system-architecture)
[![Digital Twin](https://img.shields.io/badge/Simulation-2D%20Dashboard%20%2B%203D%20Twin-purple.svg)](#visualization-suite)
[![Automated Tests](https://img.shields.io/badge/Tests-13%2F13%20Passing%20(100%25)-brightgreen.svg)](#automated-testing)
[![License](https://img.shields.io/badge/License-MIT-orange.svg)](#license)

An end-to-end, industrial-grade **Autonomous Mobile Robot (AMR)** warehouse fleet coordination and Digital Twin simulation developed in MATLAB. Designed to overcome the single-point failure risks, computational latency, and corridor gridlocks of conventional centralized fleet managers, this project implements a **Distributed Edge-AI Multi-Agent Swarm** operating over a $30 \times 30$ warehouse grid (900 operating cells).

---

## 🌟 Key Engineering Highlights

* 🤖 **5 Autonomous Mobile Robots (AMRs):** Differential drive kinematics, LiDAR obstacle perception, dynamic battery gauges, and cargo carrying decks.
* 📦 **8 Categorized Industrial Racks (Shelves A–H):** Consumer Electronics, Computers, Gaming & Audio, Smart Home, Apparel, Stationery, Healthcare, and Tools.
* ⚡ **Peer-to-Peer (R2R) Task Trading ("*Bring My Item, I Bring Yours*"):** Autonomous wireless handshake enabling robots in opposing zones to swap cross-facility tasks, saving 28–52 cells of travel per trade.
* 🔒 **Master-Slave Exclusive Aisle Leases:** Dynamically locks picking corridors to the primary robot while safely buffering secondary robots in outer queue slots, ensuring **0 picking deadlocks**.
* 🚀 **High-Speed Lateral Corridor Dispersal (< 0.8s):** Resolves oncoming corridor conflicts instantly by commanding slave robots into parallel lanes.
* 🔋 **Autonomous Battery BMS (<30%) with Task Memory Freezing:** Active orders are frozen in memory (`PausedForCharging`) upon low charge, and automatically resumed once fast-charging finishes with **zero task loss**.
* 🌐 **Dual Visualization Engines:**
  * **2D Telemetry Dashboard:** 4 live shells (System KPI HUD, Scrollable R2R Terminal, In-Hand Parcel Monitor, Interactive Orders UITable with barcodes).
  * **3D Digital Twin:** Multi-tier storage racks, physical 3D cardboard parcel boxes on AMR decks, illuminated dual-state charging docks, glowing cyan laser links, and 360° mouse orbital controls.
* 📁 **All-In-One Standalone Single File:** [`SmartWarehouse2D_AllInOne.m`](SmartWarehouse2D_AllInOne.m) packages all 13 modules into one standalone file with zero folder dependencies.

---

## 🏗️ System Architecture

```
+-------------------------------------------------------------------------+
|                  SMART WAREHOUSE AMR FLEET SYSTEM                       |
+-------------------------------------------------------------------------+
                                    |
     +------------------------------+------------------------------+
     |                              |                              |
[Physical / Spatial Layer]    [Multi-Agent Intelligence]   [Visualization Layer]
  - 30x30 Warehouse Map         - Distributed Edge-AI        - 2D Dashboard (4 Shells)
  - 8 Storage Racks (A-H)       - Master-Slave Leases        - 3D Digital Twin Visualizer
  - Packing Hubs (P1, P2)       - Corridor Dispersal (<0.8s) - Interactive UITable
  - Dual-Port Chargers (C1, C2) - P2P R2R Task Trading       - 360° Orbital Camera
                                - Battery BMS (<30% Freeze)  - Standalone Single File
```

---

## 🚀 Quick Start & Execution

Open MATLAB and navigate to the repository directory:

```matlab
cd('c:/Users/deepa/OneDrive/Documents/anti')
```

### 1. Run Interactive 2D Simulation (Modular)
```matlab
run_simulation(1)
```
*Opens the 2D warehouse canvas with live AMR badges, route trajectories, R2R dialogue terminal, in-hand parcel tracking, and interactive historical orders table.*

### 2. Run 3D Digital Twin Simulation
```matlab
run_simulation_3d
```
*Launches the full 3D Digital Twin with 3D multi-tier racks, physical parcel boxes on robot decks, illuminated charging towers, glowing cyan wireless laser links, and 360° camera orbital navigation.*

### 3. Run Standalone All-In-One Single File
```matlab
SmartWarehouse2D_AllInOne
```
*Executes the complete 2D simulation from a single self-contained script without needing subfolders or path setup.*

### 4. Run Automated Test Suite & Benchmarks
```matlab
run_simulation(5)  % Full 13-point automated unit & system test suite
run_simulation(4)  % Centralized vs. Distributed Edge-AI quantitative benchmark
```

---

## 📊 Benchmark Performance Results

| Performance Metric | Centralized Fleet System | Distributed Edge-AI Swarm | Empirical Improvement |
|---|---|---|---|
| **Order Throughput** | 18.2 orders / 500s | **24.4 orders / 500s** | **+ 34.1% Higher** |
| **Cross-Zone Travel Distance** | 1,420 grid cells | **1,040 grid cells** | **- 26.8% Transit Saved** |
| **Conflict Clearance Time** | 4.2 seconds | **< 0.8 seconds** | **81.0% Faster** |
| **Aisle Deadlocks & Freezes** | 14 deadlock events | **0 (Zero Deadlocks)** | **100% Elimination** |
| **Task Loss on Low Battery** | 3 orders abandoned | **0 (100% resumed)** | **Zero Task Abandonment** |
| **Fleet Energy Efficiency** | 1.84 cells / % battery | **2.38 cells / % battery** | **+ 29.3% Efficiency** |

---

## 📂 Repository Structure

```
anti/
├── run_simulation.m              # Top-level interactive 2D scenario & benchmark launcher
├── run_simulation_3d.m           # Top-level dedicated 1-click 3D Digital Twin launcher
├── SmartWarehouse2D_AllInOne.m   # Standalone single-file 2D simulation (13 modules in 1 file)
├── src/                          # Core algorithm & object classes
│   ├── AMRRobot.m                # Kinematics, battery BMS, task memory & resumption
│   ├── WarehouseMap.m            # 30x30 spatial grid, shelves A-H, pack/charge hubs
│   ├── TaskManager.m             # Orders, barcodes, categories, and delivery states
│   ├── TaskAllocator.m           # Distributed Edge-AI order dispatching engine
│   ├── AStarPlanner.m            # A* shortest-path algorithm with avoid-mask support
│   ├── MasterSlaveTrafficController.m # Aisle exclusive leases & lateral collision dispersal
│   ├── R2RCommunicator.m         # P2P cross-zone task exchange ("Bring my item") protocol
│   ├── BatteryManager.m          # Low-battery monitor (<=30%), dual-port allocation, freeze
│   ├── CollisionAvoidance.m      # Spatial conflict detection & right-of-way yielding
│   ├── WarehouseDashboard.m      # 2D multi-shell graphical dashboard with orders table
│   └── WarehouseDashboard3D.m    # 3D Digital Twin visualizer with parcels & camera toolbar
├── scenarios/                    # Scenario runners (normal 2D, 3D, obstacle, failure)
├── benchmarks/                   # Automated empirical benchmark evaluation suite
├── docs/                         # Project submission dossier, certificates, & manuals
└── .gitignore                    # MATLAB and Python ignore rules
```

---

## 📜 License & Academic Citation

This project is licensed under the MIT License. Developed as an advanced robotics capstone project demonstrating multi-agent coordination, distributed algorithms, and digital twin simulation.
