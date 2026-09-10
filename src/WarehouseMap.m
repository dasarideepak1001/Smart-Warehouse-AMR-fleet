classdef WarehouseMap < handle
    % WAREHOUSEMAP Defines the 2D occupancy grid, shelves, zones, and stations
    % for the Smart Warehouse AMR simulation.
    
    properties
        GridDimensions % [Width, Height] in grid units e.g. [30, 30]
        Grid           % Matrix of 0 (free space) and 1 (static obstacle/shelf)
        DynamicGrid    % Matrix of 0 and 1 (dynamic obstacles e.g. dropped boxes/failed robots)
        EdgeZones      % Struct array defining geographic boundaries of edge nodes
        Shelves        % Struct of shelf locations and pickup waypoints
        PackingStations% Struct of packing station coordinates
        ChargingStations% Struct of charging station coordinates
    end
    
    methods
        function obj = WarehouseMap(width, height)
            if nargin < 1, width = 30; end
            if nargin < 2, height = 30; end
            
            obj.GridDimensions = [width, height];
            obj.Grid = zeros(height, width);
            obj.DynamicGrid = zeros(height, width);
            
            % Initialize Shelves & Obstacles
            obj.setupWarehouseLayout();
            
            % Initialize Edge Zones (4 Quadrants)
            obj.setupEdgeZones();
        end
        
        function setupWarehouseLayout(obj)
            w = obj.GridDimensions(1);
            h = obj.GridDimensions(2);
            
            % Outer Walls (boundary protection)
            obj.Grid(1, :) = 1; obj.Grid(h, :) = 1;
            obj.Grid(:, 1) = 1; obj.Grid(:, w) = 1;
            
            % Shelves (Vertical blocks of obstacles with aisles)
            % Shelf Block A (Top-Left)
            obj.Grid(4:10, 4:5) = 1;
            obj.Grid(4:10, 9:10) = 1;
            
            % Shelf Block B (Top-Right)
            obj.Grid(4:10, 19:20) = 1;
            obj.Grid(4:10, 24:25) = 1;
            
            % Shelf Block C (Bottom-Left)
            obj.Grid(18:24, 4:5) = 1;
            obj.Grid(18:24, 9:10) = 1;
            
            % Shelf Block D (Bottom-Right)
            obj.Grid(18:24, 19:20) = 1;
            obj.Grid(18:24, 24:25) = 1;
            
            % Named Landmarks & Waypoints with Product Categories
            obj.Shelves = struct(...
                'ShelfA', struct('Area', [4 10 4 5],   'Pickup', [3, 7],   'Category', 'Consumer Electronics',     'ShortCat', '📱 Electronics', ...
                                 'Items', {{'Mobile Phone', 'Tablet', 'Smart Watch', 'Wireless Earbuds', 'Digital Camera'}}), ...
                'ShelfB', struct('Area', [4 10 9 10],  'Pickup', [11, 7],  'Category', 'Computers & IT Hardware',  'ShortCat', '💻 Computers', ...
                                 'Items', {{'Laptop', 'Mechanical Keyboard', 'Gaming Mouse', 'Computer Monitor', 'Wi-Fi 6 Router'}}), ...
                'ShelfC', struct('Area', [4 10 19 20], 'Pickup', [18, 7],  'Category', 'Gaming & Audio',           'ShortCat', '🎮 Gaming/Audio', ...
                                 'Items', {{'Gaming Console', 'Wireless Headphones', 'VR Headset', 'Game Controller', 'Smart Speaker'}}), ...
                'ShelfD', struct('Area', [4 10 24 25], 'Pickup', [26, 7],  'Category', 'Smart Home Appliances',    'ShortCat', '🏠 Smart Home', ...
                                 'Items', {{'Robotic Vacuum', 'Smart Air Purifier', 'Electric Kettle', 'Smart LED Lamp', 'Induction Cooktop'}}), ...
                'ShelfE', struct('Area', [18 24 4 5],  'Pickup', [3, 21],  'Category', 'Apparel & Sportswear',     'ShortCat', '👟 Apparel', ...
                                 'Items', {{'Running Shoes', 'Sports Jacket', 'Fitness Backpack', 'Training Hoodie', 'Hiking Boots'}}), ...
                'ShelfF', struct('Area', [18 24 9 10], 'Pickup', [11, 21], 'Category', 'Books & Office Supplies',  'ShortCat', '📚 Books/Office', ...
                                 'Items', {{'Technical Books', 'Notebook & Pen Set', 'Desktop Organizer', 'Graphing Calculator', 'Document Scanner'}}), ...
                'ShelfG', struct('Area', [18 24 19 20],'Pickup', [18, 21], 'Category', 'Healthcare & Personal Care','ShortCat', '💊 Health/Care', ...
                                 'Items', {{'Digital Thermometer', 'Blood Pressure Monitor', 'Electric Toothbrush', 'First Aid Kit', 'Pulse Oximeter'}}), ...
                'ShelfH', struct('Area', [18 24 24 25],'Pickup', [26, 21], 'Category', 'Tools & Industrial HW',    'ShortCat', '🔧 Tools/HW', ...
                                 'Items', {{'Cordless Power Drill', 'Digital Multimeter', 'Precision Screwdriver Set', 'Soldering Station', 'Laser Rangefinder'}}) ...
            );
            
            % Packing Stations at top of warehouse
            obj.PackingStations = struct(...
                'P1', struct('Pos', [7, 2], 'Name', 'Packing Station 1'), ...
                'P2', struct('Pos', [22, 2], 'Name', 'Packing Station 2') ...
            );
            
            % Charging Stations at bottom corners with 2 Dedicated Charging Ports Each (Capacity: 2 AMRs Max)
            obj.ChargingStations = struct(...
                'C1', struct('Pos', [2, 28], 'Name', 'Charging Station 1', 'Capacity', 2, ...
                             'Ports', struct('PortA', [2, 28], 'PortB', [3, 28]), ...
                             'QueuePos', [2, 25]), ...
                'C2', struct('Pos', [28, 28], 'Name', 'Charging Station 2', 'Capacity', 2, ...
                             'Ports', struct('PortA', [27, 28], 'PortB', [28, 28]), ...
                             'QueuePos', [28, 25]) ...
            );
        end
        
        function setupEdgeZones(obj)
            w = obj.GridDimensions(1);
            h = obj.GridDimensions(2);
            midX = floor(w / 2);
            midY = floor(h / 2);
            
            % 4 Zone Partitioning
            obj.EdgeZones = struct(...
                'Zone1', struct('ID', 1, 'XRange', [1, midX], 'YRange', [1, midY], 'Name', 'Zone 1 (NW)'), ...
                'Zone2', struct('ID', 2, 'XRange', [midX+1, w], 'YRange', [1, midY], 'Name', 'Zone 2 (NE)'), ...
                'Zone3', struct('ID', 3, 'XRange', [1, midX], 'YRange', [midY+1, h], 'Name', 'Zone 3 (SW)'), ...
                'Zone4', struct('ID', 4, 'XRange', [midX+1, w], 'YRange', [midY+1, h], 'Name', 'Zone 4 (SE)') ...
            );
        end
        
        function zoneID = getZoneForPosition(obj, pos)
            x = pos(1); y = pos(2);
            w = obj.GridDimensions(1);
            h = obj.GridDimensions(2);
            midX = floor(w / 2);
            midY = floor(h / 2);
            
            if x <= midX && y <= midY
                zoneID = 1;
            elseif x > midX && y <= midY
                zoneID = 2;
            elseif x <= midX && y > midY
                zoneID = 3;
            else
                zoneID = 4;
            end
        end
        
        function tf = isOccupied(obj, x, y)
            % Returns true if (x,y) is blocked by static or dynamic obstacles
            if x < 1 || x > obj.GridDimensions(1) || y < 1 || y > obj.GridDimensions(2)
                tf = true;
                return;
            end
            tf = (obj.Grid(y, x) == 1) || (obj.DynamicGrid(y, x) == 1);
        end
        
        function addDynamicObstacle(obj, x, y)
            if x >= 1 && x <= obj.GridDimensions(1) && y >= 1 && y <= obj.GridDimensions(2)
                obj.DynamicGrid(y, x) = 1;
            end
        end
        
        function removeDynamicObstacle(obj, x, y)
            if x >= 1 && x <= obj.GridDimensions(1) && y >= 1 && y <= obj.GridDimensions(2)
                obj.DynamicGrid(y, x) = 0;
            end
        end
        
        function clearDynamicObstacles(obj)
            obj.DynamicGrid(:) = 0;
        end
    end
end
