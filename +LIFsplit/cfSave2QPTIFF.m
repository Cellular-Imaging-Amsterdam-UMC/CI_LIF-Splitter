function cfSave2QPTIFF(app, Filename, lifinfo)
    app.setLog('LIF/XLEF RGB Image Convert to QPTIFF');
    [~, ~, iminfo] = cfReadMetaData(lifinfo);

    BitsPerSample = iminfo.channelResolution(1);
    MaxV = 2^BitsPerSample - 1;
    if BitsPerSample > 8
        BitsPerSample = 16;
    end

    app.setLog('Converting to 8-bits RGB PerkinElmer QPTIFF');
    doScaleQPTIFF = (BitsPerSample ~= 8);
    BitsPerSample = 8;

    app.setLog('Reading Image');
    im = ReadIm(lifinfo, iminfo);
    if doScaleQPTIFF
        im = uint8(imadjust(im, [0, MaxV / 65535], [0, 255 / 65535]));
    end
    im = fliplr(imrotate(im, -90));
    s = size(im);
    iminfo.xsfull = s(2);
    iminfo.ysfull = s(1);
    im = imadjust(im, stretchlim(nonzeros(im), [0 1]), []);

    if isfile(Filename)
        delete(Filename);
    end
    
    TiffObject = Tiff(Filename, 'w8');

    app.setLog('Saving Tiles');
    level = 0;
    while true
        ts = struct;
        TileWidth = 512; % PerkinElmer uses 512x512 tiles everywhere
        if level == 0
            ts.Software = 'PerkinElmer-QPI';
            ts.XResolution = 1 / (iminfo.xres * 100);
            ts.YResolution = 1 / (iminfo.yres * 100);
            [imtiles, ymax, xmax] = Im2TilesRange(im, TileWidth);
            xsize = xmax * TileWidth;
            ysize = ymax * TileWidth;
            ts.ImageDescription = createImageDescriptionQPTIFF(iminfo, xsize, ysize, TileWidth);
            ts.ImageLength = iminfo.ysfull;
            ts.ImageWidth = iminfo.xsfull;
            ts.TileLength = TileWidth;
            ts.TileWidth = TileWidth;
            app.setLog('Adding Full Image:');
            app.setLog([num2str(xmax) 'x' num2str(ymax) ' tiles of ' num2str(TileWidth) 'x' num2str(TileWidth) ' px']);
        elseif level == 1
            imr = imresize(im, [512, (iminfo.xsfull / iminfo.ysfull * 512)]); % Thumbnail size ~500x500
            ts.ImageLength = size(imr, 1);
            ts.ImageWidth = size(imr, 2);
            app.setLog('Adding Thumbnail');
        else
            scale = 2^(level-1);
            imr = imresize(im, [iminfo.ysfull / scale, iminfo.xsfull / scale]); % Reduced resolution
            ts.XResolution = (1 / (iminfo.xres * 100)) / scale;
            ts.YResolution = (1 / (iminfo.yres * 100)) / scale;
            [imtiles, ymax, xmax] = Im2TilesRange(imr, TileWidth);
            ts.ImageLength = size(imr, 1);
            ts.ImageWidth = size(imr, 2);
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
        maxComplete2 = xmax;
        startTime2 = datetime('now');  

        if level == 0
            app.setLog(['Processing Tiles: Pass: ' num2str(level+1)]);
            for x = 1:xmax
                for y = 1:ymax
                    region_start = [(y - 1) * TileWidth + 1, (x - 1) * TileWidth + 1];
                    tile_number = TiffObject.computeTile(region_start);
                    TiffObject.writeEncodedTile(tile_number, im(imtiles{y, x}(1, 1):imtiles{y, x}(1, 2), imtiles{y, x}(2, 1):imtiles{y, x}(2, 2), :));
                end
                nUpdateWaitbar2;
            end
        elseif level == 1
            app.setLog(['Processing Thumbnail: Pass: ' num2str(level+1)]);
            TiffObject.write(imr);
        else
            app.setLog(['Processing Tiles: Pass: ' num2str(level+1)]);
            for x = 1:xmax
                for y = 1:ymax
                    region_start = [(y - 1) * TileWidth + 1, (x - 1) * TileWidth + 1];
                    tile_number = TiffObject.computeTile(region_start);
                    TiffObject.writeEncodedTile(tile_number, imr(imtiles{y, x}(1, 1):imtiles{y, x}(1, 2), imtiles{y, x}(2, 1):imtiles{y, x}(2, 2), :));
                end
                nUpdateWaitbar2;
            end
        end

        if level > 1 && (size(imr, 1) <= 2000 && size(imr, 2) <= 2000)
            break;
        end

        clear imr;
        level = level + 1;
    end

    TiffObject.close();
    app.setProgress2(0, '');

    function desc = createImageDescriptionQPTIFF(iminfo, xsize, ysize, TileWidth)
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

    function nUpdateWaitbar2(~)
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
end

function [seg, max_row, max_col] = Im2TilesRange(img, Lseg)
    L = size(img);
    max_row = floor(L(1) / Lseg);
    rm_row = L(1) - Lseg * max_row;
    max_col = floor(L(2) / Lseg);
    rm_col = L(2) - Lseg * max_col;
    if rm_row > 0
        max_row = max_row + 1;
    end
    if rm_col > 0
        max_col = max_col + 1;
    end
    seg = cell(max_row, max_col);
    r1 = 1;
    for row = 1:max_row
        c1 = 1;
        for col = 1:max_col
            r2 = r1 + Lseg - 1;
            c2 = c1 + Lseg - 1;
            if r2 > L(1)
                r2 = L(1);
            end
            if c2 > L(2)
                c2 = L(2);
            end
            seg(row, col) = {[r1, r2; c1, c2]};
            c1 = c2 + 1;
        end
        r1 = r2 + 1;
    end
end

function imdata = ReadIm(lifinfo, iminfo)
    if strcmpi(lifinfo.filetype, ".lif")
        fid = fopen(lifinfo.LIFFile, 'r', 'n', 'UTF-8');
        p = iminfo.channelbytesinc(1) + lifinfo.Position;
        fseek(fid, p, 'bof');
        imdata = readImageData(fid, iminfo);
        fclose(fid);
    elseif strcmpi(lifinfo.filetype, ".xlef")
        fid = fopen(lifinfo.LOFFile, 'r', 'n', 'UTF-8');
        p = iminfo.channelbytesinc(1) + 62;
        fseek(fid, p, 'bof');
        imdata = readImageData(fid, iminfo);
        fclose(fid);
    end
end

function imdata = readImageData(fid, iminfo)
    if iminfo.channelResolution(1) == 8
        imdata = fread(fid, iminfo.ys * iminfo.xs * 3, 'uint8=>uint8');
        imdata = reshapeChannels(imdata, iminfo.xs, iminfo.ys);
    else
        imdata = fread(fid, iminfo.ys * iminfo.xs * 3, 'uint16=>uint16');
        imdata = reshapeChannels(imdata, iminfo.xs, iminfo.ys);
    end
end

function imdata = reshapeChannels(imdata, xs, ys)
    redChannel = reshape(imdata(1:3:end), [xs, ys]);
    greenChannel = reshape(imdata(2:3:end), [xs, ys]);
    blueChannel = reshape(imdata(3:3:end), [xs, ys]);
    imdata = cat(3, redChannel, greenChannel, blueChannel);
end
