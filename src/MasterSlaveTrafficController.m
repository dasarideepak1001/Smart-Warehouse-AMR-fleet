classdef MasterSlaveTrafficController < handle
    % MASTERSLAVETRAFFICCONTROLLER Master-Slave Swarm Fleet Protocol Engine.
    % Provides two integrated coordination layers:
    % 1. MASTER-SLAVE PRODUCT PICKING PROTOCOL:
    %    - Dynamic Master Election & Exclusive Shelf Lease/Token Arbitration
    %    - Slave Holding Buffer Waypoints outside narrow shelf aisles to prevent deadlocks
    %    - Collaborative Dual-AMR Team Picking for high-priority & heavy products
    %    - Synchronized handshakes & automatic lease handoff upon aisle departure
    % 2. MASTER-SLAVE TRAFFIC & PACKING DISPERSAL:
    %    - Dynamic Packing Station Load Balancing between PACK 1 and PACK 2
    %    - Instant Step-Aside Dispersal commands to Slave AMRs in narrow highway corridors (<1s)
    
    properties
        MasterCommandCount      % Counter of master-slave traffic commands issued
        MasterPickCommandCount  % Counter of master-slave picking commands issued
        AisleDeadlocksAvoided   % Counter of narrow shelf aisle deadlocks avoided
        CollaborativePicksCount % Counter of collaborative dual-AMR picks executed
        ShelfLocks              % Struct tracking which robot holds the master lease for each shelf
        ShelfHoldBuffers        % Struct of holding buffer coordinates for each shelf
        Pack1Occupied           % Boolean flag indicating if PACK 1 is currently in use
        Pack2Occupied           % Boolean flag indicating if PACK 2 is currently in use
    end
    
    methods
        function obj = MasterSlaveTrafficController()
            obj.MasterCommandCount = 0;
            obj.MasterPickCommandCount = 0;
            obj.AisleDeadlocksAvoided = 0;
            obj.CollaborativePicksCount = 0;
            obj.Pack1Occupied = false;
            obj.Pack2Occupied = false;
            
            % Initialize Master Locks for all 8 warehouse shelves (0 = Unlocked)
            obj.ShelfLocks = struct(...
                'ShelfA', 0, ...
                'ShelfB', 0, ...
                'ShelfC', 0, ...
                'ShelfD', 0, ...
                'ShelfE', 0, ...
                'ShelfF', 0, ...
                'ShelfG', 0, ...
                'ShelfH', 0  ...
            );
            
            % Pre-computed Aisle Entrance Holding Buffers (Guaranteed free navigable cells)
            obj.ShelfHoldBuffers = struct(...
                'ShelfA', [3, 4], ...
                'ShelfB', [11, 4], ...
                'ShelfC', [18, 4], ...
                'ShelfD', [26, 4], ...
                'ShelfE', [3, 17], ...
                'ShelfF', [11, 17], ...
                'ShelfG', [18, 17], ...
                'ShelfH', [26, 17]  ...
            );
        end
        
        % =========================================================================
        % LAYER 1: MASTER-SLAVE PRODUCT PICKING PROTOCOL AT SHELVES
        % =========================================================================
        function resolveMasterSlavePicking(obj, robots, map, taskMgr)
            % Arbitrates shelf picking operations, enforces exclusive aisle leases,
            % and commands approaching secondary AMRs to hold in buffer zones.
            
            shelfNames = fieldnames(map.Shelves);
            numShelves = numel(shelfNames);
            numRobots = length(robots);
            
            % -----------------------------------------------------------------
            % 1. CHECK & RELEASE VACATED SHELF LEASES
            % -----------------------------------------------------------------
            for s = 1:numShelves
                sName = shelfNames{s};
                masterID = obj.ShelfLocks.(sName);
                
                if masterID > 0
                    if masterID > numRobots
                        obj.ShelfLocks.(sName) = 0;
                        continue;
                    end
                    
                    masterBot = robots(masterID);
                    shelfPickPos = map.Shelves.(sName).Pickup;
                    distToShelf = abs(masterBot.Position(1) - shelfPickPos(1)) + abs(masterBot.Position(2) - shelfPickPos(2));
                    
                    % Master has finished pick if task is now HeadingToDelivery or has departed pick cell
                    isDonePicking = isempty(masterBot.CurrentTask) || ...
                                    strcmp(masterBot.CurrentTask.State, 'HeadingToDelivery') || ...
                                    strcmp(masterBot.CurrentTask.State, 'Completed') || ...
                                    strcmp(masterBot.Status, 'Failed');
                    
                    if isDonePicking
                        % Master has completed picking or cleared the bay! Release lease.
                        obj.ShelfLocks.(sName) = 0;
                        if strcmp(masterBot.PickingRole, 'MasterPicker')
                            masterBot.PickingRole = 'None';
                            masterBot.PickingPartnerID = 0;
                        end
                        
                        % ---------------------------------------------------------
                        % PROMOTE WAITING SLAVE PICKER TO MASTER
                        % ---------------------------------------------------------
                        for r = 1:numRobots
                            candidateSlave = robots(r);
                            if strcmp(candidateSlave.PickingRole, 'SlaveHolding') && ...
                               strcmp(candidateSlave.TargetShelfName, sName)
                                
                                % Promote Slave to Master Picker!
                                candidateSlave.PickingRole = 'MasterPicker';
                                candidateSlave.PickingPartnerID = 0;
                                candidateSlave.TargetShelfName = sName;
                                candidateSlave.WaitTicks = 0;
                                candidateSlave.Target = shelfPickPos;
                                
                                newPickPath = AStarPlanner.findPath(map, candidateSlave.Position, shelfPickPos);
                                if ~isempty(newPickPath)
                                    candidateSlave.assignPath(newPickPath);
                                end
                                
                                obj.ShelfLocks.(sName) = candidateSlave.ID;
                                obj.MasterPickCommandCount = obj.MasterPickCommandCount + 1;
                                
                                fprintf('[MASTER PROMOTION] 👑 Master R%d departed %s. Slave R%d PROMOTED to Master Picker! Entering picking bay.\n', ...
                                    masterBot.ID, sName, candidateSlave.ID);
                                break;
                            end
                        end
                    end
                end
            end
            
            % -----------------------------------------------------------------
            % 2. ARBITRATE NEW PICKING ARRIVALS (MASTER ELECTION & SLAVE HOLDING)
            % -----------------------------------------------------------------
            for r = 1:numRobots
                bot = robots(r);
                if strcmp(bot.Status, 'Failed') || isempty(bot.CurrentTask)
                    continue;
                end
                
                % Process robots heading to pick an item from a shelf
                if strcmp(bot.CurrentTask.State, 'HeadingToPickup')
                    pickPos = bot.CurrentTask.PickupPos;
                    
                    % Identify which shelf corresponds to this pickup position
                    matchingShelf = '';
                    for s = 1:numShelves
                        sName = shelfNames{s};
                        if isequal(map.Shelves.(sName).Pickup, pickPos)
                            matchingShelf = sName;
                            break;
                        end
                    end
                    
                    if isempty(matchingShelf), continue; end
                    bot.TargetShelfName = matchingShelf;
                    
                    distToShelf = abs(bot.Position(1) - pickPos(1)) + abs(bot.Position(2) - pickPos(2));
                    currentLockHolder = obj.ShelfLocks.(matchingShelf);
                    
                    if currentLockHolder == bot.ID
                        % Bot already holds the master lease on this shelf
                        if ~strcmp(bot.PickingRole, 'MasterPicker')
                            bot.PickingRole = 'MasterPicker';
                            bot.PickingStage = 'Approaching';
                        end
                    elseif currentLockHolder == 0
                        % Shelf is free: elect as Master Picker ONLY when approaching aisle (dist <= 5)
                        if distToShelf <= 5
                            obj.ShelfLocks.(matchingShelf) = bot.ID;
                            bot.PickingRole = 'MasterPicker';
                            bot.PickingStage = 'Approaching';
                            obj.MasterPickCommandCount = obj.MasterPickCommandCount + 1;
                            fprintf('[MASTER PICK LEASE] 👑 AMR R%d granted Master Lease for %s! Aisle locked for picking.\n', ...
                                bot.ID, matchingShelf);
                        else
                            % Bot is still far away (>5 cells): travel normally without premature locking
                            if strcmp(bot.PickingRole, 'MasterPicker')
                                bot.PickingRole = 'None';
                            end
                        end
                        
                        % ---------------------------------------------------------
                        % 3. COLLABORATIVE DUAL-AMR PICKING FOR PRIORITY 1 ITEMS
                        % ---------------------------------------------------------
                        if bot.CurrentTask.Priority == 1 && bot.PickingPartnerID == 0 && distToShelf <= 4
                            % Find nearest available idle AMR to recruit as Slave Assistant
                            bestAssistantID = 0;
                            minDist = inf;
                            for a = 1:numRobots
                                if a == bot.ID, continue; end
                                ast = robots(a);
                                if strcmp(ast.Status, 'Free') && ast.Battery >= 30.0 && isempty(ast.CurrentTask)
                                    d = abs(bot.Position(1) - ast.Position(1)) + abs(bot.Position(2) - ast.Position(2));
                                    if d < minDist
                                        minDist = d;
                                        bestAssistantID = ast.ID;
                                    end
                                end
                            end
                            
                            if bestAssistantID > 0
                                slaveAssistant = robots(bestAssistantID);
                                bot.PickingPartnerID = slaveAssistant.ID;
                                
                                slaveAssistant.Status = 'Working';
                                slaveAssistant.PickingRole = 'SlaveAssistant';
                                slaveAssistant.PickingPartnerID = bot.ID;
                                slaveAssistant.TargetShelfName = matchingShelf;
                                
                                % Route Slave Assistant to escort position at aisle buffer
                                holdPos = obj.ShelfHoldBuffers.(matchingShelf);
                                assistPath = AStarPlanner.findPath(map, slaveAssistant.Position, holdPos);
                                if ~isempty(assistPath)
                                    slaveAssistant.assignPath(assistPath);
                                    slaveAssistant.Target = holdPos;
                                end
                                
                                obj.CollaborativePicksCount = obj.CollaborativePicksCount + 1;
                                obj.MasterPickCommandCount = obj.MasterPickCommandCount + 1;
                                
                                fprintf('[COLLABORATIVE PICK] 🤝 Master R%d recruited Slave Assistant R%d for Priority 1 [%s] at %s!\n', ...
                                    bot.ID, slaveAssistant.ID, bot.CurrentTask.ItemName, matchingShelf);
                            end
                        end
                        
                    else
                        % Shelf is ALREADY LOCKED by another robot (currentLockHolder)!
                        if currentLockHolder ~= bot.ID
                            % Designate this robot as Slave Picker
                            bot.PickingPartnerID = currentLockHolder;
                            holdPos = obj.ShelfHoldBuffers.(matchingShelf);
                            bot.HoldPosition = holdPos;
                            
                            % If approaching within narrow corridor range (dist <= 5)
                            if distToShelf <= 5
                                if ~strcmp(bot.PickingRole, 'SlaveHolding')
                                    bot.PickingRole = 'SlaveHolding';
                                    obj.AisleDeadlocksAvoided = obj.AisleDeadlocksAvoided + 1;
                                    obj.MasterPickCommandCount = obj.MasterPickCommandCount + 1;
                                    
                                    % Re-route Slave to Holding Buffer rather than entering blocked bay
                                    holdPath = AStarPlanner.findPath(map, bot.Position, holdPos);
                                    if ~isempty(holdPath)
                                        bot.assignPath(holdPath);
                                        bot.Target = holdPos;
                                    end
                                    
                                    fprintf('[SLAVE PICK HOLD] 🛡️ Master R%d holds %s. Slave R%d commanded to HOLD at buffer (%d,%d) to prevent aisle deadlock!\n', ...
                                        currentLockHolder, matchingShelf, bot.ID, holdPos(1), holdPos(2));
                                end
                                
                                % If slave has reached the holding position, pause it there!
                                if isequal(bot.Position, holdPos)
                                    bot.WaitTicks = max(bot.WaitTicks, 2); % Hold in buffer slot
                                end
                            end
                        end
                    end
                end
            end
        end
        
        % =========================================================================
        % LAYER 2: MASTER-SLAVE TRAFFIC & PACKING STATION LOAD BALANCING
        % =========================================================================
        function resolveMasterSlaveTraffic(obj, robots, map, taskMgr)
            % 1. Evaluate Live Physical Occupancy of Packing Stations PACK 1 and PACK 2
            p1Pos = map.PackingStations.P1.Pos;
            p2Pos = map.PackingStations.P2.Pos;
            
            p1Occupied = false;
            p2Occupied = false;
            p1Occupant = 0;
            p2Occupant = 0;
            
            numRobots = length(robots);
            for r = 1:numRobots
                bot = robots(r);
                if strcmp(bot.Status, 'Failed'), continue; end
                d1 = abs(bot.Position(1) - p1Pos(1)) + abs(bot.Position(2) - p1Pos(2));
                d2 = abs(bot.Position(1) - p2Pos(1)) + abs(bot.Position(2) - p2Pos(2));
                
                % ANY robot physically within 2 cells of the pack station occupies it!
                if d1 <= 2.0
                    p1Occupied = true;
                    p1Occupant = bot.ID;
                end
                if d2 <= 2.0
                    p2Occupied = true;
                    p2Occupant = bot.ID;
                end
            end
            
            % 2. Master Dynamic Load Balancing: Redirect incoming AMRs if targeted station is occupied!
            for r = 1:numRobots
                bot = robots(r);
                if strcmp(bot.Status, 'Failed'), continue; end
                if ~isempty(bot.CurrentTask) && strcmp(bot.CurrentTask.State, 'HeadingToDelivery')
                    distP1 = abs(bot.Position(1) - p1Pos(1)) + abs(bot.Position(2) - p1Pos(2));
                    distP2 = abs(bot.Position(1) - p2Pos(1)) + abs(bot.Position(2) - p2Pos(2));
                    
                    % Heading to PACK 1, but PACK 1 is occupied:
                    if isequal(bot.CurrentTask.DeliveryPos, p1Pos) && p1Occupied && p1Occupant ~= bot.ID
                        if ~p2Occupied
                            bot.CurrentTask.DeliveryPos = p2Pos;
                            bot.Target = p2Pos;
                            newPath = AStarPlanner.findPath(map, bot.Position, p2Pos);
                            if ~isempty(newPath)
                                bot.assignPath(newPath);
                                obj.MasterCommandCount = obj.MasterCommandCount + 1;
                                p2Occupied = true;
                                p2Occupant = bot.ID;
                                fprintf('[PACK REDIRECT] 🚚 AMR R%d dynamically redirected from occupied PACK 1 to free PACK 2!\n', bot.ID);
                            end
                        else
                            if distP1 <= 2
                                bot.WaitTicks = max(bot.WaitTicks, 1); % Queue safely
                            end
                        end
                    % Heading to PACK 2, but PACK 2 is occupied:
                    elseif isequal(bot.CurrentTask.DeliveryPos, p2Pos) && p2Occupied && p2Occupant ~= bot.ID
                        if ~p1Occupied
                            bot.CurrentTask.DeliveryPos = p1Pos;
                            bot.Target = p1Pos;
                            newPath = AStarPlanner.findPath(map, bot.Position, p1Pos);
                            if ~isempty(newPath)
                                bot.assignPath(newPath);
                                obj.MasterCommandCount = obj.MasterCommandCount + 1;
                                p1Occupied = true;
                                p1Occupant = bot.ID;
                                fprintf('[PACK REDIRECT] 🚚 AMR R%d dynamically redirected from occupied PACK 2 to free PACK 1!\n', bot.ID);
                            end
                        else
                            if distP2 <= 2
                                bot.WaitTicks = max(bot.WaitTicks, 1); % Queue safely
                            end
                        end
                    end
                end
            end
            
            % 3. Master-Slave Instant Corridor Dispersal Protocol (Resolves Head-On Encounters across ALL Corridors!)
            w = map.GridDimensions(1);
            h = map.GridDimensions(2);
            
            for r1 = 1:numRobots
                bot1 = robots(r1);
                if strcmp(bot1.Status, 'Failed'), continue; end
                
                for r2 = (r1+1):numRobots
                    bot2 = robots(r2);
                    if strcmp(bot2.Status, 'Failed'), continue; end
                    
                    % Exemption: If either robot is stationary Charging in a charging port,
                    % or moving into separate adjacent ports (1A vs 1B, 2A vs 2B),
                    % they are permitted to stand/dock side-by-side without corridor conflict!
                    isCharging1 = strcmp(bot1.Status, 'Charging');
                    isCharging2 = strcmp(bot2.Status, 'Charging');
                    if (isCharging1 || isCharging2)
                        if ~isequal(bot1.Position, bot2.Position) && ...
                           (isempty(bot1.Target) || isempty(bot2.Target) || ~isequal(bot1.Target, bot2.Target))
                            continue;
                        end
                    end
                    
                    distBetween = abs(bot1.Position(1) - bot2.Position(1)) + abs(bot1.Position(2) - bot2.Position(2));
                    
                    % Check if clustered or facing each other within 3.0 cells
                    if distBetween <= 3.0
                        nextPos1 = [];
                        if ~isempty(bot1.Path) && bot1.PathIndex <= size(bot1.Path, 1)
                            nextPos1 = bot1.Path(bot1.PathIndex, :);
                        end
                        nextPos2 = [];
                        if ~isempty(bot2.Path) && bot2.PathIndex <= size(bot2.Path, 1)
                            nextPos2 = bot2.Path(bot2.PathIndex, :);
                        end
                        
                        % Real spatial conflicts:
                        isNext1Occ = ~isempty(nextPos1) && isequal(nextPos1, bot2.Position);
                        isNext2Occ = ~isempty(nextPos2) && isequal(nextPos2, bot1.Position);
                        isSameNext = ~isempty(nextPos1) && ~isempty(nextPos2) && isequal(nextPos1, nextPos2);
                        
                        isHeadOn = false;
                        if ~isempty(nextPos1) && ~isempty(nextPos2)
                            dPos = bot2.Position - bot1.Position;
                            m1 = nextPos1 - bot1.Position;
                            m2 = nextPos2 - bot2.Position;
                            relMotion = m1 - m2;
                            if (dPos(1)*relMotion(1) + dPos(2)*relMotion(2)) > 0
                                isHeadOn = true;
                            end
                        end
                        
                        isStalledAhead = (isNext1Occ && bot2.WaitTicks > 0) || (isNext2Occ && bot1.WaitTicks > 0);
                        
                        % Only trigger Master-Slave Dispersal if there is an ACTUAL path conflict!
                        if isNext1Occ || isNext2Occ || isSameNext || isHeadOn || isStalledAhead
                            % Determine Master and Slave
                            p1 = 0; if ~isempty(bot1.CurrentTask), p1 = bot1.CurrentTask.Priority; end
                            p2 = 0; if ~isempty(bot2.CurrentTask), p2 = bot2.CurrentTask.Priority; end
                            
                            % Priority Rule: An AMR inside or leaving the pack dock gets priority to exit!
                            inDock1 = (abs(bot1.Position(1) - p1Pos(1)) + abs(bot1.Position(2) - p1Pos(2)) <= 1.5) || ...
                                      (abs(bot1.Position(1) - p2Pos(1)) + abs(bot1.Position(2) - p2Pos(2)) <= 1.5);
                            inDock2 = (abs(bot2.Position(1) - p1Pos(1)) + abs(bot2.Position(2) - p1Pos(2)) <= 1.5) || ...
                                      (abs(bot2.Position(1) - p2Pos(1)) + abs(bot2.Position(2) - p2Pos(2)) <= 1.5);
                            
                            if inDock1 && ~inDock2
                                masterBot = bot1; slaveBot = bot2;
                            elseif inDock2 && ~inDock1
                                masterBot = bot2; slaveBot = bot1;
                            % Critical low-battery priority rule: lower battery AMR gets priority to charger!
                            elseif strcmp(bot1.Status, 'RoutingToCharge') && strcmp(bot2.Status, 'RoutingToCharge')
                                if bot1.Battery <= bot2.Battery
                                    masterBot = bot1; slaveBot = bot2;
                                else
                                    masterBot = bot2; slaveBot = bot1;
                                end
                            elseif strcmp(bot1.Status, 'RoutingToCharge')
                                masterBot = bot1; slaveBot = bot2;
                            elseif strcmp(bot2.Status, 'RoutingToCharge')
                                masterBot = bot2; slaveBot = bot1;
                            elseif p1 > p2 || (p1 == p2 && bot1.ID < bot2.ID)
                                masterBot = bot1;
                                slaveBot = bot2;
                            else
                                masterBot = bot2;
                                slaveBot = bot1;
                            end
                        
                        % Build avoidMask of all other robots and Master's position
                        avoidMask = zeros(h, w);
                        for b = 1:numRobots
                            other = robots(b);
                            if other.ID ~= slaveBot.ID && ~strcmp(other.Status, 'Failed')
                                avoidMask(other.Position(2), other.Position(1)) = 1;
                            end
                        end
                        
                        sx = slaveBot.Position(1);
                        sy = slaveBot.Position(2);
                        mx = masterBot.Position(1);
                        my = masterBot.Position(2);
                        
                        % Determine if conflict is Horizontal or Vertical
                        isEastWest = abs(sx - mx) >= abs(sy - my);
                        
                        if isEastWest
                            % Horizontal corridor conflict: shift vertically to clear lane!
                            candidates = [sx, sy+1; sx, sy-1; sx, sy+2; sx, sy-2; sx+1, sy; sx-1, sy];
                        else
                            % Vertical corridor conflict: shift horizontally to clear lane!
                            candidates = [sx+1, sy; sx-1, sy; sx+2, sy; sx-2, sy; sx, sy+1; sx, sy-1];
                        end
                        
                        % Try direct detour from current position first
                        detourDone = false;
                        if ~isempty(slaveBot.Target)
                            directDetour = AStarPlanner.findPath(map, slaveBot.Position, slaveBot.Target, avoidMask);
                            if ~isempty(directDetour) && size(directDetour, 1) > 1
                                slaveBot.assignPath(directDetour);
                                slaveBot.WaitTicks = 0;
                                masterBot.WaitTicks = 0;
                                obj.MasterCommandCount = obj.MasterCommandCount + 1;
                                detourDone = true;
                            end
                        end
                        
                        if ~detourDone
                            for c = 1:size(candidates, 1)
                                optX = candidates(c, 1);
                                optY = candidates(c, 2);
                                
                                if optX >= 1 && optX <= w && optY >= 1 && optY <= h
                                    if map.Grid(optY, optX) == 0 && map.DynamicGrid(optY, optX) == 0 && avoidMask(optY, optX) == 0
                                        % Found free parallel lane! Command Slave to lateral-shift!
                                        slaveBot.Position = [optX, optY];
                                        
                                        if ~isempty(slaveBot.Target)
                                            newPath = AStarPlanner.findPath(map, [optX, optY], slaveBot.Target, avoidMask);
                                            if ~isempty(newPath)
                                                slaveBot.assignPath(newPath);
                                            end
                                        end
                                        
                                        slaveBot.WaitTicks = 0; % Slave keeps moving quickly without delay!
                                        masterBot.WaitTicks = 0; % Master proceeds without freeze!
                                        obj.MasterCommandCount = obj.MasterCommandCount + 1;
                                        
                                        fprintf('[MASTER HEAD-ON CLEARANCE] 👑 Master R%d commanded Slave R%d to lateral lane (%d,%d) to clear corridor quickly!\n', ...
                                            masterBot.ID, slaveBot.ID, optX, optY);
                                        break;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
end

