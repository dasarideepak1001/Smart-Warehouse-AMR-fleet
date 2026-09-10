classdef TaskManager < handle
    % TASKMANAGER Handles warehouse order creation, task queues, and state tracking.
    
    properties
        AllTasks       % Struct array of all created tasks
        NextTaskID     % Integer auto-increment counter
    end
    
    methods
        function obj = TaskManager()
            obj.AllTasks = struct([]);
            obj.NextTaskID = 1;
        end
        
        function task = createTask(obj, itemName, pickupPos, deliveryPos, priority, tick, category, shelfKey)
            if nargin < 5, priority = 1; end
            if nargin < 6, tick = 0; end
            if nargin < 7, category = 'General'; end
            if nargin < 8, shelfKey = ''; end
            
            barcodeStr = sprintf('BC-%06d', randi([100000, 999999]));
            timeStr = datestr(now, 'HH:MM:SS');
            
            task = struct(...
                'ID', obj.NextTaskID, ...
                'ItemName', itemName, ...
                'Category', category, ...
                'ShelfKey', shelfKey, ...
                'ShelfName', shelfKey, ...
                'Barcode', barcodeStr, ...
                'TimestampStr', timeStr, ...
                'PickupPos', pickupPos, ...
                'DeliveryPos', deliveryPos, ...
                'Priority', priority, ...
                'State', 'Unassigned', ...  % Unassigned, Assigned, HeadingToPickup, HeadingToDelivery, Completed
                'AssignedRobotID', 0, ...
                'PickingMasterID', 0, ...
                'PickingSlaveID', 0, ...
                'PickingMode', 'Standard', ... % Standard, MasterSolo, MasterSlaveCoop
                'R2RTraded', false, ...
                'TradedWithRobotID', 0, ...
                'CreatedTime', tick, ...
                'CompletedTime', -1 ...
            );
            
            obj.NextTaskID = obj.NextTaskID + 1;
            
            if isempty(obj.AllTasks)
                obj.AllTasks = task;
            else
                obj.AllTasks(end+1) = task;
            end
        end
        
        function generateStandardScenarioTasks(obj, map)
            % Pre-populates standard scenario tasks categorized by shelf
            shelfSequence = {'ShelfH', 'ShelfB', 'ShelfC', 'ShelfA', 'ShelfE', 'ShelfG'};
            itemsSequence = {'Precision Screwdriver Set', 'Laptop', 'Gaming Console', 'Mobile Phone', 'Running Shoes', 'Smart Air Purifier'};
            
            for i = 1:6
                sKey = shelfSequence{i};
                sInfo = map.Shelves.(sKey);
                pickupPos = sInfo.Pickup;
                category = sInfo.Category;
                itemName = itemsSequence{i};
                
                % Alternate packing stations
                if mod(i, 2) == 1
                    deliveryPos = map.PackingStations.P1.Pos;
                else
                    deliveryPos = map.PackingStations.P2.Pos;
                end
                
                priority = mod(i, 3) + 1; % Priorities 1, 2, 3
                obj.createTask(itemName, pickupPos, deliveryPos, priority, 0, category, sKey);
            end
        end
        
        function task = generateRandomTask(obj, map, currentTick)
            shelfKeys = fieldnames(map.Shelves);
            randomIdx = randi(numel(shelfKeys));
            shelfName = shelfKeys{randomIdx};
            shelfInfo = map.Shelves.(shelfName);
            
            pickupPos = shelfInfo.Pickup;
            category = shelfInfo.Category;
            
            % Select an item specifically belonging to this shelf's category catalog!
            shelfItems = shelfInfo.Items;
            itemName = shelfItems{randi(numel(shelfItems))};
            
            if rand() > 0.5
                deliveryPos = map.PackingStations.P1.Pos;
            else
                deliveryPos = map.PackingStations.P2.Pos;
            end
            
            priority = randi([1, 3]);
            task = obj.createTask(itemName, pickupPos, deliveryPos, priority, currentTick, category, shelfName);
        end
        
        function unassigned = getUnassignedTasks(obj)
            unassigned = struct([]);
            if isempty(obj.AllTasks)
                return;
            end
            
            idx = strcmp({obj.AllTasks.State}, 'Unassigned');
            if any(idx)
                unassigned = obj.AllTasks(idx);
            end
        end
        
        function updateTaskState(obj, taskID, newState, robotID, tick)
            for i = 1:length(obj.AllTasks)
                if obj.AllTasks(i).ID == taskID
                    obj.AllTasks(i).State = newState;
                    if nargin >= 4 && robotID > 0
                        obj.AllTasks(i).AssignedRobotID = robotID;
                    end
                    if strcmp(newState, 'Completed') && nargin >= 5
                        obj.AllTasks(i).CompletedTime = tick;
                    end
                    break;
                end
            end
        end
        
        function recordMasterSlavePick(obj, taskID, masterID, slaveID, mode)
            if nargin < 4, slaveID = 0; end
            if nargin < 5, mode = 'MasterPicker'; end
            for i = 1:length(obj.AllTasks)
                if obj.AllTasks(i).ID == taskID
                    obj.AllTasks(i).PickingMasterID = masterID;
                    obj.AllTasks(i).PickingSlaveID = slaveID;
                    obj.AllTasks(i).PickingMode = mode;
                    break;
                end
            end
        end
    end
end
