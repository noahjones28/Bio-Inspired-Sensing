function S = update_design(r, design_name, do_save)
    %% ABOUT
    % Input: radius array, design_name, save updated linkage to directory
    % Output: updated linkage S
    

    %% SETUP
    % Set default value if not provided
    if nargin < 3
        do_save = true;
    end


    %% UPDATE DESIGN
    if design_name == "cylindrical" % [r1]
        try
            load('my_robots\cylindrical\my_robot.mat');
            S1.VLinks(2).r{1} = @(X1) r;
            S1.CVRods{2}(1+1).UpdateAll;
            S1 = S1.Update();
            if do_save
                save('my_robot.mat','S1')
            end
        catch ME
            error('Failed to change beam radii: %s', ME.message);
        end
        
    elseif design_name == "cylindrical_tapered" % [r1, r2]
        try
            load("my_robots\cylindrical_tapered\my_robot.mat");
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
    
    elseif design_name == "elliptical_tapered" % [r_major_1, r_minor_1, r_major_2, r_minor_2]
        try
            load("my_robots\elliptical_tapered\my_robot.mat");
            normalized_grad_a = r(3)-r(1);
            normalized_grad_b = r(4)-r(2);
            S1.VLinks(2).a{1} = @(X1)X1.*normalized_grad_a+r(1);
            S1.VLinks(2).b{1} = @(X1)X1.*normalized_grad_b+r(2);
            S1.CVRods{2}(1+1).UpdateAll;
            S1 = S1.Update();
            if do_save
                save('my_robot.mat','S1')
            end
        catch ME
            error('Failed to change beam radii: %s', ME.message);
        end
    
    elseif design_name == "elliptical_multi_division" % [r_major_1, r_minor_1,...,r_major_20, r_minor_20] 
        try
            load("my_robots\elliptical_multi_division\my_robot.mat");
            for i = 1:length(r)/2
                r_major = r(2*i-1);
                r_minor = r(2*i);
                S1.VLinks(2).a{i} = @(X1) r_major;
                S1.VLinks(2).b{i} = @(X1) r_minor;
                S1.CVRods{2}(1+i).UpdateAll;
                S1 = S1.Update();
            end
            if do_save
                save('my_robot.mat','S1')
            end
        catch ME
            error('Failed to change beam radii: %s', ME.message);
        end
    elseif design_name == "cylindrical_multi_division" % [r1, r2, ..., r20] 
        try
            load('my_robots\cylindrical_multi_division\my_robot.mat');
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
        error('invalid design_name!')
    end
    
    S = S1;
end