function currentDir = getCurrentDir
if isdeployed % Stand-alone mode.
    [~, result] = system('path');
    currentDir = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
else % MATLAB mode.
    currentDir = pwd;
end