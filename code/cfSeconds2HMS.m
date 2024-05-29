function HMS = cfSeconds2HMS(t)
    hours = floor(t / 3600);
    t = t - hours * 3600;
    mins = floor(t / 60);
    secs = t - mins * 60;
    HMS = sprintf('%02d:%02d:%02d', hours, mins, secs);
end

