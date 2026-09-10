classdef AStarPlanner < handle
    % ASTARPLANNER Grid-based A* optimal path planning algorithm for warehouse navigation.
    
    methods (Static)
        function path = findPath(map, startPos, goalPos, avoidMask)
            % FINDPATH Finds optimal grid path from startPos [x,y] to goalPos [x,y].
            % avoidMask (optional): additional 2D binary matrix of temporary dynamic obstacles.
            
            if nargin < 4 || isempty(avoidMask)
                avoidMask = zeros(map.GridDimensions(2), map.GridDimensions(1));
            end
            
            w = map.GridDimensions(1);
            h = map.GridDimensions(2);
            
            startPos = round(startPos);
            goalPos = round(goalPos);
            
            % Sanity check start and goal bounds
            if startPos(1) < 1 || startPos(1) > w || startPos(2) < 1 || startPos(2) > h || ...
               goalPos(1) < 1 || goalPos(1) > w || goalPos(2) < 1 || goalPos(2) > h
                path = [];
                return;
            end
            
            if isequal(startPos, goalPos)
                path = startPos;
                return;
            end
            
            % 4-neighbor directions: Right, Left, Down, Up
            dx = [1, -1, 0, 0];
            dy = [0, 0, 1, -1];
            
            % Open set, Closed set, gScore, fScore, Parent matrices
            gScore = inf(h, w);
            fScore = inf(h, w);
            parentX = zeros(h, w);
            parentY = zeros(h, w);
            closedSet = false(h, w);
            
            gScore(startPos(2), startPos(1)) = 0;
            fScore(startPos(2), startPos(1)) = AStarPlanner.heuristic(startPos, goalPos);
            
            % Priority Queue representation using arrays
            % Store nodes as [fScore, x, y]
            openSet = [fScore(startPos(2), startPos(1)), startPos(1), startPos(2)];
            
            foundGoal = false;
            
            while ~isempty(openSet)
                % Pop node with lowest fScore
                [~, minIdx] = min(openSet(:, 1));
                current = openSet(minIdx, 2:3);
                openSet(minIdx, :) = []; % Remove from open set
                
                currX = current(1);
                currY = current(2);
                
                if isequal(current, goalPos)
                    foundGoal = true;
                    break;
                end
                
                closedSet(currY, currX) = true;
                
                % Explore 4-neighbors
                for i = 1:4
                    nx = currX + dx(i);
                    ny = currY + dy(i);
                    
                    % Check map bounds
                    if nx < 1 || nx > w || ny < 1 || ny > h
                        continue;
                    end
                    
                    % Check obstacle status (unless neighbor is goalPos and avoidMask is mild)
                    if (map.Grid(ny, nx) == 1 || map.DynamicGrid(ny, nx) == 1 || avoidMask(ny, nx) == 1) ...
                            && ~isequal([nx, ny], goalPos)
                        continue;
                    end
                    
                    if closedSet(ny, nx)
                        continue;
                    end
                    
                    % -------------------------------------------------------------
                    % MULTI-LANE DIRECTIONAL HIGHWAY NETWORK PREFERENCES:
                    % Prevents head-on encounters by separating opposing traffic into
                    % dedicated parallel lanes (like highway lanes on a dual carriageway).
                    % -------------------------------------------------------------
                    highwayPenalty = 0;
                    
                    % 1. Horizontal Corridors (Eastbound vs. Westbound)
                    % Top Highway (y = 2..3)
                    if goalPos(1) > startPos(1) && ny == 3 && nx >= 4 && nx <= 26
                        highwayPenalty = highwayPenalty + 1.5; % Eastbound prefers row y = 2
                    elseif goalPos(1) < startPos(1) && ny == 2 && nx >= 4 && nx <= 26
                        highwayPenalty = highwayPenalty + 1.5; % Westbound prefers row y = 3
                    end
                    
                    % Middle Cross-Corridor (y = 12..16)
                    if abs(goalPos(1) - startPos(1)) >= 5 && ny >= 12 && ny <= 16
                        if goalPos(1) > startPos(1) && ny > 13
                            highwayPenalty = highwayPenalty + 1.0; % Eastbound prefers row y = 13
                        elseif goalPos(1) < startPos(1) && ny < 15
                            highwayPenalty = highwayPenalty + 1.0; % Westbound prefers row y = 15
                        end
                    end
                    
                    % 2. Vertical Corridors (Northbound vs. Southbound)
                    % Central Highway Corridor (x = 11..18 between Shelf Block A and B)
                    if abs(goalPos(2) - startPos(2)) >= 4 && nx >= 11 && nx <= 18
                        % Southbound (moving Down, goalPos(2) > startPos(2)): prefers left lane (x = 11, 12)
                        % Northbound (moving Up, goalPos(2) < startPos(2)): prefers right lane (x = 14, 15, 16)
                        if goalPos(2) > startPos(2) && nx >= 14 && ~isequal([nx, ny], goalPos)
                            highwayPenalty = highwayPenalty + 2.0; % Southbound penalized on northbound lanes
                        elseif goalPos(2) < startPos(2) && nx <= 12 && ~isequal([nx, ny], goalPos)
                            highwayPenalty = highwayPenalty + 2.0; % Northbound penalized on southbound lanes
                        end
                    end
                    
                    % Shelf Block A Middle Aisle (x = 6..8)
                    if abs(goalPos(2) - startPos(2)) >= 4 && nx >= 6 && nx <= 8
                        if goalPos(2) > startPos(2) && nx == 8
                            highwayPenalty = highwayPenalty + 1.5; % Southbound prefers x = 6
                        elseif goalPos(2) < startPos(2) && nx == 6
                            highwayPenalty = highwayPenalty + 1.5; % Northbound prefers x = 8
                        end
                    end
                    
                    % Shelf Block B Middle Aisle (x = 21..23)
                    if abs(goalPos(2) - startPos(2)) >= 4 && nx >= 21 && nx <= 23
                        if goalPos(2) > startPos(2) && nx == 23
                            highwayPenalty = highwayPenalty + 1.5; % Southbound prefers x = 21
                        elseif goalPos(2) < startPos(2) && nx == 21
                            highwayPenalty = highwayPenalty + 1.5; % Northbound prefers x = 23
                        end
                    end
                    
                    tentativeG = gScore(currY, currX) + 1 + highwayPenalty;
                    
                    if tentativeG < gScore(ny, nx)
                        parentX(ny, nx) = currX;
                        parentY(ny, nx) = currY;
                        gScore(ny, nx) = tentativeG;
                        fScore(ny, nx) = tentativeG + AStarPlanner.heuristic([nx, ny], goalPos);
                        
                        % Add to openSet if not already present
                        inOpen = false;
                        if ~isempty(openSet)
                            inOpen = any(openSet(:, 2) == nx & openSet(:, 3) == ny);
                        end
                        
                        if ~inOpen
                            openSet = [openSet; fScore(ny, nx), nx, ny]; %#ok<AGROW>
                        end
                    end
                end
            end
            
            if ~foundGoal
                path = [];
                return;
            end
            
            % Reconstruct path from goalPos back to startPos
            currX = goalPos(1);
            currY = goalPos(2);
            revPath = [currX, currY];
            
            while ~(currX == startPos(1) && currY == startPos(2))
                px = parentX(currY, currX);
                py = parentY(currY, currX);
                if px == 0 && py == 0
                    break; % Fallback safeguard
                end
                currX = px;
                currY = py;
                revPath = [revPath; currX, currY]; %#ok<AGROW>
            end
            
            path = flipud(revPath);
        end
        
        function hVal = heuristic(pos, goal)
            % Manhattan distance heuristic
            hVal = abs(pos(1) - goal(1)) + abs(pos(2) - goal(2));
        end
    end
end
