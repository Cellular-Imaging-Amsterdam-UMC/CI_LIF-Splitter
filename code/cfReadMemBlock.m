function memblock = cfReadMemBlock(iminfo,lifinfo,tile)
    if strcmpi(lifinfo.filetype,".lif")
        fid=fopen(lifinfo.LIFFile,'r','n','UTF-8');
        p=lifinfo.Position+(tile-1)*iminfo.tilesbytesinc;        
    end
    if strcmpi(lifinfo.filetype,".xlef")
        fid=fopen(lifinfo.LOFFile,'r','n','UTF-8');
        %4+4+1+4+30(LMS_Object_File=2*15)+1+4+1+4+1+8 = 62
        p=62+(tile-1)*iminfo.tilesbytesinc;        
    end
    fseek(fid,p,'cof');
    if iminfo.xbytesinc==1
        memblock=fread(fid, iminfo.xs*iminfo.ys*iminfo.zs*iminfo.ts*iminfo.channels, '*uint8');
        if size(memblock,1)~=iminfo.xs*iminfo.ys*iminfo.zs*iminfo.ts*iminfo.channels
            memblock=fread(fid, iminfo.xs*iminfo.ys*iminfo.zs*iminfo.ts*iminfo.channels, '*uint8');
        end
    else
        memblock=fread(fid, iminfo.xs*iminfo.ys*iminfo.zs*iminfo.ts*iminfo.channels, '*uint16');
        if size(memblock,1)~=iminfo.xs*iminfo.ys*iminfo.zs*iminfo.ts*iminfo.channels
            memblock=fread(fid, iminfo.xs*iminfo.ys*iminfo.zs*iminfo.ts*iminfo.channels, '*uint16');
        end
    end
    fclose(fid);
end

