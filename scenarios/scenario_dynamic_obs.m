function scenario_dynamic_obs()
    % SCENARIO_DYNAMIC_OBS Demonstrates dynamic obstacle insertion and real-time
    % A* re-planning while an AMR is en route to pick up an order.
    
    clc;
    fprintf('=====================================================\n');
    fprintf(' SCENARIO 2: DYNAMIC OBSTACLE & RE-PLANNING DEMO     \n');
    fprintf('=====================================================\n');
    
    addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
    
    map = WarehouseMap(30, 30);
    
    % Initialize 3 Robots
    robots = [
        AMRRobot(1, [2, 2], 90), ...
        AMRRobot(2, [5, 3], 80), ...
        AMRRobot(3, [8, 2], 75)
    ];
    
    taskMgr = TaskManager();
    taskMgr.generateStandardScenarioTasks(map);
    
    allocator = TaskAllocator('Distributed');
    collisionAvoid = CollisionAvoidance();
    masterSlaveController = MasterSlaveTrafficController();
    dashboard = WarehouseDashboard('Scenario 2: Dynamic Obstacle Re-planning');
    
    obstacleInserted = false;
    maxTicks = 100;
    
    for tick = 1:maxTicks
        % Inject Dynamic Obstacle at tick 15 in the middle of aisle (15, 7)
        if tick == 15 && ~obstacleInserted
            obstacleInserted = true;
            map.addDynamicObstacle(15, 7);
            map.addDynamicObstacle(15, 8);
            fprintf('\n[EVENT] Dynamic Obstacle (Dropped Cargo Blockage) inserted at (15,7) and (15,8)!\n');
        end
        
        % Check for dynamic obstacle path blockages & re-plan
        collisionAvoid.checkDynamicObstacleBlocked(robots, map);
        
        % Allocate & move
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
            fprintf('[SUCCESS] All jobs completed despite dynamic obstacle!\n');
            break;
        end
        
        pause(0.05);
    end
end
