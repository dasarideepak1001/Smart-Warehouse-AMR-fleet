classdef R2RCommunicator < handle
    % R2RCOMMUNICATOR Dedicated Peer-to-Peer Cross-Zone Task Trade Communication Engine.
    % Logs and streams EXCLUSIVELY the robot-to-robot task swap data:
    % "Robot A sends request to Robot B: Bring my product, and I will bring your product!"
    
    properties
        TotalR2RMessages        % Count of peer-to-peer messages transmitted across fleet
        TotalR2RTransfers       % Count of successful peer-to-peer parcel handoffs completed
        TotalCrossZoneTrades    % Count of successful cross-zone cooperative task swaps
        ActiveTransfers         % Struct array of active R2R co-pickup agreements
        ActiveTrades            % Struct array of active cross-zone task trades
        TrackedTrades           % Struct array tracking active traded fulfillment stages
        CommLog                 % Cell array storing STRICTLY P2P Task Trade communications
        MaxLogEntries           % Maximum lines retained in scrolling buffer
    end
    
    methods
        function obj = R2RCommunicator()
            obj.TotalR2RMessages = 0;
            obj.TotalR2RTransfers = 0;
            obj.TotalCrossZoneTrades = 0;
            obj.ActiveTransfers = struct([]);
            obj.ActiveTrades = struct([]);
            obj.TrackedTrades = struct([]);
            obj.MaxLogEntries = 50;
            
            % Clean real-time log buffer (dynamically populated by live simulation!)
            obj.CommLog = {
                '[T+00s] 🌐 P2P Task Trade Mesh Online';
                '[T+01s] 🔍 Scanning active zones for task swaps...'
            };
        end
        
        function logTradePacket(obj, packetStr)
            % Appends ONLY task-trade related messages to the scrolling buffer
            obj.CommLog{end+1} = packetStr;
            if length(obj.CommLog) > obj.MaxLogEntries
                obj.CommLog = obj.CommLog((end - obj.MaxLogEntries + 1):end);
            end
        end
        
        function logs = getRecentLogs(obj, n)
            % Returns the last n lines for real-time shell display
            if nargin < 2, n = 8; end
            if isempty(obj.CommLog)
                logs = {'[STANDBY] Awaiting R2R Task Trade Requests...'};
            else
                numL = length(obj.CommLog);
                startIdx = max(1, numL - n + 1);
                logs = obj.CommLog(startIdx:numL);
            end
        end
        
        function processR2RCommunications(obj, robots, taskMgr, map, currentTick, masterSlaveController)
            if nargin < 5
                currentTick = max(1, obj.TotalR2RMessages + 1);
            end
            if nargin < 6
                masterSlaveController = [];
            end
            
            % 1. PROCESS CROSS-ZONE COOPERATIVE TASK TRADING (R1 Zone 1 <-> R2 Other Zone)
            obj.processCrossZoneTaskTrades(robots, taskMgr, map, currentTick, masterSlaveController);
            
            % 2. TRACK FULFILLMENT & DELIVERIES OF TRADED ORDERS
            obj.trackTradeFulfillment(robots, map, currentTick);
            
            % Direct-to-Pack Delivery Model (No mid-aisle meetings or rendezvous stalls!)
        end
        
        function processCrossZoneTaskTrades(obj, robots, taskMgr, map, currentTick, masterSlaveController)
            if nargin < 6
                masterSlaveController = [];
            end
            % CROSS-ZONE PEER-TO-PEER (R2R) TASK TRADE PROTOCOL
            % Evaluates when Robot A has an order in Robot B's zone, and Robot B has an order in Robot A's zone.
            % Sends the explicit proposal: "Bring my product, and I will bring your product!"
            
            numRobots = length(robots);
            for r1 = 1:numRobots
                bot1 = robots(r1);
                
                % Must be actively working, heading to pickup, and not already traded
                if ~strcmp(bot1.Status, 'Working') || isempty(bot1.CurrentTask) || ...
                   ~strcmp(bot1.CurrentTask.State, 'HeadingToPickup') || bot1.R2RTradePartnerID > 0
                    continue;
                end
                
                zone1 = map.getZoneForPosition(bot1.Position);
                task1Pickup = bot1.CurrentTask.PickupPos;
                task1Zone = map.getZoneForPosition(task1Pickup);
                
                % If bot1's task is already in bot1's current zone, no cross-zone trade needed
                if task1Zone == zone1
                    continue;
                end
                
                % Search for peer bot2 in task1Zone that has a task in zone1 (or mutual swap benefit)
                for r2 = 1:numRobots
                    if r1 == r2, continue; end
                    bot2 = robots(r2);
                    
                    if ~strcmp(bot2.Status, 'Working') || isempty(bot2.CurrentTask) || ...
                       ~strcmp(bot2.CurrentTask.State, 'HeadingToPickup') || bot2.R2RTradePartnerID > 0
                        continue;
                    end
                    
                    zone2 = map.getZoneForPosition(bot2.Position);
                    task2Pickup = bot2.CurrentTask.PickupPos;
                    task2Zone = map.getZoneForPosition(task2Pickup);
                    
                    % Distance comparisons
                    d1_current = abs(bot1.Position(1) - task1Pickup(1)) + abs(bot1.Position(2) - task1Pickup(2));
                    d1_swapped = abs(bot1.Position(1) - task2Pickup(1)) + abs(bot1.Position(2) - task2Pickup(2));
                    
                    d2_current = abs(bot2.Position(1) - task2Pickup(1)) + abs(bot2.Position(2) - task2Pickup(2));
                    d2_swapped = abs(bot2.Position(1) - task1Pickup(1)) + abs(bot2.Position(2) - task1Pickup(2));
                    
                    isMutualZoneTrade = (zone2 == task1Zone && task2Zone == zone1);
                    isDistanceBeneficial = (d1_swapped < d1_current && d2_swapped < d2_current);
                    
                    if isMutualZoneTrade || isDistanceBeneficial
                        obj.TotalR2RMessages = obj.TotalR2RMessages + 2; % Proposal + Acceptance
                        obj.TotalCrossZoneTrades = obj.TotalCrossZoneTrades + 1;
                        
                        task1 = bot1.CurrentTask;
                        task2 = bot2.CurrentTask;
                        
                        distSaved = (d1_current + d2_current) - (d1_swapped + d2_swapped);
                        
                        % LOG THE EXACT P2P REQUEST AND CONFIRMATION FITTED TO SHELL WIDTH
                        req1 = sprintf('[T+%02ds] 🔄 R%d[Z%d] ➔ R%d[Z%d]: "Bring my [%s]"', ...
                            currentTick, bot1.ID, zone1, bot2.ID, zone2, task1.ItemName);
                        req2 = sprintf('        └─ "and I will bring your [%s]!"', ...
                            task2.ItemName);
                        ack1 = sprintf('[T+%02ds] 🤝 R%d[Z%d] ➔ R%d[Z%d]: "CONFIRMED! Swap agreed"', ...
                            currentTick, bot2.ID, zone2, bot1.ID, zone1);
                        ack2 = sprintf('        └─ "Both navigating direct to Pack Area"');
                        
                        obj.logTradePacket(req1);
                        obj.logTradePacket(req2);
                        obj.logTradePacket(ack1);
                        obj.logTradePacket(ack2);
                        
                        fprintf('\n=================================================================\n');
                        fprintf('[R2R P2P TASK TRADE] 🔄 Mutual Task Trade Handshake!\n');
                        fprintf('%s\n%s\n', req1, req2);
                        fprintf('%s\n%s\n', ack1, ack2);
                        fprintf('• Fleet Efficiency: Saved %d cells of cross-facility travel! Direct pack delivery engaged.\n', distSaved);
                        fprintf('=================================================================\n\n');
                        
                        % 1. Swap task ownership
                        task1.AssignedRobotID = bot2.ID;
                        task2.AssignedRobotID = bot1.ID;
                        task1.R2RTraded = true;
                        task2.R2RTraded = true;
                        task1.TradedWithRobotID = bot1.ID;
                        task2.TradedWithRobotID = bot2.ID;
                        
                        bot1.CurrentTask = task2; % R1 now picks task 2 locally (for R2)
                        bot2.CurrentTask = task1; % R2 now picks task 1 locally (for R1)
                        
                        % 2. Update task manager records
                        if ~isempty(taskMgr)
                            for t = 1:length(taskMgr.AllTasks)
                                if taskMgr.AllTasks(t).ID == task1.ID
                                    taskMgr.AllTasks(t).AssignedRobotID = bot2.ID;
                                    taskMgr.AllTasks(t).R2RTraded = true;
                                    taskMgr.AllTasks(t).TradedWithRobotID = bot1.ID;
                                elseif taskMgr.AllTasks(t).ID == task2.ID
                                    taskMgr.AllTasks(t).AssignedRobotID = bot1.ID;
                                    taskMgr.AllTasks(t).R2RTraded = true;
                                    taskMgr.AllTasks(t).TradedWithRobotID = bot2.ID;
                                end
                            end
                        end
                        
                        % 3. Immediately re-plan paths directly to newly acquired nearby pickups!
                        path1 = AStarPlanner.findPath(map, bot1.Position, task2.PickupPos);
                        if ~isempty(path1)
                            bot1.assignPath(path1);
                            bot1.Target = task2.PickupPos;
                        end
                        
                        path2 = AStarPlanner.findPath(map, bot2.Position, task1.PickupPos);
                        if ~isempty(path2)
                            bot2.assignPath(path2);
                            bot2.Target = task1.PickupPos;
                        end
                        
                        % 4. Synchronize with Master-Slave Controller so no shelf locks or stale slave holds block traded bots!
                        if ~isempty(masterSlaveController)
                            oldShelf1 = bot1.TargetShelfName;
                            oldShelf2 = bot2.TargetShelfName;
                            if ~isempty(oldShelf1) && isfield(masterSlaveController.ShelfLocks, oldShelf1)
                                if masterSlaveController.ShelfLocks.(oldShelf1) == bot1.ID
                                    masterSlaveController.ShelfLocks.(oldShelf1) = 0;
                                end
                            end
                            if ~isempty(oldShelf2) && isfield(masterSlaveController.ShelfLocks, oldShelf2)
                                if masterSlaveController.ShelfLocks.(oldShelf2) == bot2.ID
                                    masterSlaveController.ShelfLocks.(oldShelf2) = 0;
                                end
                            end
                        end
                        
                        % Assign newly traded target shelves
                        if isfield(task2, 'ShelfKey') && ~isempty(task2.ShelfKey)
                            bot1.TargetShelfName = task2.ShelfKey;
                        end
                        if isfield(task1, 'ShelfKey') && ~isempty(task1.ShelfKey)
                            bot2.TargetShelfName = task1.ShelfKey;
                        end
                        
                        % Reset picking roles so both AMRs cleanly approach their new tasks as local pickers
                        bot1.PickingRole = 'None';
                        bot1.PickingPartnerID = 0;
                        bot1.PickingStage = 'None';
                        
                        bot2.PickingRole = 'None';
                        bot2.PickingPartnerID = 0;
                        bot2.PickingStage = 'None';
                        
                        % Record active trade partner
                        bot1.R2RTradePartnerID = bot2.ID;
                        bot2.R2RTradePartnerID = bot1.ID;
                        
                        % 5. Register in TrackedTrades for continuous progress updates
                        newTrade = struct(...
                            'Bot1ID', bot1.ID, ...
                            'Bot2ID', bot2.ID, ...
                            'Item1Name', task2.ItemName, ... % R1 is picking this for R2
                            'Item2Name', task1.ItemName, ... % R2 is picking this for R1
                            'Bot1Picked', false, ...
                            'Bot2Picked', false, ...
                            'Bot1Delivered', false, ...
                            'Bot2Delivered', false ...
                        );
                        if isempty(obj.TrackedTrades)
                            obj.TrackedTrades = newTrade;
                        else
                            obj.TrackedTrades(end+1) = newTrade;
                        end
                        
                        break;
                    end
                end
            end
        end
        
        function trackTradeFulfillment(obj, robots, map, currentTick)
            % Continuously monitors and logs progress of traded orders: picking and direct delivery
            if isempty(obj.TrackedTrades)
                return;
            end
            
            for i = 1:length(obj.TrackedTrades)
                trade = obj.TrackedTrades(i);
                if trade.Bot1Delivered && trade.Bot2Delivered
                    continue;
                end
                
                b1 = robots(trade.Bot1ID);
                b2 = robots(trade.Bot2ID);
                
                % Check Bot 1 picking
                if ~trade.Bot1Picked && ~isempty(b1.CurrentTask) && strcmp(b1.CurrentTask.State, 'HeadingToDelivery')
                    trade.Bot1Picked = true;
                    z1 = map.getZoneForPosition(b1.Position);
                    obj.logTradePacket(sprintf('[T+%02ds] 📦 R%d[Z%d]: Picked [%s] (for R%d) -> Pack', ...
                        currentTick, b1.ID, z1, trade.Item1Name, b2.ID));
                end
                
                % Check Bot 2 picking
                if ~trade.Bot2Picked && ~isempty(b2.CurrentTask) && strcmp(b2.CurrentTask.State, 'HeadingToDelivery')
                    trade.Bot2Picked = true;
                    z2 = map.getZoneForPosition(b2.Position);
                    obj.logTradePacket(sprintf('[T+%02ds] 📦 R%d[Z%d]: Picked [%s] (for R%d) -> Pack', ...
                        currentTick, b2.ID, z2, trade.Item2Name, b1.ID));
                end
                
                % Check Bot 1 delivery
                if trade.Bot1Picked && ~trade.Bot1Delivered && (isempty(b1.CurrentTask) || ~strcmp(b1.CurrentTask.State, 'HeadingToDelivery'))
                    trade.Bot1Delivered = true;
                    obj.logTradePacket(sprintf('[T+%02ds] ✅ R%d: Delivered [%s] (for R%d) @ Pack', ...
                        currentTick, b1.ID, trade.Item1Name, b2.ID));
                end
                
                % Check Bot 2 delivery
                if trade.Bot2Picked && ~trade.Bot2Delivered && (isempty(b2.CurrentTask) || ~strcmp(b2.CurrentTask.State, 'HeadingToDelivery'))
                    trade.Bot2Delivered = true;
                    obj.logTradePacket(sprintf('[T+%02ds] ✅ R%d: Delivered [%s] (for R%d) @ Pack', ...
                        currentTick, b2.ID, trade.Item2Name, b1.ID));
                end
                
                obj.TrackedTrades(i) = trade;
            end
        end
        
        function processPeerCoPickups(obj, robots, taskMgr, map, currentTick)
            % Handles optional rendezvous co-pickups if applicable
            numRobots = length(robots);
            for r1 = 1:numRobots
                bot1 = robots(r1);
                if strcmp(bot1.Status, 'Working') && ~isempty(bot1.CurrentTask) && ...
                   strcmp(bot1.CurrentTask.State, 'HeadingToPickup') && isempty(bot1.AssignedPeerID) && ...
                   bot1.R2RTradePartnerID == 0
               
                    shelfPos1 = bot1.CurrentTask.PickupPos;
                    for r2 = 1:numRobots
                        if r1 == r2, continue; end
                        bot2 = robots(r2);
                        if strcmp(bot2.Status, 'Working') && ~isempty(bot2.CurrentTask) && ...
                           strcmp(bot2.CurrentTask.State, 'HeadingToPickup') && isempty(bot2.AssignedPeerID) && ...
                           bot2.R2RTradePartnerID == 0
                       
                            shelfPos2 = bot2.CurrentTask.PickupPos;
                            distBot1ToShelf2 = abs(bot1.Position(1) - shelfPos2(1)) + abs(bot1.Position(2) - shelfPos2(2));
                            distBot2ToShelf2 = abs(bot2.Position(1) - shelfPos2(1)) + abs(bot2.Position(2) - shelfPos2(2));
                            
                            if distBot1ToShelf2 <= 4 && distBot2ToShelf2 >= 8
                                obj.TotalR2RMessages = obj.TotalR2RMessages + 2;
                                rendX = round((bot1.Position(1) + bot2.Position(1)) / 2);
                                rendY = round((bot1.Position(2) + bot2.Position(2)) / 2);
                                if map.Grid(rendY, rendX) == 1
                                    rendY = max(1, rendY - 1);
                                end
                                rendezvousPos = [rendX, rendY];
                                
                                bot1.AssignedPeerID = bot2.ID;
                                bot1.R2RRole = 'CarrierHelper';
                                bot1.R2RTaskOnBehalf = bot2.CurrentTask;
                                bot1.R2RRendezvousPos = rendezvousPos;
                                
                                bot2.AssignedPeerID = bot1.ID;
                                bot2.R2RRole = 'ReceiverReceiver';
                                bot2.R2RRendezvousPos = rendezvousPos;
                                
                                rendPath2 = AStarPlanner.findPath(map, bot2.Position, rendezvousPos);
                                if ~isempty(rendPath2)
                                    bot2.assignPath(rendPath2);
                                    bot2.Target = rendezvousPos;
                                end
                                break;
                            end
                        end
                    end
                end
            end
        end
        
        function processRendezvousHandoffs(obj, robots, map, currentTick)
            numRobots = length(robots);
            for r1 = 1:numRobots
                bot1 = robots(r1);
                if strcmp(bot1.R2RRole, 'CarrierHelper') && ~isempty(bot1.AssignedPeerID)
                    r2 = bot1.AssignedPeerID;
                    bot2 = robots(r2);
                    
                    distBetweenBots = abs(bot1.Position(1) - bot2.Position(1)) + abs(bot1.Position(2) - bot2.Position(2));
                    if distBetweenBots <= 3.5
                        obj.TotalR2RTransfers = obj.TotalR2RTransfers + 1;
                        obj.TotalR2RMessages = obj.TotalR2RMessages + 1;
                        
                        bot2.CurrentTask.State = 'HeadingToDelivery';
                        deliveryPath2 = AStarPlanner.findPath(map, bot2.Position, bot2.CurrentTask.DeliveryPos);
                        if ~isempty(deliveryPath2)
                            bot2.assignPath(deliveryPath2);
                            bot2.Target = bot2.CurrentTask.DeliveryPos;
                        end
                        
                        bot1.AssignedPeerID = [];
                        bot1.R2RRole = '';
                        bot1.R2RTaskOnBehalf = [];
                        bot2.AssignedPeerID = [];
                        bot2.R2RRole = '';
                    end
                end
            end
        end
    end
end
