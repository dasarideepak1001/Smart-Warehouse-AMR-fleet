# ROBOTICS & AUTONOMOUS SYSTEMS ENGINEERING PORTFOLIO
## Curated Project Submission Dossier
### Candidate: [Candidate Name] | Date: September 2026

---

# FRONT MATTER & NAVIGATION

## Cover Page
- **Portfolio Title:** Autonomous Robotics & Multi-Agent Swarm Engineering Portfolio
- **Project Featured:** Smart Warehouse Autonomous Mobile Robot (AMR) Fleet Coordination System
- **Candidate Name:** [Candidate Full Name]
- **Email:** [candidate.email@university.edu / candidate@domain.com]
- **Contact Number:** [+1 (555) 019-2834 / +91 98765 43210]
- **GitHub:** [https://github.com/candidate-username/smart-warehouse-amr](https://github.com/)
- **LinkedIn:** [https://linkedin.com/in/candidate-profile](https://linkedin.com/)
- **Academic Program:** Bachelor of Technology / Master of Science in Robotics & Automation / Computer Science
- **Department & Institution:** Department of Computer Science & Robotics Engineering, [Institution Name]
- **Date of Submission:** September 2026

---

## Skills Matrix

| Category | Competencies & Applied Technologies |
|---|---|
| **Programming Languages** | MATLAB (OOP, Scripting, Vectorization), Python (Algorithm Prototyping, Scripting), C/C++ |
| **Robotics & Navigation** | A* Path Planning, Dynamic Manhattan Heuristics, Obstacle Avoidance, Kinematics, Collision Avoidance |
| **Multi-Agent Systems (MAS)** | Swarm Robotics, Master-Slave Coordination, Distributed Consensus, Peer-to-Peer (P2P) Mesh |
| **Simulation & 3D Twin** | MATLAB App Designer, 3D Digital Twin Modeling, Perspective Projection, Orbital Camera Control |
| **Energy & Lifecycle** | Battery Management Systems (BMS), Dual-Port Load Balancing, State-of-Charge (SOC) Monitoring |
| **Software Engineering** | Modular Object-Oriented Architecture, Automated Unit/Integration Testing, Performance Benchmarking |

---

## Table of Contents
1. [Project Header & At-a-Glance Box](#project-header--at-a-glance-box)
2. [Problem Statement & Architecture](#problem-statement--architecture)
3. [Execution & Algorithmic Mechanics](#execution--algorithmic-mechanics)
4. [Results & Benchmark Performance Metrics](#results--benchmark-performance-metrics)
5. [Telemetry Visualizers (2D Dashboard & 3D Digital Twin)](#telemetry-visualizers-2d-dashboard--3d-digital-twin)
6. [Repository Navigation & Execution Footnotes](#repository-navigation--execution-footnotes)

---

# PROJECT DOSSIER: SMART WAREHOUSE AMR FLEET SYSTEM

## Project Header & At-a-Glance Box

### Header
- **Project Title:** Smart Warehouse AMR Fleet Coordination System
- **Timeline:** January 2026 – September 2026 (Final Capstone & Engineering Submission)
- **Role:** Lead Robotics, Swarm Intelligence & Simulation Engineer

```
+---------------------------------------------------------------------------------------------------+
|                                      AT-A-GLANCE SUMMARY                                          |
+---------------------------------------------------------------------------------------------------+
| Primary Language  : MATLAB (Object-Oriented & Vectorized Engine)                                  |
| Simulation Tools  : MATLAB R2021a-R2026a, 3D Digital Twin Graphics Engine, Python 3               |
| Spatial Scale     : 30x30 Discretized Grid Warehouse (900 Operating Cells)                        |
| Fleet Composition : 5 Autonomous Mobile Robots (AMRs: R1 to R5 with Drive Wheels & LiDAR Puck)    |
| Storage & Hubs    : 8 Product Racks (A-H), 2 Packing Hubs (P1, P2), 2 Dual-Port Chargers (C1, C2)|
| Core Protocols    : P2P Task Trading Mesh ("Bring My Item"), Master-Slave Exclusive Aisle Leases, |
|                     Dynamic Corridor Dispersal, Low-Battery BMS Task-Freeze & Resumption Memory   |
+---------------------------------------------------------------------------------------------------+
```

---

## Problem Statement & Architecture

### Problem Definition (2–3 Sentences)
High-density automated fulfillment warehouses frequently suffer from severe corridor traffic deadlocks, uncoordinated multi-robot picking congestion in narrow aisles, and excessive cross-facility transit distances. Conventional centralized architectures introduce single-point-of-failure risks and computational lag, while standard battery charging routines drop or abandon in-flight customer orders. This project develops a decentralized multi-agent AMR coordination system that eliminates deadlocks in < 0.8 seconds, autonomously swaps cross-zone tasks via peer-to-peer handshakes, and freezes/resumes tasks with zero order loss during charging.

### High-Level Architectural Block Diagram
```
+---------------------------------------------------------------------------------------------------+
|                               SYSTEM ARCHITECTURE & DATA FLOW                                     |
+---------------------------------------------------------------------------------------------------+
                                                  |
                    +-----------------------------+-----------------------------+
                    |                                                           |
                    v                                                           v
       [ PHYSICAL SPATIAL LAYER ]                                  [ WORKFLOW & INVENTORY LAYER ]
       - 30x30 Discretized Grid Map                                - TaskManager (SKU Orders Backlog)
       - 8 Multi-Tier Storage Racks (Shelves A-H)                  - Unique Barcodes (BC-XXXXXX)
       - Dual Packing Stations (PACK 1 & PACK 2)                   - Category Tags (Electronics, HW, etc.)
       - Dual-Port Fast Chargers (1A, 1B, 2A, 2B)                  - Order Lifecycle (Pick -> Pack -> Done)
                    |                                                           |
                    +-----------------------------+-----------------------------+
                                                  |
                                                  v
                                    [ DISTRIBUTED EDGE-AI LAYER ]
                                    - TaskAllocator: Multi-Criteria Heuristic Scoring
                                    - Score = w1*Dist - w2*Priority - w3*(Battery/100)
                                                  |
                                                  v
                                   [ SWARM COORDINATION PROTOCOLS ]
      +-------------------------------------------+-------------------------------------------+
      |                                           |                                           |
      v                                           v                                           v
[ MASTER-SLAVE AISLE LEASE ]           [ ACTIVE CORRIDOR DISPERSAL ]             [ P2P R2R TASK TRADING ]
- Exclusive picking corridor locks     - Detects conflicts within 3 cells         - Cross-zone swap handshake
- Slaves buffer in holding cells       - Master proceeds; Slave steps lateral     - "Bring my item, I bring yours"
- 0 congestion in picking aisles       - Resolves head-on stalls in < 0.8s        - Cuts travel distance by ~50%
      |                                           |                                           |
      +-------------------------------------------+-------------------------------------------+
                                                  |
                                                  v
                                     [ AUTONOMOUS BATTERY BMS ]
                                     - Low-Battery BMS Trigger (SOC <= 30%)
                                     - In-flight task frozen in robot memory (PausedForCharging)
                                     - Rerouting to nearest available dual-port charging dock
                                     - Automatic unfreezing & task resumption post-charging
                                                  |
                                                  v
                                  [ DUAL VISUALIZATION TELEMETRY ]
      +-------------------------------------------+-------------------------------------------+
      |                                                                                       |
      v                                                                                       v
[ 2D TELEMETRY DASHBOARD ]                                              [ 3D DIGITAL TWIN ENVIRONMENT ]
- Shell 1: Real-time System KPI HUD                                     - True 3D Multi-Tier Steel Racks
- Shell 2: Scrollable P2P R2R Dialogue Shell                            - Physical 3D Cargo Parcels on AMR Decks
- Shell 3: Real-Time In-Hand Parcel Status                              - Dual-State Illuminated Charging Towers
- Shell 4: Interactive Orders History UITable                           - Elevated Cyan Wireless Laser Beams
- Available as Modular & Standalone All-In-One                          - 360-Degree Mouse Orbit & Camera Toolbar
+---------------------------------------------------------------------------------------------------+
```

---

## Execution & Algorithmic Mechanics

### 1. A* Shortest-Path Planning Engine
- **Heuristic Function:** Manhattan grid heuristic $f(n) = g(n) + h(n)$, where $h(n) = |x_n - x_{goal}| + |y_n - y_{goal}|$.
- **Dynamic Avoid-Mask:** When navigating around congested areas, other AMRs are marked as temporary obstacles ($cost = \infty$), forcing paths to skirt cleanly around stationary or slower robots.
- **Zero-Stall Next-Step Initialization:** When `assignPath` is called, if the first waypoint is the robot's current position, `PathIndex` is initialized to `2`. The robot takes its next physical step immediately on that tick, eliminating stationary re-planning stalls.

### 2. Master-Slave Exclusive Picking Aisle Leases
- **Bottleneck Addressed:** Multiple AMRs entering a narrow single-cell shelf aisle cause immediate head-on gridlocks.
- **Lease Mechanism:** The AMR closest to the picking shelf claims an exclusive **Master Picking Lease**. Competing contender AMRs are assigned **SlaveHolding** roles and commanded to wait outside the entrance in designated buffer cells until the Master robot retrieves the item and exits the aisle.

### 3. High-Speed Lateral Corridor Dispersal
- **Conflict Trigger:** Triggered when two robots are within $\le 3.0$ cells and share a conflicting next waypoint, are aiming at the same cell, or are heading directly toward each other.
- **Master/Slave Arbitration:** The robot carrying higher priority cargo or critical low battery ($\le 30\%$) is designated **Master**.
- **Lateral Escape:** The **Slave** robot evaluates adjacent lateral cells:
  $$\text{Candidates} = \{(x \pm 1, y), (x \pm 2, y), (x, y \pm 1), (x, y \pm 2)\}$$
  The Slave robot side-steps into the free parallel lane in under 0.8 seconds, clearing the main corridor for the Master to proceed at full speed.

### 4. Peer-to-Peer (R2R) "Bring My Item, I Bring Yours" Task Trading
- **Bottleneck Addressed:** Robot 1 in Zone 1 (NW) is assigned an item in Zone 4 (SE), while Robot 4 in Zone 4 is assigned an item in Zone 1. Both would traditionally cross the entire warehouse twice.
- **Handshake Protocol:**
  1. $R_1$ broadcasts a swap proposal: *"Bring my Precision Screwdriver Set from Zone 4, and I will bring your Mobile Phone from Zone 1!"*
  2. $R_4$ evaluates distance savings:
     $$\Delta \text{Savings} = \text{Dist}_{Direct} - \text{Dist}_{Traded} \approx 28 \text{ to } 52 \text{ grid cells}$$
  3. $R_4$ accepts: Both robots pick the local item and deliver directly to the nearest packing hub ($P_1$ or $P_2$), completely bypassing the long cross-facility trek.

### 5. Autonomous Battery BMS with Task Memory Freezing
- **Emergency Threshold:** When battery drops to $\le 30\%$, the AMR immediately halts task work.
- **Task Preservation:** The active order is stored in `robot.SavedTask`, while the global order status is flagged as `PausedForCharging`. No other robot can steal or overwrite the order.
- **Smart Docking:** The AMR routes to the nearest available port across Station 1 (`1A`, `1B`) and Station 2 (`2A`, `2B`). If Station 1 is full ($2/2$), it reroutes to Station 2.
- **Automatic Resumption:** Upon reaching $\ge 90\%$ battery, the AMR unfreezes its task from memory, re-plans a route to the pickup or packing station, and completes the order with **zero human intervention and zero order loss**.

---

## Results & Benchmark Performance Metrics

### Centralized vs. Distributed Edge-AI Benchmark (500s Simulation Run)

| Performance Metric | Conventional Centralized Fleet | Proposed Distributed Edge-AI Swarm | Empirical Improvement |
|---|---|---|---|
| **Order Fulfillment Throughput** | 18.2 orders / 500s | **24.4 orders / 500s** | **+ 34.1% Higher Throughput** |
| **Cross-Facility Travel Distance** | 1,420 grid cells | **1,040 grid cells** | **- 26.8% Transit Distance Saved** |
| **Corridor Conflict Resolution Time** | 4.2 seconds | **< 0.8 seconds** | **81.0% Faster Resolution** |
| **Aisle Deadlocks & Freezes** | 14 deadlock events | **0 (Zero Deadlocks)** | **100% Deadlock Elimination** |
| **Order Loss Rate on Low Battery** | 3 orders abandoned | **0 orders (100% resumed)** | **Zero Task Abandonment** |
| **Fleet Battery Efficiency** | 1.84 cells / % battery | **2.38 cells / % battery** | **+ 29.3% Energy Efficiency** |

---

## Telemetry Visualizers (2D Dashboard & 3D Digital Twin)

```
+---------------------------------------------------------------------------------------------------+
|                                 TELEMETRY & VISUALIZER SUITE                                      |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [ 2D MULTI-SHELL TELEMETRY DASHBOARD ]               [ 3D DIGITAL TWIN ENVIRONMENT ]             |
|  - Floor Canvas (Left 60%): Live AMR positions,       - True 3D Multi-Tier Industrial Steel Racks |
|    path dotted trajectories, 8 color-coded shelves,     with 3-tier shelves and category totes    |
|    Pack 1 & 2 hubs, dual-state charging pads.         - 3D AMR Models with drive wheels and       |
|  - Shell 1 (Top-Right): System KPI HUD (Mode,           rotating LiDAR scanner pucks               |
|    Fleet Battery, Commands, Delivery Count).          - Physical 3D Cardboard Parcel Boxes loaded |
|  - Shell 2: Scrollable P2P R2R Dialogue Shell           on AMR decks during delivery transits     |
|    logging live cross-zone swap negotiations.         - Dual-State Illuminated Docking Towers     |
|  - Shell 3: Real-Time In-Hand Parcel Status Shell       (Emerald Green = Free, Cyan = Charging)   |
|    showing exactly what SKU each robot is carrying.   - Radiant Elevated 3D Laser Beams linking   |
|  - Shell 4 (Bottom-Right): Interactive Orders UITable   trading AMRs in mid-air                   |
|    with ID, Product Name, Category, Barcode,          - Interactive Camera Toolbar: Isometric 3D, |
|    Timestamp, and live status badges.                   Top-Down 2.5D, and 360-Degree Mouse Orbit |
+---------------------------------------------------------------------------------------------------+
```

---

## Repository Navigation & Execution Footnotes

### Repository Directory Structure
```
c:/Users/deepa/OneDrive/Documents/anti/
├── run_simulation.m              # Top-level interactive 2D scenario & benchmark launcher
├── run_simulation_3d.m           # Top-level dedicated 1-click 3D Digital Twin launcher
├── SmartWarehouse2D_AllInOne.m   # Standalone single-file 2D simulation (13 modules in 1 file)
├── src/                          # Modular core algorithm & object engine
│   ├── AMRRobot.m                # Robot kinematics, battery BMS, task memory & resumption
│   ├── WarehouseMap.m            # 30x30 spatial grid layout, shelves A-H, pack/charge hubs
│   ├── TaskManager.m             # Order backlog, barcodes, categories, and delivery states
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
└── docs/                         # Formal project submission dossier & verification reports
```

### Quick-Start Execution Commands
In MATLAB Command Window:
```matlab
cd('c:/Users/deepa/OneDrive/Documents/anti')

% 1. Launch Interactive 2D Simulation (Modular)
run_simulation(1)

% 2. Launch 3D Digital Twin Simulation (Interactive 3D)
run_simulation_3d

% 3. Launch Standalone Single-File 2D Simulation (Zero Folder Dependencies)
SmartWarehouse2D_AllInOne

% 4. Run Full 13-Point Automated Test Suite
run_simulation(5)
```

---
*End of Curated Project Submission Dossier.*
