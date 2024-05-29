function Seconds = cfHMS2Seconds(t)
    [~, ~, ~, H, MN, S] = datevec(t);
    Seconds=H*3600+MN*60+S;
end

