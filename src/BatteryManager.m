classdef BatteryManager < handle
    % BATTERYMANAGER Autonomous Self-Charging Engine with Capacity Limit & Task Resume.
    % Enables AMRs to self-monitor battery BMS (<30%), route directly to chargers without freezing,
    % balance station load (Max 2 per station), and resume saved tasks where they left off!
    
    methods (Static)
        function checkAndRouteLowBatteryRobots(robots, map, taskMgr, ~)
            if nargin < 3, taskMgr = []; end
            if nargin < 4, allocator = []; end
            
            % Define 2 Dedicated Physical Charging Ports per Station (Capacity: 2 Robots per Station)
            c1PortA = [2, 28];
            c1PortB = [3, 28];
            c2PortA = [27, 28];
            c2PortB = [28, 28];
            
            c1Queue = [2, 25];
            c2Queue = [28, 25];
            
            % 1. Evaluate Live Occupancy of each Charging Port
            c1PortA_Occupied = false;
            c1PortB_Occupied = false;
            c2PortA_Occupied = false;
            c2PortB_Occupied = false;
            
            for k = 1:length(robots)
                other = robots(k);
                if strcmp(other.Status, 'Charging') || strcmp(other.Status, 'RoutingToCharge')
                    if isequal(other.Target, c1PortA) || (strcmp(other.Status, 'Charging') && isequal(other.Position, c1PortA))
                        c1PortA_Occupied = true;
                    elseif isequal(other.Target, c1PortB) || (strcmp(other.Status, 'Charging') && isequal(other.Position, c1PortB))
                        c1PortB_Occupied = true;
                    elseif isequal(other.Target, c2PortA) || (strcmp(other.Status, 'Charging') && isequal(other.Position, c2PortA))
                        c2PortA_Occupied = true;
                    elseif isequal(other.Target, c2PortB) || (strcmp(other.Status, 'Charging') && isequal(other.Position, c2PortB))
                        c2PortB_Occupied = true;
                    end
                end
            end
            
            c1Occupancy = double(c1PortA_Occupied) + double(c1PortB_Occupied);
            c2Occupancy = double(c2PortA_Occupied) + double(c2PortB_Occupied);
            
            % 2. Promote Queued AMRs if a port has become free
            for r = 1:length(robots)
                robot = robots(r);
                if strcmp(robot.Status, 'RoutingToCharge') && (isequal(robot.Target, c1Queue) || isequal(robot.Target, c2Queue))
                    promotedPos = [];
                    portName = '';
                    if ~c1PortA_Occupied
                        promotedPos = c1PortA; portName = 'Station 1 Port 1A'; c1PortA_Occupied = true;
                    elseif ~c1PortB_Occupied
                        promotedPos = c1PortB; portName = 'Station 1 Port 1B'; c1PortB_Occupied = true;
                    elseif ~c2PortA_Occupied
                        promotedPos = c2PortA; portName = 'Station 2 Port 2A'; c2PortA_Occupied = true;
                    elseif ~c2PortB_Occupied
                        promotedPos = c2PortB; portName = 'Station 2 Port 2B'; c2PortB_Occupied = true;
                    end
                    
                    if ~isempty(promotedPos)
                        avoidMask = zeros(map.GridDimensions(2), map.GridDimensions(1));
                        for b = 1:length(robots)
                            otherBot = robots(b);
                            if otherBot.ID ~= robot.ID && ~strcmp(otherBot.Status, 'Failed')
                                avoidMask(otherBot.Position(2), otherBot.Position(1)) = 1;
                            end
                        end
                        pPath = AStarPlanner.findPath(map, robot.Position, promotedPos, avoidMask);
                        if isempty(pPath)
                            pPath = AStarPlanner.findPath(map, robot.Position, promotedPos);
                        end
                        if ~isempty(pPath)
                            robot.assignChargingTask(promotedPos, pPath);
                            fprintf('[AUTO-BMS] ⚡ Port opened! Queued AMR R%d promoted into %s at (%d,%d)\n', ...
                                robot.ID, portName, promotedPos(1), promotedPos(2));
                        end
                    end
                end
            end
            
            % 3. Check for AMRs needing charge (< 30%)
            for r = 1:length(robots)
                robot = robots(r);
                
                % Trigger when Battery <= 30% and not already routing/charging
                if robot.Battery <= 30.0 && ~strcmp(robot.Status, 'Charging') && ...
                   ~strcmp(robot.Status, 'RoutingToCharge') && ~strcmp(robot.Status, 'Failed')
                    
                    % Preserve & Freeze work in middle (DO NOT ABANDON!)
                    if ~isempty(robot.CurrentTask)
                        robot.SavedTask = robot.CurrentTask;
                        robot.SavedTaskStage = robot.CurrentTask.State;
                        
                        % Keep task assigned to THIS robot in taskMgr
                        if ~isempty(taskMgr)
                            taskMgr.updateTaskState(robot.CurrentTask.ID, 'PausedForCharging', robot.ID);
                        end
                        
                        fprintf('[AUTO-BMS] ⚡ AMR R%d battery low (%.1f%% <= 30%%). WORK STOPPED IN MIDDLE! Pausing Task #%d [%s] (Stage: %s)...\n', ...
                            robot.ID, robot.Battery, robot.SavedTask.ID, robot.SavedTask.ItemName, robot.SavedTaskStage);
                        
                        % Suspend current task while heading to charger
                        robot.CurrentTask = [];
                    end
                    
                    % Select Station & Specific Port with strict 2-port limit
                    dist1 = abs(robot.Position(1) - c1PortA(1)) + abs(robot.Position(2) - c1PortA(2));
                    dist2 = abs(robot.Position(1) - c2PortA(1)) + abs(robot.Position(2) - c2PortA(2));
                    
                    selectedPos = [];
                    selectedPortName = '';
                    
                    if dist1 <= dist2
                        % Try Station 1 first (Max 2 robots)
                        if ~c1PortA_Occupied
                            selectedPos = c1PortA; selectedPortName = 'Station 1 Port 1A'; c1PortA_Occupied = true;
                        elseif ~c1PortB_Occupied
                            selectedPos = c1PortB; selectedPortName = 'Station 1 Port 1B'; c1PortB_Occupied = true;
                        % Station 1 is full (2/2)! Try Station 2
                        elseif ~c2PortA_Occupied
                            selectedPos = c2PortA; selectedPortName = 'Station 2 Port 2A'; c2PortA_Occupied = true;
                            fprintf('[AUTO-BMS] ⚠️ Station 1 Full (2/2). Rerouting AMR R%d to Station 2...\n', robot.ID);
                        elseif ~c2PortB_Occupied
                            selectedPos = c2PortB; selectedPortName = 'Station 2 Port 2B'; c2PortB_Occupied = true;
                            fprintf('[AUTO-BMS] ⚠️ Station 1 Full (2/2). Rerouting AMR R%d to Station 2...\n', robot.ID);
                        end
                    else
                        % Try Station 2 first (Max 2 robots)
                        if ~c2PortA_Occupied
                            selectedPos = c2PortA; selectedPortName = 'Station 2 Port 2A'; c2PortA_Occupied = true;
                        elseif ~c2PortB_Occupied
                            selectedPos = c2PortB; selectedPortName = 'Station 2 Port 2B'; c2PortB_Occupied = true;
                        % Station 2 is full (2/2)! Try Station 1
                        elseif ~c1PortA_Occupied
                            selectedPos = c1PortA; selectedPortName = 'Station 1 Port 1A'; c1PortA_Occupied = true;
                            fprintf('[AUTO-BMS] ⚠️ Station 2 Full (2/2). Rerouting AMR R%d to Station 1...\n', robot.ID);
                        elseif ~c1PortB_Occupied
                            selectedPos = c1PortB; selectedPortName = 'Station 1 Port 1B'; c1PortB_Occupied = true;
                            fprintf('[AUTO-BMS] ⚠️ Station 2 Full (2/2). Rerouting AMR R%d to Station 1...\n', robot.ID);
                        end
                    end
                    
                    % If both stations full (2/2 at Station 1 AND 2/2 at Station 2 = 4 robots charging):
                    if isempty(selectedPos)
                        if dist1 <= dist2
                            selectedPos = c1Queue;
                            selectedPortName = 'Station 1 Queue Buffer';
                        else
                            selectedPos = c2Queue;
                            selectedPortName = 'Station 2 Queue Buffer';
                        end
                        fprintf('[AUTO-BMS] ⏳ All 4 Charging Ports Full (2/2 at both stations). AMR R%d waiting in Queue...\n', robot.ID);
                    end
                    
                    % Route robot to assigned port avoiding other active robots
                    avoidMask = zeros(map.GridDimensions(2), map.GridDimensions(1));
                    for b = 1:length(robots)
                        otherBot = robots(b);
                        if otherBot.ID ~= robot.ID && ~strcmp(otherBot.Status, 'Failed')
                            avoidMask(otherBot.Position(2), otherBot.Position(1)) = 1;
                        end
                    end
                    path = AStarPlanner.findPath(map, robot.Position, selectedPos, avoidMask);
                    if isempty(path)
                        path = AStarPlanner.findPath(map, robot.Position, selectedPos);
                    end
                    if ~isempty(path)
                        robot.assignChargingTask(selectedPos, path);
                        fprintf('[AUTO-BMS] ⚡ AMR R%d routed to %s at (%d,%d)...\n', ...
                            robot.ID, selectedPortName, selectedPos(1), selectedPos(2));
                    end
                end
            end
        end
    end
end
