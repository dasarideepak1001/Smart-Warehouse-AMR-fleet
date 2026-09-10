function run_simulation_3d()
    % RUN_SIMULATION_3D Direct launcher for the 3D Digital Twin Fleet Simulation.
    % Usage:
    %   run_simulation_3d
    
    clc;
    rootDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(rootDir, 'src'));
    addpath(fullfile(rootDir, 'benchmarks'));
    addpath(fullfile(rootDir, 'scenarios'));
    
    scenario_3d();
end
