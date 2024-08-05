function cfSave2SVS(app, Filename,lifinfo)
    %try

        app.setLog('LIF/XLEF RGB Image Convert to SVS');
        [~, ~, iminfo]=cfReadMetaData(lifinfo);

        BitsPerSample=iminfo.channelResolution(1);
        MaxV=2^BitsPerSample-1;
        if BitsPerSample>8; BitsPerSample=16; end

        app.setLog('Converting to 8-bits RGB Aperio SVS')
        tdepth=4;
        doScaleSVS=(BitsPerSample~=8);
        BitsPerSample=8;

        app.setLog('Reading Image')
        im=ReadIm(lifinfo, iminfo, 1, 1, 1, 1, false);
        if doScaleSVS
            im=uint8(imadjust(im,[0,MaxV/65535],[0,255/65535]));
        end
        im=fliplr(imrotate(im,-90));
        s=size(im);
        iminfo.xsfull=s(2);
        iminfo.ysfull=s(1);                    
        im=imadjust(im,stretchlim(nonzeros(im),[0 1]),[]);

        s=iminfo.xsfull*iminfo.ysfull*iminfo.channels*(BitsPerSample/8);
        s=s+s/4+s/8+s/16+s/32+s/64+s/128+s/256+s/1024+s/4096;
        s=s/1024/1024/1024;
        % Create the Tiff object (w8 is bigtiff).
        if isfile(Filename); delete(Filename); end
        if s>3.8
            TiffObject=Tiff(Filename,'w8');
        else
            TiffObject=Tiff(Filename,'w');
        end
        app.setLog('Saving Tiles')
        for r=1:tdepth
            ts=struct;
            if r==1 % 
                TileWidth=256;
                ts.Software='CI-LIFSplitter';
                ts.XResolution=1/(iminfo.xres*100);
                ts.YResolution=1/(iminfo.yres*100);
                [imtiles, ymax, xmax]=Im2TilesRange(im,TileWidth);
                xsize=xmax*TileWidth; ysize=ymax*TileWidth;
                ts.ImageDescription=createImageDescriptionSVS();
                app.setLog(['Adding Full Image: ' num2str(xmax) 'x' num2str(ymax) ' tiles of ' num2str(TileWidth) 'x' num2str(TileWidth) ' px'])
            end
            if r==2 % for SVS Thumbnail
                imr=imresize(im,[1024 (iminfo.xsfull/iminfo.ysfull*1024)]);
                ts.XResolution=72;
                ts.YResolution=72;
                app.setLog('Adding Thumbnail')                    
            end
            if r==3 % for SVS Pyramid
                TileWidth=64;
                imr=imresize(im,[iminfo.ysfull/4 iminfo.xsfull/4]);
                ts.XResolution=(1/(iminfo.xres*100))/4;
                ts.YResolution=(1/(iminfo.yres*100))/4;
                [imtiles, ymax, xmax]=Im2TilesRange(imr,TileWidth);
                app.setLog(['Adding 2x Reduced Pyramid Image: ' num2str(xmax) 'x' num2str(ymax) ' tiles of ' num2str(TileWidth) 'x' num2str(TileWidth) ' px'])
            end
            if r==4 % for SVS Pyramid
                TileWidth=16;
                imr=imresize(im,[iminfo.ysfull/16 iminfo.xsfull/16]);
                ts.XResolution=(1/(iminfo.xres*100))/16;
                ts.YResolution=(1/(iminfo.yres*100))/16;
                [imtiles, ymax, xmax]=Im2TilesRange(imr,TileWidth);
                app.setLog(['Adding 16x Reduced Pyramid Image: ' num2str(xmax) 'x' num2str(ymax) ' tiles of ' num2str(TileWidth) 'x' num2str(TileWidth) ' px'])
            end
            if r>1
                TiffObject.writeDirectory();
            end
            if r==2 % Thumbnail
                s=size(imr);
                ts.ImageLength=s(1);
                ts.ImageWidth=s(2);
            else
                ts.ImageLength=ymax*TileWidth;
                ts.ImageWidth=xmax*TileWidth;
                ts.TileLength=TileWidth;
                ts.TileWidth=TileWidth;
            end
            ts.Photometric=Tiff.Photometric.RGB;
            ts.JPEGColorMode=Tiff.JPEGColorMode.RGB;
            ts.Compression=Tiff.Compression.JPEG;
            ts.JPEGQuality=80;
            ts.BitsPerSample=BitsPerSample;
            ts.SampleFormat=Tiff.SampleFormat.UInt;
            ts.SamplesPerPixel=3; % RGB;
            ts.ResolutionUnit=Tiff.ResolutionUnit.Centimeter;
            ts.PlanarConfiguration=Tiff.PlanarConfiguration.Chunky;
            ts.SubFileType=0;
            TiffObject.setTag(ts);
            if r~=2
                app.setLog(['Processing Tiles: Pass: ' num2str(r) ' of ' num2str(tdepth)])
                for x=1:xmax 
                    for y=1:ymax
                        region_start=[(y-1)*TileWidth+1,(x-1)*TileWidth+1];
                        tile_number = TiffObject.computeTile(region_start);
                        if r==1
                            TiffObject.writeEncodedTile(tile_number,im(imtiles{y,x}(1,1):imtiles{y,x}(1,2),imtiles{y,x}(2,1):imtiles{y,x}(2,2),:));
                        else
                            TiffObject.writeEncodedTile(tile_number,imr(imtiles{y,x}(1,1):imtiles{y,x}(1,2),imtiles{y,x}(2,1):imtiles{y,x}(2,2),:));
                        end
                    end
                end
            else
                app.setLog(['Processing Thumbnail: Pass: ' num2str(r) ' of ' num2str(tdepth)])
                TiffObject.write(imr);
            end
        end
        TiffObject.close();
%     catch ME
%          app.setLog('Error!');
%          app.setLog(['ID: ' ME.identifier])
%          app.setLog(['Message: ' ME.message])
%          app.setLog('Probably: Incompatible Format/Missing MetaData')
%          app.setLog('Or maybe not enough Memory!')
%    end
    
    function desc=createImageDescriptionSVS()
        s=['Aperio Image Library v10.0.50' char(13) newline];
        s=[s num2str(xsize) 'x' num2str(ysize) ' [0,100 ' num2str(iminfo.xsfull) 'x' num2str(iminfo.ysfull) '] (' num2str(TileWidth) 'x' num2str(TileWidth) ')'];
        s=[s '|AppMag = ' num2str(iminfo.magnification)];
        s=[s '|MPP = ' num2str(round(iminfo.xres2,3))];
        s=[s '|OriginalWidth = ' num2str(xsize)];
        s=[s '|OriginalHeight = ' num2str(ysize)];
        desc=s;
    end

end

function [seg, max_row, max_col] = Im2TilesRange(img,Lseg)
    L = size(img);
    max_row = floor(L(1)/Lseg);
    rm_row=L(1)-Lseg*max_row;
    max_col = floor(L(2)/Lseg);
    rm_col=L(2)-Lseg*max_col;
    if rm_row>0; max_row=max_row+1; end
    if rm_col>0; max_col=max_col+1; end
    seg = cell(max_row,max_col);
    r1 = 1; % current row index, initially 1
    for row = 1:max_row
        c1 = 1; % current col index, initially 1
        for col = 1:max_col
            % find end rows/columns for segment
            r2 = r1+Lseg-1;
            c2 = c1+Lseg-1;
            if r2>L(1);r2=L(1); end
            if c2>L(2);c2=L(2); end
            % store segment range in cell array
            seg(row,col) = {[r1,r2;c1,c2]};
            % increment col start index
            c1 = c2 +1;
        end
        % increment row start index
        r1 = r2 +1;
    end
end

function imdata = ReadIm(lifinfo, iminfo, channel, z, t, tile, dotranspose)
    if strcmpi(lifinfo.filetype,".lif")
        % LIF
        fid=fopen(lifinfo.LIFFile,'r','n','UTF-8');

        p=iminfo.channelbytesinc(channel);
        p=p+(z-1)*iminfo.zbytesinc;
        p=p+(tile-1)*iminfo.tilesbytesinc;
        p=p+(t-1)*iminfo.tbytesinc;

        LIFOffset=lifinfo.Position;
        p=p+LIFOffset;

        fseek(fid,p,'bof');
        if iminfo.channelResolution(channel)==8
            imdata=fread(fid, iminfo.ys*iminfo.xs*3, 'uint8=>uint8');
            redChannel = reshape(imdata(1:3:end), [iminfo.xs, iminfo.ys]);
            greenChannel = reshape(imdata(2:3:end), [iminfo.xs, iminfo.ys]);
            blueChannel = reshape(imdata(3:3:end), [iminfo.xs, iminfo.ys]);
            imdata = cat(3, redChannel, greenChannel, blueChannel);                
        else
            imdata=fread(fid, iminfo.ys*iminfo.xs*3, 'uint16=>uint16');
            redChannel = reshape(imdata(1:3:end), [iminfo.xs, iminfo.ys]);
            greenChannel = reshape(imdata(2:3:end), [iminfo.xs, iminfo.ys]);
            blueChannel = reshape(imdata(3:3:end), [iminfo.xs, iminfo.ys]);
            imdata = cat(3, redChannel, greenChannel, blueChannel);                 
        end
        if dotranspose
            imdata=permute(imdata,[2 1 3]);
        end
        fclose(fid);
    end
    if strcmpi(lifinfo.filetype,".xlef")
        % LOF
        fid=fopen(lifinfo.LOFFile,'r','n','UTF-8');

        p=iminfo.channelbytesinc(channel);
        p=p+(z-1)*iminfo.zbytesinc;
        p=p+(tile-1)*iminfo.tilesbytesinc;
        p=p+(t-1)*iminfo.tbytesinc;

        LIFOffset=62;  %4 + 4 + 1 + 4 + 30 (LMS_Object_File=2*15) + 1 + 4 + 1 + 4 + 1 + 8
        p=p+LIFOffset;

        fseek(fid,p,'bof');

        if iminfo.channelResolution(channel)==8
            imdata=fread(fid, iminfo.ys*iminfo.xs*3, '*uint8');
            redChannel = reshape(imdata(1:3:end), [iminfo.xs, iminfo.ys]);
            greenChannel = reshape(imdata(2:3:end), [iminfo.xs, iminfo.ys]);
            blueChannel = reshape(imdata(3:3:end), [iminfo.xs, iminfo.ys]);
            imdata = cat(3, redChannel, greenChannel, blueChannel);                
        else
            imdata=fread(fid, iminfo.ys*iminfo.xs*3, '*uint16');
            redChannel = reshape(imdata(1:3:end), [iminfo.xs, iminfo.ys]);
            greenChannel = reshape(imdata(2:3:end), [iminfo.xs, iminfo.ys]);
            blueChannel = reshape(imdata(3:3:end), [iminfo.xs, iminfo.ys]);
            imdata = cat(3, redChannel, greenChannel, blueChannel);                 
        end
        if dotranspose
            imdata=permute(imdata,[2 1 3]);
        end
        fclose(fid);
    end
end
