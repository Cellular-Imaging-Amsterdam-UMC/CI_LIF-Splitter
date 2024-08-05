function cfCopyMemBlock(app, lifinfo, fidw)

    % Determine the correct file and position based on filetype
    if strcmpi(lifinfo.filetype, '.lif')
        fid = fopen(lifinfo.LIFFile, 'r', 'n', 'UTF-8');
        p = lifinfo.Position;
    elseif strcmpi(lifinfo.filetype, '.xlef') || strcmpi(lifinfo.filetype, '.lof')
        fid = fopen(lifinfo.LOFFile, 'r', 'n', 'UTF-8');
        %4+4+1+4+30(LMS_Object_File=2*15)+1+4+1+4+1+8 = 62
        p = 62;
    else
        error('Unsupported filetype');
    end

    % Check if file opened successfully
    if fid == -1
        error('Failed to open file');
    end

    % Move to the starting position in the file
    fseek(fid, p, 'cof');

    % Define the size of each block to read and write (e.g., 8192 bytes)
    blockSize = 256000000;  % This can be adjusted based on memory constraints

    % Calculate the number of full blocks and the size of the final block
    numFullBlocks = floor(lifinfo.MemorySize / blockSize);
    finalBlockSize = rem(lifinfo.MemorySize, blockSize);

    app.ProgressBar.startProgress('')
    numComplete2=0;
    maxComplete2=numFullBlocks;
    startTime2 = datetime('now');  

    % Process each full block
    for i = 1:numFullBlocks
        % Read a block
        memblock = fread(fid, blockSize, '*uint8');
        % Write the block
        fwrite(fidw, memblock, 'uint8');
        nUpdateWaitbar2 
    end
    
    % Process the final block, if any
    if finalBlockSize > 0
        memblock = fread(fid, finalBlockSize, '*uint8');
        fwrite(fidw, memblock, 'uint8');
    end
    
    app.setProgress2(0, '')

    % Close the file
    % fclose(fid);

    function nUpdateWaitbar2(~)
        numComplete2 = numComplete2 + 1;
        fractionComplete2 = numComplete2/maxComplete2;
        timeElapsed = datetime('now') - startTime2;
        elapsedStr = datestr(timeElapsed, 'HH:MM:SS');
        setProgress2(app, fractionComplete2, ['Elapsed time: ' elapsedStr]);
    end    
end
