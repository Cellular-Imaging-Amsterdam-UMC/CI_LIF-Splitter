function cfProcessLIFSplit(app)
    %try
        selectedNodes = app.Tree.SelectedNodes;
        if numel(selectedNodes)==0
            app.setLog('No Images Selected!')
            return
        end

        progressTitle='LIF Splitting';
        app.setProgress(0, 'Start')
        numComplete=0;
        maxComplete=numel(selectedNodes);
        startTime = clock();
        for i=1:numel(selectedNodes)
            lifinfo=selectedNodes(i).NodeData{2};
            [~, ~, iminfo]=cfReadMetaData(lifinfo);
            if strcmpi(selectedNodes(i).Tag,'Image') || strcmpi(selectedNodes(i).Tag,'ImageFile')
                if app.PreviewDropDown.Value>0 
                    app.ShowPreview(lifinfo, iminfo);
                end
                if strcmpi(lifinfo.filetype,'.xlef')
                    [lifmap,lifname,~]=fileparts(lifinfo.XLEFFile);
                elseif strcmpi(lifinfo.filetype,'.lof')
                    [lifmap,lifname,~]=fileparts(lifinfo.LOFFile);
                else
                    [lifmap,lifname,~]=fileparts(lifinfo.LIFFile);
                end
                if iminfo.isrgb && iminfo.zs==1 && iminfo.ts==1 && iminfo.tiles==1 && iminfo.channels==3 && app.ConvertToQTIFFCheckBox.Value
                    app.setLog(['Splitting of: ' lifinfo.name])
                    Filename=[lifmap '\' lifname '_' lifinfo.Parent '_' lifinfo.name '.qptiff'];
                    LIFsplit.cfSave2QPTIFFRGB(app, Filename,lifinfo)                    
                elseif ~iminfo.isrgb && iminfo.ts==1 && iminfo.tiles==1 && app.ConvertToQTIFFCheckBox.Value
                    app.setLog(['Splitting of: ' lifinfo.name])
                    Filename=[lifmap '\' lifname '_' lifinfo.Parent '_' lifinfo.name '.qptiff'];
                    LIFsplit.cfSave2QPTIFFMultiChannel(app, Filename,lifinfo)                    
                elseif strcmpi(lifinfo.filetype,'.lof')
                    app.setLog(['Splitting of: ' lifinfo.name])
                    Filename=[lifmap '\' lifname '.lif'];
                    LIFsplit.cfSave2LIF(app, Filename,lifinfo)
                else
                    app.setLog(['Splitting of: ' lifinfo.name])
                    Filename=[lifmap '\' lifname '_' lifinfo.Parent '_' lifinfo.name '.lif'];
                    LIFsplit.cfSave2LIF(app, Filename,lifinfo)
                end
            end
            nUpdateWaitbar 
            if checkCancel; break; end
        end
   %  catch ME
   %       app.setLog('Error!');
   %       app.setLog(['ID: ' ME.identifier])
   %       app.setLog(['Message: ' ME.message])
   %       app.setLog('Probably: Incompatible Format/Missing MetaData')
   %       app.setLog('When Converting to SVS, maybe not enough memory')
   % end
   % 
    function nUpdateWaitbar(~)
        numComplete = numComplete + 1;
        fractionComplete = numComplete/maxComplete;
        timeElapsed = etime(clock(), startTime);
        setProgress(app, fractionComplete, [progressTitle ': ' num2str(numComplete) ' of ' num2str(maxComplete) ' - Elapsed time: ' datestr(datenum(0,0,0,0,0,timeElapsed),'HH:MM:SS')]);
        drawnow limitrate
    end

    function chkCancel=checkCancel()
        if app.isCancelled
            chkCancel=true;
            app.setLog('Cancelled');
        else
            chkCancel=false;
        end
    end

end