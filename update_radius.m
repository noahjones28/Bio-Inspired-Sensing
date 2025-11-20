function S = update_radius(r, mode, do_save)
    % Load robot and change radius
    % do_save: optional parameter (default: true) - saves to 'my_robot.mat' if true
    
    % Set default value for do_save if not provided
    if nargin < 3
        do_save = true;
    end
    
    if mode == "cylindrical"
        try
            load('my_robots\my_robot_cylindrical_3tendon\my_robot.mat');
            S1.VLinks(2).r{1} = @(X1) r;
            S1.CVRods{2}(1+1).UpdateAll;
            S1 = S1.Update();
            if do_save
                save('my_robot.mat','S1')
            end
        catch ME
            error('Failed to change beam radii: %s', ME.message);
        end
        
    elseif mode == "tapered"
        try
            load("my_robots\my_robot_tapered_3tendon\my_robot.mat");
            normalized_grad = r(2)-r(1);
            S1.VLinks(2).r{1} = @(X1)X1.*normalized_grad+r(1);
            S1.CVRods{2}(1+1).UpdateAll;
            S1 = S1.Update();
            if do_save
                save('my_robot.mat','S1')
            end
        catch ME
            error('Failed to change beam radii: %s', ME.message);
        end
        
    elseif mode == "multi division"
        try
            load('my_robots\my_robot_multi_division_20_3tendon\my_robot.mat');
            for i = 1:length(r)
                S1.VLinks(2).r{i} = @(X1) r(i);
                S1.CVRods{2}(1+i).UpdateAll;
                S1 = S1.Update();
            end
            if do_save
                save('my_robot.mat','S1')
            end
        catch ME
            error('Failed to change beam radii: %s', ME.message);
        end
        
    else
        error('invalid mode!')
    end
    
    S = S1;
end