function SmartWarehouseAMR(option)
    % SMARTWAREHOUSEAMR Main Executable Entry Point for MATLAB & Simulink.
    % Usage:
    %   SmartWarehouseAMR             - Launches 2D Animated GUI Simulation
    %   SmartWarehouseAMR('simulink') - Builds & Opens Simulink Diagram Model
    
    if nargin < 1, option = 'gui'; end
    
    clc;
    fprintf('=================================================================\n');
    fprintf('   SMART WAREHOUSE AMR FLEET COORDINATION SYSTEM (MATLAB/SIMULINK)\n');
    fprintf('   Edge AI + Distributed Coordination + A* + Collision Avoidance \n');
    fprintf('=================================================================\n\n');
    
    rootDir = fileparts(mfilename('fullpath'));
    if ~isempty(rootDir)
        addpath(fullfile(rootDir, 'src'));
        addpath(fullfile(rootDir, 'benchmarks'));
        addpath(fullfile(rootDir, 'scenarios'));
    end
    
    if strcmpi(option, 'simulink')
        create_simulink_model();
    else
        scenario_normal();
    end
end
