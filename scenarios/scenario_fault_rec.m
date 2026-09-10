function scenario_fault_rec()
    % SCENARIO_FAULT_REC Demonstrates robot failure detection mid-task,
    % dynamic obstacle registration, and automated task reassignment handoff.
    
    clc;
    fprintf('=====================================================\n');
    fprintf(' SCENARIO 3: ROBOT FAILURE & AUTOMATED TASK HANDOFF  \n');
    fprintf('=====================================================\n');
    
    addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
    
    map = WarehouseMap(30, 30);
    
    % Initialize 4 Robots
    robots = [
        AMRRobot(1, [2, 2], 90), ...
        AMRRobot(2, [5, 3], 85), ...
        AMRRobot(3, [8, 2], 80), ...
        AMRRobot(4, [3, 7], 75)
    ];
    
    taskMgr = TaskManager();
    taskMgr.generateStandardScenarioTasks(map);
    
    allocator = TaskAllocator('Distributed');
    collisionAvoid = CollisionAvoidance();
    masterSlaveController = MasterSlaveTrafficController();
    dashboard = WarehouseDashboard('Scenario 3: Robot Failure & Task Handoff');
    
    failureInjected = false;
    maxTicks = 120;
    
    for tick = 1:maxTicks
        % Trigger Robot R2 failure at tick 20 while carrying out task
        if tick == 20 && ~failureInjected
            failureInjected = true;
            [reassignedTask, eventMsg] = FaultHandler.injectRobotFailure(2, robots, map, allocator, taskMgr);
            fprintf('\n%s\n', eventMsg);
        end
        
        allocator.allocatePendingTasks(taskMgr, map, robots);
        masterSlaveController.resolveMasterSlavePicking(robots, map, taskMgr);
        masterSlaveController.resolveMasterSlaveTraffic(robots, map, taskMgr);
        collisionAvoid.resolveCollisions(robots, map);
        
        for r = 1:length(robots)
            robots(r).update(map, taskMgr, tick, robots);
        end
        
        BatteryManager.checkAndRouteLowBatteryRobots(robots, map, taskMgr, allocator);
        dashboard.render(map, robots, taskMgr, collisionAvoid, allocator, tick, [], masterSlaveController);
        
        completedCount = sum(strcmp({taskMgr.AllTasks.State}, 'Completed'));
        if completedCount >= length(taskMgr.AllTasks)
            fprintf('\n[SUCCESS] Task handoff complete! All remaining jobs completed despite Robot 2 failure.\n');
            break;
        end
        
        pause(0.05);
    end
end
