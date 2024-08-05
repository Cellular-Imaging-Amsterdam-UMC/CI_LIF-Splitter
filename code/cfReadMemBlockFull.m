function memblock = cfReadMemBlockFull(lifinfo)
    if strcmpi(lifinfo.filetype,".lif")
        fid=fopen(lifinfo.LIFFile,'r','n','UTF-8');
        p=lifinfo.Position;        
    end
    if strcmpi(lifinfo.filetype,".xlef")
        fid=fopen(lifinfo.LOFFile,'r','n','UTF-8');
        %4+4+1+4+30(LMS_Object_File=2*15)+1+4+1+4+1+8 = 62
        p=62;        
    end
    fseek(fid,p,'cof');
    memblock=fread(fid, lifinfo.MemorySize,'*uint8');
    fclose(fid);
end

