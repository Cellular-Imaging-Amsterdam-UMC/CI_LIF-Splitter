function impreview = cfCreatePreviewRGB(app, lifinfo)
    previewWidth = app.PreviewDropDown.Value;
    [~, ~, iminfo] = cfReadMetaData(lifinfo);

    % Get fileName and basePos
    if strcmpi(lifinfo.filetype, ".lif")
        fileName=lifinfo.LIFFile;
        basePos = lifinfo.Position;
    elseif strcmpi(lifinfo.filetype, ".xlef") || strcmpi(lifinfo.filetype, ".lof")
        fileName=lifinfo.LOFFile;
        basePos = 62;
    end
    if iminfo.zs>1 
        if app.ButtonMaxProj.Value
            z=-1;
        else
            z=floor(app.SliderZ.Value);
        end
    else
        z=1;
    end
    if iminfo.tiles>1
        tile=floor(app.SliderTiles.Value);
        basePos=basePos+(tile-1)*iminfo.tilesbytesinc;
    end
    if iminfo.ts>1
        t=floor(app.SliderT.Value);
        basePos=basePos+(t-1)*iminfo.tbytesinc;
    end      

    % Check the cache first
    for c = 1:length(app.cache)
        if strcmp(app.cache(c).fileName, fileName) ...
            && app.cache(c).basePos == basePos ...
            && app.cache(c).previewWidth == previewWidth ...
            && app.cache(c).z == z 

            impreview = app.cache(c).imageData;
            app.setLog('Loading Cached Preview');
            return;
        end
    end  
    
    % Create preview
    app.setLog('Creating Preview');

    % Scale to create a preview with previewWidth height
    tscale = previewWidth / iminfo.ys; 
    ysize = previewWidth; % Fixed height for the preview
    xsize = round(iminfo.xs * tscale); % Calculate the width after scaling
    
    % Determine the skip factor for creating the preview
    skip_factor = ceil(iminfo.ys / ysize);
    if iminfo.zs>10
        zstep = ceil(iminfo.zs / ysize);
        if zstep<=0; zstep=0; end
        if zstep>iminfo.zs; zstep=iminfo.zs; end
    else
        zstep=1;
    end

    app.ProgressBar.startProgress('')
    startTime2 = datetime('now');  
    updatePoints = round(linspace(1, ceil(iminfo.ys / skip_factor), 10));

    % Read and resize image data
    row_data = readImageDataRowResized(iminfo, skip_factor, zstep, fileName, basePos, z);
    impreview = imresize(row_data, [ysize, xsize]);

    setProgress2(app, 0, '')

    impreview=imadjust(impreview,[0 max(stretchlim(impreview),[],'all')]);

    % Update the cache
    app.cache(app.cacheIndex).fileName = fileName;
    app.cache(app.cacheIndex).basePos = basePos;
    app.cache(app.cacheIndex).previewWidth = previewWidth;
    app.cache(app.cacheIndex).z = z;
    app.cache(app.cacheIndex).imageData = impreview;
    app.cacheIndex = mod(app.cacheIndex, app.cacheSize) + 1;    

    app.setLog('Creating Ready');
    
    function row_data = readImageDataRowResized(iminfo,skip_factor, zstep, fileName, basePos, zvalue)
        fid = fopen(fileName, 'r', 'n', 'UTF-8');
        if fid == -1
            error('Failed to open file: %s', fileName);
        end

        % Calculate the total number of rows to read
        totalRows = ceil(iminfo.ys / skip_factor);
        
        % Preallocate data
        if iminfo.channelResolution(1) == 8
            row_data = zeros(totalRows, iminfo.xs, 3, 'uint8');
        else
            row_data = zeros(totalRows, iminfo.xs, 3, 'uint16');
        end

        for i = 1:totalRows
            if zvalue==-1
                z1=1; z2=iminfo.zs;
            else
                z1=zvalue; z2=zvalue;
                zstep=1;
            end
            for zz=z1:zstep:z2
                r_start = 1 + (i - 1) * skip_factor;

                if iminfo.channelResolution(1) == 8
                    p = (r_start - 1) * iminfo.xs * 3;
                    fseek(fid, basePos + (zz-1)*iminfo.zbytesinc + p, 'bof');
                    row_pixels = fread(fid, [3, iminfo.xs], '*uint8');
                else
                    p = (r_start - 1) * iminfo.xs * 6;
                    fseek(fid, basePos + (zz-1)*iminfo.zbytesinc + p, 'bof');
                    row_pixels = fread(fid, [3, iminfo.xs], '*uint16');
                end                
                row_pixels = permute(row_pixels, [2, 1]);

                if zz==z1
                    row_pixels_p=row_pixels;
                else
                    row_pixels_p=max(row_pixels,row_pixels_p);
                end
            end
            row_data(i, :, :) = row_pixels_p;

            if ismember(i, updatePoints)
                nUpdateWaitbar2(i/totalRows);
            end            
        end        

        fclose(fid);
    end

    function nUpdateWaitbar2(Value)
        timeElapsed = datetime('now') - startTime2;
        elapsedStr = datestr(timeElapsed, 'HH:MM:SS');
        if Value<=1
            setProgress2(app, Value, ['Elapsed time: ' elapsedStr]);
        end
    end
end
