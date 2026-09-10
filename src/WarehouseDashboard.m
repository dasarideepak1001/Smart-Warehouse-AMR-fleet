classdef WarehouseDashboard < handle
    % WAREHOUSEDASHBOARD Sleek Cyber-Dark GUI with Interactive Scrollable Order History uitable.
    
    properties
        Fig                 % Figure window handle
        MapAx               % Main Map Axes handle
        InfoAx              % System KPI HUD panel handle
        R2RTableUI          % Scrollable R2R P2P Task Trade Shell with native vertical scrollbar!
        OrderLogUI          % Scrollable Real-Time Order & Parcel Status Shell with native vertical scrollbar!
        OrderTableUI        % Interactive MATLAB uitable control (Scrollable historical table!)
        HasGUI              % Boolean flag for GUI availability
    end
    
    methods
        function obj = WarehouseDashboard(titleStr)
            if nargin < 1, titleStr = 'Smart Warehouse AMR Fleet Simulation (Edge AI)'; end
            
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
                % Sleek Dark Charcoal Theme Figure (Width: 1380, Height: 800)
                obj.Fig = figure('Name', titleStr, 'NumberTitle', 'off', ...
                    'Position', [30, 30, 1380, 800], 'Color', [0.10, 0.12, 0.16]);
                
                % Left Subplot: Warehouse Map (56% width, 90% height)
                obj.MapAx = subplot('Position', [0.03, 0.05, 0.56, 0.90]);
                
                % Right 1 (Top): System KPI Dashboard Card (36% width, 19% height)
                obj.InfoAx = subplot('Position', [0.61, 0.77, 0.36, 0.19]);
                
                % Right 2 (Upper Middle): SCROLLABLE R2R TASK TRADE SHELL (36% width, 24% height)
                % Equipped with native interactive vertical scrollbar!
                obj.R2RTableUI = uitable('Parent', obj.Fig, ...
                    'Units', 'normalized', ...
                    'Position', [0.61, 0.51, 0.36, 0.24], ...
                    'ColumnName', {' 🔄 R2R P2P TASK TRADE: "BRING MY ITEM, I BRING YOURS" '}, ...
                    'ColumnWidth', {465}, ...
                    'RowName', [], ...
                    'BackgroundColor', [0.08 0.10 0.15; 0.10 0.12 0.18], ...
                    'ForegroundColor', [0.35 0.92 1.0], ...
                    'FontName', 'Courier', 'FontSize', 8, 'FontWeight', 'bold');
                
                % Right 3 (Lower Middle): SCROLLABLE REAL-TIME ORDER & IN-HAND PARCEL SHELL (36% width, 22% height)
                % Equipped with native interactive vertical scrollbar!
                obj.OrderLogUI = uitable('Parent', obj.Fig, ...
                    'Units', 'normalized', ...
                    'Position', [0.61, 0.26, 0.36, 0.22], ...
                    'ColumnName', {' 📦 REAL-TIME ORDER SHELL & IN-HAND PARCEL STATUS '}, ...
                    'ColumnWidth', {465}, ...
                    'RowName', [], ...
                    'BackgroundColor', [0.08 0.10 0.15; 0.10 0.12 0.18], ...
                    'ForegroundColor', [0.4 1.0 0.6], ...
                    'FontName', 'Courier', 'FontSize', 8, 'FontWeight', 'bold');
                
                % Right 4 (Bottom): INTERACTIVE SCROLLABLE HISTORICAL ORDERS UITABLE (36% width, 22% height)
                % User can scroll up/down to see all previous historical data rows (#1 to #N)!
                obj.OrderTableUI = uitable('Parent', obj.Fig, ...
                    'Units', 'normalized', ...
                    'Position', [0.61, 0.02, 0.36, 0.22], ...
                    'ColumnName', {'No', 'Product Name', 'Category', 'Barcode', 'Timestamp', 'Status'}, ...
                    'ColumnWidth', {32, 95, 90, 75, 65, 140}, ...
                    'BackgroundColor', [0.10 0.12 0.18; 0.14 0.16 0.22], ...
                    'ForegroundColor', [0.4 1.0 0.6], ...
                    'FontName', 'Courier', 'FontSize', 8, 'FontWeight', 'bold');
            end
        end
        
        function render(obj, map, robots, taskMgr, collisionAvoid, allocator, currentTick, r2rCommunicator, masterSlaveController)
            if ~obj.HasGUI || ~isvalid(obj.Fig)
                return; % Non-GUI headless execution
            end
            if nargin < 8, r2rCommunicator = []; end
            if nargin < 9, masterSlaveController = []; end
            
            set(0, 'CurrentFigure', obj.Fig);
            
            % -------------------------------------------------------------
            % 1. DRAW WAREHOUSE MAP (DARK CANVAS)
            % -------------------------------------------------------------
            axes(obj.MapAx);
            cla(obj.MapAx);
            hold(obj.MapAx, 'on');
            
            w = map.GridDimensions(1);
            h = map.GridDimensions(2);
            
            % Dark Navy Canvas Background
            set(obj.MapAx, 'Color', [0.14, 0.16, 0.20], 'XColor', [0.7, 0.7, 0.8], 'YColor', [0.7, 0.7, 0.8]);
            xlim(obj.MapAx, [0.5, w + 0.5]);
            ylim(obj.MapAx, [0.5, h + 0.5]);
            set(obj.MapAx, 'YDir', 'reverse', 'XTick', 1:5:w, 'YTick', 1:5:h);
            grid(obj.MapAx, 'on');
            set(obj.MapAx, 'GridColor', [0.3, 0.35, 0.45], 'GridAlpha', 0.5);
            
            % Check for active R2R trades across fleet
            activeR2RTrades = [];
            for r = 1:length(robots)
                if robots(r).R2RTradePartnerID > robots(r).ID
                    activeR2RTrades = [activeR2RTrades; robots(r).ID, robots(r).R2RTradePartnerID];
                end
            end
            
            if ~isempty(activeR2RTrades)
                rA = activeR2RTrades(1, 1); rB = activeR2RTrades(1, 2);
                zA = robots(rA).ZoneID; zB = robots(rB).ZoneID;
                titleStr = sprintf('WAREHOUSE AMR MAP | Tick: %d s | 🔄 ACTIVE R2R TRADE: R%d [Z%d] ⟷ R%d [Z%d] ("BRING MINE, I BRING YOURS")', ...
                    currentTick, rA, zA, rB, zB);
                titleColor = [0.15, 0.95, 1.0]; % Radiant Electric Cyan!
            else
                titleStr = sprintf('WAREHOUSE AMR MAP  |  Tick: %d s', currentTick);
                titleColor = [0.3, 0.9, 1.0];
            end
            title(obj.MapAx, titleStr, 'FontSize', 11, 'FontWeight', 'bold', 'Color', titleColor);
            
            % Draw Static Shelves / Obstacles (Dark Metallic Gray Blocks)
            [obsY, obsX] = find(map.Grid == 1);
            for k = 1:length(obsX)
                rectangle(obj.MapAx, 'Position', [obsX(k)-0.5, obsY(k)-0.5, 1, 1], ...
                    'FaceColor', [0.28, 0.30, 0.36], 'EdgeColor', [0.20, 0.22, 0.26]);
            end
            
            % Draw Dynamic Obstacles (Neon Red Crosses)
            [dynY, dynX] = find(map.DynamicGrid == 1);
            for k = 1:length(dynX)
                plot(obj.MapAx, dynX(k), dynY(k), 'rx', 'MarkerSize', 14, 'LineWidth', 3);
                text(obj.MapAx, dynX(k)+0.4, dynY(k), 'OBSTACLE / FAILURE', 'Color', [1.0 0.3 0.3], 'FontSize', 8, 'FontWeight', 'bold');
            end
            
            % Draw Zone Boundaries (Dashed Neon Cyan Lines)
            midX = floor(w / 2);
            midY = floor(h / 2);
            line(obj.MapAx, [midX+0.5, midX+0.5], [0.5, h+0.5], 'Color', [0.0, 0.75, 1.0], 'LineStyle', '--', 'LineWidth', 1.5);
            line(obj.MapAx, [0.5, w+0.5], [midY+0.5, midY+0.5], 'Color', [0.0, 0.75, 1.0], 'LineStyle', '--', 'LineWidth', 1.5);
            
            % Zone Labels
            text(obj.MapAx, 1.5, 2, 'ZONE 1 (NW)', 'Color', [0.5, 0.8, 1.0], 'FontSize', 9, 'FontWeight', 'bold');
            text(obj.MapAx, midX+1.5, 2, 'ZONE 2 (NE)', 'Color', [0.5, 0.8, 1.0], 'FontSize', 9, 'FontWeight', 'bold');
            text(obj.MapAx, 1.5, midY+2, 'ZONE 3 (SW)', 'Color', [0.5, 0.8, 1.0], 'FontSize', 9, 'FontWeight', 'bold');
            text(obj.MapAx, midX+5.5, midY+2, 'ZONE 4 (SE)', 'Color', [0.5, 0.8, 1.0], 'FontSize', 9, 'FontWeight', 'bold');
            
            % Draw Packing Stations (Vibrant Emerald Green)
            p1 = map.PackingStations.P1.Pos;
            p2 = map.PackingStations.P2.Pos;
            rectangle(obj.MapAx, 'Position', [p1(1)-0.5, p1(2)-0.5, 1, 1], 'FaceColor', [0.1, 0.8, 0.4], 'EdgeColor', 'w');
            text(obj.MapAx, p1(1)-0.4, p1(2)-0.7, 'PACK 1 📦', 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.4, 1.0, 0.6]);
            
            rectangle(obj.MapAx, 'Position', [p2(1)-0.5, p2(2)-0.5, 1, 1], 'FaceColor', [0.1, 0.8, 0.4], 'EdgeColor', 'w');
            text(obj.MapAx, p2(1)-0.4, p2(2)-0.7, 'PACK 2 📦', 'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.4, 1.0, 0.6]);
            
            % Draw Charging Stations (2 Dedicated Charging Ports Each - Capacity: 2 AMRs Max)
            p1A = [2, 28]; p1B = [3, 28];
            p2A = [27, 28]; p2B = [28, 28];
            
            % Check live port occupancy
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
            
            % Render Station 1 Ports (Green = Free, Electric Blue = Charging Active)
            c1ColorA = [0.15, 0.75, 0.35]; if p1A_occ, c1ColorA = [0.08, 0.52, 0.92]; end
            c1ColorB = [0.15, 0.75, 0.35]; if p1B_occ, c1ColorB = [0.08, 0.52, 0.92]; end
            rectangle(obj.MapAx, 'Position', [p1A(1)-0.5, p1A(2)-0.5, 1, 1], 'FaceColor', c1ColorA, 'EdgeColor', 'w');
            text(obj.MapAx, p1A(1)-0.4, p1A(2), '1A⚡', 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w');
            
            rectangle(obj.MapAx, 'Position', [p1B(1)-0.5, p1B(2)-0.5, 1, 1], 'FaceColor', c1ColorB, 'EdgeColor', 'w');
            text(obj.MapAx, p1B(1)-0.4, p1B(2), '1B⚡', 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w');
            
            c1Count = double(p1A_occ) + double(p1B_occ);
            text(obj.MapAx, p1A(1)-1.0, p1A(2)+0.9, sprintf('Charger 1 [%d/2 Ports]', c1Count), ...
                'FontSize', 8, 'FontWeight', 'bold', 'Color', [1.0, 0.9, 0.3]);
            
            % Render Station 2 Ports (Green = Free, Electric Blue = Charging Active)
            c2ColorA = [0.15, 0.75, 0.35]; if p2A_occ, c2ColorA = [0.08, 0.52, 0.92]; end
            c2ColorB = [0.15, 0.75, 0.35]; if p2B_occ, c2ColorB = [0.08, 0.52, 0.92]; end
            rectangle(obj.MapAx, 'Position', [p2A(1)-0.5, p2A(2)-0.5, 1, 1], 'FaceColor', c2ColorA, 'EdgeColor', 'w');
            text(obj.MapAx, p2A(1)-0.4, p2A(2), '2A⚡', 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w');
            
            rectangle(obj.MapAx, 'Position', [p2B(1)-0.5, p2B(2)-0.5, 1, 1], 'FaceColor', c2ColorB, 'EdgeColor', 'w');
            text(obj.MapAx, p2B(1)-0.4, p2B(2), '2B⚡', 'FontSize', 7, 'FontWeight', 'bold', 'Color', 'w');
            
            c2Count = double(p2A_occ) + double(p2B_occ);
            text(obj.MapAx, p2A(1)-1.8, p2A(2)+0.9, sprintf('Charger 2 [%d/2 Ports]', c2Count), ...
                'FontSize', 8, 'FontWeight', 'bold', 'Color', [1.0, 0.9, 0.3]);
            
            % Draw Active Peer-to-Peer (R2R) Communication & Transfer Lines
            for r1 = 1:length(robots)
                bot1 = robots(r1);
                if ~isempty(bot1.AssignedPeerID)
                    r2 = bot1.AssignedPeerID;
                    bot2 = robots(r2);
                    % Draw Glowing Magenta Dashed Line connecting bot1 and bot2!
                    line(obj.MapAx, [bot1.Position(1), bot2.Position(1)], [bot1.Position(2), bot2.Position(2)], ...
                        'Color', [1.0, 0.2, 0.9], 'LineStyle', '-.', 'LineWidth', 2.2);
                end
                
                % Draw Active Cross-Zone Task Trade Link Line (Bright Cyan-Green Dashed Line)
                if bot1.R2RTradePartnerID > 0 && bot1.R2RTradePartnerID <= length(robots) && bot1.ID < bot1.R2RTradePartnerID
                    bot2 = robots(bot1.R2RTradePartnerID);
                    line(obj.MapAx, [bot1.Position(1), bot2.Position(1)], [bot1.Position(2), bot2.Position(2)], ...
                        'Color', [0.2, 0.95, 0.8], 'LineStyle', ':', 'LineWidth', 2.5);
                end
            end
            
            % Draw Vertical Shelf Names & Categories in the Center of each Shelf Obstacle
            shelfNames = fieldnames(map.Shelves);
            for s = 1:numel(shelfNames)
                sName = shelfNames{s};
                sInfo = map.Shelves.(sName);
                
                yMin = sInfo.Area(1);
                yMax = sInfo.Area(2);
                xMin = sInfo.Area(3);
                xMax = sInfo.Area(4);
                xCenter = (xMin + xMax) / 2;
                yCenter = (yMin + yMax) / 2;
                
                mID = 0;
                if ~isempty(masterSlaveController) && isfield(masterSlaveController.ShelfLocks, sName)
                    mID = masterSlaveController.ShelfLocks.(sName);
                end
                
                shortCat = '';
                if isfield(sInfo, 'ShortCat'), shortCat = sInfo.ShortCat; end
                
                if mID > 0
                    % Active Master Lock: Radiant Gold Vertical Text in Center of Shelf
                    text(obj.MapAx, xCenter, yCenter, sprintf('🔒 %s [R%d M]', sName, mID), ...
                        'Rotation', 90, ...
                        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                        'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [1.0, 0.90, 0.2]);
                else
                    % Default: Vertical Shelf Name and Category centered inside Shelf body
                    text(obj.MapAx, xCenter, yCenter, sprintf('%s: %s', sName, shortCat), ...
                        'Rotation', 90, ...
                        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                        'FontSize', 8.0, 'FontWeight', 'bold', 'Color', [0.85, 0.95, 1.0]);
                end
            end
            
            % Draw Master-to-Slave Coordinated Picking Link Line (Gold Dashed Line)
            if ~isempty(masterSlaveController)
                for r1 = 1:length(robots)
                    bot1 = robots(r1);
                    if bot1.PickingPartnerID > 0 && bot1.PickingPartnerID <= length(robots) && bot1.ID < bot1.PickingPartnerID
                        bot2 = robots(bot1.PickingPartnerID);
                        line(obj.MapAx, [bot1.Position(1), bot2.Position(1)], [bot1.Position(2), bot2.Position(2)], ...
                            'Color', [1.0, 0.82, 0.1], 'LineStyle', '--', 'LineWidth', 2.0);
                    end
                end
            end
            
            % -------------------------------------------------------------
            % Draw Active R2R P2P Wireless Communication Beam (Clean & Sleek!)
            % -------------------------------------------------------------
            for r1 = 1:length(robots)
                bot1 = robots(r1);
                if bot1.R2RTradePartnerID > 0 && bot1.R2RTradePartnerID <= length(robots) && bot1.ID < bot1.R2RTradePartnerID
                    bot2 = robots(bot1.R2RTradePartnerID);
                    if bot2.R2RTradePartnerID == bot1.ID
                        % Clean, elegant, non-cluttering wireless communication link beam
                        line(obj.MapAx, [bot1.Position(1), bot2.Position(1)], [bot1.Position(2), bot2.Position(2)], ...
                            'Color', [0.0, 0.88, 1.0], 'LineStyle', '--', 'LineWidth', 2.0);
                    end
                end
            end
            
            % Draw Robots & Paths
            for r = 1:length(robots)
                robot = robots(r);
                
                % Draw Planned Path (Glowing Dashed Line)
                if ~isempty(robot.Path) && robot.PathIndex <= size(robot.Path, 1)
                    remPath = robot.Path(robot.PathIndex:end, :);
                    plot(obj.MapAx, remPath(:, 1), remPath(:, 2), ':', 'Color', robot.Color, 'LineWidth', 1.2);
                end
                
                carryingPackage = ~isempty(robot.CurrentTask) && strcmp(robot.CurrentTask.State, 'HeadingToDelivery');
                
                % Draw Robot Body & Battery Gauge Ring
                if strcmp(robot.Status, 'Failed')
                    plot(obj.MapAx, robot.Position(1), robot.Position(2), 'ko', 'MarkerFaceColor', [0.3 0.3 0.3], 'MarkerSize', 16);
                    text(obj.MapAx, robot.Position(1), robot.Position(2), sprintf('R%d', robot.ID), ...
                        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', [1 0.3 0.3], 'FontSize', 8, 'FontWeight', 'bold');
                else
                    % 1. Determine Battery Ring Border Color (R2R Trade AMRs get glowing Electric Cyan halo!)
                    if robot.R2RTradePartnerID > 0
                        ringColor = [0.0, 0.95, 1.0]; % Radiant Electric Cyan for R2R Active Trade Partner!
                    elseif strcmp(robot.PickingRole, 'MasterPicker')
                        ringColor = [1.0, 0.85, 0.1]; % Radiant Golden Crown Border
                    elseif strcmp(robot.PickingRole, 'SlaveHolding')
                        ringColor = [1.0, 0.55, 0.1]; % Vibrant Amber Shield Border
                    elseif strcmp(robot.PickingRole, 'SlaveAssistant')
                        ringColor = [0.2, 0.85, 1.0]; % Neon Cyan Team Border
                    elseif robot.Battery >= 60.0
                        ringColor = [0.2, 0.9, 0.4]; % Bright Neon Green
                    elseif robot.Battery >= 30.0
                        ringColor = [1.0, 0.75, 0.1]; % Bright Gold/Amber
                    else
                        ringColor = [1.0, 0.25, 0.25]; % Bright Crimson Red
                    end
                    
                    % 2. Draw Robot Circle with Outer Battery / Role Ring Border
                    plot(obj.MapAx, robot.Position(1), robot.Position(2), 'o', 'MarkerEdgeColor', ringColor, ...
                        'MarkerFaceColor', robot.Color, 'MarkerSize', 14, 'LineWidth', 2.4);
                    
                    % Extra Electric Cyan Pulsing Halo for active R2R Partner AMRs
                    if robot.R2RTradePartnerID > 0
                        plot(obj.MapAx, robot.Position(1), robot.Position(2), 'o', ...
                            'MarkerEdgeColor', [0.1, 0.95, 1.0], 'MarkerFaceColor', 'none', ...
                            'MarkerSize', 22, 'LineWidth', 2.0);
                    end
                    
                    text(obj.MapAx, robot.Position(1), robot.Position(2), robot.Name, ...
                        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                        'Color', 'w', 'FontSize', 7.5, 'FontWeight', 'bold');
                    
                    % 3. Format compact status label for robot
                    shelfStr = robot.TargetShelfName;
                    if isempty(shelfStr), shelfStr = 'Shelf'; end
                    
                    if strcmp(robot.PickingRole, 'MasterPicker')
                        if strcmp(robot.PickingStage, 'PickingActive') || robot.WaitTicks > 0
                            statusStr = sprintf('👑 Pick [%s]', shelfStr);
                        else
                            statusStr = sprintf('👑 %s', shelfStr);
                        end
                    elseif strcmp(robot.PickingRole, 'SlaveHolding')
                        statusStr = sprintf('🛡️ Hold (R%d)', robot.PickingPartnerID);
                    elseif strcmp(robot.PickingRole, 'SlaveAssistant')
                        statusStr = sprintf('🤝 Team (R%d)', robot.PickingPartnerID);
                    elseif strcmp(robot.R2RRole, 'CarrierHelper')
                        % Draw Dual Cargo Box Overlay (2 side-by-side boxes on top of robot circle!)
                        rectangle(obj.MapAx, 'Position', [robot.Position(1)-0.45, robot.Position(2)-0.6, 0.4, 0.4], ...
                            'FaceColor', [0.8, 0.5, 0.2], 'EdgeColor', 'w', 'LineWidth', 1.0); % Box 1 (Own item)
                        rectangle(obj.MapAx, 'Position', [robot.Position(1)+0.05, robot.Position(2)-0.6, 0.4, 0.4], ...
                            'FaceColor', [0.9, 0.2, 0.8], 'EdgeColor', 'w', 'LineWidth', 1.0); % Box 2 (Peer item)
                        statusStr = '📦📦 Dual';
                    elseif strcmp(robot.R2RRole, 'ReceiverReceiver')
                        statusStr = sprintf('⏳ Meet R%d', robot.AssignedPeerID);
                    elseif carryingPackage
                        rectangle(obj.MapAx, 'Position', [robot.Position(1)-0.25, robot.Position(2)-0.6, 0.5, 0.5], ...
                            'FaceColor', [0.8, 0.5, 0.2], 'EdgeColor', 'w', 'LineWidth', 1.0);
                        if robot.R2RTradePartnerID > 0
                            statusStr = sprintf('📦 R%d (for R%d) -> Pack', robot.ID, robot.R2RTradePartnerID);
                        else
                            statusStr = '📦 -> Pack';
                        end
                    elseif ~isempty(robot.CurrentTask) && strcmp(robot.CurrentTask.State, 'HeadingToPickup')
                        if robot.R2RTradePartnerID > 0
                            statusStr = sprintf('🔄 R%d Pick (for R%d)', robot.ID, robot.R2RTradePartnerID);
                        else
                            statusStr = sprintf('-> %s', shelfStr);
                        end
                    elseif strcmp(robot.Status, 'RoutingToCharge')
                        if ~isempty(robot.SavedTask)
                            statusStr = sprintf('⚡ Chg (Paused: %s)', robot.SavedTask.ItemName);
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
                    else
                        statusStr = 'Base';
                    end
                    
                    % Check if robot is currently picking a product at the shelf
                    isPickingProduct = ~isempty(robot.CurrentTask) && ...
                        (strcmp(robot.PickingStage, 'PickingActive') || strcmp(robot.PickingStage, 'Scanning') || ...
                         strcmp(robot.PickingStage, 'ToteSecured') || ...
                         (strcmp(robot.CurrentTask.State, 'HeadingToPickup') && (robot.WaitTicks > 0 || isequal(robot.Position, robot.CurrentTask.PickupPos))));
                    
                    if isPickingProduct
                        prodName = robot.CurrentTask.ItemName;
                        if robot.R2RTradePartnerID > 0
                            badgeColor = [0.15, 0.95, 1.0];
                            pickLabel = sprintf('🔄 R%d: [%s] (for R%d)', robot.ID, prodName, robot.R2RTradePartnerID);
                        else
                            badgeColor = [1.0, 0.85, 0.2];
                            pickLabel = sprintf('👑 R%d: [%s]', robot.ID, prodName);
                        end
                        
                        % Smart vertical positioning: above normally, below if near top wall
                        if robot.Position(2) <= 3
                            yLbl = robot.Position(2) + 0.85;
                            vAlign = 'top';
                        else
                            yLbl = robot.Position(2) - 0.75;
                            vAlign = 'bottom';
                        end
                        
                        text(obj.MapAx, robot.Position(1), yLbl, pickLabel, ...
                            'HorizontalAlignment', 'center', 'VerticalAlignment', vAlign, ...
                            'FontSize', 7.5, 'FontWeight', 'bold', 'Color', badgeColor);
                    else
                        % Smart vertical positioning: above normally, below if near top wall (prevents collision with Pack stations)
                        if robot.Position(2) <= 3
                            yLbl = robot.Position(2) + 0.85;
                            vAlign = 'top';
                        else
                            yLbl = robot.Position(2) - 0.75;
                            vAlign = 'bottom';
                        end
                        
                        % Highlight active R2R trade partner status in Radiant Electric Cyan!
                        if robot.R2RTradePartnerID > 0
                            lblColor = [0.15, 0.95, 1.0];
                        else
                            lblColor = [0.95, 0.95, 1.0];
                        end
                        
                        text(obj.MapAx, robot.Position(1), yLbl, statusStr, ...
                            'HorizontalAlignment', 'center', 'VerticalAlignment', vAlign, ...
                            'FontSize', 7.5, 'FontWeight', 'bold', 'Color', lblColor);
                    end
                end
            end
            hold(obj.MapAx, 'off');
            
            % -------------------------------------------------------------
            % 2. DRAW TOP RIGHT: SYSTEM KPI DASHBOARD PANEL
            % -------------------------------------------------------------
            axes(obj.InfoAx);
            cla(obj.InfoAx);
            set(obj.InfoAx, 'Color', [0.14, 0.16, 0.22]);
            xlim(obj.InfoAx, [0, 1]);
            ylim(obj.InfoAx, [0, 1]);
            axis(obj.InfoAx, 'off');
            
            % Card Container Box
            rectangle(obj.InfoAx, 'Position', [0.01, 0.01, 0.98, 0.98], ...
                'FaceColor', [0.14, 0.16, 0.22], 'EdgeColor', [0.3, 0.7, 1.0], 'LineWidth', 1.5);
            
            % Collect Metrics
            completedTasks = sum(strcmp({taskMgr.AllTasks.State}, 'Completed'));
            totalTasks = length(taskMgr.AllTasks);
            activeRobots = sum(~strcmp({robots.Status}, 'Failed'));
            avgBattery = mean([robots.Battery]);
            
            r2rMsgs = 0;
            r2rXfers = 0;
            r2rTrades = 0;
            if ~isempty(r2rCommunicator)
                r2rMsgs = r2rCommunicator.TotalR2RMessages;
                r2rXfers = r2rCommunicator.TotalR2RTransfers;
                if isprop(r2rCommunicator, 'TotalCrossZoneTrades')
                    r2rTrades = r2rCommunicator.TotalCrossZoneTrades;
                end
            end
            
            msPicks = 0;
            msDeadlocks = 0;
            msCoops = 0;
            if ~isempty(masterSlaveController)
                msPicks = masterSlaveController.MasterPickCommandCount;
                msDeadlocks = masterSlaveController.AisleDeadlocksAvoided;
                msCoops = masterSlaveController.CollaborativePicksCount;
            end
            
            hudText = cell(11, 1);
            hudText{1} = '========================================';
            hudText{2} = '  SYSTEM KPI HUD (EDGE AI & M-S SWARM)  ';
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
            % 2. UPDATE SCROLLABLE R2R TASK TRADE SHELL (WITH VERTICAL SCROLLBAR!)
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
            % 3. UPDATE SCROLLABLE ROBOT PARCEL & ORDER QUEUE SHELL (WITH VERTICAL SCROLLBAR!)
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
            % 4. UPDATE HISTORICAL SCROLLABLE UITABLE (BOTTOM RIGHT)
            % -------------------------------------------------------------
            % User can scroll up/down using the scrollbar or mouse wheel!
            tasks = taskMgr.AllTasks;
            numTasks = length(tasks);
            tableData = cell(numTasks, 6);
            todayDateStr = datestr(now, 'dd-mmm');
            
            for i = 1:numTasks
                tItem = tasks(i);
                
                % Column 1: S.No
                tableData{i, 1} = sprintf('#%02d', tItem.ID);
                
                % Column 2: Product Name
                tableData{i, 2} = tItem.ItemName;
                
                % Column 3: Category
                if isfield(tItem, 'Category') && ~isempty(tItem.Category)
                    tableData{i, 3} = tItem.Category;
                else
                    tableData{i, 3} = 'General';
                end
                
                % Column 4: Product Barcode (BC-406347 or BC-UNKNOWN)
                if isfield(tItem, 'Barcode') && ~isempty(tItem.Barcode)
                    tableData{i, 4} = tItem.Barcode;
                else
                    tableData{i, 4} = 'BC-UNKNOWN';
                end
                
                % Column 5: Date & Time (e.g. 03-Sep 13:23:30)
                if isfield(tItem, 'TimestampStr') && ~isempty(tItem.TimestampStr)
                    tableData{i, 5} = [todayDateStr, ' ', tItem.TimestampStr];
                else
                    tableData{i, 5} = [todayDateStr, ' ', datestr(now, 'HH:MM:SS')];
                end
                
                % Column 6: Status
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
            
            % Update Interactive uitable Data
            set(obj.OrderTableUI, 'Data', tableData);
            
            drawnow;
        end
    end
end
