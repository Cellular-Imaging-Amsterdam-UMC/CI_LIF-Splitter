function uuidStr = UUID
    % Create a new UUID
    uuidObj = java.util.UUID.randomUUID();
    % Convert the UUID object to string
    uuidStr = char(uuidObj.toString());
end

