function [result, serror, iminfo] = cfReadMetaData(lifinfo)
    import java.io.StringReader;
    import org.xml.sax.InputSource;
    %Reading MetaData (Leica LAS-X)
    if strcmpi(lifinfo.datatype,'Image') || strcmpi(lifinfo.datatype,'ImageFile')
        iminfo.xs=1;                     % imwidth
        iminfo.xbytesinc=0;
        iminfo.ys=1;                     % imheight
        iminfo.ybytesinc=0;
        iminfo.zs=1;                     % slices (stack)
        iminfo.zbytesinc=0;
        iminfo.ts=1;                     % time
        iminfo.tbytesinc=0;
        iminfo.tiles=1;                  % tiles
        iminfo.tilesbytesinc=0;
        iminfo.xres=0;                   % resolution x
        iminfo.yres=0;                   % resolution y
        iminfo.zres=0;                   % resolution z
        iminfo.tres=0;                   % time interval (from timestamps)
        iminfo.timestamps=[];            % Timestamps t
        iminfo.resunit='';               % resulution unit
        iminfo.xres2=0;                  % resolution x in �m
        iminfo.yres2=0;                  % resolution y in �m
        iminfo.zres2=0;                  % resolution z in �m
        iminfo.resunit2='�m';            % resulution unit in �m
        iminfo.lutname=cell(10,1);
        iminfo.channels=1;
        iminfo.isrgb=false;
        iminfo.channelResolution=zeros(10,1);
        iminfo.channelbytesinc=zeros(10,1);
        iminfo.contrastmethod=strings(10,1);
        iminfo.filterblock=strings(10,1);
        iminfo.excitation=zeros(10,1);
        iminfo.emission=zeros(10,1);
        iminfo.sn=zeros(10,1);
        iminfo.blackvalue=zeros(10,1);
        iminfo.whitevalue=zeros(10,1);
        iminfo.mictype='';
        iminfo.mictype2='';
        iminfo.objective='';
        iminfo.magnification='';
        iminfo.na=0;
        iminfo.refractiveindex=0;
        iminfo.pinholeradius=250;
        iminfo.flipx=0;
        iminfo.flipy=0;
        iminfo.swapxy=0;

        serror='';
        
        %Channels
        xmlInfo = lifinfo.Image.ImageDescription.Channels.ChannelDescription;
        iminfo.channels=numel(xmlInfo);
        if iminfo.channels>1
            iminfo.isrgb=(str2double(char(xmlInfo{1}.Attributes.ChannelTag))~=0);
        end
        for k = 1:iminfo.channels
            if iminfo.channels>1
                iminfo.channelbytesinc(k)=str2double(char(xmlInfo{k}.Attributes.BytesInc));
                iminfo.channelResolution(k)=str2double(char(xmlInfo{k}.Attributes.Resolution));
                iminfo.lutname{k}=lower(char(xmlInfo{k}.Attributes.LUTName));
            else
                iminfo.channelbytesinc(k)=str2double(char(xmlInfo.Attributes.BytesInc));
                iminfo.channelResolution(k)=str2double(char(xmlInfo.Attributes.Resolution));
                iminfo.lutname{k}=lower(char(xmlInfo.Attributes.LUTName));
            end
        end
        %Dimensions and size
        iminfo.zs=1;
        xmlInfo = lifinfo.Image.ImageDescription.Dimensions.DimensionDescription;
        for k = 1:numel(xmlInfo)
            dim=str2double(xmlInfo{k}.Attributes.DimID);
            switch dim
                case 1
                    iminfo.xs=str2double(xmlInfo{k}.Attributes.NumberOfElements);
                    iminfo.xres=str2double(xmlInfo{k}.Attributes.Length)/(iminfo.xs-1);
                    iminfo.xbytesinc=str2double(xmlInfo{k}.Attributes.BytesInc');
                    iminfo.resunit=char(xmlInfo{k}.Attributes.Unit);
                case 2
                    iminfo.ys=str2double(xmlInfo{k}.Attributes.NumberOfElements);
                    iminfo.yres=str2double(xmlInfo{k}.Attributes.Length)/(iminfo.ys-1);
                    iminfo.ybytesinc=str2double(xmlInfo{k}.Attributes.BytesInc');
                case 3
                    iminfo.zs=str2double(xmlInfo{k}.Attributes.NumberOfElements);
                    iminfo.zres=str2double(xmlInfo{k}.Attributes.Length)/(iminfo.zs-1);
                    iminfo.zbytesinc=str2double(xmlInfo{k}.Attributes.BytesInc');
                case 4
                    iminfo.ts=str2double(xmlInfo{k}.Attributes.NumberOfElements);
                    iminfo.tres=str2double(xmlInfo{k}.Attributes.Length)/(iminfo.ts-1);
                    iminfo.tbytesinc=str2double(xmlInfo{k}.Attributes.BytesInc');
                case 10
                    iminfo.tiles=str2double(xmlInfo{k}.Attributes.NumberOfElements);
                    iminfo.tilesbytesinc=str2double(xmlInfo{k}.Attributes.BytesInc');
            end
        end
        
        %TimeStamps
        % if iminfo.ts>1
        %     %Get Timestamps and number of timestamps
        %     xmlInfo = lifinfo.Image.TimeStampList;
        %     lifinfo.numberoftimestamps=str2double(xmlInfo.Attributes.NumberOfTimeStamps);
        %     %Convert to date and time
        %     ts=split(xmlInfo.Text,' ');
        %     ts=ts(1:end-1);
        %     tsd=datetime(datestr(now()),'TimeZone','Europe/Zurich');
        %     for t=1:numel(ts)
        %         tsd(t)=datetime(uint64(hex2dec(ts{t})),'ConvertFrom','ntfs','TimeZone','Europe/Zurich');
        %     end
        %     %??? Timestamps ???
        %     if iminfo.ts*iminfo.channels==lifinfo.numberoftimestamps
        %         t=tsd(end-(iminfo.channels-1))-tsd(1);
        %         iminfo.tres=seconds(t/(iminfo.ts-1));                
        %     elseif iminfo.ts*iminfo.channels<lifinfo.numberoftimestamps
        %         %Find Average Duration between events;
        %         [~,a]=findpeaks(histcounts(tsd,iminfo.ts*iminfo.tiles));
        %         c=numel(tsd)/(iminfo.ts*iminfo.tiles);
        %         t=tsd(floor(a(end)*c))-tsd(floor(a(1)*c));
        %         iminfo.tres=seconds(t/numel(a));
        %     end
        % end
        
        %Positions
        if iminfo.tiles>1
            if isfield(lifinfo.Image,'Attachment')
                if numel(lifinfo.Image.Attachment)==1
                    if strcmp(lifinfo.Image.Attachment.Attributes.Name,'TileScanInfo')
                        xmlInfo = lifinfo.Image.Attachment;
                    end
                else
                    for i=1:numel(lifinfo.Image.Attachment)
                        if strcmp(lifinfo.Image.Attachment{i}.Attributes.Name,'TileScanInfo')
                            xmlInfo = lifinfo.Image.Attachment{i};
                            break;
                        end
                    end
                end
                for i=1:iminfo.tiles
                    iminfo.tile(i).num=i;
                    iminfo.tile(i).fieldx=str2double(xmlInfo.Tile{i}.Attributes.FieldX);
                    iminfo.tile(i).fieldy=str2double(xmlInfo.Tile{i}.Attributes.FieldY);
                    iminfo.tile(i).posx=str2double(xmlInfo.Tile{i}.Attributes.PosX);
                    iminfo.tile(i).posy=str2double(xmlInfo.Tile{i}.Attributes.PosY);
                end
                iminfo.tilex=struct;
                iminfo.tilex.xmin=min([iminfo.tile.posx]);
                iminfo.tilex.ymin=min([iminfo.tile.posy]);
                iminfo.tilex.xmax=max([iminfo.tile.posx]);
                iminfo.tilex.ymax=max([iminfo.tile.posy]);
            end
        end
        
        %Image ViewerScaling
        isfound=false;
        if isfield(lifinfo.Image,'Attachment')
            if numel(lifinfo.Image.Attachment)==1
                if strcmp(lifinfo.Image.Attachment.Attributes.Name,'ViewerScaling')
                    xmlInfo = lifinfo.Image.Attachment;
                    isfound=true;
                end
            else
                for i=1:numel(lifinfo.Image.Attachment)
                    if strcmp(lifinfo.Image.Attachment{i}.Attributes.Name,'ViewerScaling')
                        xmlInfo = lifinfo.Image.Attachment{i};
                        isfound=true;
                        break;
                    end
                end
            end
        end
        if isfound
            if iminfo.channels==1
                iminfo.blackvalue(1)=str2double(xmlInfo.ChannelScalingInfo.Attributes.BlackValue);
                iminfo.whitevalue(1)=str2double(xmlInfo.ChannelScalingInfo.Attributes.WhiteValue);
            else
                for i=1:iminfo.channels
                    iminfo.blackvalue(i)=str2double(xmlInfo.ChannelScalingInfo{i}.Attributes.BlackValue);
                    iminfo.whitevalue(i)=str2double(xmlInfo.ChannelScalingInfo{i}.Attributes.WhiteValue);
                end
            end
        else
            for i=1:iminfo.channels
                iminfo.blackvalue(i)=0;
                iminfo.whitevalue(i)=1;
            end
        end
        
        %Mic
        isfound=false;
        if isfield(lifinfo.Image,'Attachment')
            if numel(lifinfo.Image.Attachment)==1
                if strcmp(lifinfo.Image.Attachment.Attributes.Name,'HardwareSetting')
                    xmlInfo = lifinfo.Image.Attachment;
                    isfound=true;
                end
            else
                for i=1:numel(lifinfo.Image.Attachment)
                    if strcmp(lifinfo.Image.Attachment{i}.Attributes.Name,'HardwareSetting')
                        xmlInfo = lifinfo.Image.Attachment{i};
                        isfound=true;
                        break;
                    end
                end        
            end
        end 
        if isfound
            iminfo.magnification=str2double(cfStructSearch(xmlInfo,'Magnification'));
            iminfo.objective=cfStructSearch(xmlInfo,'Objective');
            iminfo.na=cfStructSearch(xmlInfo,'NumericalAperture');
        end
        
        %TileScan
        isfound=false;
        if isfield(lifinfo.Image,'Attachment')
            if numel(lifinfo.Image.Attachment)==1
                if strcmp(lifinfo.Image.Attachment.Attributes.Name,'TileScanInfo')
                    xmlInfo = lifinfo.Image.Attachment;
                    isfound=true;
                end
            else
                for i=1:numel(lifinfo.Image.Attachment)
                    if strcmp(lifinfo.Image.Attachment{i}.Attributes.Name,'TileScanInfo')
                        xmlInfo = lifinfo.Image.Attachment{i};
                        isfound=true;
                        break;
                    end
                end      
            end
        end 
        if isfound
            iminfo.flipx=str2double(cfStructSearch(xmlInfo,'FlipX'));
            iminfo.flipy=str2double(cfStructSearch(xmlInfo,'FlipY'));
            iminfo.swapxy=str2double(cfStructSearch(xmlInfo,'SwapXY'));
        end
        
        %Mic Type
        if isfield(lifinfo.Image,'Attachment')
            xmlInfo = lifinfo.Image.Attachment;
            for k = 1:numel(xmlInfo)
                if numel(xmlInfo)==1
                    xli=xmlInfo;
                else
                    xli=xmlInfo{k}; 
                end
                name=xli.Attributes.Name; 
                switch name
                    case 'HardwareSetting'
                        if strcmpi(xli.Attributes.DataSourceTypeName,'Confocal')
                            iminfo.mictype='IncohConfMicr';
                            iminfo.mictype2='confocal';
                            %Objective specs
                            thisInfo = xli.ATLConfocalSettingDefinition.Attributes;
                            iminfo.objective=thisInfo.ObjectiveName;  
                            iminfo.na=str2double(thisInfo.NumericalAperture);  
                            iminfo.refractiveindex=str2double(thisInfo.RefractionIndex');  
                            %Channel Excitation and Emission
                            if isfield(xli.ATLConfocalSettingDefinition,'Spectro')
                                thisInfo = xli.ATLConfocalSettingDefinition.Spectro;
                                for k1 = 1:numel(thisInfo.MultiBand)
                                    iminfo.emission(k1)= str2double(thisInfo.MultiBand{k1}.Attributes.LeftWorld)+(str2double(thisInfo.MultiBand{k1}.Attributes.RightWorld)-str2double(thisInfo.MultiBand{k1}.Attributes.LeftWorld))/2;
                                    iminfo.excitation(k1)= iminfo.emission(k1)-10;
                                end
                            end
                        elseif strcmpi(xli.Attributes.DataSourceTypeName,'Camera')
                            iminfo.mictype='IncohWFMicr';
                            iminfo.mictype2='widefield';
                        else
                            iminfo.mictype='unknown';
                            iminfo.mictype2='generic';
                        end
                        break;
                end
            end 
        else
            iminfo.mictype='unknown';
            iminfo.mictype2='generic';
        end
        %Widefield
        if strcmpi(iminfo.mictype,'IncohWFMicr')
            %Objective specs
            thisInfo = xli.ATLCameraSettingDefinition.Attributes;
            iminfo.objective=thisInfo.ObjectiveName;  
            iminfo.na=str2double(thisInfo.NumericalAperture);  
            iminfo.refractiveindex=str2double(thisInfo.RefractionIndex');  

            %Channel Excitation and Emission
            thisInfo = xli.ATLCameraSettingDefinition.WideFieldChannelConfigurator;
            for k = 1:numel(thisInfo.WideFieldChannelInfo)
                if numel(thisInfo.WideFieldChannelInfo)==1
                    FluoCubeName=thisInfo.WideFieldChannelInfo.Attributes.FluoCubeName;
                    ContrastMethodName=thisInfo.WideFieldChannelInfo.Attributes.ContrastingMethodName;
                else
                    FluoCubeName=thisInfo.WideFieldChannelInfo{k}.Attributes.FluoCubeName;            
                    ContrastMethodName=thisInfo.WideFieldChannelInfo{k}.Attributes.ContrastingMethodName;
                end
                iminfo.contrastmethod(k)=ContrastMethodName;
                if numel(thisInfo.WideFieldChannelInfo)==1
                    if strcmpi(FluoCubeName,'QUAD-S')
                        ExName=thisInfo.WideFieldChannelInfo.Attributes.FFW_Excitation1FilterName;
                        iminfo.filterblock(k)=[FluoCubeName ': ' ExName];
                    elseif strcmpi(FluoCubeName,'DA/FI/TX')
                        ExName=thisInfo.WideFieldChannelInfo.Attributes.LUT;
                        iminfo.filterblock(k)=[FluoCubeName ': ' ExName];
                    else
                        ExName=FluoCubeName;
                        iminfo.filterblock(k)=FluoCubeName;
                    end
                else
                    if strcmpi(FluoCubeName,'QUAD-S')
                        ExName=thisInfo.WideFieldChannelInfo{k}.Attributes.FFW_Excitation1FilterName;
                        iminfo.filterblock(k)=[FluoCubeName ': ' ExName];
                    elseif strcmpi(FluoCubeName,'DA/FI/TX')
                        ExName=thisInfo.WideFieldChannelInfo{k}.Attributes.LUT;
                        iminfo.filterblock(k)=[FluoCubeName ': ' ExName];
                    else
                        ExName=FluoCubeName;
                        iminfo.filterblock(k)=FluoCubeName;
                    end
                end
                if strcmpi(ExName,'DAPI') || strcmpi(ExName,'DAP') || strcmpi(ExName,'A') || strcmpi(ExName,'Blue')
                    iminfo.excitation(k)=355;
                    iminfo.emission(k)=460;
                end
                if strcmpi(ExName,'L5') || strcmpi(ExName,'I5') || strcmpi(ExName,'Green') || strcmpi(ExName,'FITC')
                    iminfo.excitation(k)=480;
                    iminfo.emission(k)=527;
                end
                if strcmpi(ExName,'N3') || strcmpi(ExName,'N2.1') || strcmpi(ExName,'TRITC')
                    iminfo.excitation(k)=545;
                    iminfo.emission(k)=605;
                end
                if strcmpi(ExName,'488')
                    iminfo.excitation(k)=488;
                    iminfo.emission(k)=525;
                end
                if strcmpi(ExName,'532')
                    iminfo.excitation(k)=532;
                    iminfo.emission(k)=550;
                end                
                if strcmpi(ExName,'642')
                    iminfo.excitation(k)=642;
                    iminfo.emission(k)=670;
                end                
                if strcmpi(ExName,'Red')
                    iminfo.excitation(k)=545;
                    iminfo.emission(k)=605;
                end
                if strcmpi(ExName,'Y3') || strcmpi(ExName,'I3')
                    iminfo.excitation(k)=545;
                    iminfo.emission(k)=605;
                end
                if strcmpi(ExName,'Y5') 
                    iminfo.excitation(k)=590;
                    iminfo.emission(k)=700;
                end
            end
        end
        
        if isfield(xli.Attributes,'SystemTypeName')
            if contains(xli.Attributes.SystemTypeName,'STELLARIS')
                chinfo=lifinfo.Image.ImageDescription.Channels(1).ChannelDescription;
                for ch=1:iminfo.channels
                    for cd=1:numel(chinfo{ch}.ChannelProperty)
                        if strcmpi(strtrim(chinfo{ch}.ChannelProperty{cd}.Key.Text),'DyeName')
                            iminfo.filterblock{ch}=strtrim(chinfo{ch}.ChannelProperty{cd}.Value.Text);
                            break;
                        end
                    end
                end
            end
        end

        if strcmpi(iminfo.filterblock(1), 'MICA_WF')
            % Parse the XML string
            stringReader = StringReader(lifinfo.xmlElement);
            inputSource = InputSource(stringReader);            
            xmlData = xmlread(inputSource);
        
            % Get all Structure elements
            structures = xmlData.getElementsByTagName('Structure');
        
            % Initialize a container for structure names and their corresponding LUT names
            structureData = containers.Map;
            structureLUTs = containers.Map('KeyType', 'char', 'ValueType', 'int32');
        
            % Loop through each Structure element to get the Name, LutName, EmissionWavelength, and ExcitationWavelength
            for i = 0:structures.getLength-1
                structure = structures.item(i);
        
                % Get the Name element
                nameElement = structure.getElementsByTagName('Name').item(0);
                structureName = char(nameElement.getTextContent());
        
                % Get the LutName element
                lutNameElement = structure.getElementsByTagName('LutName').item(0);
                lutName = char(lutNameElement.getTextContent());
        
                % Get the EmissionWavelength element
                emissionWavelengthElement = structure.getElementsByTagName('EmissionWavelength').item(0);
                emissionWavelength = char(emissionWavelengthElement.getTextContent());
        
                % Get the ExcitationWavelength element
                excitationWavelengthElement = structure.getElementsByTagName('ExcitationWavelength').item(0);
                excitationWavelength = char(excitationWavelengthElement.getTextContent());
        
                % Store the structure data
                structureData(lutName) = struct('Name', structureName, 'EmissionWavelength', emissionWavelength, 'ExcitationWavelength', excitationWavelength);
        
                if isKey(structureLUTs, lutName)
                    structureLUTs(lutName) = structureLUTs(lutName) + 1;
                else
                    structureLUTs(lutName) = 1;
                end
            end
        
            % Check if all LUT names are unique
            allUnique = true;
            lutNames = keys(structureLUTs);
            for i = 1:length(lutNames)
                if structureLUTs(lutNames{i}) > 1
                    allUnique = false;
                    break;
                end
            end
        
            % Get all ChannelDescription elements
            channels = xmlData.getElementsByTagName('ChannelDescription');
        
            % Loop through each ChannelDescription element
            for i = 0:channels.getLength-1
                channel = channels.item(i);
        
                % Get the LUTName attribute
                lutName = char(channel.getAttribute('LUTName'));
        
                % Check if all LUT names are unique
                if ~allUnique
                    % If not all LUT names are unique, set the numerical data to 0 and text data to ''
                    iminfo.excitation(i+1) = 0;
                    iminfo.emission(i+1) = 0;
                    iminfo.lutname{i+1} = '';
                    iminfo.filterblock{i+1} = '';
                else
                    % Find the corresponding structure data using the LUTName
                    if isKey(structureData, lutName)
                        structureInfo = structureData(lutName);
                        structureName = structureInfo.Name;
                        emissionWavelength = str2double(structureInfo.EmissionWavelength);
                        excitationWavelength = str2double(structureInfo.ExcitationWavelength);
                    else
                        structureName = 'Unknown';
                        emissionWavelength = 0;
                        excitationWavelength = 0;
                    end
        
                    % Store the extracted information
                    iminfo.excitation(i+1) = excitationWavelength;
                    iminfo.emission(i+1) = emissionWavelength;
                    iminfo.lutname{i+1} = lutName;
                    iminfo.filterblock{i+1} = structureName;
                end
            end
        end

        % Recalculate resolution to micrometer
        if strcmpi(iminfo.resunit,'meter') || strcmpi(iminfo.resunit,'m')
            iminfo.xres2=iminfo.xres*1000000;
            iminfo.yres2=iminfo.yres*1000000;
            iminfo.zres2=iminfo.zres*1000000;
        end
        if strcmpi(iminfo.resunit,'centimeter')
            iminfo.xres2=iminfo.xres*10000;
            iminfo.yres2=iminfo.yres*10000;
            iminfo.zres2=iminfo.zres*10000;
        end
        if strcmpi(iminfo.resunit,'inch')
            iminfo.xres2=iminfo.xres*25400;
            iminfo.yres2=iminfo.yres*25400;
            iminfo.zres2=iminfo.zres*25400;
        end
        if strcmpi(iminfo.resunit,'milimeter')
            iminfo.xres2=iminfo.xres*1000;
            iminfo.yres2=iminfo.yres*1000;
            iminfo.zres2=iminfo.zres*1000;
        end
        if strcmpi(iminfo.resunit,'micrometer')
            iminfo.xres2=iminfo.xres;
            iminfo.yres2=iminfo.yres;
            iminfo.zres2=iminfo.zres;
        end

        result=true;
    elseif strcmpi(lifinfo.datatype,'eventlist')
        iminfo.channels=1;
        iminfo.NumberOfEvents=str2double(lifinfo.GISTEventList.GISTEventListDescription.NumberOfEvents.Attributes.NumberOfEventsValue);
        iminfo.Threshold=str2double(lifinfo.GISTEventList.GISTEventListDescription.LocalizationParameters.Attributes.Threshold);
        iminfo.Gain=str2double(lifinfo.GISTEventList.GISTEventListDescription.LocalizationParameters.Attributes.Gain);
        iminfo.FieldOfViewX=str2double(lifinfo.GISTEventList.GISTEventListDescription.LocalizationParameters.Attributes.FieldOfViewX2);
        iminfo.FieldOfViewY=str2double(lifinfo.GISTEventList.GISTEventListDescription.LocalizationParameters.Attributes.FieldOfViewY2);
        serror='';  
        result=true;
    end
end
