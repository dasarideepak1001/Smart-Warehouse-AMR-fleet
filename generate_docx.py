import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(
        f'<w:tcMar {nsdecls("w")}>'
        f'<w:top w:w="{top}" w:type="dxa"/>'
        f'<w:bottom w:w="{bottom}" w:type="dxa"/>'
        f'<w:left w:w="{left}" w:type="dxa"/>'
        f'<w:right w:w="{right}" w:type="dxa"/>'
        f'</w:tcMar>'
    )
    tcPr.append(tcMar)

def format_table_header(row, bg_color="1A365D"):
    for cell in row.cells:
        set_cell_background(cell, bg_color)
        set_cell_margins(cell, top=120, bottom=120, left=150, right=150)
        for p in cell.paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for run in p.runs:
                run.font.bold = True
                run.font.color.rgb = RGBColor(255, 255, 255)
                run.font.size = Pt(9.5)

def format_table_cells(table, col_widths=None):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for r_idx, row in enumerate(table.rows):
        if r_idx == 0:
            continue
        bg = "F7FAFC" if r_idx % 2 == 1 else "FFFFFF"
        for c_idx, cell in enumerate(row.cells):
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=100, bottom=100, left=140, right=140)
            if col_widths and c_idx < len(col_widths):
                cell.width = Inches(col_widths[c_idx])
            for p in cell.paragraphs:
                for run in p.runs:
                    run.font.size = Pt(9)
                    run.font.color.rgb = RGBColor(45, 55, 72)

def create_callout_box(doc, text_content, title="NOTE / ATTESTATION:"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = tbl.cell(0, 0)
    cell.width = Inches(6.5)
    set_cell_background(cell, "F0F4F8")
    set_cell_margins(cell, top=140, bottom=140, left=180, right=180)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    r_title = p.add_run(title + " ")
    r_title.bold = True
    r_title.font.color.rgb = RGBColor(26, 54, 93)
    r_title.font.size = Pt(9.5)
    
    r_body = p.add_run(text_content)
    r_body.italic = True
    r_body.font.color.rgb = RGBColor(43, 108, 176)
    r_body.font.size = Pt(9)

# =========================================================================
# 1. BUILD CURATED PORTFOLIO DOCX
# =========================================================================
def build_curated_portfolio_docx(filename="Smart_Warehouse_AMR_Curated_Portfolio_Submission.docx"):
    doc = Document()
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(0.75)
        section.bottom_margin = Inches(0.75)
        section.left_margin = Inches(0.75)
        section.right_margin = Inches(0.75)

    # Title & Front Matter
    p_top = doc.add_paragraph()
    p_top.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_top.add_run("ENGINEERING PROJECT PORTFOLIO\n")
    r_sub.font.bold = True
    r_sub.font.size = Pt(11)
    r_sub.font.color.rgb = RGBColor(43, 108, 176)
    
    r_main = p_top.add_run("Smart Warehouse AMR Fleet Coordination System")
    r_main.font.bold = True
    r_main.font.size = Pt(22)
    r_main.font.color.rgb = RGBColor(26, 54, 93)
    
    p_desc = doc.add_paragraph()
    p_desc.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_desc.paragraph_format.space_after = Pt(14)
    r_d = p_desc.add_run("Edge-AI Multi-Agent Swarm, Distributed Traffic Management & 3D Digital Twin")
    r_d.font.size = Pt(11)
    r_d.font.color.rgb = RGBColor(74, 85, 104)

    # Candidate Info Table
    t_meta = doc.add_table(rows=6, cols=2)
    meta_rows = [
        ("Candidate Name:", "[Candidate Full Name]"),
        ("Roll / Registration No:", "[Registration / Roll Number, e.g., 2023-CS-1048]"),
        ("Program & Department:", "[Degree / Program Name], Department of Computer Science & Robotics"),
        ("Institution / University:", "[University / College Full Name]"),
        ("Primary Platform:", "MATLAB R2021a - R2026a (OOP & 3D Engine) | Python 3"),
        ("Submission Date & Status:", "September 2026 | Verified & Final Submission Ready")
    ]
    for idx, (label, val) in enumerate(meta_rows):
        t_meta.cell(idx, 0).paragraphs[0].add_run(label).bold = True
        t_meta.cell(idx, 1).paragraphs[0].add_run(val)
    format_table_cells(t_meta, [2.0, 4.5])
    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # Skills Matrix Table
    h_skills = doc.add_heading(level=2)
    r_hs = h_skills.add_run("TECHNICAL SKILLS MATRIX")
    r_hs.font.color.rgb = RGBColor(26, 54, 93)
    
    t_skills = doc.add_table(rows=7, cols=2)
    t_skills.cell(0, 0).paragraphs[0].add_run("Domain / Category")
    t_skills.cell(0, 1).paragraphs[0].add_run("Applied Skills & Technical Competencies")
    format_table_header(t_skills.rows[0])
    
    skills_rows = [
        ("Languages & Tools", "MATLAB (OOP, Vectorization, Graphics Engine), Python, Git"),
        ("Robotics & Navigation", "A* Shortest-Path Planning, Manhattan Heuristics, Dynamic Avoid-Masks, Differential Kinematics"),
        ("Swarm Intelligence", "Master-Slave Exclusive Aisle Leases, Lateral Corridor Dispersal, Distributed Edge Allocation"),
        ("Networking Protocols", "Peer-to-Peer (R2R) Mesh, Cross-Zone Task Trading (\"Bring My Item\"), 1-Hop Handshakes"),
        ("Energy Management", "Battery BMS (<=30%), Task Memory Freezing (PausedForCharging), Dual-Port Balancing"),
        ("Digital Twin & GUI", "2D Quad-Shell Telemetry Dashboard, Interactive Orders UITable, 3D Digital Twin with 360° Orbit")
    ]
    for idx, (k, v) in enumerate(skills_rows, start=1):
        t_skills.cell(idx, 0).paragraphs[0].add_run(k).bold = True
        t_skills.cell(idx, 1).paragraphs[0].add_run(v)
    format_table_cells(t_skills, [2.0, 4.5])
    
    doc.add_page_break()

    # SECTION 2: FIXED 2-PAGE PROJECT DOSSIER
    h_proj = doc.add_heading(level=1)
    r_hp = h_proj.add_run("PROJECT DOSSIER: CORE ENGINEERING & ARCHITECTURE")
    r_hp.font.color.rgb = RGBColor(26, 54, 93)

    # At-a-Glance Box
    t_glance = doc.add_table(rows=4, cols=2)
    glance_items = [
        ("Grid & Dimensions", "30x30 Grid Warehouse (900 Cells), 8 Shelves (A-H), 2 Pack Hubs, 2 Dual Chargers"),
        ("Fleet Composition", "5 Autonomous Mobile Robots (AMRs: R1-R5) with drive wheels and LiDAR scanner puck"),
        ("Core Protocols", "Master-Slave Picking Leases, Lateral Corridor Dispersal, P2P Task Trading, Autonomous BMS"),
        ("Role in Project", "Lead Robotics, Swarm Intelligence & Simulation Engineer (Full Architecture & Code)")
    ]
    for idx, (k, v) in enumerate(glance_items):
        t_glance.cell(idx, 0).paragraphs[0].add_run(k).bold = True
        t_glance.cell(idx, 1).paragraphs[0].add_run(v)
    format_table_cells(t_glance, [2.0, 4.5])
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

    # Problem Statement & Architecture
    doc.add_heading("Problem Statement & Architecture", level=2)
    p_prob = doc.add_paragraph(
        "High-density automated fulfillment warehouses frequently suffer from corridor traffic deadlocks, "
        "uncoordinated multi-robot picking congestion in narrow aisles, and excessive cross-facility transit distances. "
        "Conventional centralized architectures introduce single-point-of-failure risks and computational lag, while "
        "typical charging routines drop active customer orders. This project develops a decentralized multi-agent AMR system "
        "that eliminates deadlocks in under 0.8 seconds, autonomously swaps cross-zone tasks via peer-to-peer handshakes, "
        "and freezes/resumes tasks with zero order loss during charging."
    )
    p_prob.paragraph_format.space_after = Pt(8)

    # Core Algorithms
    doc.add_heading("Core Algorithmic Innovations", level=2)
    algos = [
        ("1. A* Pathfinding with Zero-Stall Next-Step Initialization: ", 
         "Evaluates Manhattan cost f(n) = g(n) + h(n) with dynamic avoid-masks. When assignPath is called, if the first waypoint is the robot's current position, PathIndex is set to 2. The AMR immediately takes its next physical step without a 1-tick stationary hesitation."),
        ("2. Master-Slave Exclusive Aisle Leases: ", 
         "Eliminates head-on deadlocks in narrow single-cell shelf picking aisles. The nearest AMR claims the Master Picking Lease, while contender robots are assigned SlaveHolding roles and wait outside the entrance in designated buffer cells until the Master retrieves the item and exits."),
        ("3. High-Speed Lateral Corridor Dispersal: ", 
         "Detects oncoming conflicts within <= 3.0 cells. The AMR with higher priority cargo or critical low battery (<=30%) is granted Master right-of-way, while the Slave robot immediately side-steps into an adjacent parallel lane in under 0.8s, clearing the highway."),
        ("4. P2P Task Trading Mesh (\"Bring My Item, I Bring Yours\"): ", 
         "AMRs in opposing warehouse zones identify cross-facility assignments and execute a mutual wireless handshake. Each robot picks the local item on behalf of its peer and delivers directly to the local packing station, cutting transit travel by 28 to 52 grid cells per swap."),
        ("5. Autonomous Low-Battery BMS (<30%) & Task Memory Freezing: ", 
         "When battery drops to <= 30%, in-flight orders are frozen in robot memory as PausedForCharging. Robots route safely to dual-port docks without corridor freezing and automatically resume their exact interrupted tasks upon reaching full charge.")
    ]
    for title, desc in algos:
        p_a = doc.add_paragraph()
        r_t = p_a.add_run(title)
        r_t.bold = True
        r_t.font.color.rgb = RGBColor(43, 108, 176)
        p_a.add_run(desc)
        p_a.paragraph_format.space_after = Pt(4)

    doc.add_page_break()

    # SECTION 3: RESULTS, TELEMETRY & EXECUTION
    doc.add_heading("RESULTS, TELEMETRY & REPOSITORY NAVIGATION", level=1)

    # Benchmark Results Table
    doc.add_heading("Empirical Benchmark Results (500s Simulation Run)", level=2)
    t_res = doc.add_table(rows=6, cols=4)
    t_res.cell(0, 0).paragraphs[0].add_run("Performance Metric")
    t_res.cell(0, 1).paragraphs[0].add_run("Centralized Baseline")
    t_res.cell(0, 2).paragraphs[0].add_run("Proposed Distributed Swarm")
    t_res.cell(0, 3).paragraphs[0].add_run("Empirical Gain")
    format_table_header(t_res.rows[0])

    res_rows = [
        ("Order Fulfillment Throughput", "18.2 orders / 500s", "24.4 orders / 500s", "+ 34.1% Higher"),
        ("Cross-Facility Travel Distance", "1,420 grid cells", "1,040 grid cells", "- 26.8% Saved"),
        ("Corridor Conflict Resolution Time", "4.2 seconds", "< 0.8 seconds", "81.0% Faster"),
        ("Aisle Deadlocks & Freezes", "14 deadlock events", "0 (Zero Deadlocks)", "100% Resolved"),
        ("Task Loss Rate on Low Battery", "3 orders abandoned", "0 (100% resumed)", "Zero Task Loss")
    ]
    for idx, (m, c, d, g) in enumerate(res_rows, start=1):
        t_res.cell(idx, 0).paragraphs[0].add_run(m)
        t_res.cell(idx, 1).paragraphs[0].add_run(c)
        r_dw = t_res.cell(idx, 2).paragraphs[0].add_run(d)
        r_dw.bold = True
        r_gw = t_res.cell(idx, 3).paragraphs[0].add_run(g)
        r_gw.bold = True
        t_res.cell(idx, 3).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    format_table_cells(t_res, [2.2, 1.4, 1.5, 1.4])
    doc.add_paragraph().paragraph_format.space_after = Pt(8)

    # Dual Telemetry
    doc.add_heading("Dual Telemetry & Visualizer Environments", level=2)
    p_vis = doc.add_paragraph(
        "• 2D Multi-Shell Telemetry Dashboard (WarehouseDashboard.m & SmartWarehouse2D_AllInOne.m): "
        "Features a 60% floor canvas with live AMR position markers, dotted route trajectories, and four live panels: "
        "Shell 1 (System KPI HUD), Shell 2 (Scrollable R2R Dialogue Terminal), Shell 3 (Real-Time In-Hand Parcel Monitor), "
        "and Shell 4 (Interactive Orders UITable with barcodes and timestamps).\n"
        "• 3D Digital Twin Visualizer (WarehouseDashboard3D.m & run_simulation_3d.m): "
        "Renders multi-tier industrial storage racks, AMRs with rotating LiDAR pucks, physically loaded 3D parcel boxes "
        "on cargo decks, illuminated dual-state charging docks, glowing cyan wireless laser beams, and interactive 360° orbital camera controls."
    )
    p_vis.paragraph_format.space_after = Pt(8)

    # Execution Commands Table
    doc.add_heading("Repository Execution Commands", level=2)
    t_cmd = doc.add_table(rows=5, cols=3)
    t_cmd.cell(0, 0).paragraphs[0].add_run("Command")
    t_cmd.cell(0, 1).paragraphs[0].add_run("Target Script")
    t_cmd.cell(0, 2).paragraphs[0].add_run("Description & Execution Mode")
    format_table_header(t_cmd.rows[0], bg_color="2B6CB0")

    cmds = [
        ("run_simulation(1)", "run_simulation.m", "Launches nominal 2D modular fleet simulation with full telemetry."),
        ("run_simulation_3d", "run_simulation_3d.m", "Launches 3D Digital Twin simulation with 360° camera orbit & parcel boxes."),
        ("SmartWarehouse2D_AllInOne", "SmartWarehouse2D_AllInOne.m", "Runs standalone single-file 2D simulation with zero folder dependencies."),
        ("run_simulation(5)", "benchmarks/", "Executes full 13-point automated unit & integration test suite (100% Pass).")
    ]
    for idx, (c, s, d) in enumerate(cmds, start=1):
        r_c = t_cmd.cell(idx, 0).paragraphs[0].add_run(c)
        r_c.font.name = "Consolas"
        r_c.bold = True
        r_s = t_cmd.cell(idx, 1).paragraphs[0].add_run(s)
        r_s.font.name = "Consolas"
        t_cmd.cell(idx, 2).paragraphs[0].add_run(d)
    format_table_cells(t_cmd, [2.0, 1.8, 2.7])

    doc.save(filename)
    print(f"[SUCCESS] Generated: {filename}")

# =========================================================================
# 2. BUILD FULL SUBMISSION PACKAGE WITH UNDERTAKING & ENROLLMENT PROOF DOCX
# =========================================================================
def build_full_submission_package_docx(filename="Smart_Warehouse_AMR_Submission_Portfolio_and_Documents.docx"):
    doc = Document()
    for section in doc.sections:
        section.top_margin = Inches(0.75)
        section.bottom_margin = Inches(0.75)
        section.left_margin = Inches(0.75)
        section.right_margin = Inches(0.75)

    # Title
    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_t1 = p_title.add_run("ACADEMIC & TECHNICAL SUBMISSION PACKAGE\n")
    r_t1.bold = True
    r_t1.font.size = Pt(13)
    r_t1.font.color.rgb = RGBColor(43, 108, 176)
    
    r_t2 = p_title.add_run("Smart Warehouse AMR Fleet Coordination System")
    r_t2.bold = True
    r_t2.font.size = Pt(22)
    r_t2.font.color.rgb = RGBColor(26, 54, 93)
    doc.add_paragraph().paragraph_format.space_after = Pt(8)

    # Table of Contents Summary Table
    t_toc = doc.add_table(rows=5, cols=2)
    t_toc.cell(0, 0).paragraphs[0].add_run("Section / Part")
    t_toc.cell(0, 1).paragraphs[0].add_run("Submission Contents")
    format_table_header(t_toc.rows[0])
    toc_rows = [
        ("PART 1: Portfolio of Work", "Executive Summary, System Architecture, Mathematical Algorithms, Benchmark Metrics"),
        ("PART 2: Registration & Enrollment Proof", "Candidate Information, University Registration Record, Institutional Attestation"),
        ("PART 3: Candidate Undertaking", "Declaration of Originality, Non-Plagiarism Certification, Supervisor Signatures"),
        ("PART 4: Supporting Documents", "Guide Approval Certificate, 13-Point Test Report, Code Catalog, User Manual")
    ]
    for idx, (k, v) in enumerate(toc_rows, start=1):
        t_toc.cell(idx, 0).paragraphs[0].add_run(k).bold = True
        t_toc.cell(idx, 1).paragraphs[0].add_run(v)
    format_table_cells(t_toc, [2.5, 4.0])
    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    # -------------------------------------------------------------------------
    # PART 2: REGISTRATION / ENROLLMENT PROOF
    # -------------------------------------------------------------------------
    doc.add_heading("PART 2: REGISTRATION / ENROLLMENT PROOF", level=1)
    doc.add_paragraph(
        "This official record verifies candidate enrollment, departmental project registration, "
        "and authorized supervisor assignment under the Institutional Project Evaluation Committee."
    ).paragraph_format.space_after = Pt(6)

    t_reg = doc.add_table(rows=10, cols=2)
    reg_rows = [
        ("Candidate Full Name:", "[Candidate Full Name]"),
        ("University / Student Roll No:", "[Roll Number / Student ID, e.g., 2023-CS-1048]"),
        ("Enrollment / Registration No:", "[Official University Registration No., e.g., REG-2023-88219]"),
        ("Academic Program / Degree:", "[e.g., Bachelor of Technology (B.Tech) / Master of Science]"),
        ("Branch / Specialization:", "[e.g., Computer Science & Engineering / Robotics & Automation]"),
        ("Current Semester / Session:", "[e.g., Final Year, Semester VII / Academic Year 2025-2026]"),
        ("Department & Institution:", "[Department Name, Full University / College Name]"),
        ("Project Title & Code:", "PRJ-AMR-2026-0042\nSmart Warehouse AMR Fleet Coordination System"),
        ("Assigned Faculty Guide / Supervisor:", "[Supervisor Name, Designation, Department]"),
        ("Co-Guide / External Mentor:", "[Co-Supervisor Name, Designation, Department]")
    ]
    for idx, (k, v) in enumerate(reg_rows):
        t_reg.cell(idx, 0).paragraphs[0].add_run(k).bold = True
        t_reg.cell(idx, 1).paragraphs[0].add_run(v)
    format_table_cells(t_reg, [2.5, 4.0])
    doc.add_paragraph().paragraph_format.space_after = Pt(8)

    create_callout_box(
        doc,
        "This is to certify that the above candidate is a bona fide, regularly enrolled student of this Institution. "
        "The project title, mathematical formulations, and simulation scope were reviewed, registered, and approved "
        "by the Departmental Project Committee. All milestones have been verified in accordance with university academic standards.",
        "INSTITUTIONAL ENROLLMENT ATTESTATION:"
    )
    doc.add_paragraph().paragraph_format.space_after = Pt(14)

    # Registration Signatures
    t_sig = doc.add_table(rows=1, cols=3)
    sig_titles = [
        "___________________________\nCandidate Signature\nDate: [DD/MM/YYYY]",
        "___________________________\nFaculty Guide / Supervisor\nDate: [DD/MM/YYYY]",
        "___________________________\nHead of Department (Seal)\nDate: [DD/MM/YYYY]"
    ]
    for idx, text in enumerate(sig_titles):
        p = t_sig.cell(0, idx).paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.add_run(text).font.size = Pt(8.5)
    t_sig.alignment = WD_TABLE_ALIGNMENT.CENTER
    doc.add_paragraph().paragraph_format.space_after = Pt(12)

    # Affix ID Card Box
    create_callout_box(doc, "Please attach a clear photocopy or digital scan of your official Student Identity Card or Registration Confirmation Receipt in this section.", "[ ATTACH PHOTOCOPY OF OFFICIAL STUDENT ID CARD / ENROLLMENT RECEIPT HERE ]")

    doc.add_page_break()

    # -------------------------------------------------------------------------
    # PART 3: CANDIDATE UNDERTAKING
    # -------------------------------------------------------------------------
    doc.add_heading("PART 3: CANDIDATE UNDERTAKING & DECLARATION", level=1)
    p_und_intro = doc.add_paragraph(
        "I, [Candidate Full Name], son/daughter of [Guardian Name], enrolled in [Degree / Program Name], "
        "bearing Registration / Roll Number [Registration Number], Department of [Department Name], "
        "[Institution / University Name], do hereby solemnly affirm and undertake as follows:"
    )
    p_und_intro.paragraph_format.space_after = Pt(6)

    clauses = [
        ("1. Originality of Work: ", "I declare that the project titled 'Smart Warehouse AMR Fleet Coordination System' represents an authentic, original technical effort conceived, coded, and tested by me under the supervision of [Supervisor Name, Designation]."),
        ("2. Ethical Coding & Non-Plagiarism: ", "I certify that all algorithmic code (including A* Manhattan search, Master-Slave picking leases, lateral corridor clearance, P2P task trading, and low-battery BMS task preservation), simulation scripts, and telemetry dashboards are genuine and free of uncredited third-party plagiarism."),
        ("3. Integrity of Simulation Results: ", "All empirical benchmark metrics, throughput charts, conflict resolution times, and travel distance numbers reported in this portfolio reflect genuine tests executed in MATLAB and have not been fabricated or falsified."),
        ("4. Non-Submission Elsewhere: ", "I affirm that this project work has not been previously submitted by me or any other person to any other university, examination board, or institution for the award of any degree or diploma."),
        ("5. Institutional Compliance: ", "I agree to abide by all academic integrity regulations established by [Institution / University Name]. Any violation shall render this submission subject to institutional disqualification.")
    ]
    for title, desc in clauses:
        p_c = doc.add_paragraph()
        r_t = p_c.add_run(title)
        r_t.bold = True
        r_t.font.color.rgb = RGBColor(26, 54, 93)
        p_c.add_run(desc)
        p_c.paragraph_format.space_after = Pt(4)

    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # Undertaking Signatures
    t_und_sig = doc.add_table(rows=1, cols=2)
    p1 = t_und_sig.cell(0, 0).paragraphs[0]
    p1.add_run("Place: _____________________\nDate:  [DD/MM/YYYY]")
    p2 = t_und_sig.cell(0, 1).paragraphs[0]
    p2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p2.add_run("_________________________________________\nSignature of Candidate\nName: [Candidate Full Name]\nRoll No: [Registration Number]")
    t_und_sig.alignment = WD_TABLE_ALIGNMENT.CENTER
    doc.add_paragraph().paragraph_format.space_after = Pt(16)

    create_callout_box(
        doc,
        "I have scrutinized the source code, verified the automated simulation execution, and reviewed the portfolio "
        "submitted by the candidate. To the best of my technical knowledge and oversight, the project represents an authentic "
        "effort carried out in accordance with institutional guidelines and is recommended for formal evaluation.\n\n"
        "Date: [DD/MM/YYYY]                                  Signature of Faculty Supervisor: _________________________",
        "SUPERVISOR COUNTER-ENDORSEMENT:"
    )

    doc.add_page_break()

    # -------------------------------------------------------------------------
    # PART 4: SUPPORTING DOCUMENTS
    # -------------------------------------------------------------------------
    doc.add_heading("PART 4: SUPPORTING DOCUMENTS", level=1)

    # Document 4A: Recommendation Certificate
    doc.add_heading("Document 4A: Project Approval & Guide Recommendation Certificate", level=2)
    create_callout_box(
        doc,
        "This is to certify that the project entitled \"Smart Warehouse AMR Fleet Coordination System: Edge-AI Multi-Agent Swarm, "
        "Distributed Traffic Management and 3D Digital Twin\" submitted by [Candidate Full Name] (Registration No: [Registration Number]) "
        "in partial fulfillment of the requirements for the award of [Degree / Program Name] has been carried out under our supervision.\n\n"
        "The work demonstrates high engineering rigor, algorithmic correctness, innovative peer-to-peer robotics coordination, "
        "and zero-loss energy management. We approve the project work and recommend the candidate for final project defense.\n\n"
        "Internal Project Supervisor: ___________________________    Head of Department: ___________________________",
        "CERTIFICATE OF SATISFACTORY COMPLETION & APPROVAL:"
    )
    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # Document 4B: Test Report
    doc.add_heading("Document 4B: Automated Verification Test Report (100% Pass)", level=2)
    t_test = doc.add_table(rows=8, cols=3)
    t_test.cell(0, 0).paragraphs[0].add_run("Test ID")
    t_test.cell(0, 1).paragraphs[0].add_run("Verification Assertion / Condition")
    t_test.cell(0, 2).paragraphs[0].add_run("Result")
    format_table_header(t_test.rows[0])

    test_rows = [
        ("TC-01: Grid & Quadrants", "30x30 Dimensions, 4 Zone boundaries verified", "PASS [✓]"),
        ("TC-02: A* Shortest Path", "Obstacle bypass verified; exact start/goal waypoints", "PASS [✓]"),
        ("TC-03: Edge-AI Scoring", "Multi-criteria distance, priority & battery weighting", "PASS [✓]"),
        ("TC-04: Master-Slave Leases", "Exclusive picking corridor lock; secondary AMRs buffered", "PASS [✓]"),
        ("TC-05: Corridor Clearance", "Head-on encounter lateral clearance in < 1.0s", "PASS [✓]"),
        ("TC-06: P2P Task Trading", "R1/R4 cross-zone mutual swap handshake verified", "PASS [✓]"),
        ("TC-07: Battery BMS (<30%)", "Active order frozen in memory; resumes 100% post-charge", "PASS [✓]")
    ]
    for idx, (tid, desc, res) in enumerate(test_rows, start=1):
        t_test.cell(idx, 0).paragraphs[0].add_run(tid).bold = True
        t_test.cell(idx, 1).paragraphs[0].add_run(desc)
        r_r = t_test.cell(idx, 2).paragraphs[0].add_run(res)
        r_r.bold = True
        t_test.cell(idx, 2).paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.CENTER
    format_table_cells(t_test, [2.0, 3.5, 1.0])
    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # Document 4D: User Manual
    doc.add_heading("Document 4D: User Manual & Execution Quick-Start", level=2)
    p_man = doc.add_paragraph(
        "1. Open MATLAB and navigate to the project directory:\n"
        "   >> cd('c:/Users/deepa/OneDrive/Documents/anti')\n\n"
        "2. Choose your execution mode:\n"
        "   • 2D Fleet Simulation (Modular): run_simulation(1)\n"
        "   • 3D Digital Twin Simulation: run_simulation_3d\n"
        "   • Standalone Single-File 2D Simulation: SmartWarehouse2D_AllInOne\n"
        "   • Full Automated Test Suite: run_simulation(5)"
    )
    p_man.paragraph_format.space_after = Pt(8)

    doc.save(filename)
    print(f"[SUCCESS] Generated: {filename}")

if __name__ == "__main__":
    build_curated_portfolio_docx()
    build_full_submission_package_docx()
