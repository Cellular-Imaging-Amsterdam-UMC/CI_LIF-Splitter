function beautifiedSize = cfBytesString(bytes)
    % Define unit thresholds and corresponding labels
    units = [1, 1024, 1024^2, 1024^3, 1024^4, 1024^5];
    unitLabels = {'bytes', 'KB', 'MB', 'GB', 'TB', 'PB'};
    
    % Find the largest unit that the bytes can be converted into
    % without the result being less than 1.
    index = find(bytes < units, 1) - 1;
    if isempty(index)
        % If the bytes are larger than all predefined units, use the largest unit
        index = length(units);
    end
    
    % Convert the bytes to the selected unit
    convertedValue = bytes / units(index);
    
    % Format the result with two decimal places and append the unit label
    beautifiedSize = sprintf('%.2f %s', convertedValue, unitLabels{index});
end
