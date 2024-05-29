function [imicon] = cfGetimIcon(app, sname, node, lifinfo)
    if strcmpi(lifinfo.datatype,'image')
        imicon='image.png';
    elseif strcmpi(lifinfo.datatype,'eventlist')
        imicon='eventlist.png';
    end
end

