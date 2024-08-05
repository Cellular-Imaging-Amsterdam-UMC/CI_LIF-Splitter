function cfSave2QPTIFFRGB(app, Filename, lifinfo)
    [~, ~, iminfo] = cfReadMetaData(lifinfo);

    do12bit8bit=app.RGBCheckBox.Value;

    [map,basename,ext]=fileparts(Filename);
    if app.LZWlosslessButton.Value
        Filename=[map '\' basename '_LZW' ext];
        Compression=Tiff.Compression.LZW;
        BitsPerSample = iminfo.channelResolution(1);
        SMinSampleValue=0;
        if BitsPerSample>8 && BitsPerSample<=16 && ~do12bit8bit
            SMaxSampleValue=(2^BitsPerSample-1);   
            BitsPerSample=16;
        else
            BitsPerSample=8;
            SMaxSampleValue=(2^BitsPerSample-1);   
        end
        doscaleMinMax = false;
        app.setLog(['Converting to ' num2str(BitsPerSample) '-bits RGB QPTIFF (LZW,Lossless)']);
    else
        Filename=[map '\' basename '_JPG' ext];
        app.setLog('Converting to 8-bits RGB QPTIFF (JPG, Lossy)');
        Compression=Tiff.Compression.JPEG;
        JPEGQuality=app.QualitySpinner.Value;
        BitsPerSample = 8;
        SMinSampleValue=0;
        SMaxSampleValue=(2^BitsPerSample-1);
        doscaleMinMax=(app.MChanMinMaxScalingCheckBox.Value && iminfo.channelResolution(1)>8);
    end

    if isfile(Filename)
        delete(Filename);
    end
    
    TiffObject = Tiff(Filename, 'w8');
    TileWidth = 512; % PerkinElmer uses 512x512 tiles everywhere

    app.setLog('Creating Thumbnail');
    level = 0;
    imthumb = createThumbnail(lifinfo, iminfo, TileWidth);
    if doscaleMinMax
        maxV=max(imthumb,[],'all');
    end
    imthumb = imadjust(imthumb,[0 max(stretchlim(imthumb),[],'all')]);
    app.setLog('Saving Tiles');
    while true
        ts = struct;
        if level == 0
            [~, ymax, xmax] = Im2TilesRange(iminfo, TileWidth, 1);
            ts.Software = 'PerkinElmer-QPI';
            ts.XResolution = 1 / (iminfo.xres * 100);
            ts.YResolution = 1 / (iminfo.yres * 100);
            ts.ImageLength = iminfo.ys;
            ts.ImageWidth = iminfo.xs;
            ts.TileLength = TileWidth;
            ts.TileWidth = TileWidth;
            ts.SMinSampleValue=SMinSampleValue;
            ts.SMaxSampleValue=SMaxSampleValue;            
            ts.ImageDescription = createImageDescriptionQPTIFF(iminfo);
            app.setLog('Adding Full Image:');
            app.setLog([num2str(xmax) 'x' num2str(ymax) ' tiles of ' num2str(TileWidth) 'x' num2str(TileWidth) ' px']);
        elseif level == 1
            imr = imthumb;
            ts.ImageLength = size(imr, 1);
            ts.ImageWidth = size(imr, 2);
            app.setLog(['Adding Thumbnail: Pass: ' num2str(level+1)]);
        else
            scale = 2^(level-1);
            [~, ymax, xmax] = Im2TilesRange(iminfo, TileWidth, scale);
            [ts.ImageWidth, ts.ImageLength] = getSizeForLevel(iminfo, scale);
            ts.XResolution = (1 / (iminfo.xres * 100)) / scale;
            ts.YResolution = (1 / (iminfo.yres * 100)) / scale;
            ts.TileLength = TileWidth;
            ts.TileWidth = TileWidth;
            ts.SMinSampleValue=SMinSampleValue;
            ts.SMaxSampleValue=SMaxSampleValue;            
            app.setLog(['Adding ' num2str(scale) 'x Reduced Pyramid Image:']);
            app.setLog([num2str(xmax) 'x' num2str(ymax) ' tiles of ' num2str(TileWidth) 'x' num2str(TileWidth) ' px']);
        end

        if level > 0
            TiffObject.writeDirectory();
        end

        if Compression == Tiff.Compression.JPEG
            ts.Compression=Tiff.Compression.JPEG;
            ts.JPEGQuality = JPEGQuality;
        else
            ts.Compression=Tiff.Compression.LZW;
        end        
        ts.Photometric = Tiff.Photometric.RGB;
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
                tile_data_row = readTileRowResizedAndReshaped(lifinfo, iminfo, y, xmax, TileWidth, 1);
                for x = 1:xmax
                    if doscaleMinMax
                        tile_data_row{x}=uint8(double(tile_data_row{x})/double(maxV)*255);
                    end
                    region_start = [(y - 1) * TileWidth + 1, (x - 1) * TileWidth + 1];
                    tile_number = TiffObject.computeTile(region_start);
                    TiffObject.writeEncodedTile(tile_number, tile_data_row{x});
                end
                nUpdateWaitbar2();
            end
        elseif level == 1
            TiffObject.write(imr);
        else
            app.setLog(['Processing Tiles: Pass: ' num2str(level+1)]);
            for y = 1:ymax
                tile_data_row = readTileRowResizedAndReshaped(lifinfo, iminfo, y, xmax, TileWidth, scale);
                for x = 1:xmax
                    if doscaleMinMax
                        tile_data_row{x}=uint8(double(tile_data_row{x})/double(maxV)*255);
                    end
                    region_start = [(y - 1) * TileWidth + 1, (x - 1) * TileWidth + 1];
                    tile_number = TiffObject.computeTile(region_start);
                    TiffObject.writeEncodedTile(tile_number, tile_data_row{x});
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
    app.setLog('Ready');

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
        desc = [desc sprintf('<Objective>%d</Objective>\n', iminfo.magnification)];
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

    function imthumb = createThumbnail(lifinfo, iminfo, TileWidth)
        % Scale to create a thumbnail with TileWidth height
        tscale = TileWidth / iminfo.ys; 
        ysize = TileWidth; % Fixed height for the thumbnail
        xsize = round(iminfo.xs * tscale); % Calculate the width after scaling
        
        % Determine the skip factor for creating the thumbnail
        skip_factor = ceil(iminfo.ys / ysize);
        
        % Read the entire image and resize it to thumbnail dimensions
        row_data = readImageDataRowResized(lifinfo, iminfo, 1, iminfo.ys, skip_factor);
        imthumb = imresize(row_data, [ysize, xsize]);
    end

    function [xsize, ysize] = getSizeForLevel(iminfo, scale)
        ysize = ceil(iminfo.ys / scale);
        xsize = ceil(iminfo.xs / scale);
    end

    function tile_data_row = readTileRowResizedAndReshaped(lifinfo, iminfo, y, xmax, TileWidth, scale)
        % Read and resize row data while reading
        r1 = (y - 1) * TileWidth * scale + 1;
        r2 = min(r1 + TileWidth * scale - 1, iminfo.ys);
        
        skip_factor = round(scale);
        row_data = readImageDataRowResized(lifinfo, iminfo, r1, r2, skip_factor);
    
        % Preallocate cell array for tiles
        tile_data_row = cell(1, xmax);
        
        for xx = 1:xmax
            c1 = (xx - 1) * TileWidth * scale + 1;
            c2 = min(c1 + TileWidth * scale - 1, iminfo.xs);
            c2 = min(c2, size(row_data, 2)); % Ensure c2 does not exceed row_data bounds
            tile = row_data(:, c1:skip_factor:c2, :);
            if size(tile, 1) < TileWidth || size(tile, 2) < TileWidth
                tile = padarray(tile, [TileWidth - size(tile, 1), TileWidth - size(tile, 2)], 0, 'post');
            end
            tile_data_row{xx} = tile;
        end
    end

    function imdata = readImageDataRowResized(lifinfo, iminfo, r1, r2, skip_factor)
        numRows = r2 - r1 + 1;
        if strcmpi(lifinfo.filetype, ".lif")
            fid = fopen(lifinfo.LIFFile, 'r', 'n', 'UTF-8');
            basePos = lifinfo.Position;
        elseif strcmpi(lifinfo.filetype, ".xlef") || strcmpi(lifinfo.filetype, ".lof")
            fid = fopen(lifinfo.LOFFile, 'r', 'n', 'UTF-8');
            basePos = 62;
        else
            error('Unsupported file type: %s', lifinfo.filetype);
        end

        if fid == -1
            error('Failed to open file: %s', lifinfo.LIFFile);
        end

        % Calculate the total number of rows to read
        totalRows = ceil(numRows / skip_factor);
        
        % Preallocate data
        if BitsPerSample == 8
            imdata = zeros(totalRows, iminfo.xs, 3, 'uint8');
        else
            imdata = zeros(totalRows, iminfo.xs, 3, 'uint16');
        end        
        
        for i = 1:totalRows
            r_start = r1 + (i - 1) * skip_factor;
            
            res=iminfo.channelResolution(1);
            resvalue=2^res-1;
            
            if BitsPerSample == 8
                if iminfo.channelResolution(1) == 8
                    p = (r_start - 1) * iminfo.xs * 3;
                    fseek(fid, basePos + p, 'bof');
                    row_pixels = fread(fid, [3, iminfo.xs], '*uint8');
                else
                    p = (r_start - 1) * iminfo.xs * 6;
                    fseek(fid, basePos + p, 'bof');
                    row_pixels = double(fread(fid, [3, iminfo.xs], '*uint16'));
                    if iminfo.channelResolution(1) == 12 && do12bit8bit
                        row_pixels=row_pixels/16;
                    else
                        row_pixels = uint8((row_pixels/resvalue)*255);
                    end
                end
            else
                p = iminfo.channelbytesinc(1) + (r_start - 1) * iminfo.xs * 6;
                fseek(fid, basePos + p, 'bof');
                row_pixels = fread(fid, [3, iminfo.xs], '*uint16');
            end

            row_pixels = row_pixels';
            imdata(i, :, :) = row_pixels(:, :);
        end

        fclose(fid);
    end

end
