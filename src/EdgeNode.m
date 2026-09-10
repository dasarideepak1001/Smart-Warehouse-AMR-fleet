classdef EdgeNode < handle
    % EDGENODE Local Edge Computing Node representing a warehouse zone.
    % Handles local task allocation, edge AI scoring, and neighbor inter-node messages.
    
    properties
        ZoneID              % Edge Zone ID (1..4)
        ZoneName            % Name string
        ManagedRobotIDs     % List of robot IDs currently in this zone
        EdgeAI              % Instance of EdgeAIModel
        MessageCount        % Counter of network communication messages
    end
    
    methods
        function obj = EdgeNode(zoneID, zoneName)
            obj.ZoneID = zoneID;
            obj.ZoneName = zoneName;
            obj.ManagedRobotIDs = [];
            obj.EdgeAI = EdgeAIModel();
            obj.MessageCount = 0;
        end
        
        function updateManagedRobots(obj, allRobots, map)
            % Identify which robots are currently in this zone
            obj.ManagedRobotIDs = [];
            for i = 1:length(allRobots)
                if map.getZoneForPosition(allRobots(i).Position) == obj.ZoneID
                    obj.ManagedRobotIDs(end+1) = allRobots(i).ID;
                end
            end
        end
        
        function [bestRobotID, bestPath, minScore] = allocateTaskLocally(obj, task, allRobots, map)
            % Evaluates tasks using local edge node compute
            bestRobotID = 0;
            bestPath = [];
            minScore = inf;
            
            % 1. Evaluate robots inside this zone first
            candidateIDs = obj.ManagedRobotIDs;
            
            for i = 1:length(candidateIDs)
                rIdx = candidateIDs(i);
                robot = allRobots(rIdx);
                
                % Record message exchange: Robot -> Edge Node
                obj.MessageCount = obj.MessageCount + 1;
                
                if strcmp(robot.Status, 'Free') && robot.Battery >= 30.0
                    [score, ~] = obj.EdgeAI.calculateRobotScore(robot, task, map, allRobots);
                    
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
            
            % 2. Record message exchange: Edge Node -> Robot decision
            if bestRobotID > 0
                obj.MessageCount = obj.MessageCount + 1;
            end
        end
    end
end
