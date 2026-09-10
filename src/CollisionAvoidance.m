classdef CollisionAvoidance < handle
    % COLLISIONAVOIDANCE High-Speed Traffic Dispersal & Active Step-Aside Collision Avoidance Engine.
    % Forces lower-priority AMRs to immediately step sideways into adjacent free aisle cells,
    % clearing highway corridors in under 1 second without head-on deadlocks.
    
    properties
        AvoidedCollisionsCount % Total count of resolved potential collisions
        ReplanningCount        % Total count of dynamic re-planning events
    end
    
    methods
        function obj = CollisionAvoidance()
            obj.AvoidedCollisionsCount = 0;
            obj.ReplanningCount = 0;
        end
        
        function resolveCollisions(obj, robots, map)
            % Checks for upcoming spatial conflicts among all active robots
            nRobots = length(robots);
            
            for i = 1:nRobots
                r1 = robots(i);
                if strcmp(r1.Status, 'Failed') || isempty(r1.Path) || r1.PathIndex > size(r1.Path, 1)
                    continue;
                end
                
                nextPos1 = r1.Path(r1.PathIndex, :);
                
                for j = (i+1):nRobots
                    r2 = robots(j);
                    if strcmp(r2.Status, 'Failed')
                        continue;
                    end
                    
                    distBetween = abs(r1.Position(1) - r2.Position(1)) + abs(r1.Position(2) - r2.Position(2));
                    
                    % 1. Immediate Conflict: Next cell is occupied by other robot
                    isNextOccupied = isequal(nextPos1, r2.Position);
                    
                    % 2. Converging Conflict: Both aiming at same cell
                    isSameCell = false;
                    nextPos2 = [];
                    if ~isempty(r2.Path) && r2.PathIndex <= size(r2.Path, 1)
                        nextPos2 = r2.Path(r2.PathIndex, :);
                        isSameCell = isequal(nextPos1, nextPos2);
                    end
                    
                    % 3. Approaching Head-On within 3.5 cells
                    isFacingEachOther = false;
                    if distBetween <= 3.5 && ~isempty(nextPos2)
                        % Moving towards each other (opposing direction vectors)
                        dPos = r2.Position - r1.Position;
                        m1 = nextPos1 - r1.Position;
                        m2 = nextPos2 - r2.Position;
                        relMotion = m1 - m2;
                        if (dPos(1)*relMotion(1) + dPos(2)*relMotion(2)) > 0
                            isFacingEachOther = true;
                        end
                    end
                    
                    if isNextOccupied || isSameCell || isFacingEachOther
                        p1 = obj.calculateRobotPriority(r1);
                        p2 = obj.calculateRobotPriority(r2);
                        if p1 >= p2
                            obj.yieldOrReplan(r2, r1, map, robots);
                        else
                            obj.yieldOrReplan(r1, r2, map, robots);
                        end
                    end
                end
            end
        end
        
        function p = calculateRobotPriority(~, robot)
            p = 0;
            if strcmp(robot.Status, 'Working')
                p = 10;
                if ~isempty(robot.CurrentTask)
                    p = p + robot.CurrentTask.Priority * 5;
                end
            elseif strcmp(robot.Status, 'RoutingToCharge')
                % Urgent right-of-way for low battery AMRs to avoid dead battery on floor
                p = 12 + (30 - min(30, robot.Battery)) * 0.2;
            elseif strcmp(robot.Status, 'Charging')
                p = 2;
            end
            % Tie-breaker: lower ID gets higher priority
            p = p + (10 - robot.ID) * 0.1;
        end
        
        function yieldOrReplan(obj, lowerPriorityRobot, higherPriorityRobot, map, robots)
            if nargin < 5, robots = []; end
            obj.AvoidedCollisionsCount = obj.AvoidedCollisionsCount + 1;
            
            w = map.GridDimensions(1);
            h = map.GridDimensions(2);
            avoidMask = zeros(h, w);
            
            % 1. Mark ALL other active robots in avoidMask
            if ~isempty(robots)
                for b = 1:length(robots)
                    bot = robots(b);
                    if bot.ID ~= lowerPriorityRobot.ID && ~strcmp(bot.Status, 'Failed')
                        avoidMask(bot.Position(2), bot.Position(1)) = 1;
                    end
                end
            else
                avoidMask(higherPriorityRobot.Position(2), higherPriorityRobot.Position(1)) = 1;
            end
            
            % 2. Mask higher priority robot's forward trajectory corridor (next 3 waypoints)
            if ~isempty(higherPriorityRobot.Path) && higherPriorityRobot.PathIndex <= size(higherPriorityRobot.Path, 1)
                lookAhead = min(size(higherPriorityRobot.Path, 1), higherPriorityRobot.PathIndex + 2);
                for p = higherPriorityRobot.PathIndex:lookAhead
                    wp = higherPriorityRobot.Path(p, :);
                    avoidMask(wp(2), wp(1)) = 1;
                end
            end
            
            % 3. Higher priority robot maintains full speed and right-of-way!
            higherPriorityRobot.WaitTicks = 0;
            
            % 4. Lower priority robot finds another way quickly & moves away!
            detourFound = false;
            
            % Try A: Direct detour path from current position around oncoming robot
            if ~isempty(lowerPriorityRobot.Target)
                newDetour = AStarPlanner.findPath(map, lowerPriorityRobot.Position, lowerPriorityRobot.Target, avoidMask);
                if ~isempty(newDetour) && size(newDetour, 1) > 1
                    lowerPriorityRobot.assignPath(newDetour);
                    lowerPriorityRobot.WaitTicks = 0; % Keep moving quickly without stopping!
                    obj.ReplanningCount = obj.ReplanningCount + 1;
                    detourFound = true;
                end
            end
            
            % Try B: Lateral escape into parallel lane if nose-to-nose
            if ~detourFound
                rx = lowerPriorityRobot.Position(1);
                ry = lowerPriorityRobot.Position(2);
                hx = higherPriorityRobot.Position(1);
                hy = higherPriorityRobot.Position(2);
                
                % Check motion direction
                isEastWest = abs(rx - hx) >= abs(ry - hy);
                if isEastWest
                    % Horizontal conflict: move vertically (y+1, y-1, y+2, y-2) to clear lane!
                    candidates = [rx, ry+1; rx, ry-1; rx, ry+2; rx, ry-2; rx+1, ry; rx-1, ry];
                else
                    % Vertical conflict: move horizontally (x+1, x-1, x+2, x-2) to clear lane!
                    candidates = [rx+1, ry; rx-1, ry; rx+2, ry; rx-2, ry; rx, ry+1; rx, ry-1];
                end
                
                for k = 1:size(candidates, 1)
                    opt = candidates(k, :);
                    if opt(1) >= 1 && opt(1) <= w && opt(2) >= 1 && opt(2) <= h
                        if map.Grid(opt(2), opt(1)) == 0 && map.DynamicGrid(opt(2), opt(1)) == 0 && avoidMask(opt(2), opt(1)) == 0
                            if ~isempty(lowerPriorityRobot.Target)
                                detourPath = AStarPlanner.findPath(map, opt, lowerPriorityRobot.Target, avoidMask);
                                if isempty(detourPath)
                                    singleMask = zeros(h, w);
                                    singleMask(higherPriorityRobot.Position(2), higherPriorityRobot.Position(1)) = 1;
                                    detourPath = AStarPlanner.findPath(map, opt, lowerPriorityRobot.Target, singleMask);
                                end
                                
                                if ~isempty(detourPath)
                                    lowerPriorityRobot.Position = opt; % Quick lateral shift!
                                    lowerPriorityRobot.assignPath(detourPath);
                                    lowerPriorityRobot.WaitTicks = 0; % Move away quickly without delay!
                                    obj.ReplanningCount = obj.ReplanningCount + 1;
                                    detourFound = true;
                                    break;
                                end
                            end
                        end
                    end
                end
            end
            
            if ~detourFound
                % In tight single-cell pocket where detour is temporarily enclosed, yield 1 tick
                lowerPriorityRobot.WaitTicks = max(lowerPriorityRobot.WaitTicks, 1);
            end
        end
        
        function checkDynamicObstacleBlocked(obj, robots, map)
            % Checks if dynamic obstacles block current path
            for r = 1:length(robots)
                robot = robots(r);
                if strcmp(robot.Status, 'Failed') || isempty(robot.Path)
                    continue;
                end
                
                % Look ahead 3 steps along path
                lookAheadLimit = min(size(robot.Path, 1), robot.PathIndex + 2);
                pathBlocked = false;
                
                for k = robot.PathIndex:lookAheadLimit
                    wp = robot.Path(k, :);
                    if map.DynamicGrid(wp(2), wp(1)) == 1
                        pathBlocked = true;
                        break;
                    end
                end
                
                if pathBlocked && ~isempty(robot.Target)
                    % Dynamic Re-planning triggered!
                    newPath = AStarPlanner.findPath(map, robot.Position, robot.Target);
                    if ~isempty(newPath)
                        robot.assignPath(newPath);
                        obj.ReplanningCount = obj.ReplanningCount + 1;
                    end
                end
            end
        end
    end
end
