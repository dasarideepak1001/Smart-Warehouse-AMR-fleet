import os
import sys
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        if self._pageNumber == 1:
            return
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#4A5568"))
        self.drawString(54, 750, "Autonomous Robotics & Multi-Agent Swarm Engineering Portfolio")
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        self.line(54, 744, 558, 744)
        self.line(54, 45, 558, 45)
        self.drawString(54, 32, "Confidential Project Submission Dossier")
        self.drawRightString(558, 32, f"Page {self._pageNumber} of {page_count}")
        self.restoreState()

def build_pdf(filename="Smart_Warehouse_AMR_Curated_Portfolio_Submission.pdf"):
    doc = SimpleDocTemplate(filename, pagesize=letter, leftMargin=54, rightMargin=54, topMargin=54, bottomMargin=54)
    styles = getSampleStyleSheet()

    PRIMARY = colors.HexColor("#1A365D")
    SECONDARY = colors.HexColor("#2B6CB0")
    DARK_TEXT = colors.HexColor("#2D3748")
    LIGHT_BG = colors.HexColor("#F7FAFC")
    BORDER_COLOR = colors.HexColor("#E2E8F0")

    title_s = ParagraphStyle('DocTitle', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=22, leading=26, textColor=PRIMARY, alignment=TA_CENTER, spaceAfter=8)
    subtitle_s = ParagraphStyle('DocSubTitle', parent=styles['Normal'], fontName='Helvetica', fontSize=11, leading=15, textColor=SECONDARY, alignment=TA_CENTER, spaceAfter=18)
    h1_s = ParagraphStyle('H1', parent=styles['Heading1'], fontName='Helvetica-Bold', fontSize=14, leading=18, textColor=PRIMARY, spaceBefore=12, spaceAfter=6, keepWithNext=True)
    h2_s = ParagraphStyle('H2', parent=styles['Heading2'], fontName='Helvetica-Bold', fontSize=11, leading=15, textColor=SECONDARY, spaceBefore=8, spaceAfter=4, keepWithNext=True)
    body_s = ParagraphStyle('Body', parent=styles['Normal'], fontName='Helvetica', fontSize=8.8, leading=12.5, textColor=DARK_TEXT, alignment=TA_JUSTIFY, spaceAfter=5)
    th_s = ParagraphStyle('TH', parent=styles['Normal'], fontName='Helvetica-Bold', fontSize=8.5, leading=11, textColor=colors.white, alignment=TA_CENTER)
    td_s = ParagraphStyle('TD', parent=styles['Normal'], fontName='Helvetica', fontSize=8.0, leading=10.5, textColor=DARK_TEXT, alignment=TA_LEFT)
    td_c = ParagraphStyle('TDC', parent=td_s, alignment=TA_CENTER)

    story = []

    # PAGE 1: FRONT MATTER (Cover + Skills Matrix)
    story.append(Spacer(1, 20))
    story.append(Paragraph("ENGINEERING PROJECT PORTFOLIO", ParagraphStyle('Sub', fontName='Helvetica-Bold', fontSize=11, textColor=SECONDARY, alignment=TA_CENTER, spaceAfter=10)))
    story.append(Paragraph("Smart Warehouse AMR Fleet<br/>Coordination System", title_s))
    story.append(Paragraph("Edge-AI Multi-Agent Swarm, Distributed Traffic Management & 3D Digital Twin", subtitle_s))
    story.append(HRFlowable(width="80%", thickness=1.5, color=PRIMARY, spaceBefore=2, spaceAfter=16))

    meta_data = [
        [Paragraph("<b>Candidate Name:</b>", td_s), Paragraph("[Candidate Full Name]", td_s)],
        [Paragraph("<b>Roll / Reg No:</b>", td_s), Paragraph("[Registration / Roll Number]", td_s)],
        [Paragraph("<b>Program & Dept:</b>", td_s), Paragraph("[Degree / Program Name], Department of Computer Science & Robotics", td_s)],
        [Paragraph("<b>Institution:</b>", td_s), Paragraph("[University / Institution Full Name]", td_s)],
        [Paragraph("<b>Primary Platform:</b>", td_s), Paragraph("MATLAB R2021a - R2026a (OOP & 3D Digital Twin) | Python 3", td_s)],
        [Paragraph("<b>Date & Status:</b>", td_s), Paragraph("September 2026 | Verified & Final Submission Ready", td_s)],
    ]
    t_m = Table(meta_data, colWidths=[140, 360])
    t_m.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), LIGHT_BG),
        ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t_m)
    story.append(Spacer(1, 14))

    story.append(Paragraph("TECHNICAL SKILLS MATRIX", h2_s))
    skills_data = [
        [Paragraph("<b>Domain / Category</b>", th_s), Paragraph("<b>Applied Skills & Technical Competencies</b>", th_s)],
        [Paragraph("<b>Languages & Tools</b>", td_s), Paragraph("MATLAB (OOP, Vectorization, Graphics Engine), Python, Git", td_s)],
        [Paragraph("<b>Robotics & Navigation</b>", td_s), Paragraph("A* Shortest-Path Planning, Manhattan Heuristics, Dynamic Avoid-Masks, Kinematics", td_s)],
        [Paragraph("<b>Swarm Intelligence</b>", td_s), Paragraph("Master-Slave Exclusive Aisle Leases, Lateral Collision Dispersal, Distributed Allocation", td_s)],
        [Paragraph("<b>Networking Protocols</b>", td_s), Paragraph("Peer-to-Peer (R2R) Mesh, Cross-Zone Task Trading (\"Bring My Item\"), 1-hop Handshake", td_s)],
        [Paragraph("<b>Energy Management</b>", td_s), Paragraph("Battery BMS (<30%), Task Memory Freezing (PausedForCharging), Dual-Port Balancing", td_s)],
        [Paragraph("<b>Digital Twin & GUI</b>", td_s), Paragraph("2D Quad-Shell Telemetry Dashboard, Interactive UITable, 3D Digital Twin with 360° Orbit", td_s)],
    ]
    t_s = Table(skills_data, colWidths=[140, 360])
    t_s.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PRIMARY),
        ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, LIGHT_BG]),
        ('TOPPADDING', (0, 0), (-1, -1), 3.5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3.5),
    ]))
    story.append(t_s)
    story.append(PageBreak())

    # PAGE 2: PROJECT OVERVIEW, ARCHITECTURE & CORE ALGORITHMS
    story.append(Paragraph("PROJECT DOSSIER: CORE ENGINEERING & ARCHITECTURE", h1_s))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY, spaceBefore=2, spaceAfter=8))

    story.append(Paragraph("At-A-Glance Specification", h2_s))
    glance_data = [
        [Paragraph("<b>Grid & Dimensions</b>", td_s), Paragraph("30×30 Grid Warehouse (900 Cells), 8 Shelves (A-H), 2 Pack Hubs, 2 Dual Chargers", td_s)],
        [Paragraph("<b>Fleet Configuration</b>", td_s), Paragraph("5 Autonomous Mobile Robots (AMRs: R1-R5) with differential kinematics & LiDAR puck", td_s)],
        [Paragraph("<b>Core Protocols</b>", td_s), Paragraph("Master-Slave Picking Leases, Lateral Corridor Dispersal, P2P Task Trading, BMS", td_s)],
        [Paragraph("<b>Role in Project</b>", td_s), Paragraph("Lead Robotics, Swarm Intelligence & Simulation Engineer (Full Architecture & Code)", td_s)]
    ]
    t_g = Table(glance_data, colWidths=[140, 360])
    t_g.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), LIGHT_BG),
        ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ]))
    story.append(t_g)
    story.append(Spacer(1, 8))

    story.append(Paragraph("Problem Statement & Architecture", h2_s))
    story.append(Paragraph(
        "High-density automated fulfillment centers suffer from corridor deadlocks, multi-robot picking congestion in narrow aisles, "
        "and excessive cross-facility transit overheads. Monolithic centralized servers introduce single-point failure risks and computational lag, "
        "while typical charging routines drop active customer orders. This project implements a decentralized multi-agent AMR system that eliminates "
        "deadlocks in under 0.8 seconds, autonomously trades cross-zone tasks, and preserves active tasks with zero order loss.",
        body_s
    ))

    story.append(Paragraph("Core Algorithmic Innovations", h2_s))
    story.append(Paragraph("<b>1. A* Pathfinding with Zero-Stall Next-Step Initialization:</b> Evaluates Manhattan cost <i>f(n) = g(n) + h(n)</i> with dynamic avoid-masks. Initializes <i>PathIndex = 2</i> when starting at current position to eliminate 1-tick stationary hesitation.", body_s))
    story.append(Paragraph("<b>2. Master-Slave Exclusive Aisle Leases:</b> Prevents congestion in narrow shelf picking aisles. The nearest robot secures the Master lease, while contender robots wait in safe buffer cells outside the aisle until the Master exits.", body_s))
    story.append(Paragraph("<b>3. High-Speed Lateral Corridor Dispersal:</b> Detects conflicts within 3.0 cells. The higher-priority AMR (or low-battery AMR) maintains right-of-way, while the Slave executes a lateral sidestep into a parallel lane in < 0.8s.", body_s))
    story.append(Paragraph("<b>4. P2P Task Trading Mesh (\"Bring My Item\"):</b> AMRs in opposing zones execute a mutual wireless handshake to swap cross-zone delivery tasks, saving 28 to 52 grid cells of travel per transaction.", body_s))
    story.append(Paragraph("<b>5. Low-Battery BMS (<30%) & Task Memory Freezing:</b> Active orders are frozen in memory as <i>PausedForCharging</i>. Robots route to dual-port docks without corridor freezing and automatically resume interrupted jobs post-charge.", body_s))
    story.append(PageBreak())

    # PAGE 3: RESULTS, TELEMETRY VISUALIZERS & EXECUTION
    story.append(Paragraph("RESULTS, TELEMETRY & REPOSITORY NAVIGATION", h1_s))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY, spaceBefore=2, spaceAfter=8))

    story.append(Paragraph("Empirical Benchmark Results (500s Simulation Run)", h2_s))
    res_data = [
        [Paragraph("<b>Performance Metric</b>", th_s), Paragraph("<b>Centralized Baseline</b>", th_s), Paragraph("<b>Proposed Distributed Swarm</b>", th_s), Paragraph("<b>Empirical Gain</b>", th_s)],
        [Paragraph("Order Fulfillment Throughput", td_s), Paragraph("18.2 orders / 500s", td_s), Paragraph("<b>24.4 orders / 500s</b>", td_s), Paragraph("<b>+ 34.1% Higher</b>", td_c)],
        [Paragraph("Cross-Facility Travel Distance", td_s), Paragraph("1,420 grid cells", td_s), Paragraph("<b>1,040 grid cells</b>", td_s), Paragraph("<b>- 26.8% Saved</b>", td_c)],
        [Paragraph("Corridor Conflict Resolution Time", td_s), Paragraph("4.2 seconds", td_s), Paragraph("<b>< 0.8 seconds</b>", td_s), Paragraph("<b>81.0% Faster</b>", td_c)],
        [Paragraph("Aisle Deadlocks & Freezes", td_s), Paragraph("14 deadlock events", td_s), Paragraph("<b>0 (Zero Deadlocks)</b>", td_s), Paragraph("<b>100% Resolved</b>", td_c)],
        [Paragraph("Task Loss on Low Battery", td_s), Paragraph("3 orders abandoned", td_s), Paragraph("<b>0 (100% resumed)</b>", td_s), Paragraph("<b>Zero Task Loss</b>", td_c)],
    ]
    t_r = Table(res_data, colWidths=[150, 115, 125, 110])
    t_r.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PRIMARY),
        ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, LIGHT_BG]),
        ('TOPPADDING', (0, 0), (-1, -1), 3.5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3.5),
    ]))
    story.append(t_r)
    story.append(Spacer(1, 10))

    story.append(Paragraph("Dual Telemetry & Visualizer Environments", h2_s))
    story.append(Paragraph(
        "• <b>2D Telemetry Dashboard (WarehouseDashboard.m & SmartWarehouse2D_AllInOne.m):</b> Features a 60% floor canvas "
        "with live AMR position markers, dotted route trajectories, and four live panels: Shell 1 (System KPI HUD), Shell 2 (Scrollable R2R Dialogue Terminal), "
        "Shell 3 (Real-Time In-Hand Parcel Monitor), and Shell 4 (Interactive Orders UITable with barcodes and timestamps).<br/>"
        "• <b>3D Digital Twin Visualizer (WarehouseDashboard3D.m & run_simulation_3d.m):</b> Renders multi-tier industrial storage racks, "
        "AMRs with rotating LiDAR pucks, <b>physically loaded 3D parcel boxes</b> on cargo decks, illuminated dual-state charging docks, glowing cyan wireless laser beams, "
        "and interactive 360° orbital camera controls.",
        body_s
    ))

    story.append(Paragraph("Repository Execution Quick-Start", h2_s))
    repo_data = [
        [Paragraph("<b>Command</b>", th_s), Paragraph("<b>Script File</b>", th_s), Paragraph("<b>Functional Responsibility & Mode</b>", th_s)],
        [Paragraph("<code>run_simulation(1)</code>", td_s), Paragraph("<code>run_simulation.m</code>", td_s), Paragraph("Launches nominal 2D modular fleet simulation with full telemetry.", td_s)],
        [Paragraph("<code>run_simulation_3d</code>", td_s), Paragraph("<code>run_simulation_3d.m</code>", td_s), Paragraph("Launches 3D Digital Twin simulation with 360° camera orbit & parcel boxes.", td_s)],
        [Paragraph("<code>SmartWarehouse2D_AllInOne</code>", td_s), Paragraph("<code>SmartWarehouse2D_AllInOne.m</code>", td_s), Paragraph("Runs standalone single-file 2D simulation with zero folder dependencies.", td_s)],
        [Paragraph("<code>run_simulation(5)</code>", td_s), Paragraph("<code>benchmarks/</code>", td_s), Paragraph("Executes full 13-point automated unit & integration test suite (100% Pass).", td_s)],
    ]
    t_rep = Table(repo_data, colWidths=[140, 140, 220])
    t_rep.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), SECONDARY),
        ('BOX', (0, 0), (-1, -1), 1, BORDER_COLOR),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, LIGHT_BG]),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ]))
    story.append(t_rep)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"[SUCCESS] Built Curated Portfolio PDF: {filename}")

if __name__ == "__main__":
    build_pdf()
