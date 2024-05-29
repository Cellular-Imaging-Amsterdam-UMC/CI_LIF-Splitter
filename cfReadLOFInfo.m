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
        XMLObjDescriptionUTF16=reshape(fread(fileID,2*testvalue,'*char'),1,testvalue*2);
        XMLObjDescription=cfUnicode2ascii(XMLObjDescriptionUTF16);
        %XMLObjDescription=regexprep(XMLObjDescription,'</',[newline '</']);
        %xmlElement=cfExtractElementContentsLOF(XMLObjDescription);
        %xmlElement=xmlElement{1};
        xmlElement=XMLObjDescription;
        fclose(fileID);
    catch
        xmlElement='';
        MemorySize=0;
    end
end

