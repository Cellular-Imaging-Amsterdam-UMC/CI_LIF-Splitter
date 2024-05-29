function elementsContent = cfExtractElementContentsLOF(xmlString)
    % Parse the input XML string
    xmlDoc = xmlreadstring(xmlString);
    
    % Navigate to the first <Children> element
    childrenNode = xmlDoc.getElementsByTagName('Children').item(0);
    if isempty(childrenNode)
        error('<Children> node not found.');
    end
    
    % Navigate to the first <Element> node
    elementNodes = xmlDoc.getElementsByTagName('Element');
    numElements = elementNodes.getLength;
    
    % Initialize a cell array to hold the content of each <Element>
    elementsContent = cell(1, elementNodes.getLength);
    
    % Loop through all <Element> nodes
    for i = 0:numElements-1
        % Get the current <Element> node
        currentNode = elementNodes.item(i);
        
        % Serialize the current <Element> node back to string
        elementsContent{i+1} = getCleanElementText(xmlwrite(currentNode));
    end
end

function cleanText = getCleanElementText(textContent)
    % Remove all newlines and extra whitespace from the text content
    cleanText = regexprep(textContent, '\s+', ' ');
    cleanText = replace(cleanText,'> <','><');
    cleanText = replace(cleanText,'<?xml version="1.0" encoding="utf-8"?>','');
end

function xmlDoc = xmlreadstring(xmlString)
    % Create a temporary file
    tempFileName = [tempname, '.xml'];
    
    % Write the XML string to the temporary file
    fid = fopen(tempFileName, 'w');
    if fid == -1
        error('Failed to create temporary file for XML parsing.');
    end
    
    fwrite(fid, xmlString);
    fclose(fid);
    
    % Use xmlread to parse the XML from the temporary file
    try
        xmlDoc = xmlread(tempFileName);
    catch e
        error('Failed to parse XML: %s', e.message);
    end
    
    % Clean up by deleting the temporary file
    delete(tempFileName);
end
