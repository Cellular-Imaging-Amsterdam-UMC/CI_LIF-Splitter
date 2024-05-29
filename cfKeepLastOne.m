function newLogicalArray = cfKeepLastOne(logicalArray)
    % This function retains only the last '1' in the logical array
    % and sets all other elements to '0'.
    
    % Find indices of all '1's
    indicesOfOnes = find(logicalArray);

    % Initialize the output array as all zeros of the same size as the input
    newLogicalArray = zeros(size(logicalArray), 'logical'); % Specify logical type here

    % Check if there is at least one '1' in the array
    if ~isempty(indicesOfOnes)
        % Keep only the last '1'
        lastOneIndex = indicesOfOnes(end);

        % Set only the last '1' to true
        newLogicalArray(lastOneIndex) = 1;
    end
end

