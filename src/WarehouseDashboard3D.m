classdef WarehouseDashboard3D < handle
    % WAREHOUSEDASHBOARD3D Ultra-Realistic Interactive 3D Digital Twin GUI Dashboard
    % Renders full 3D industrial multi-tier racks, category-coded totes, 3D AMRs
    % with loaded parcels, 3D charging towers, glowing P2P laser beams, and
    % interactive camera orbital controls alongside all real-time scrollable shells.
    
    properties
        Fig                 % Figure window handle
        MapAx               % Main 3D Map Axes handle
        InfoAx              % System KPI HUD panel handle
        R2RTableUI          % Scrollable R2R P2P Task Trade Shell
        OrderLogUI          % Scrollable Real-Time Order & Parcel Status Shell
        OrderTableUI        % Interactive MATLAB uitable control
        HasGUI              % Boolean flag for GUI availability
        
        % 3D Camera State
        CamAz               % Current camera azimuth angle
        CamEl               % Current camera elevation angle
        LightHandle         % 3D scene light handle
    end
    
    methods
        function obj = WarehouseDashboard3D(titleStr)
            if nargin < 1, titleStr = 'Smart Warehouse AMR Fleet 3D Digital Twin (Edge AI)'; end
            
            % Initial 3D isometric perspective
            obj.CamAz = -38;
            obj.CamEl = 36;
            
            % Check if graphical display is available
            obj.HasGUI = feature('ShowFigureWindows');
            if ~obj.HasGUI
                try
                    obj.Fig = figure('Visible', 'off');
                    close(obj.Fig);
                    obj.HasGUI = false;
                catch
                    obj.HasGUI = false;
                end
            end
            
            if obj.HasGUI
                % Sleek Cyber-Dark Theme Figure (Width: 1440, Height: 840)
                obj.Fig = figure('Name', titleStr, 'NumberTitle', 'off', ...
                    'Position', [20, 20, 1440, 840], 'Color', [0.08, 0.10, 0.14], ...
                    'Renderer', 'opengl');
                
                % Left Subplot: 3D Warehouse Environment (57% width, 88% height)
                obj.MapAx = subplot('Position', [0.03, 0.04, 0.57, 0.88]);
                
                % 3D Camera Quick-Switch Buttons Bar
                uicontrol('Parent', obj.Fig, 'Style', 'pushbutton', 'String', '🌐 Isometric 3D', ...
                    'Units', 'normalized', 'Position', [0.03, 0.94, 0.10, 0.035], ...
                    'BackgroundColor', [0.18, 0.22, 0.30], 'ForegroundColor', [0.35, 0.92, 1.0], ...
                    'FontWeight', 'bold', 'FontSize', 8, ...
                    'Callback', @(~,~) obj.setCameraView(-38, 36));
                
                uicontrol('Parent', obj.Fig, 'Style', 'pushbutton', 'String', '⬇️ Top-Down (2.5D)', ...
                    'Units', 'normalized', 'Position', [0.135, 0.94, 0.11, 0.035], ...
                    'BackgroundColor', [0.18, 0.22, 0.30], 'ForegroundColor', [0.95, 0.95, 1.0], ...
                    'FontWeight', 'bold', 'FontSize', 8, ...
                    'Callback', @(~,~) obj.setCameraView(0, 89));
                
                uicontrol('Parent', obj.Fig, 'Style', 'pushbutton', 'String', '🔍 Zone 1/4 View', ...
                    'Units', 'normalized', 'Position', [0.250, 0.94, 0.10, 0.035], ...
                    'BackgroundColor', [0.18, 0.22, 0.30], 'ForegroundColor', [0.95, 0.95, 1.0], ...
                    'FontWeight', 'bold', 'FontSize', 8, ...
                    'Callback', @(~,~) obj.setCameraView(-65, 30));
                
                uicontrol('Parent', obj.Fig, 'Style', 'pushbutton', 'String', '🔍 Zone 2/3 View', ...
                    'Units', 'normalized', 'Position', [0.355, 0.94, 0.10, 0.035], ...
                    'BackgroundColor', [0.18, 0.22, 0.30], 'ForegroundColor', [0.95, 0.95, 1.0], ...
                    'FontWeight', 'bold', 'FontSize', 8, ...
                    'Callback', @(~,~) obj.setCameraView(45, 30));
                
                uicontrol('Parent', obj.Fig, 'Style', 'pushbutton', 'String', '🔄 Orbit Rotate3D', ...
                    'Units', 'normalized', 'Position', [0.460, 0.94, 0.11, 0.035], ...
                    'BackgroundColor', [0.12, 0.35, 0.25], 'ForegroundColor', [0.4, 1.0, 0.6], ...
                    'FontWeight', 'bold', 'FontSize', 8, ...
                    'Callback', @(~,~) rotate3d(obj.MapAx));
                
                % Right 1 (Top): System KPI Dashboard Card (36% width, 19% height)
                obj.InfoAx = subplot('Position', [0.61, 0.77, 0.36, 0.19]);
                
                % Right 2 (Upper Middle): SCROLLABLE R2R TASK TRADE SHELL (36% width, 24% height)
                obj.R2RTableUI = uitable('Parent', obj.Fig, ...
                    'Units', 'normalized', ...
                    'Position', [0.61, 0.51, 0.36, 0.24], ...
                    'ColumnName', {' 🔄 R2R P2P TASK TRADE: "BRING MY ITEM, I BRING YOURS" '}, ...
                    'ColumnWidth', {485}, ...
                    'RowName', [], ...
                    'BackgroundColor', [0.06 0.08 0.12; 0.08 0.10 0.16], ...
                    'ForegroundColor', [0.35 0.92 1.0], ...
                    'FontName', 'Courier', 'FontSize', 8, 'FontWeight', 'bold');
                
                % Right 3 (Lower Middle): SCROLLABLE REAL-TIME ORDER & IN-HAND PARCEL SHELL (36% width, 22% height)
                obj.OrderLogUI = uitable('Parent', obj.Fig, ...
                    'Units', 'normalized', ...
                    'Position', [0.61, 0.26, 0.36, 0.22], ...
                    'ColumnName', {' 📦 REAL-TIME ORDER SHELL & IN-HAND PARCEL STATUS '}, ...
                    'ColumnWidth', {485}, ...
                    'RowName', [], ...
                    'BackgroundColor', [0.06 0.08 0.12; 0.08 0.10 0.16], ...
                    'ForegroundColor', [0.4 1.0 0.6], ...
                    'FontName', 'Courier', 'FontSize', 8, 'FontWeight', 'bold');
                
                % Right 4 (Bottom): INTERACTIVE SCROLLABLE HISTORICAL ORDERS UITABLE (36% width, 22% height)
                obj.OrderTableUI = uitable('Parent', obj.Fig, ...
                    'Units', 'normalized', ...
                    'Position', [0.61, 0.02, 0.36, 0.22], ...
                    'ColumnName', {'No', 'Product Name', 'Category', 'Barcode', 'Timestamp', 'Status'}, ...
                    'ColumnWidth', {32, 100, 95, 75, 65, 140}, ...
                    'BackgroundColor', [0.08 0.10 0.15; 0.10 0.12 0.18], ...
                    'ForegroundColor', [0.4 1.0 0.6], ...
                    'FontName', 'Courier', 'FontSize', 8, 'FontWeight', 'bold');
            end
        end
        
        function setCameraView(obj, az, el)
            obj.CamAz = az;
            obj.CamEl = el;
            if ~isempty(obj.MapAx) && isvalid(obj.MapAx)
                view(obj.MapAx, [az, el]);
            end
        end
        
        function render(obj, map, robots, taskMgr, collisionAvoid, allocator, currentTick, r2rCommunicator, masterSlaveController)
            if ~obj.HasGUI || ~isvalid(obj.Fig)
                return;
            end
            if nargin < 8, r2rCommunicator = []; end
            if nargin < 9, masterSlaveController = []; end
            
            set(0, 'CurrentFigure', obj.Fig);
            
            % Preserve user rotation if camera was orbited
            if ~isempty(obj.MapAx) && isvalid(obj.MapAx)
                try
                    [az, el] = view(obj.MapAx);
                    if ~isnan(az) && ~isnan(el) && (az ~= 0 || el ~= 90)
                        obj.CamAz = az;
                        obj.CamEl = el;
                    end
                catch
                end
            end
            
            % -------------------------------------------------------------
            % 1. RENDER 3D WAREHOUSE ENVIRONMENT
            % -------------------------------------------------------------
            axes(obj.MapAx);
            cla(obj.MapAx);
            hold(obj.MapAx, 'on');
            
            w = map.GridDimensions(1);
            h = map.GridDimensions(2);
            
            % Setup 3D Canvas
            set(obj.MapAx, 'Color', [0.10, 0.12, 0.16], ...
                'XColor', [0.5, 0.55, 0.65], 'YColor', [0.5, 0.55, 0.65], 'ZColor', [0.5, 0.55, 0.65]);
            xlim(obj.MapAx, [0.5, w + 0.5]);
            ylim(obj.MapAx, [0.5, h + 0.5]);
            zlim(obj.MapAx, [0.0, 4.5]);
            view(obj.MapAx, [obj.CamAz, obj.CamEl]);
            grid(obj.MapAx, 'on');
            set(obj.MapAx, 'GridColor', [0.22, 0.26, 0.35], 'GridAlpha', 0.5);
            
            % 3D Industrial Lighting
            light('Position', [15, 15, 20], 'Style', 'local', 'Color', [1 0.98 0.95], 'Parent', obj.MapAx);
            light('Position', [5, 25, 15], 'Style', 'local', 'Color', [0.6 0.7 0.9], 'Parent', obj.MapAx);
            lighting(obj.MapAx, 'flat');
            
            % A. 3D Warehouse Floor Base
            patch('Vertices', [0.5 0.5 0; w+0.5 0.5 0; w+0.5 h+0.5 0; 0.5 h+0.5 0], ...
                  'Faces', [1 2 3 4], 'FaceColor', [0.12, 0.14, 0.18], 'EdgeColor', [0.18, 0.22, 0.28], ...
                  'Parent', obj.MapAx);
            
            % Floor Grid Lines
            for x = 1:5:w
                line(obj.MapAx, [x x], [0.5 h+0.5], [0.005 0.005], 'Color', [0.18, 0.22, 0.30], 'LineWidth', 0.8);
            end
            for y = 1:5:h
                line(obj.MapAx, [0.5 w+0.5], [y y], [0.005 0.005], 'Color', [0.18, 0.22, 0.30], 'LineWidth', 0.8);
            end
            
            % Zone Division Dashed Boundaries on Floor
            line(obj.MapAx, [15.5 15.5], [0.5 h+0.5], [0.01 0.01], 'Color', [0.35, 0.45, 0.65], 'LineStyle', '--', 'LineWidth', 1.5);
            line(obj.MapAx, [0.5 w+0.5], [14.5 14.5], [0.01 0.01], 'Color', [0.35, 0.45, 0.65], 'LineStyle', '--', 'LineWidth', 1.5);
            
            % Zone Subtle Watermark Badges on Floor
            text(obj.MapAx, 7.5, 7.5, 0.02, 'ZONE 1 (West Top)', 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.25, 0.32, 0.45]);
            text(obj.MapAx, 22.5, 7.5, 0.02, 'ZONE 2 (East Top)', 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.25, 0.32, 0.45]);
            text(obj.MapAx, 7.5, 22.5, 0.02, 'ZONE 3 (West Bottom)', 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.25, 0.32, 0.45]);
            text(obj.MapAx, 22.5, 22.5, 0.02, 'ZONE 4 (East Bottom)', 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.25, 0.32, 0.45]);
            
            % B. Render 3D Industrial Storage Racks with Totes
            obj.renderShelves3D(map, masterSlaveController);
            
            % C. Render 3D Packing Stations
            obj.renderPackingStations3D(map, robots);
            
            % D. Render 3D Charging Stations (Ports 1A, 1B, 2A, 2B)
            [c1Count, c2Count] = obj.renderChargingStations3D(map, robots);
            
            % E. Render 3D P2P Wireless Data Link Beams
            obj.renderWirelessBeams3D(robots);
            
            % F. Render 3D AMRs, Paths & Cargo Parcels
            obj.renderRobots3D(robots, map, masterSlaveController);
            
            title(obj.MapAx, sprintf('3D DIGITAL TWIN: SMART AMR FLEET SIMULATION | TICK: %d s', currentTick), ...
                'Color', [0.35, 0.92, 1.0], 'FontSize', 10, 'FontWeight', 'bold');
            
            % -------------------------------------------------------------
            % 2. UPDATE SYSTEM KPI HUD (INFOAX)
            % -------------------------------------------------------------
            axes(obj.InfoAx);
            cla(obj.InfoAx);
            set(obj.InfoAx, 'Color', [0.06, 0.08, 0.12], 'XColor', 'none', 'YColor', 'none');
            xlim(obj.InfoAx, [0, 1]); ylim(obj.InfoAx, [0, 1]);
            
            activeRobots = sum(strcmp({robots.Status}, 'Working') | strcmp({robots.Status}, 'RoutingToCharge'));
            r2rMsgs = 0; r2rTrades = 0;
            if ~isempty(r2rCommunicator)
                if isprop(r2rCommunicator, 'TotalMessagesTransmitted')
                    r2rMsgs = r2rCommunicator.TotalMessagesTransmitted;
                end
                if isprop(r2rCommunicator, 'TotalCrossZoneTrades')
                    r2rTrades = r2rCommunicator.TotalCrossZoneTrades;
                end
            end
            
            msPicks = 0; msDeadlocks = 0; msCoops = 0;
            if ~isempty(masterSlaveController)
                msPicks = masterSlaveController.MasterPickCommandCount;
                msDeadlocks = masterSlaveController.AisleDeadlocksAvoided;
                msCoops = masterSlaveController.CollaborativePicksCount;
            end
            
            hudText = cell(11, 1);
            hudText{1} = '========================================';
            hudText{2} = '  3D DIGITAL TWIN KPI HUD (EDGE AI)     ';
            hudText{3} = '========================================';
            hudText{4} = sprintf('  Mode:             %s', allocator.Mode);
            hudText{5} = sprintf('  Simulation Time:  %d s  | AMRs: %d/%d', currentTick, activeRobots, length(robots));
            hudText{6} = sprintf('  Fleet Battery:    R1:%.0f%% R2:%.0f%% R3:%.0f%% R4:%.0f%% R5:%.0f%%', ...
                robots(1).Battery, robots(2).Battery, robots(3).Battery, robots(4).Battery, robots(5).Battery);
            hudText{7} = sprintf('  Charging Ports:   C1 [%d/2] | C2 [%d/2]', c1Count, c2Count);
            hudText{8} = sprintf('  M-S Pick Leases:  %-3d  | Aisle Deadlocks: %-3d', msPicks, msDeadlocks);
            hudText{9} = sprintf('  Cross Trades:     %-3d  | Dual Co-op Picks:%-3d', r2rTrades, msCoops);
            hudText{10}= sprintf('  R2R Messages:     %-3d  | M-S Traffic Cmd: %-3d', r2rMsgs, msPicks);
            hudText{11}= sprintf('  Collisions Avoid: %-3d  | Re-plans:        %-3d', collisionAvoid.AvoidedCollisionsCount, collisionAvoid.ReplanningCount);
            
            text(obj.InfoAx, 0.03, 0.95, hudText, 'FontSize', 7.2, 'FontName', 'Courier', ...
                'FontWeight', 'bold', 'Color', [0.9, 0.95, 1.0], 'VerticalAlignment', 'top');
            
            % -------------------------------------------------------------
            % 3. UPDATE SCROLLABLE SHELLS & HISTORICAL TABLE
            % -------------------------------------------------------------
            obj.updateShellsAndTable(robots, taskMgr, r2rCommunicator);
            
            drawnow;
        end
        
        function renderShelves3D(obj, map, masterSlaveController)
            % Renders multi-tier steel storage racks with colorful category-coded totes
            shelfNames = fieldnames(map.Shelves);
            
            for s = 1:numel(shelfNames)
                sName = shelfNames{s};
                sInfo = map.Shelves.(sName);
                
                yMin = sInfo.Area(1); yMax = sInfo.Area(2);
                xMin = sInfo.Area(3); xMax = sInfo.Area(4);
                
                % Rack Posts & Beams Color (Dark Industrial Steel)
                rackColor = [0.22, 0.25, 0.32];
                
                % Highlight shelf if Master-Slave pick lease is active
                mID = 0;
                if ~isempty(masterSlaveController) && isfield(masterSlaveController.ShelfLocks, sName)
                    mID = masterSlaveController.ShelfLocks.(sName);
                    if mID > 0
                        rackColor = [0.15, 0.65, 0.85]; % Glowing Blue Lease
                    end
                end
                
                % Draw 4 Vertical Upright Posts
                colW = 0.2;
                obj.drawCuboid(xMin-0.5, xMin-0.5+colW, yMin-0.5, yMin-0.5+colW, 0, 2.6, rackColor);
                obj.drawCuboid(xMax+0.5-colW, xMax+0.5, yMin-0.5, yMin-0.5+colW, 0, 2.6, rackColor);
                obj.drawCuboid(xMin-0.5, xMin-0.5+colW, yMax+0.5-colW, yMax+0.5, 0, 2.6, rackColor);
                obj.drawCuboid(xMax+0.5-colW, xMax+0.5, yMax+0.5-colW, yMax+0.5, 0, 2.6, rackColor);
                
                % Draw 3 Shelf Levels (Decks)
                shelfZ = [0.75, 1.55, 2.35];
                for z = shelfZ
                    obj.drawCuboid(xMin-0.45, xMax+0.45, yMin-0.45, yMax+0.45, z, z+0.08, [0.30, 0.34, 0.42]);
                end
                
                % Category Color for Storage Bins/Totes
                toteColor = obj.getCategoryColor(sInfo.Category);
                
                % Place 3D Storage Bins on Each Level
                for z = shelfZ
                    for y = (yMin):2:(yMax-1)
                        obj.drawCuboid(xMin-0.3, xMin+0.3, y-0.35, y+0.35, z+0.08, z+0.55, toteColor);
                        obj.drawCuboid(xMax-0.3, xMax+0.3, y-0.35, y+0.35, z+0.08, z+0.55, toteColor * 0.9);
                    end
                end
                
                % 3D Floating Billboard Shelf Label
                xCenter = (xMin + xMax) / 2;
                yCenter = (yMin + yMax) / 2;
                
                shortCat = sInfo.Category;
                if isfield(sInfo, 'ShortCat'), shortCat = sInfo.ShortCat; end
                
                lblText = sprintf('%s\n%s', sName, shortCat);
                if mID > 0
                    lblText = sprintf('👑 R%d LEASE\n%s', mID, shortCat);
                    text(obj.MapAx, xCenter, yCenter, 3.2, lblText, 'FontSize', 7.5, ...
                        'FontWeight', 'bold', 'Color', [0.2, 0.95, 1.0], 'HorizontalAlignment', 'center');
                else
                    text(obj.MapAx, xCenter, yCenter, 3.2, lblText, 'FontSize', 7.2, ...
                        'FontWeight', 'bold', 'Color', [0.9, 0.92, 1.0], 'HorizontalAlignment', 'center');
                end
            end
        end
        
        function renderPackingStations3D(obj, map, robots)
            % Packing Station 1 (P1)
            p1 = map.PackingStations.P1.Pos;
            obj.drawCuboid(p1(1)-1.0, p1(1)+1.0, p1(2)-0.6, p1(2)+0.6, 0, 0.65, [0.15, 0.55, 0.35]);
            obj.drawCuboid(p1(1)-0.9, p1(1)+0.9, p1(2)-0.5, p1(2)+0.5, 0.65, 0.72, [0.65, 0.70, 0.75]); % Conveyor
            text(obj.MapAx, p1(1), p1(2), 1.6, 'PACK 1 📦', 'FontSize', 8, 'FontWeight', 'bold', ...
                'Color', [0.2, 0.95, 0.4], 'HorizontalAlignment', 'center');
            
            % Packing Station 2 (P2)
            p2 = map.PackingStations.P2.Pos;
            obj.drawCuboid(p2(1)-1.0, p2(1)+1.0, p2(2)-0.6, p2(2)+0.6, 0, 0.65, [0.15, 0.55, 0.35]);
            obj.drawCuboid(p2(1)-0.9, p2(1)+0.9, p2(2)-0.5, p2(2)+0.5, 0.65, 0.72, [0.65, 0.70, 0.75]); % Conveyor
            text(obj.MapAx, p2(1), p2(2), 1.6, 'PACK 2 📦', 'FontSize', 8, 'FontWeight', 'bold', ...
                'Color', [0.2, 0.95, 0.4], 'HorizontalAlignment', 'center');
        end
        
        function [c1Count, c2Count] = renderChargingStations3D(obj, map, robots)
            p1A = [2, 28]; p1B = [3, 28];
            p2A = [27, 28]; p2B = [28, 28];
            
            % Check Port Occupancy
            p1A_occ = false; p1B_occ = false; p2A_occ = false; p2B_occ = false;
            for r = 1:length(robots)
                b = robots(r);
                if strcmp(b.Status, 'Charging') || strcmp(b.Status, 'RoutingToCharge')
                    if isequal(b.Target, p1A) || (strcmp(b.Status, 'Charging') && isequal(b.Position, p1A)), p1A_occ = true; end
                    if isequal(b.Target, p1B) || (strcmp(b.Status, 'Charging') && isequal(b.Position, p1B)), p1B_occ = true; end
                    if isequal(b.Target, p2A) || (strcmp(b.Status, 'Charging') && isequal(b.Position, p2A)), p2A_occ = true; end
                    if isequal(b.Target, p2B) || (strcmp(b.Status, 'Charging') && isequal(b.Position, p2B)), p2B_occ = true; end
                end
            end
            
            c1Count = double(p1A_occ) + double(p1B_occ);
            c2Count = double(p2A_occ) + double(p2B_occ);
            
            % Colors: Emerald Green = Available/Free, Electric Cyan-Blue = Active Charging
            freeCol = [0.15, 0.75, 0.35];
            chgCol = [0.08, 0.55, 0.95];
            
            % Station 1 Docking Pads (1A & 1B)
            col1A = freeCol; if p1A_occ, col1A = chgCol; end
            col1B = freeCol; if p1B_occ, col1B = chgCol; end
            obj.drawCuboid(p1A(1)-0.45, p1A(1)+0.45, p1A(2)-0.45, p1A(2)+0.45, 0, 0.08, col1A);
            obj.drawCuboid(p1B(1)-0.45, p1B(1)+0.45, p1B(2)-0.45, p1B(2)+0.45, 0, 0.08, col1B);
            
            % Station 1 Charging Tower
            obj.drawCuboid(1.3, 1.7, 28.2, 28.8, 0, 1.6, [0.35, 0.38, 0.45]);
            text(obj.MapAx, 2.5, 29.3, 1.8, sprintf('CHARGER 1 [%d/2 Ports]', c1Count), ...
                'FontSize', 7.5, 'FontWeight', 'bold', 'Color', [1.0, 0.9, 0.3], 'HorizontalAlignment', 'center');
            text(obj.MapAx, p1A(1), p1A(2), 0.2, '1A⚡', 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w', 'HorizontalAlignment', 'center');
            text(obj.MapAx, p1B(1), p1B(2), 0.2, '1B⚡', 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w', 'HorizontalAlignment', 'center');
            
            % Station 2 Docking Pads (2A & 2B)
            col2A = freeCol; if p2A_occ, col2A = chgCol; end
            col2B = freeCol; if p2B_occ, col2B = chgCol; end
            obj.drawCuboid(p2A(1)-0.45, p2A(1)+0.45, p2A(2)-0.45, p2A(2)+0.45, 0, 0.08, col2A);
            obj.drawCuboid(p2B(1)-0.45, p2B(1)+0.45, p2B(2)-0.45, p2B(2)+0.45, 0, 0.08, col2B);
            
            % Station 2 Charging Tower
            obj.drawCuboid(28.3, 28.7, 28.2, 28.8, 0, 1.6, [0.35, 0.38, 0.45]);
            text(obj.MapAx, 27.5, 29.3, 1.8, sprintf('CHARGER 2 [%d/2 Ports]', c2Count), ...
                'FontSize', 7.5, 'FontWeight', 'bold', 'Color', [1.0, 0.9, 0.3], 'HorizontalAlignment', 'center');
            text(obj.MapAx, p2A(1), p2A(2), 0.2, '2A⚡', 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w', 'HorizontalAlignment', 'center');
            text(obj.MapAx, p2B(1), p2B(2), 0.2, '2B⚡', 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w', 'HorizontalAlignment', 'center');
        end
        
        function renderWirelessBeams3D(obj, robots)
            for r1 = 1:length(robots)
                bot1 = robots(r1);
                
                % Glowing Cyan-Green 3D Laser Beam connecting Cross-Zone Task Trading AMRs
                if bot1.R2RTradePartnerID > 0 && bot1.R2RTradePartnerID <= length(robots) && bot1.ID < bot1.R2RTradePartnerID
                    bot2 = robots(bot1.R2RTradePartnerID);
                    line(obj.MapAx, [bot1.Position(1), bot2.Position(1)], ...
                                    [bot1.Position(2), bot2.Position(2)], ...
                                    [0.85, 0.85], ...
                                    'Color', [0.15, 0.95, 1.0], 'LineStyle', ':', 'LineWidth', 2.5);
                end
                
                % Glowing Magenta 3D Line for P2P Coordination
                if ~isempty(bot1.AssignedPeerID) && bot1.ID < bot1.AssignedPeerID
                    bot2 = robots(bot1.AssignedPeerID);
                    line(obj.MapAx, [bot1.Position(1), bot2.Position(1)], ...
                                    [bot1.Position(2), bot2.Position(2)], ...
                                    [0.70, 0.70], ...
                                    'Color', [1.0, 0.2, 0.9], 'LineStyle', '-.', 'LineWidth', 2.0);
                end
            end
        end
        
        function renderRobots3D(obj, robots, map, masterSlaveController)
            for r = 1:length(robots)
                robot = robots(r);
                rx = robot.Position(1);
                ry = robot.Position(2);
                
                % Robot Color
                botCol = robot.Color;
                if isempty(botCol), botCol = [0.2, 0.8, 0.4]; end
                
                % 1. Render Planned Trajectory Line on Floor
                if ~isempty(robot.Path) && robot.PathIndex <= size(robot.Path, 1)
                    remPath = robot.Path(robot.PathIndex:end, :);
                    line(obj.MapAx, [rx; remPath(:, 1)], [ry; remPath(:, 2)], ...
                         ones(size(remPath, 1)+1, 1) * 0.03, ...
                         'Color', botCol, 'LineStyle', ':', 'LineWidth', 1.4);
                end
                
                % 2. Render 3D AMR Chassis Body (Low-Profile Heavy-Duty Platform)
                obj.drawCuboid(rx-0.42, rx+0.42, ry-0.42, ry+0.42, 0.04, 0.38, botCol);
                
                % Black Top Deck Plate
                obj.drawCuboid(rx-0.38, rx+0.38, ry-0.38, ry+0.38, 0.38, 0.42, [0.15, 0.16, 0.20]);
                
                % Drive Wheels on Sides
                obj.drawCuboid(rx-0.46, rx-0.42, ry-0.28, ry+0.28, 0.01, 0.24, [0.10, 0.10, 0.12]);
                obj.drawCuboid(rx+0.42, rx+0.46, ry-0.28, ry+0.28, 0.01, 0.24, [0.10, 0.10, 0.12]);
                
                % Top LiDAR Scanner Puck
                obj.drawCuboid(rx-0.12, rx+0.12, ry-0.12, ry+0.12, 0.42, 0.54, [0.1, 0.1, 0.12]);
                line(obj.MapAx, rx, ry, 0.55, 'Marker', 'o', 'MarkerSize', 5, ...
                    'MarkerFaceColor', [0.2, 0.95, 1.0], 'MarkerEdgeColor', 'w');
                
                % 3. Render 3D Loaded Parcel Box on Cargo Deck (When Carrying!)
                hasParcelInHand = ~isempty(robot.CurrentTask) && strcmp(robot.CurrentTask.State, 'HeadingToDelivery');
                if hasParcelInHand
                    % Cardboard Brown Parcel Box
                    obj.drawCuboid(rx-0.26, rx+0.26, ry-0.26, ry+0.26, 0.42, 0.88, [0.82, 0.62, 0.38]);
                    % Box Sealing Tape
                    line(obj.MapAx, [rx-0.26, rx+0.26], [ry, ry], [0.885, 0.885], ...
                        'Color', [0.95, 0.85, 0.5], 'LineWidth', 2.0);
                end
                
                % 4. Overhead Floating 3D Holographic Status Badge
                badgeZ = 1.35;
                if hasParcelInHand, badgeZ = 1.65; end
                
                statusStr = '';
                if strcmp(robot.Status, 'RoutingToCharge')
                    if ~isempty(robot.SavedTask)
                        statusStr = sprintf('⚡ Chg [Paused: %s]', robot.SavedTask.ItemName);
                    else
                        statusStr = '⚡ Charger';
                    end
                elseif strcmp(robot.Status, 'Charging')
                    minsLeft = max(1, ceil(robot.ChargeTicks / 4));
                    if ~isempty(robot.SavedTask)
                        statusStr = sprintf('⚡ Chg (%dm) [Paused: %s]', minsLeft, robot.SavedTask.ItemName);
                    else
                        statusStr = sprintf('⚡ Chg (%dm)', minsLeft);
                    end
                elseif hasParcelInHand
                    if robot.R2RTradePartnerID > 0
                        statusStr = sprintf('📦 R%d (for R%d) -> Pack', robot.ID, robot.R2RTradePartnerID);
                    else
                        statusStr = sprintf('📦 R%d: [%s]', robot.ID, robot.CurrentTask.ItemName);
                    end
                elseif ~isempty(robot.CurrentTask) && strcmp(robot.CurrentTask.State, 'HeadingToPickup')
                    if robot.R2RTradePartnerID > 0
                        statusStr = sprintf('🔄 R%d: [%s] (for R%d)', robot.ID, robot.CurrentTask.ItemName, robot.R2RTradePartnerID);
                    else
                        statusStr = sprintf('👑 R%d: [%s]', robot.ID, robot.CurrentTask.ItemName);
                    end
                else
                    statusStr = sprintf('R%d: Free', robot.ID);
                end
                
                % Badge Color
                lblColor = [0.95, 0.95, 1.0];
                if robot.R2RTradePartnerID > 0
                    lblColor = [0.15, 0.95, 1.0]; % Electric Cyan for R2R trade
                elseif robot.Battery <= 30
                    lblColor = [1.0, 0.35, 0.35]; % Red warning
                end
                
                badgeText = sprintf('%s\nBat: %.0f%%', statusStr, robot.Battery);
                text(obj.MapAx, rx, ry, badgeZ, badgeText, 'FontSize', 7.5, ...
                    'FontWeight', 'bold', 'Color', lblColor, 'HorizontalAlignment', 'center');
            end
        end
        
        function drawCuboid(obj, xMin, xMax, yMin, yMax, zMin, zMax, col)
            % Draws an efficient 6-face 3D solid cuboid patch
            vx = [xMin, xMax, xMax, xMin, xMin, xMax, xMax, xMin];
            vy = [yMin, yMin, yMax, yMax, yMin, yMin, yMax, yMax];
            vz = [zMin, zMin, zMin, zMin, zMax, zMax, zMax, zMax];
            faces = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
            patch('Vertices', [vx', vy', vz'], 'Faces', faces, ...
                  'FaceColor', col, 'EdgeColor', col * 0.75, 'Parent', obj.MapAx);
        end
        
        function col = getCategoryColor(~, category)
            switch category
                case 'Consumer Electronics'
                    col = [0.20, 0.65, 0.95]; % Blue
                case 'Computers & IT Hardware'
                    col = [0.35, 0.50, 0.95]; % Indigo
                case 'Gaming & Audio'
                    col = [0.85, 0.25, 0.85]; % Magenta
                case 'Smart Home Appliances'
                    col = [0.95, 0.65, 0.15]; % Orange
                case 'Apparel & Sportswear'
                    col = [0.20, 0.85, 0.50]; % Green
                case 'Books & Office Supplies'
                    col = [0.95, 0.80, 0.20]; % Gold
                case 'Healthcare & Personal Care'
                    col = [0.95, 0.30, 0.40]; % Coral Red
                case 'Tools & Industrial HW'
                    col = [0.70, 0.75, 0.80]; % Silver Steel
                otherwise
                    col = [0.45, 0.65, 0.75];
            end
        end
        
        function updateShellsAndTable(obj, robots, taskMgr, r2rCommunicator)
            % -------------------------------------------------------------
            % 1. UPDATE SCROLLABLE R2R TASK TRADE SHELL (RIGHT 2)
            % -------------------------------------------------------------
            numTrades = 0;
            if ~isempty(r2rCommunicator) && isprop(r2rCommunicator, 'TotalCrossZoneTrades')
                numTrades = r2rCommunicator.TotalCrossZoneTrades;
            end
            swappedItems = numTrades * 2;
            savedTransit = numTrades * 28;
            
            r2rLines = {};
            r2rLines{end+1} = sprintf(' 1. Trades = %-3d  |  2. Swapped = %-3d  |  3. Saved = %-3dc', ...
                numTrades, swappedItems, savedTransit);
            
            % Check if any active trade is underway
            actR2R = [];
            for r = 1:length(robots)
                if robots(r).R2RTradePartnerID > robots(r).ID
                    actR2R = [actR2R; robots(r).ID, robots(r).R2RTradePartnerID];
                end
            end
            
            if ~isempty(actR2R)
                rA = actR2R(1, 1); rB = actR2R(1, 2);
                r2rLines{end+1} = sprintf(' 🟢 LIVE AUDIT: R%d [Z%d] ⟷ R%d [Z%d] (PHYSICAL DIRECT-TO-PACK ACTIVE)', ...
                    rA, robots(rA).ZoneID, rB, robots(rB).ZoneID);
            elseif numTrades > 0
                r2rLines{end+1} = ' 🟢 LIVE AUDIT: All Cross-Zone Swaps Fully Delivered & Verified';
            else
                r2rLines{end+1} = ' 🟢 LIVE AUDIT: Distributed Mesh Standby - Continuous Scanning';
            end
            r2rLines{end+1} = '---------------------------------------------------------------';
            r2rLines{end+1} = ' --- PEER-TO-PEER "BRING MY PRODUCT" DIALOGUE (SCROLLABLE) ---';
            
            if ~isempty(r2rCommunicator) && isprop(r2rCommunicator, 'CommLog')
                for l = 1:length(r2rCommunicator.CommLog)
                    r2rLines{end+1} = r2rCommunicator.CommLog{l};
                end
            else
                r2rLines{end+1} = ' [STANDBY] Awaiting R2R Task Trade Requests...';
            end
            
            set(obj.R2RTableUI, 'Data', r2rLines(:));
            
            % -------------------------------------------------------------
            % 2. UPDATE SCROLLABLE ROBOT PARCEL & ORDER QUEUE SHELL (RIGHT 3)
            % -------------------------------------------------------------
            totalOrders = length(taskMgr.AllTasks);
            deliveredOrders = sum(strcmp({taskMgr.AllTasks.State}, 'Completed'));
            pendingOrders = totalOrders - deliveredOrders;
            
            orderLines = {};
            orderLines{end+1} = sprintf(' 1. Orders = %-3d  |  2. Delivered = %-3d  |  3. Pending = %-3d', ...
                totalOrders, deliveredOrders, pendingOrders);
            orderLines{end+1} = '---------------------------------------------------------------';
            orderLines{end+1} = ' --- PRESENT IN-HAND PARCELS RUNNING IN ROBOT HANDS ---';
            
            for r = 1:length(robots)
                bot = robots(r);
                if strcmp(bot.PickingRole, 'MasterPicker')
                    itemStr = 'Item';
                    if ~isempty(bot.CurrentTask), itemStr = bot.CurrentTask.ItemName; end
                    if strcmp(bot.PickingStage, 'PickingActive') || bot.WaitTicks > 0
                        robotStateStr = sprintf('👑 Master Picking [%s] @ %s', itemStr, bot.TargetShelfName);
                    else
                        robotStateStr = sprintf('👑 Master En Route -> %s', bot.TargetShelfName);
                    end
                elseif strcmp(bot.PickingRole, 'SlaveHolding')
                    robotStateStr = sprintf('🛡️ Slave Holding for R%d outside %s', bot.PickingPartnerID, bot.TargetShelfName);
                elseif strcmp(bot.PickingRole, 'SlaveAssistant')
                    robotStateStr = sprintf('🤝 Slave Assistant co-picking with R%d', bot.PickingPartnerID);
                elseif ~isempty(bot.R2RRole) && strcmp(bot.R2RRole, 'CarrierHelper')
                    ownItem = 'Item';
                    if ~isempty(bot.CurrentTask), ownItem = bot.CurrentTask.ItemName; end
                    peerItem = 'Item';
                    if ~isempty(bot.R2RTaskOnBehalf), peerItem = bot.R2RTaskOnBehalf.ItemName; end
                    robotStateStr = sprintf('📦📦 2 Items: [%s] + [%s -> R%d]', ownItem, peerItem, bot.AssignedPeerID);
                elseif ~isempty(bot.R2RRole) && strcmp(bot.R2RRole, 'ReceiverReceiver')
                    peerItem = 'Item';
                    if ~isempty(bot.CurrentTask), peerItem = bot.CurrentTask.ItemName; end
                    robotStateStr = sprintf('⏳ Meeting R%d to receive [%s]', bot.AssignedPeerID, peerItem);
                elseif strcmp(bot.Status, 'RoutingToCharge')
                    robotStateStr = '⚡ En Route to Charging Station';
                elseif strcmp(bot.Status, 'Charging')
                    minsLeft = max(1, ceil(bot.ChargeTicks / 4));
                    robotStateStr = sprintf('⚡ Auto-Charging (%d min)', minsLeft);
                elseif ~isempty(bot.CurrentTask)
                    catStr = '';
                    if isfield(bot.CurrentTask, 'Category') && ~isempty(bot.CurrentTask.Category)
                        catStr = sprintf(' (%s)', bot.CurrentTask.Category);
                    end
                    if bot.R2RTradePartnerID > 0
                        robotStateStr = sprintf('🔄 Traded (R%d) -> Local Pick [%s%s]', ...
                            bot.R2RTradePartnerID, bot.CurrentTask.ItemName, catStr);
                    elseif strcmp(bot.CurrentTask.State, 'HeadingToDelivery')
                        robotStateStr = sprintf('📦 Carrying [%s%s]', bot.CurrentTask.ItemName, catStr);
                    else
                        robotStateStr = sprintf('🚚 En Route to Pick [%s%s]', bot.CurrentTask.ItemName, catStr);
                    end
                else
                    robotStateStr = '🏠 Idle at Base';
                end
                orderLines{end+1} = sprintf('  %s : %s', bot.Name, robotStateStr);
            end
            
            % Also list queued pending orders so the user can scroll down to inspect backlog!
            orderLines{end+1} = '---------------------------------------------------------------';
            orderLines{end+1} = ' --- QUEUED PENDING ORDERS (SCROLL DOWN TO INSPECT) ---';
            unassigned = taskMgr.getUnassignedTasks();
            if isempty(unassigned)
                orderLines{end+1} = '  (No unassigned pending orders in warehouse queue)';
            else
                for u = 1:length(unassigned)
                    task = unassigned(u);
                    sKey = '';
                    if isfield(task, 'ShelfKey') && ~isempty(task.ShelfKey)
                        sKey = task.ShelfKey;
                    elseif isfield(task, 'ShelfName') && ~isempty(task.ShelfName)
                        sKey = task.ShelfName;
                    end
                    catName = 'General';
                    if isfield(task, 'Category') && ~isempty(task.Category)
                        catName = task.Category;
                    end
                    orderLines{end+1} = sprintf('  #%02d [%s] @ %s (Prio:%d, %s)', ...
                        task.ID, task.ItemName, sKey, task.Priority, catName);
                end
            end
            
            set(obj.OrderLogUI, 'Data', orderLines(:));
            
            % -------------------------------------------------------------
            % 3. UPDATE HISTORICAL SCROLLABLE UITABLE (BOTTOM RIGHT)
            % -------------------------------------------------------------
            tasks = taskMgr.AllTasks;
            numTasks = length(tasks);
            tableData = cell(numTasks, 6);
            todayDateStr = datestr(now, 'dd-mmm');
            
            for i = 1:numTasks
                tItem = tasks(i);
                
                tableData{i, 1} = sprintf('#%02d', tItem.ID);
                tableData{i, 2} = tItem.ItemName;
                
                if isfield(tItem, 'Category') && ~isempty(tItem.Category)
                    tableData{i, 3} = tItem.Category;
                else
                    tableData{i, 3} = 'General';
                end
                
                if isfield(tItem, 'Barcode') && ~isempty(tItem.Barcode)
                    tableData{i, 4} = tItem.Barcode;
                else
                    tableData{i, 4} = 'BC-UNKNOWN';
                end
                
                if isfield(tItem, 'TimestampStr') && ~isempty(tItem.TimestampStr)
                    tableData{i, 5} = [todayDateStr, ' ', tItem.TimestampStr];
                else
                    tableData{i, 5} = [todayDateStr, ' ', datestr(now, 'HH:MM:SS')];
                end
                
                isTraded = isfield(tItem, 'R2RTraded') && tItem.R2RTraded;
                tradedPeer = 0;
                if isfield(tItem, 'TradedWithRobotID'), tradedPeer = tItem.TradedWithRobotID; end
                
                if strcmp(tItem.State, 'Completed')
                    if isTraded && tradedPeer > 0
                        tableData{i, 6} = sprintf('✅ 🔄 R%d delivered (for R%d)', tItem.AssignedRobotID, tradedPeer);
                    elseif isfield(tItem, 'PickingSlaveID') && tItem.PickingSlaveID > 0
                        tableData{i, 6} = sprintf('✅ 🤝 Co-Delivered (R%d+R%d)', tItem.PickingMasterID, tItem.PickingSlaveID);
                    elseif isfield(tItem, 'PickingMasterID') && tItem.PickingMasterID > 0
                        tableData{i, 6} = sprintf('✅ 👑 Master Delivered (R%d)', tItem.PickingMasterID);
                    else
                        tableData{i, 6} = '✅ Delivered';
                    end
                elseif strcmp(tItem.State, 'HeadingToDelivery')
                    if isTraded && tradedPeer > 0
                        tableData{i, 6} = sprintf('📦 🔄 R%d carrying (for R%d) -> Pack', tItem.AssignedRobotID, tradedPeer);
                    else
                        tableData{i, 6} = sprintf('📦 R%d Carrying', tItem.AssignedRobotID);
                    end
                elseif strcmp(tItem.State, 'HeadingToPickup')
                    if isTraded && tradedPeer > 0
                        tableData{i, 6} = sprintf('➡️ 🔄 R%d picking (for R%d)', tItem.AssignedRobotID, tradedPeer);
                    else
                        tableData{i, 6} = sprintf('➡️ 👑 R%d Master Pick', tItem.AssignedRobotID);
                    end
                elseif strcmp(tItem.State, 'PausedForCharging')
                    tableData{i, 6} = sprintf('⏸️ ⚡ Paused (R%d Charging)', tItem.AssignedRobotID);
                else
                    tableData{i, 6} = '⏳ Pending Queue';
                end
            end
            
            set(obj.OrderTableUI, 'Data', tableData);
        end
    end
end
