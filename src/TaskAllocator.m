classdef TaskAllocator < handle
    % TASKALLOCATOR Task Allocation engine supporting Distributed Edge AI mode
    % and Centralized Master Computer mode for benchmark comparison.
    
    properties
        EdgeNodes           % Struct or array of 4 EdgeNode instances
        Mode                % 'Distributed' or 'Centralized'
        TotalNetworkMessages% Network message counter
        AIModel             % Global EdgeAIModel instance
    end
    
    methods
        function obj = TaskAllocator(mode)
            if nargin < 1, mode = 'Distributed'; end
            obj.Mode = mode;
            obj.TotalNetworkMessages = 0;
            obj.AIModel = EdgeAIModel();
            
            % Initialize 4 Edge Nodes
            obj.EdgeNodes = [
                EdgeNode(1, 'Zone 1 (NW)'), ...
                EdgeNode(2, 'Zone 2 (NE)'), ...
                EdgeNode(3, 'Zone 3 (SW)'), ...
                EdgeNode(4, 'Zone 4 (SE)')
            ];
        end
        
        function allocatePendingTasks(obj, taskMgr, map, robots)
            pending = taskMgr.getUnassignedTasks();
            if isempty(pending)
                return;
            end
            
            if contains(obj.Mode, 'Distributed')
                obj.allocateDistributed(pending, taskMgr, map, robots);
            else
                obj.allocateCentralized(pending, taskMgr, map, robots);
            end
        end
        
        function allocateDistributed(obj, pendingTasks, taskMgr, map, robots)
            % Distributed Edge Node Task Allocation Strategy
            
            % 1. Update robot assignments per edge node
            for e = 1:length(obj.EdgeNodes)
                obj.EdgeNodes(e).updateManagedRobots(robots, map);
            end
            
            for t = 1:length(pendingTasks)
                task = pendingTasks(t);
                
                % Anti-Congestion Shield: Prevent dispatching multiple AMRs to the exact same shelf concurrently!
                shelfOccupied = false;
                for r = 1:length(robots)
                    b = robots(r);
                    if ~isempty(b.CurrentTask) && isequal(b.CurrentTask.PickupPos, task.PickupPos) && ...
                       (strcmp(b.CurrentTask.State, 'HeadingToPickup') || isequal(b.Position, task.PickupPos))
                        shelfOccupied = true;
                        break;
                    end
                end
                if shelfOccupied
                    continue; % Defer task until active AMR finishes picking and clears the aisle!
                end
                
                pickupZone = map.getZoneForPosition(task.PickupPos);
                
                % Primary assignment: Local Edge Node
                edgeNode = obj.EdgeNodes(pickupZone);
                [bestRobotID, bestPath, minScore] = edgeNode.allocateTaskLocally(task, robots, map);
                
                % Fallback negotiation with adjacent Edge Nodes if no local robot is free
                if bestRobotID == 0
                    for e = 1:length(obj.EdgeNodes)
                        if e ~= pickupZone
                            % Edge-to-Edge inter-node communication message
                            obj.TotalNetworkMessages = obj.TotalNetworkMessages + 2; 
                            
                            [altRobotID, altPath, altScore] = obj.EdgeNodes(e).allocateTaskLocally(task, robots, map);
                            if altRobotID > 0 && altScore < minScore
                                minScore = altScore;
                                bestRobotID = altRobotID;
                                bestPath = altPath;
                            end
                        end
                    end
                end
                
                % Commit assignment
                if bestRobotID > 0
                    targetRobot = robots(bestRobotID);
                    task.State = 'HeadingToPickup';
                    targetRobot.assignTask(task, bestPath);
                    taskMgr.updateTaskState(task.ID, 'HeadingToPickup', bestRobotID);
                end
            end
            
            % Sum Edge Node messages
            for e = 1:length(obj.EdgeNodes)
                obj.TotalNetworkMessages = obj.TotalNetworkMessages + obj.EdgeNodes(e).MessageCount;
                obj.EdgeNodes(e).MessageCount = 0; % Reset tick count
            end
        end
        
        function allocateCentralized(obj, pendingTasks, taskMgr, map, robots)
            % Centralized Server Allocation Strategy
            % Every task queries ALL robots across the entire network continuously
            
            for t = 1:length(pendingTasks)
                task = pendingTasks(t);
                bestRobotID = 0;
                bestPath = [];
                minScore = inf;
                
                for r = 1:length(robots)
                    % Central computer receives telemetry from EVERY robot continuously
                    % (High communication bottleneck!)
                    obj.TotalNetworkMessages = obj.TotalNetworkMessages + 4; 
                    
                    robot = robots(r);
                    if strcmp(robot.Status, 'Free') && robot.Battery >= 30.0
                        [score, ~] = obj.AIModel.calculateRobotScore(robot, task, map, robots);
                        
                        if score < minScore
                            path = AStarPlanner.findPath(map, robot.Position, task.PickupPos);
                            if ~isempty(path)
                                minScore = score;
                                bestRobotID = robot.ID;
                                bestPath = path;
                            end
                        end
                    end
                end
                
                if bestRobotID > 0
                    targetRobot = robots(bestRobotID);
                    task.State = 'HeadingToPickup';
                    targetRobot.assignTask(task, bestPath);
                    taskMgr.updateTaskState(task.ID, 'HeadingToPickup', bestRobotID);
                    obj.TotalNetworkMessages = obj.TotalNetworkMessages + 2; % Send command back to robot
                end
            end
        end
        
        function reassignTask(obj, task, taskMgr, map, robots)
            % Re-assigns an abandoned/interrupted task (e.g. from a failed robot)
            task.State = 'Unassigned';
            task.AssignedRobotID = 0;
            taskMgr.updateTaskState(task.ID, 'Unassigned', 0);
            
            % Immediately trigger allocation
            if contains(obj.Mode, 'Distributed')
                obj.allocateDistributed(task, taskMgr, map, robots);
            else
                obj.allocateCentralized(task, taskMgr, map, robots);
            end
        end
    end
end
