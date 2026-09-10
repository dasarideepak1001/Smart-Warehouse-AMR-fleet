function scenario_normal()
    % SCENARIO_NORMAL Infinite Continuous Fleet Simulation of Smart Warehouse AMRs.
    % Features 5 AMRs, 4 Edge Zones, Edge AI task allocation, A* path planning,
    % inter-robot collision avoidance, continuous job streaming, and 5-minute autonomous charging (<30%).
    
    clc;
    fprintf('=================================================================\n');
    fprintf(' SCENARIO 1: INFINITE CONTINUOUS WAREHOUSE FLEET SIMULATION    \n');
    fprintf('=================================================================\n');
    
    % Add src to MATLAB path
    addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
    
    % Initialize Environment Map (30x30 Grid, 4 Edge Zones)
    map = WarehouseMap(30, 30);
    
    % Create 5 AMR Robots distributed across warehouse edge zones (Zone 1, Zone 2, Zone 3, Zone 4)
    numRobots = 5;
    startPositions = [2 3; 3 11; 16 3; 18 18; 2 18]; % R1 in Zone 1, R4 in Zone 4!
    initialBatteries = [100, 95, 95, 90, 95];
    
    robots = AMRRobot.empty(numRobots, 0);
    for r = 1:numRobots
        robots(r) = AMRRobot(r, startPositions(r, :), initialBatteries(r));
    end
    
    % Initialize Task Manager & pre-generate initial task queue
    taskMgr = TaskManager();
    taskMgr.generateStandardScenarioTasks(map);
    for k = 1:5
        taskMgr.generateRandomTask(map, 0);
    end
    
    % Initialize Allocator, Collision Avoidance, R2R Communicator, Master-Slave Controller, and Dashboard
    allocator = TaskAllocator('Master-Slave Distributed');
    collisionAvoid = CollisionAvoidance();
    r2rCommunicator = R2RCommunicator();
    masterSlaveController = MasterSlaveTrafficController();
    dashboard = WarehouseDashboard('Scenario 1: Infinite Continuous Fleet Operation');
    
    % Pre-assign Cross-Zone Benchmark Tasks: R1 (Zone 1) and R4 (Zone 4)
    % R1 (in Zone 1) got order that needs product from Zone 4 (ShelfH: Precision Screwdriver Set)
    % R4 (in Zone 4) got order that needs product from Zone 1 (ShelfA: Mobile Phone)
    t1 = taskMgr.AllTasks(1);
    p1 = AStarPlanner.findPath(map, robots(1).Position, t1.PickupPos);
    t1.State = 'HeadingToPickup';
    robots(1).assignTask(t1, p1);
    taskMgr.updateTaskState(t1.ID, 'HeadingToPickup', 1);
    
    t4 = taskMgr.AllTasks(4);
    p4 = AStarPlanner.findPath(map, robots(4).Position, t4.PickupPos);
    t4.State = 'HeadingToPickup';
    robots(4).assignTask(t4, p4);
    taskMgr.updateTaskState(t4.ID, 'HeadingToPickup', 4);
    
    maxTicks = 999999; % Continuous infinite simulation loop
    
    for tick = 1:maxTicks
        % Continuously generate new incoming warehouse orders whenever pending queue drops
        unassignedTasks = taskMgr.getUnassignedTasks();
        if length(unassignedTasks) < 4
            taskMgr.generateRandomTask(map, tick);
        end
        
        % 1. Allocate pending warehouse jobs
        allocator.allocatePendingTasks(taskMgr, map, robots);
        
        % 2. Process Master-Slave Shelf Picking Protocol (Lease Locks, Slave Holding Buffers, Co-Picks)
        masterSlaveController.resolveMasterSlavePicking(robots, map, taskMgr);
        
        % 3. Process Master-Slave Traffic Dispersal & Packing Load Balancing (<1s clearance)
        masterSlaveController.resolveMasterSlaveTraffic(robots, map, taskMgr);
        
        % 4. Process Peer-to-Peer Robot Communication & Cooperative Co-Pickups (Synchronized with M-S Leases!)
        r2rCommunicator.processR2RCommunications(robots, taskMgr, map, tick, masterSlaveController);
        
        % 5. Resolve spatial inter-robot collision risks
        collisionAvoid.resolveCollisions(robots, map);
        
        % 6. Advance robots along planned routes and update task status
        for r = 1:length(robots)
            robots(r).update(map, taskMgr, tick, robots);
        end
        
        % 7. Route low battery robots (<30%) autonomously to charging stations with task handoff
        BatteryManager.checkAndRouteLowBatteryRobots(robots, map, taskMgr, allocator);
        
        % 8. Render real-time graphical animation & dashboard HUD with Master-Slave Picking
        dashboard.render(map, robots, taskMgr, collisionAvoid, allocator, tick, r2rCommunicator, masterSlaveController);
        
        pause(0.02); % High-speed real-time animation pacing
    end
end
