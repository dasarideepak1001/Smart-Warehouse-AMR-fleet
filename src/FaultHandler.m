classdef FaultHandler < handle
    % FAULTHANDLER Robot failure injection, dynamic obstacle registration,
    % and automatic task handoff/reassignment.
    
    methods (Static)
        function [reassignedTask, eventMsg] = injectRobotFailure(robotID, robots, map, allocator, taskMgr)
            reassignedTask = [];
            eventMsg = '';
            
            if robotID < 1 || robotID > length(robots)
                return;
            end
            
            robot = robots(robotID);
            if strcmp(robot.Status, 'Failed')
                return; % Already failed
            end
            
            % 1. Mark robot status as Failed
            robot.failRobot();
            
            % 2. Add failed robot position to dynamic grid as physical obstacle
            map.addDynamicObstacle(robot.Position(1), robot.Position(2));
            
            % 3. Extract active task for handoff if robot was working
            if ~isempty(robot.CurrentTask)
                reassignedTask = robot.CurrentTask;
                robot.CurrentTask = [];
                
                eventMsg = sprintf('ROBOT FAILURE DETECTED: R%d failed at (%d,%d). Reassigning Task %d (%s)...', ...
                    robot.ID, robot.Position(1), robot.Position(2), reassignedTask.ID, reassignedTask.ItemName);
                
                % Reset task state to Unassigned with new pickup location as failed robot position (or original pickup)
                reassignedTask.State = 'Unassigned';
                reassignedTask.AssignedRobotID = 0;
                
                % Trigger immediate re-allocation via Edge Node / Task Allocator
                allocator.reassignTask(reassignedTask, taskMgr, map, robots);
            else
                eventMsg = sprintf('ROBOT FAILURE DETECTED: R%d failed at (%d,%d). Robot was idle.', ...
                    robot.ID, robot.Position(1), robot.Position(2));
            end
        end
    end
end
