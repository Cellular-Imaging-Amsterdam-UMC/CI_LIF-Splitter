function cfSave2LIF(app, sfileout,lifinfo)

    isLIF=strcmpi(lifinfo.filetype,'.lif');
    isXLEF=strcmpi(lifinfo.filetype,'.xlef') || strcmpi(lifinfo.filetype,'.lof');

    [~, fname, ext]=fileparts(sfileout);

    outxml='<LMSDataContainerHeader Version="2"><Element CopyOption="1" Name="%name%" UniqueID="%uuid%" Visibility="1"> <Data><Experiment IsSavedFlag="1" Path="%path%"/></Data><Memory MemoryBlockID="MemBlock_221" Size="0"/><Children>%element%</Children></Element></LMSDataContainerHeader>';
    outxml=replace(outxml,'%name%',[fname ext]);
    outxml=replace(outxml,'%path%',sfileout);
    if isXLEF
        xmldata=['<Element CopyOption="1" Name="' lifinfo.name '" UniqueID="8b48019d-6bf8-11ee-be69-80e82ce1e716" Visibility="1">'];
        xmldata=[xmldata lifinfo.xmlElement];
		xmldata=[xmldata '<Memory MemoryBlockID="MemBlock_333" Size="' num2str(lifinfo.MemorySize) '"/><Children/>'];
        xmldata=[xmldata '</Element>'];
        elementMemID='333';
    elseif isLIF
        xmldata=lifinfo.xmlElement;
        elementMemID='';
    end
    outxml=replace(outxml,'%element%',xmldata);
    outxml=replace(outxml,'%uuid%',UUID);

    % Uncomment for debugging
    % fidx=fopen('c:\xmlelement.xml','w');
    % fwrite(fidx,xmldata);
    % fclose(fidx);

    %Remove line breaks
    outxml=strrep(outxml,newline,'');

    %Remove strange chars that are not correctly read (like °) 
    %outxml(outxml > 127)='_';
    
    %Remove al whitespace
    outxml=regexprep(outxml,' +',' ');

    %Add CRLF to end of <Data> and <LMSDataContainerHeader>
    outxml=strrep(outxml,'/Data>',['/Data>' sprintf('\r\n')]);
    outxml=strrep(outxml,'/LMSDataContainerHeader>',['/LMSDataContainerHeader>' sprintf('\r\n')]);

    % Uncomment for debugging
    % fidx=fopen('c:\testfull.xml','w');
    % fwrite(fidx,outxml);
    % fclose(fidx);

    %Add zeros (UTF-8 -> UTF-16)
    outxml16=unicode2native(outxml,'UTF-16');

    %Write to file
    fid = fopen(sfileout,'w');

    %Binary Header
    fwrite(fid,hex2dec('70'),'uint32'); % 0x70 test value
    fwrite(fid,length(outxml16(3:end))+1+4,'uint32'); % Binary chunk lenght NC*2 + 1 + 4
    fwrite(fid,hex2dec('2A'),'uint8'); % 0x2A test value
    fwrite(fid,length(outxml16(3:end))/2,'uint32'); % Number of UTF-16 Characters (NC)

    %XML Header
    fwrite(fid,outxml16(3:end));

    % %MemBlock_221
    mdescription=addzeros('MemBlock_221');
    msize=0;
    fwrite(fid,hex2dec('70'),'uint32'); % 0x70 test value
    fwrite(fid,length(mdescription)+1+8+1+4,'uint32'); % Binary chunk lenght NC*2 + 1 + 8 + 1 + 4
    fwrite(fid,hex2dec('2A'),'uint8'); % 0x2A test value
    fwrite(fid,msize,'uint64'); % Size of Memory
    fwrite(fid,hex2dec('2A'),'uint8'); % 0x2A test value
    fwrite(fid,length(mdescription)/2,'uint32'); % Number of UTF-16 Characters (NC)
    fwrite(fid,mdescription); % Memory Description

    %MemBlock_element
    if strlength(elementMemID)<1
        elementMemID=findLastMemBlockNumberWithPositiveSize(lifinfo.xmlElement);
    end
    mdescription=addzeros(['MemBlock_' elementMemID]);
    msize=lifinfo.MemorySize;
    fwrite(fid,hex2dec('70'),'uint32'); % 0x70 test value
    fwrite(fid,length(mdescription)+1+8+1+4,'uint32'); % Binary chunk lenght NC*2 + 1 + 8 + 1 + 4
    fwrite(fid,hex2dec('2A'),'uint8'); % 0x2A test value
    fwrite(fid,msize,'uint64'); % Size of Memory
    fwrite(fid,hex2dec('2A'),'uint8'); % 0x2A test value
    fwrite(fid,length(mdescription)/2,'uint32'); % Number of UTF-16 Characters (NC)
    fwrite(fid,mdescription); % Memory Description

    %Memory
    cfCopyMemBlock(app,lifinfo,fid);

    app.setLog(['Created LIF: ' fname ext] )

    %Close file
    fclose(fid);
end

function outstr=addzeros(instr)
    %Add zeros (UTF-8 -> UTF-16)
    n = 1;
    out = [];
    while n<=length(instr)
        out = [out instr(n:min(n,length(instr))) char(0)]; %#ok<AGROW>
        n=n+1;
    end
    outstr=out;
end

function memBlockNumber = findLastMemBlockNumberWithPositiveSize(inputString)
    % Define the pattern to match the <Memory> tag with MemoryBlockID="MemBlock_<number>"
    % and Size="<positive number>".
    pattern = '<Memory\s+MemoryBlockID="MemBlock_(\d+)"\s+Size="(\d+)"\s*/>';
    
    % Use regexp to find matches that have a Size attribute greater than 0.
    tokens = regexp(inputString, pattern, 'tokens');
    
    % Initialize memBlockNumber as empty, indicating no match if condition is not met
    memBlockNumber = [];
    
    % Iterate through all tokens to find the last match with Size > 0
    for i = 1:length(tokens)
        % Extract the size from the current token. tokens{i}{2} is the size part of the match.
        size = str2double(tokens{i}{2});
        
        % Update memBlockNumber with the current MemBlock number if Size > 0
        if size > 0
            memBlockNumber = tokens{i}{1};
        end
    end
end



