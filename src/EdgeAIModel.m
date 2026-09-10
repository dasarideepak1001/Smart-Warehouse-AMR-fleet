classdef EdgeAIModel < handle
    % EDGEAIMODEL Edge AI / Machine Learning estimator for corridor congestion,
    % travel time prediction, and dynamic multi-factor robot scoring.
    
    properties
        WeightDistance  % Weight for travel distance
        WeightBattery   % Weight for low battery penalty
        WeightWorkload  % Weight for existing workload penalty
        WeightCongestion% Weight for predicted traffic congestion
        WeightPriority  % Weight for task priority advantage
    end
    
    methods
        function obj = EdgeAIModel()
            % Default scoring weights
            obj.WeightDistance   = 1.0;
            obj.WeightBattery    = 0.8;
            obj.WeightWorkload   = 15.0;
            obj.WeightCongestion = 2.5;
            obj.WeightPriority   = 5.0;
        end
        
        function [score, predictedTime] = calculateRobotScore(obj, robot, task, map, allRobots)
            % CALCULATEROBOTSCORE Computes multi-factor Edge AI suitability score.
            % Lower score = better candidate robot for assignment.
            
            % 1. Battery check threshold (< 30% cannot take new jobs; auto-charges)
            if robot.Battery < 30.0 || strcmp(robot.Status, 'Failed') || strcmp(robot.Status, 'Charging')
                score = inf;
                predictedTime = inf;
                return;
            end
            
            % 2. Distance from robot's position to Pickup location
            distToPickup = abs(robot.Position(1) - task.PickupPos(1)) + abs(robot.Position(2) - task.PickupPos(2));
            distPickupToDelivery = abs(task.PickupPos(1) - task.DeliveryPos(1)) + abs(task.PickupPos(2) - task.DeliveryPos(2));
            totalDistance = distToPickup + distPickupToDelivery;
            
            % 3. Zone Robot Density (Congestion Prediction)
            pickupZone = map.getZoneForPosition(task.PickupPos);
            robotsInZoneCount = 0;
            for i = 1:length(allRobots)
                if allRobots(i).ZoneID == pickupZone && allRobots(i).ID ~= robot.ID
                    robotsInZoneCount = robotsInZoneCount + 1;
                end
            end
            
            % Edge AI Congestion Estimator Formula
            % Traffic density multiplier scales exponentially with local fleet density
            congestionIndex = 1.0 + 0.18 * robotsInZoneCount;
            predictedTime = (totalDistance / robot.Speed) * congestionIndex;
            
            % 4. Workload Factor (0 if free, 1 if working)
            workloadFactor = 0;
            if strcmp(robot.Status, 'Working')
                workloadFactor = 1;
            end
            
            % 5. Battery Penalty (0 for 100% battery, high for lower battery)
            batteryPenalty = 100.0 - robot.Battery;
            
            % Multi-Factor Score Calculation
            score = (obj.WeightDistance * distToPickup) + ...
                    (obj.WeightCongestion * (congestionIndex * 10)) + ...
                    (obj.WeightBattery * batteryPenalty) + ...
                    (obj.WeightWorkload * workloadFactor) - ...
                    (obj.WeightPriority * task.Priority);
        end
    end
end
