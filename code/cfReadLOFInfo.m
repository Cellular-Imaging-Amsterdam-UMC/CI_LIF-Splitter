function [MemorySize, xmlElement] = cfReadLOFInfo(lifinfo)
    try
        fileID = fopen(lifinfo.LOFFile,'r','n','UTF-8');
        testvalue=fread(fileID,1,'int32');
        if testvalue~=112; return; end 
        BinContentLenght=fread(fileID,1,'int32');
        testvalue=fread(fileID,1,'uint8');
        if testvalue~=42; return; end 
        testvalue=fread(fileID,1,'int32');
        LMS_Object_File_UTF16=reshape(fread(fileID,2*testvalue,'*char'),1,testvalue*2);
        testvalue=fread(fileID,1,'uint8');
        if testvalue~=42; return; end 
        testvalue=fread(fileID,1,'int32');
        testvalue=fread(fileID,1,'uint8');
        if testvalue~=42; return; end 
        testvalue=fread(fileID,1,'int32');
        testvalue=fread(fileID,1,'uint8');
        if testvalue~=42; return; end 
        MemorySize=fread(fileID,1,'uint64');
        if MemorySize>0; fseek(fileID,MemorySize,0); end
        testvalue=fread(fileID,1,'uint32');
        if testvalue~=112; return; end 
        testvalue=fread(fileID,1,'uint32');
        testvalue=fread(fileID,1,'uint8');    
        if testvalue~=42; return; end 
        testvalue=fread(fileID,1,'uint32');

        XMLObjDescriptionUTF16=fread(fileID,testvalue,'uint16');
        XMLObjDescription=char(XMLObjDescriptionUTF16)';        
        
        % XMLObjDescriptionUTF16=reshape(fread(fileID,2*testvalue,'*char'),1,testvalue*2);
        % XMLObjDescription=cfUnicode2ascii(XMLObjDescriptionUTF16);
        % %XMLObjDescription=regexprep(XMLObjDescription,'</',[newline '</']);
        % %xmlElement=cfExtractElementContentsLOF(XMLObjDescription);
        % %xmlElement=xmlElement{1};

        if strcmpi(XMLObjDescription(1:4),'<LMS')
            xmlElement=ExtractData(XMLObjDescription);
        else
            xmlElement=XMLObjDescription;
        end
        fclose(fileID);
    catch
        xmlElement='';
        MemorySize=0;
    end
end

function dataContent=ExtractData(xmlContent)
    % Extract the first <Data> and the last </Data> part
    dataStart = strfind(xmlContent, '<Data>');
    dataEnd = strfind(xmlContent, '</Data>');
    
    if ~isempty(dataStart) && ~isempty(dataEnd)
        % Get the first occurrence of <Data> and the last occurrence of </Data>
        dataContent = xmlContent(dataStart(1):dataEnd(end) + length('</Data>') - 1);
    else
        error('The <Data>...</Data> section was not found in the XML file.');
    end
end

