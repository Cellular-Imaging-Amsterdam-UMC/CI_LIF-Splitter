function cfSave2QPTIFFRGB(app, Filename, lifinfo)
    app.setLog('LIF/XLEF RGB Image Convert to QPTIFF');
    [~, ~, iminfo] = cfReadMetaData(lifinfo);

    BitsPerSample = iminfo.channelResolution(1);
    if BitsPerSample > 8
        BitsPerSample = 16;
    end

    app.setLog('Converting to 8-bits RGB PerkinElmer QPTIFF');
    BitsPerSample = 8;

    if isfile(Filename)
        delete(Filename);
    end
    
    TiffObject = Tiff(Filename, 'w8');
    TileWidth = 512; % PerkinElmer uses 512x512 tiles everywhere

    app.setLog('Saving Tiles');
    level = 0;
    while true
        ts = struct;
        if level == 0
            [~, ymax, xmax] = Im2TilesRange(iminfo, TileWidth,1);
            ts.Software = 'PerkinElmer-QPI';
            ts.XResolution = 1 / (iminfo.xres * 100);
            ts.YResolution = 1 / (iminfo.yres * 100);
            ts.ImageLength = iminfo.ys;
            ts.ImageWidth = iminfo.xs;
            ts.TileLength = TileWidth;
            ts.TileWidth = TileWidth;
            ts.ImageDescription = createImageDescriptionQPTIFF(iminfo);
            app.setLog('Adding Full Image:');
            app.setLog([num2str(xmax) 'x' num2str(ymax) ' tiles of ' num2str(TileWidth) 'x' num2str(TileWidth) ' px']);
        elseif level == 1
            [~, ymax, xmax] = Im2TilesRange(iminfo, TileWidth, 1);
            imr = createThumbnail(lifinfo, iminfo, TileWidth);
            ts.ImageLength = size(imr, 1);
            ts.ImageWidth = size(imr, 2);
            app.setLog('Adding Thumbnail');
        else
            scale = 2^(level-1);
            [~, ymax, xmax] = Im2TilesRange(iminfo, TileWidth, scale);
            [ts.ImageWidth, ts.ImageLength] = getSizeForLevel(iminfo, scale);
            ts.XResolution = (1 / (iminfo.xres * 100)) / scale;
            ts.YResolution = (1 / (iminfo.yres * 100)) / scale;
            ts.TileLength = TileWidth;
            ts.TileWidth = TileWidth;
            app.setLog(['Adding ' num2str(scale) 'x Reduced Pyramid Image:']);
            app.setLog([num2str(xmax) 'x' num2str(ymax) ' tiles of ' num2str(TileWidth) 'x' num2str(TileWidth) ' px']);
        end

        if level > 0
            TiffObject.writeDirectory();
        end

        ts.Photometric = Tiff.Photometric.RGB;
        ts.Compression = Tiff.Compression.JPEG;
        ts.JPEGQuality = 80;
        ts.BitsPerSample = BitsPerSample;
        ts.SampleFormat = Tiff.SampleFormat.UInt;
        ts.SamplesPerPixel = 3;
        ts.ResolutionUnit = Tiff.ResolutionUnit.Centimeter;
        ts.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;

        TiffObject.setTag(ts);
        
        if level == 0
            TiffObject.setTag(254, 0); % Full-resolution image
        else
            TiffObject.setTag(254, 1); % Lower-resolution pyramid image
        end

        app.ProgressBar.startProgress('');
        numComplete2 = 0;
        maxComplete2 = ymax;
        startTime2 = datetime('now');  

        if level == 0
            app.setLog(['Processing Tiles: Pass: ' num2str(level+1)]);
            for y = 1:ymax
                tile_data_row = readTileRow(lifinfo, iminfo, y, xmax, TileWidth);
                for x = 1:xmax
                    region_start = [(y - 1) * TileWidth + 1, (x - 1) * TileWidth + 1];
                    tile_number = TiffObject.computeTile(region_start);
                    TiffObject.writeEncodedTile(tile_number, tile_data_row{x});
                end
                nUpdateWaitbar2();
            end
        elseif level == 1
            app.setLog(['Processing Thumbnail: Pass: ' num2str(level+1)]);
            TiffObject.write(imr);
        else
            app.setLog(['Processing Tiles: Pass: ' num2str(level+1)]);
            for y = 1:ymax
                tile_data_row = readTileRow(lifinfo, iminfo, y, xmax, TileWidth*scale);
                for x = 1:xmax
                    region_start = [(y - 1) * TileWidth + 1, (x - 1) * TileWidth + 1];
                    tile_number = TiffObject.computeTile(region_start);
                    TiffObject.writeEncodedTile(tile_number, imresize(tile_data_row{x},[512, 512]));
                end
                nUpdateWaitbar2();
            end
        end

        if level > 1 && (ts.ImageLength <= 2000 && ts.ImageWidth <= 2000)
            break;
        end

        clear imr;
        level = level + 1;
    end

    TiffObject.close();
    app.setProgress2(0, '');

    function desc = createImageDescriptionQPTIFF(iminfo)
        % XML formatted string for PerkinElmer-QPI
        uuidStr = UUID();
        desc = sprintf('<?xml version="1.0" encoding="utf-8"?>\n<PerkinElmer-QPI-ImageDescription>\n');
        desc = [desc sprintf('<DescriptionVersion>2</DescriptionVersion>\n')];
        desc = [desc sprintf('<AcquisitionSoftware>CI LIFSplitter</AcquisitionSoftware>\n')];
        desc = [desc sprintf('<Identifier>%s</Identifier>\n', uuidStr)];
        desc = [desc sprintf('<ImageType>FullResolution</ImageType>\n')];
        desc = [desc sprintf('<IsUnmixedComponent>False</IsUnmixedComponent>\n')];
        desc = [desc sprintf('<ExposureTime>50</ExposureTime>\n')];
        desc = [desc sprintf('<SignalUnits>64</SignalUnits>\n')];
        desc = [desc sprintf('<Objective>%d</Objective>\n', iminfo.objective)];
        desc = [desc sprintf('<ScanProfile></ScanProfile>\n')];
        desc = [desc sprintf('<ValidationCode>4281ff86778db65892c05151d5de738d</ValidationCode>\n')];
        desc = [desc sprintf('</PerkinElmer-QPI-ImageDescription>')];
    end

    function nUpdateWaitbar2()
        numComplete2 = numComplete2 + 1;
        fractionComplete2 = numComplete2 / maxComplete2;
        timeElapsed = datetime('now') - startTime2;
        elapsedStr = datestr(timeElapsed, 'HH:MM:SS');
        setProgress2(app, fractionComplete2, ['Elapsed time: ' elapsedStr]);
    end

    function uuidStr = UUID()
        % Create a new UUID
        uuidObj = java.util.UUID.randomUUID();
        % Convert the UUID object to string
        uuidStr = char(uuidObj.toString());
    end

    function [seg, max_row, max_col] = Im2TilesRange(iminfo, Lseg, scale)
        if nargin < 3
            scale = 1;
        end
        max_row = ceil(iminfo.ys / (Lseg * scale));
        max_col = ceil(iminfo.xs / (Lseg * scale));
        seg = cell(max_row, max_col);
        r1 = 1;
        for row = 1:max_row
            c1 = 1;
            for col = 1:max_col
                r2 = min(r1 + Lseg * scale - 1, iminfo.ys);
                c2 = min(c1 + Lseg * scale - 1, iminfo.xs);
                seg{row, col} = [r1, r2; c1, c2];
                c1 = c2 + 1;
            end
            r1 = r2 + 1;
        end
    end

    function imr = createThumbnail(lifinfo, iminfo, TileWidth)
        % Scale to create a 512 height thumbnail
        tscale = iminfo.xs / TileWidth; 
        ysize = round(iminfo.ys / tscale); % Calculate the width after scaling
    
        % Preallocate the thumbnail image
        imr = zeros(ysize,TileWidth, 3, 'uint8'); 
    
        % Calculate the number of rows to read in one go
        rows_per_tile = ceil(iminfo.ys / TileWidth);
        
        for yy = 1:rows_per_tile
            % Determine the start and end row indices for the current tile
            r1 = (yy - 1) * TileWidth + 1;
            r2 = min(r1 + TileWidth - 1, iminfo.ys);
            % Read the current row data
            row_data = readImageDataRow(lifinfo, iminfo, r1, r2);
            % Resize the row data
            TileHeight=round(ysize/rows_per_tile);
            resizedRow = imresize(row_data, [TileHeight, TileWidth]);
            % Calculate the vertical start and end positions in the thumbnail
            x_start = (yy - 1) * TileHeight + 1;
            x_end = min(x_start + size(resizedRow, 1) - 1, ysize);
            imr(x_start:x_end,1:TileWidth,:) = resizedRow(:, :, :);
        end
        s=size(imr);
        m=mod(s(1),8);
        s1=s(1)-m;
        s2=round(s(2)-m*(s(2)/s(1)));
        imr=resize(imr,[s1 s2]);
    end

    function [xsize, ysize] = getSizeForLevel(iminfo, scale)
        ysize = ceil(iminfo.ys / scale);
        xsize = ceil(iminfo.xs / scale);
    end

    function tile_data_row = readTileRow(lifinfo, iminfo, y, xmax, TileWidth)
        r1 = (y - 1) * TileWidth  + 1;
        r2 = min(r1 + TileWidth - 1, iminfo.ys);
        row_data = readImageDataRow(lifinfo, iminfo, r1, r2);

        % Preallocate cell array for tiles
        tile_data_row = cell(1, xmax);
        
        for xx = 1:xmax
            c1 = (xx - 1) * TileWidth  + 1;
            c2 = min(c1 + TileWidth - 1, iminfo.xs);
            tile_data_row{xx} = row_data(:,c1:c2,:);
        end
    end

    function imdata = readImageDataRow(lifinfo, iminfo, r1, r2)
        numRows = r2 - r1 + 1;
    
        if strcmpi(lifinfo.filetype, ".lif")
            fid = fopen(lifinfo.LIFFile, 'r', 'n', 'UTF-8');
            basePos = lifinfo.Position;
        elseif strcmpi(lifinfo.filetype, ".xlef")
            fid = fopen(lifinfo.LOFFile, 'r', 'n', 'UTF-8');
            basePos = 62;
        else
            error('Unsupported file type: %s', lifinfo.filetype);
        end
    
        if fid == -1
            error('Failed to open file: %s', lifinfo.LIFFile);
        end
    
        % Calculate the position to start reading from
        startPos = basePos + (r1 - 1) * iminfo.xs * 3 + iminfo.channelbytesinc(1);
    
        % Calculate the total number of bytes to read
        totalBytes = numRows * iminfo.xs * 3;
        
        fseek(fid, startPos, 'bof');
        
        if iminfo.channelResolution(1) == 8
            pixels = fread(fid, totalBytes, 'uint8=>uint8');
        else
            pixels = fread(fid, totalBytes, 'uint16=>uint8');
        end
    
        fclose(fid);
        
        % Reshape the read pixels to the correct format
        imdata=reshapeChannels(pixels,iminfo.xs,numRows);
        imdata=permute(imdata,[2,1,3]);
    end

    function imdata = reshapeChannels(imdata, xs, ys)
        redChannel = reshape(imdata(1:3:end), [xs, ys]);
        greenChannel = reshape(imdata(2:3:end), [xs, ys]);
        blueChannel = reshape(imdata(3:3:end), [xs, ys]);
        imdata = cat(3, redChannel, greenChannel, blueChannel);
    end
end
