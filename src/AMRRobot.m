classdef AMRRobot < handle
    % AMRROBOT Represents an Autonomous Mobile Robot (AMR) in the warehouse.
    
    properties
        ID                  % Integer ID (e.g., 1, 2, 3...)
        Name                % Robot Name string (e.g., 'R1', 'R2', 'R3', 'R4', 'R5'...)
        Position            % [x, y] Current grid coordinates
        Target              % [x, y] Current destination
        Path                % Nx2 array of waypoints [(x1,y1); (x2,y2)...]
        PathIndex           % Current waypoint index
        Battery             % Battery percentage (0 - 100)
        Status              % State: 'Free', 'Working', 'RoutingToCharge', 'Charging', 'Failed'
        CurrentTask         % Struct containing assigned job metadata or []
        SavedTask           % Struct holding suspended job during charging cycle
        SavedTaskStage      % String: 'HeadingToPickup' or 'HeadingToDelivery'
        ZoneID              % Current edge zone ID (1..4)
        Speed               % Speed in grid cells per tick (default 1)
        TotalDistance       % Total distance traveled in grid units
        TasksCompletedCount % Count of tasks successfully delivered
        Color               % RGB color vector for plot rendering
        HomePosition        % [x, y] Base depot position for return trip
        WaitTicks           % Counter for yielding / pausing motion
        ChargeTicks         % Counter for 5-minute charging duration (20 ticks = 5 mins)
        ChargeCount         % Counter tracking how many times the robot has charged today
        AssignedPeerID      % ID of peer robot communicating / cooperating with
        R2RRole             % Role: 'CarrierHelper' or 'ReceiverReceiver'
        R2RTaskOnBehalf     % Task picked on behalf of peer robot
        R2RRendezvousPos    % [x, y] Meeting position for parcel handoff
        R2RTradePartnerID   % ID of peer robot traded with in Cross-Zone Task Trade Protocol
        
        % Master-Slave Product Picking Protocol Properties
        PickingRole             % 'None', 'MasterPicker', 'SlavePicker', 'SlaveHolding', 'SlaveAssistant'
        PickingPartnerID        % ID of peer robot paired during picking (Master or Slave)
        HoldPosition            % [x, y] Aisle buffer coordinates where slave waits
        PickingStage            % 'None', 'Approaching', 'Scanning', 'PickingActive', 'ToteSecured', 'Departing'
        TargetShelfName         % Target shelf key (e.g. 'ShelfA', 'ShelfB')
        PicksCompletedAsMaster  % Count of master picking operations completed
        PicksCompletedAsSlave   % Count of slave picking operations completed
        StallTicks              % Counter tracking how many ticks the robot has been stationary
    end
    
    methods
        function obj = AMRRobot(id, initialPos, battery)
            if nargin < 1, id = 1; end
            if nargin < 2, initialPos = [2, 2]; end
            if nargin < 3, battery = 100; end
            
            obj.ID = id;
            obj.Name = sprintf('R%d', id);
            obj.Position = initialPos;
            obj.HomePosition = initialPos;
            obj.Target = [];
            obj.Path = [];
            obj.PathIndex = 1;
            obj.Battery = battery;
            obj.Status = 'Free';
            obj.CurrentTask = [];
            obj.SavedTask = [];
            obj.ZoneID = 1;
            obj.Speed = 1;
            obj.TotalDistance = 0;
            obj.TasksCompletedCount = 0;
            obj.WaitTicks = 0;
            obj.ChargeTicks = 0;
            obj.ChargeCount = 0;
            obj.AssignedPeerID = [];
            obj.R2RRole = '';
            obj.R2RTaskOnBehalf = [];
            obj.R2RRendezvousPos = [];
            obj.R2RTradePartnerID = 0;
            
            % Initialize Master-Slave Picking State
            obj.PickingRole = 'None';
            obj.PickingPartnerID = 0;
            obj.HoldPosition = [];
            obj.PickingStage = 'None';
            obj.TargetShelfName = '';
            obj.PicksCompletedAsMaster = 0;
            obj.PicksCompletedAsSlave = 0;
            obj.StallTicks = 0;
            
            % Unique visual color palette per robot
            colors = [
                0.9, 0.2, 0.2;  % R1 Red
                0.2, 0.5, 0.9;  % R2 Blue
                0.3, 0.8, 0.3;  % R3 Green
                0.9, 0.6, 0.1;  % R4 Orange
                0.7, 0.3, 0.8   % R5 Purple
            ];
            idx = mod(id - 1, size(colors, 1)) + 1;
            obj.Color = colors(idx, :);
        end
        
        function assignTask(obj, task, path)
            obj.CurrentTask = task;
            obj.Target = task.PickupPos;
            obj.Path = path;
            obj.PathIndex = 1;
            obj.Status = 'Working';
            obj.WaitTicks = 0;
        end
        
        function assignPath(obj, newPath)
            obj.Path = newPath;
            if size(newPath, 1) >= 2 && isequal(newPath(1, :), obj.Position)
                obj.PathIndex = 2;
            else
                obj.PathIndex = 1;
            end
        end
        
        function assignChargingTask(obj, chargePos, path)
            % Save current task to memory so robot resumes work after charging!
            if ~isempty(obj.CurrentTask)
                obj.SavedTask = obj.CurrentTask;
                obj.SavedTaskStage = obj.CurrentTask.State;
                fprintf('[AUTO-BMS MEMORY] AMR R%d saved Task [%s] in memory to resume after charging!\n', ...
                    obj.ID, obj.SavedTask.ItemName);
            end
            
            obj.CurrentTask = [];
            obj.Target = chargePos;
            obj.assignPath(path);
            obj.Status = 'RoutingToCharge';
            obj.WaitTicks = 0;
            obj.ChargeTicks = 20; % 20 ticks = 5-minute simulated charging duration
        end
        
        function failRobot(obj)
            obj.Status = 'Failed';
            obj.Path = [];
            obj.Target = [];
        end
        
        function update(obj, map, taskMgr, currentTick, robots)
            if nargin < 3, taskMgr = []; end
            if nargin < 4, currentTick = 0; end
            if nargin < 5, robots = []; end
            
            % Execute one simulation tick update
            if strcmp(obj.Status, 'Failed')
                return; % Robot is unresponsive
            end
            
            if obj.WaitTicks > 0
                obj.WaitTicks = obj.WaitTicks - 1;
                return; % Robot is yielding or picking up package
            end
            
            % Transition to Charging when arrived at physical charging pad
            if strcmp(obj.Status, 'RoutingToCharge')
                allPorts = [2, 28; 3, 28; 27, 28; 28, 28];
                atPort = any(allPorts(:, 1) == obj.Position(1) & allPorts(:, 2) == obj.Position(2));
                if atPort && isequal(obj.Position, obj.Target)
                    obj.Status = 'Charging';
                    obj.ChargeCount = obj.ChargeCount + 1;
                    obj.Path = [];
                    obj.PathIndex = 1;
                    fprintf('[AUTO-BMS] AMR R%d arrived at Charging Port (%d,%d). Beginning 5-minute charge cycle...\n', ...
                        obj.ID, obj.Position(1), obj.Position(2));
                end
            end
            
            % Handle 5-Minute Charging State when arrived at charging station
            if strcmp(obj.Status, 'Charging')
                obj.Battery = min(100, obj.Battery + 5.0); % Charge 5% per tick
                if obj.ChargeTicks > 0
                    obj.ChargeTicks = obj.ChargeTicks - 1;
                end
                
                % Completed 5-minute charging cycle (20 ticks) and battery >= 90%
                if obj.ChargeTicks <= 0 && obj.Battery >= 90
                    if ~isempty(obj.SavedTask)
                        % RESUME THE EXACT WORK THAT WAS STOPPED IN THE MIDDLE!
                        obj.CurrentTask = obj.SavedTask;
                        obj.SavedTask = [];
                        obj.Status = 'Working';
                        
                        if strcmp(obj.SavedTaskStage, 'HeadingToDelivery')
                            obj.CurrentTask.State = 'HeadingToDelivery';
                            obj.Target = obj.CurrentTask.DeliveryPos;
                            fprintf('[AUTO-BMS RESUME] ⚡ AMR R%d fully charged (100%%)! CONTINUING STOPPED WORK: Delivering [%s] -> Pack (%d,%d)!\n', ...
                                obj.ID, obj.CurrentTask.ItemName, obj.Target(1), obj.Target(2));
                        else
                            obj.CurrentTask.State = 'HeadingToPickup';
                            obj.Target = obj.CurrentTask.PickupPos;
                            fprintf('[AUTO-BMS RESUME] ⚡ AMR R%d fully charged (100%%)! CONTINUING STOPPED WORK: Picking [%s] @ Shelf (%d,%d)!\n', ...
                                obj.ID, obj.CurrentTask.ItemName, obj.Target(1), obj.Target(2));
                        end
                        
                        if ~isempty(taskMgr)
                            taskMgr.updateTaskState(obj.CurrentTask.ID, obj.CurrentTask.State, obj.ID, currentTick);
                        end
                        
                        resumePath = AStarPlanner.findPath(map, obj.Position, obj.Target);
                        if ~isempty(resumePath)
                            obj.assignPath(resumePath);
                        end
                        obj.SavedTaskStage = '';
                    else
                        obj.Status = 'Free';
                        obj.CurrentTask = [];
                        obj.Target = [];
                        obj.Path = [];
                        obj.PathIndex = 1;
                        fprintf('[AUTO-BMS] AMR R%d finished 5-minute charge cycle (100%%). Freshly reset & available for NEW jobs!\n', obj.ID);
                    end
                end
                return;
            end
            
            % Move along Path
            if ~isempty(obj.Path) && obj.PathIndex <= size(obj.Path, 1)
                nextPos = obj.Path(obj.PathIndex, :);
                
                % Check if next cell is currently occupied by another active robot
                cellOccupiedByOtherRobot = false;
                if ~isempty(robots)
                    for b = 1:length(robots)
                        bot = robots(b);
                        if bot.ID ~= obj.ID && ~strcmp(bot.Status, 'Failed') && isequal(nextPos, bot.Position)
                            cellOccupiedByOtherRobot = true;
                            break;
                        end
                    end
                end
                
                % Update position if next cell is valid and free of robots
                if ~map.isOccupied(nextPos(1), nextPos(2)) && ~cellOccupiedByOtherRobot
                    obj.Position = nextPos;
                    obj.PathIndex = obj.PathIndex + 1;
                    obj.TotalDistance = obj.TotalDistance + 1;
                    obj.Battery = max(0, obj.Battery - 0.25); % Battery drain
                    obj.ZoneID = map.getZoneForPosition(obj.Position);
                    obj.StallTicks = 0; % Free movement!
                else
                    % Blocked by obstacle or robot in path: wait
                    obj.WaitTicks = 1;
                    obj.StallTicks = obj.StallTicks + 1;
                    
                    % Watchdog: If stalled for >= 3 ticks, force dynamic detour avoiding other robots!
                    if obj.StallTicks >= 3 && ~isempty(obj.Target)
                        avoidMask = zeros(map.GridDimensions(2), map.GridDimensions(1));
                        if ~isempty(robots)
                            for b = 1:length(robots)
                                bot = robots(b);
                                if bot.ID ~= obj.ID && ~strcmp(bot.Status, 'Failed')
                                    avoidMask(bot.Position(2), bot.Position(1)) = 1;
                                end
                            end
                        end
                        detourPath = AStarPlanner.findPath(map, obj.Position, obj.Target, avoidMask);
                        if ~isempty(detourPath)
                            obj.assignPath(detourPath);
                        end
                        obj.StallTicks = 0;
                    end
                end
            end
            
            % Hold Slave in place if it reached holding buffer cell
            if strcmp(obj.PickingRole, 'SlaveHolding') && ~isempty(obj.HoldPosition) && isequal(obj.Position, obj.HoldPosition)
                obj.WaitTicks = max(obj.WaitTicks, 1); % Maintain hold in buffer until Master leaves shelf
            end
            
            % Check if reached waypoint / target
            if ~isempty(obj.CurrentTask) && ~isempty(obj.Target)
                if isequal(obj.Position, obj.Target)
                    if strcmp(obj.CurrentTask.State, 'HeadingToPickup')
                        % Picked up item at shelf -> Master-Slave Picking Protocol
                        if strcmp(obj.PickingRole, 'MasterPicker')
                            obj.PicksCompletedAsMaster = obj.PicksCompletedAsMaster + 1;
                            obj.PickingStage = 'PickingActive';
                        elseif strcmp(obj.PickingRole, 'SlavePicker') || strcmp(obj.PickingRole, 'SlaveHolding')
                            obj.PicksCompletedAsSlave = obj.PicksCompletedAsSlave + 1;
                        end
                        
                        % Change destination to Packing Station
                        obj.CurrentTask.State = 'HeadingToDelivery';
                        obj.Target = obj.CurrentTask.DeliveryPos;
                        obj.Path = AStarPlanner.findPath(map, obj.Position, obj.Target);
                        obj.PathIndex = 1;
                        obj.WaitTicks = 2; % 2 ticks pause to scan barcode & pick item
                        
                    elseif strcmp(obj.CurrentTask.State, 'HeadingToDelivery')
                        % Delivered item -> Update TaskManager & Return to Base Station
                        if ~isempty(taskMgr)
                            taskMgr.updateTaskState(obj.CurrentTask.ID, 'Completed', obj.ID, currentTick);
                        end
                        
                        obj.CurrentTask.State = 'Completed';
                        obj.TasksCompletedCount = obj.TasksCompletedCount + 1;
                        obj.CurrentTask = [];
                        obj.Status = 'Free';
                        obj.PickingRole = 'None';
                        obj.PickingPartnerID = 0;
                        obj.PickingStage = 'None';
                        obj.TargetShelfName = '';
                        obj.R2RTradePartnerID = 0;
                        
                        % Plan return path back to Home Position avoiding incoming robots at dock
                        avoidMask = zeros(map.GridDimensions(2), map.GridDimensions(1));
                        if nargin >= 5 && ~isempty(robots)
                            for b = 1:length(robots)
                                bot = robots(b);
                                if bot.ID ~= obj.ID && ~strcmp(bot.Status, 'Failed')
                                    avoidMask(bot.Position(2), bot.Position(1)) = 1;
                                end
                            end
                        end
                        homePath = AStarPlanner.findPath(map, obj.Position, obj.HomePosition, avoidMask);
                        if isempty(homePath)
                            homePath = AStarPlanner.findPath(map, obj.Position, obj.HomePosition);
                        end
                        if ~isempty(homePath)
                            obj.assignPath(homePath);
                            obj.Target = obj.HomePosition;
                        end
                    end
                end
            end
            
            % Handle Slave Assistant returning to Free once pick assistance is complete
            if strcmp(obj.PickingRole, 'SlaveAssistant') && isempty(obj.CurrentTask)
                if isequal(obj.Position, obj.Target)
                    obj.Status = 'Free';
                    obj.PickingRole = 'None';
                    obj.PickingPartnerID = 0;
                    obj.TargetShelfName = '';
                    homePath = AStarPlanner.findPath(map, obj.Position, obj.HomePosition);
                    if ~isempty(homePath)
                        obj.assignPath(homePath);
                        obj.Target = obj.HomePosition;
                    end
                end
            end
        end
    end
end
