function  outStruct  = SM_Xml2Struct(input)
%XML2STRUCT converts xml file into a MATLAB structure
%
% outStruct = xml2struct(input)
% 
% xml2struct2 takes either a java xml object, an xml file, or a string in
% xml format as input and returns a parsed xml tree in structure. 
% 
% Please note that the following characters are substituted
% '-' by '_dash_', ':' by '_colon_' and '.' by '_dot_'
%
% Written by J. Malina, 29-08-2022
% Adapted from function originally written by W. Falkena, ASTI, TUDelft, 21-08-2010
% Attribute parsing speed increase by 40% by A. Wanner, 14-6-2011
% Added CDATA support by I. Smirnov, 20-3-2012
% Modified by X. Mo, University of Wisconsin, 12-5-2012
% Modified by Chao-Yuan Yeh, August 2016

errorMsg = ['%s is not in a supported format.\n\nInput has to be',...
        ' a java xml object, an xml file, or a string in xml format.'];

% check if input is a java xml object
if isa(input, 'org.apache.xerces.dom.DeferredDocumentImpl') ||...
        isa(input, 'org.apache.xerces.dom.DeferredElementImpl')
    xDoc = input;
else
    try 
        if exist(input, 'file') == 2
            xDoc = xmlread(input);
        else
            try
                xDoc = xmlFromString(input);
            catch
                error(errorMsg, inputname(1));
            end
        end
    catch ME
        if strcmp(ME.identifier, 'MATLAB:UndefinedFunction')
            error(errorMsg, inputname(1));
        else
            rethrow(ME)
        end
    end
end

% parse xDoc into a MATLAB structure
outStruct = parseChildNodes(xDoc);
    
end

% ----- Local function parseChildNodes -----
function [children, ptext, textflag] = parseChildNodes(theNode)
% Recurse over node children.
children = struct;
ptext = struct; 
textflag = 'Text';

if hasChildNodes(theNode)
    mSubrName = 'parseChildNodes';
    childNodes = getChildNodes(theNode);
    numChildNodes = getLength(childNodes);
    for count = 1:numChildNodes
        theChild = item(childNodes,count-1);
        if(theChild.getNodeType()~=1)
            continue;
        end
        [text, name, attr, childs, textflag] = getNodeData(theChild);
        if strcmp(textflag,'SuccCell')
            % XML allows the same elements to be defined multiple times,
            % put each in a different cell
            if (isfield(children,name))
                if (~iscell(children.(name)))
                    % put existsing element into cell format
                    children.(name) = {children.(name)};
                end
                index = length(children.(name))+1;
                % add new element
                children.(name){index} = childs;
            else
                % add previously unknown (new) element to the structure
                children.(name) = childs;
            end
            continue
        end % if tfProcess
        if ~strcmp(name,'#text') && ~strcmp(name,'#comment') && ...
                ~strcmp(name,'#cdata_dash_section')
            % add text data ( ptext returned by child node )
            textfields = fieldnames(text);
            nTxtFields = 0; tfVals = false;
            if ~isempty(textfields)
                nTxtFields = length(textfields);
                if ~isempty(attr)
                    cAttrNames = {attr.Name};
                    [Lia,Locb]=ismember({'ItemType','Size'},cAttrNames);
                    if Lia(2)
                        [esiz,tf] = str2num(attr(Locb(2)).Value);
                        if ~tf
                            error('SM_Xml2Struct:parseChildNodes:Errors', 'Invalid Size Attribute Value!')
                        end
                    else
                        esiz = [1 1];
                    end
                    if Lia(1)&&ischar(attr(Locb(1)).Value)
                        switch(attr(Locb(1)).Value)
                            case {'double','single'}
                                categ = 'Numeric';
                            case 'logical'
                                categ = 'logical';
                            case 'datetime'
                                categ = 'DTime';
                            case 'OnOffSwitchState'
                                categ = 'OnOffSwStat';
                            case {'char'}
                                categ = 'Other'; % 'Char';
                            otherwise
                                categ = 'Other';
                        end % switch(cName)
                        if ~strcmp(categ,'Other')
                            [stat,datVals,classtyp] = deal(cell(1,nTxtFields));
                            for ii = 1:nTxtFields
                                switch(categ)
                                    case 'Numeric'
                                        [stat{ii},datVals{ii},classtyp{ii}] = parseNumeric(text.(textfields{ii}),'double');
                                    case {'logical','OnOffSwStat'}
                                        [stat{ii},datVals{ii},classtyp{ii}] = parseLogical(text.(textfields{ii}),categ,esiz);
                                    case 'DTime'
                                        [stat{ii},datVals{ii},classtyp{ii}] = parseDTime(text.(textfields{ii}),'datetime');
                                    case {'char'}
                                        
                                end % switch(categ)
                            end % for ii = 1:nTxtFields
                            tfVals = all(cell2mat(stat)==0);
                        end % if ~strcmp(categ,'Other')
                    end % if Lia(1)&& ...
                end % if ~isempty(attr) && ...
            end % if ~isempty(textfields)
            
            % XML allows the same elements to be defined multiple times,
            % put each in a different cell
            if (isfield(children,name))
                if (~iscell(children.(name)))
                    % put existsing element into cell format
                    children.(name) = {children.(name)};
                end
                index = length(children.(name))+1;
                % add new element
                if tfVals
                    if numel(tfVals)==1
                        children.(name){index} = datVals{1};
                    else
                        children.(name){index} = datVals;
                    end
                elseif isempty(fieldnames(childs)) && nTxtFields==1 ...
                        && strcmp(textfields{1},'Text') % char
                    if strcmp(text.(textfields{1}),'struct with no fields.')
                        children.(name){index} = struct;
                    else
                        children.(name){index} = text.(textfields{1});
                    end
                else
                    children.(name){index} = childs;
                    for ii = 1:nTxtFields
                        children.(name){index}.(textfields{ii}) = ...
                            text.(textfields{ii});
                    end % for ii = 1:nTxtFields
                    if ~isempty(attr)
                        children.(name){index}.Attributes = attr;
                        if nTxtFields>1
                            stat = 2;
                            warnMsg = '#%i: Node %s.%s{%u} has data of unsupported type!\n\tAttribute: %s=<''%s''>';
                            cStr = struct2cell(attr);
                            warning(['Xml2Struct:',mSubrName,':Warnings'], warnMsg, stat,theNode.getNodeName,name,index,cStr{1:2});
                        end
                    end
                end
            else
                % add previously unknown (new) element to the structure
                if tfVals
                    if numel(tfVals)==1
                        children.(name) = datVals{1};
                    else
                        children.(name) = datVals;
                    end
                elseif isempty(fieldnames(childs)) && nTxtFields==1 ...
                        && strcmp(textfields{1},'Text') % char
                    if strcmp(text.(textfields{1}),'struct with no fields.')
                        children.(name) = struct;
                    else
                        children.(name) = text.(textfields{1});
                    end
                else
                    children.(name) = childs;
                    for ii = 1:nTxtFields
                        children.(name).(textfields{ii}) = text.(textfields{ii});
                    end
                    if ~isempty(attr)
                        children.(name).Attributes = attr;
                        if nTxtFields>1
                            stat = 3;
                            warnMsg = '#%i: Node %s.%s has data of unsupported type!\n\tAttribute: %s=<''%s''>';
                            cStr = struct2cell(attr);
                            warning(['Xml2Struct:',mSubrName,':Warnings'], warnMsg, stat,theNode.getNodeName,name,cStr{1:2});
                        end
                    end
                end % if tfVals
            end
        else
            ptextflag = 'Text';
            if (strcmp(name, '#cdata_dash_section'))
                ptextflag = 'CDATA';
            elseif (strcmp(name, '#comment'))
                ptextflag = 'Comment';
            end

            % this is the text in an element (i.e., the parentNode) 
            if (~isempty(regexprep(text.(textflag),'[\s]*','')))
                if (~isfield(ptext,ptextflag) || isempty(ptext.(ptextflag)))
                    ptext.(ptextflag) = text.(textflag);
                else
                    % This is what happens when document is like this:
                    % <element>Text <!--Comment--> More text</element>
                    %
                    % text will be appended to existing ptext
                    ptext.(ptextflag) = [ptext.(ptextflag) text.(textflag)];
                end
            end
        end
    end
end
end

% ----- Local function getCellNodeData -----
function [childs,ccNodName,ccItemTyp,succflag] = getCellNodeData(theNode,Siz)
% Get Cell Node data
%make sure name is allowed as structure name
hcNumrParse = @(dt,tp) cellfun(@parseNumeric, dt, tp, 'UniformOutput',false);
hcLogcParse = @(dt,tp,sz) cellfun(@parseLogical, dt, tp, sz, 'UniformOutput', false);
childs = struct; ccItemTyp = [];

% Create cell of node info.
nElem = prod(Siz);
[clData,ccNodName,cSiz] = deal(cell(Siz));
if nElem==0
    succflag = true;
    childs = clData;
    return
end
elem = theNode.getFirstChild();
for it0 = 1:nElem
    while(elem.getNodeType()~=1)
        elem = elem.getNextSibling();
    end
    if ~isempty(elem)
        attr = parseAttributes(elem);
        if ~isempty(fieldnames(attr))
            cNames = {attr.Name};
            [Lia,Locb]=ismember({'ItemType','Size'},cNames);
            if Lia(2)
                [cSiz{it0},tf] = str2num(attr(Locb(2)).Value);
                if ~tf
                    error('SM_Xml2Struct:getNodeData:Errors', 'Invalid Size Attribute Value!')
                end
            end
        else
            cSiz{it0} = 1;
        end
        ccNodName{it0} = char(elem.getNodeName());
        if strcmp(ccNodName{it0},'struct')
            clData{it0} = elem;
        else
            clData{it0} = char(elem.getTextContent());
        end
    end
    elem = elem.getNextSibling();
end % for it0 = 1:nElem

succflag = false;
if it0==nElem
    [Lia,Locb] = ismember(ccNodName{1},{'char';'double';'logical';'struct'});
    if  Lia && all(strcmp(ccNodName{1},ccNodName))
        if Locb>1
            if Locb>3 % struct
                %parse child nodes
                %all(strcmp(ccNodName,'struct'))
                [cstProcess, clData, ccItemTyp] = cellfun(@parseCStruct, clData,ccNodName, 'UniformOutput',false);
            elseif Locb>2 % logical
                [cstProcess,clData,ccItemTyp] = hcLogcParse(clData,ccNodName,cSiz);
            else % Numeric
                [cstProcess,clData,ccItemTyp] = hcNumrParse(clData,ccNodName);
            end
        else % char
            ccItemTyp  = repmat({'char'},Siz); 
            cstProcess = repmat({0},Siz);
        end
        if all(cell2mat(cstProcess)==0)
            succflag = true;
            childs = clData;
        end
%    else
        % JM 31/5/22
        % Currently if the cell node isn`t homogeneous array, Process returns to
        % to original SubR:parseChildNodes() and continues as previously (tfProcess=.F.)! 
    end
end
end

% ----- Local function getNodeData -----
function [text,name,attr,childs,textflag] = getNodeData(theNode)
% Create structure of node info.
sz = 1;
%make sure name is allowed as structure name
name = char(getNodeName(theNode));
% name = replace(name,{'-';':';'.';'_'},{'_dash_';'_colon_';'_dot_';'u_'});
name = replace(name,{'-';':';'.'},{'_dash_';'_colon_';'_dot_'});

attr = parseAttributes(theNode);
if (isempty(fieldnames(attr))) 
    attr = []; 
else
    cNames = {attr.Name};
    [Lia,Locb]=ismember({'ClasType','Size'},cNames);
    if Lia(2)
        [sz,tf] = str2num(attr(Locb(2)).Value);
        if ~tf
            error('SM_Xml2Struct:getNodeData:Errors', 'Invalid Size Attribute Value!')
        end
    end
    if Lia(1)&&strcmp(attr(Locb(1)).Value,'Cell')
        % Cell Element
        [childs,ccNodName,ccItemTyp,succflag] = getCellNodeData(theNode,sz);
        if succflag && numel(ccItemTyp)==prod(sz)
            textflag = 'SuccCell';
            text = ccNodName;
            return
        end % if all(cell2mat(cstProcess)==0)
    end % if Lia(1)&&
end

%parse child nodes
[childs, text, textflag] = parseChildNodes(theNode);

% Get data from any childless nodes. This version is faster than below.
if isempty(fieldnames(childs)) && isempty(fieldnames(text))
    text.(textflag) = char(getTextContent(theNode));
end

% This alterative to the above 'if' block will also work but very slowly.
% if any(strcmp(methods(theNode),'getData'))
%   text.(textflag) = char(getData(theNode));
% end
    
end

% ----- Local function parseAttributes -----
function attributes = parseAttributes(theNode)
% Create attributes structure.
attributes = struct;
if hasAttributes(theNode)
    theAttributes = getAttributes(theNode);
    numAttributes = getLength(theAttributes);
    
    %    for count = 1:numAttributes
    %        % Suggestion of Adrian Wanner
    %        str = char(toString(item(theAttributes,count-1)));
    %        k = strfind(str,'=');
    %        attr_name = str(1:(k(1)-1));
    %        attr_name = replace(attr_name,{'-';':';'.'},{'_dash_';'_colon_';'_dot_'});
    %        attributes.(attr_name) = str((k(1)+2):(end-1));
    %    end
    allocCell = cell(1, numAttributes);
    attributes = struct('Name', allocCell, 'Value', allocCell);
    for count = 1:numAttributes
        attrib = theAttributes.item(count-1);
        attributes(count).Name = char(attrib.getName);
        attributes(count).Value = char(attrib.getValue);
    end
end
end

% ----- Subfunction parseCStruct -----
function [stat, stDdat, classtyp] = parseCStruct(theNode,type)
% Struct Sub-element
stat = -1;
mSubrName = 'parseCStruct';
stDdat = [];
inpNam2 = inputname(2);
if strcmp(inpNam2,'clData')
    inpNam1 = inpNam2;
    inpNam2 = inputname(3); 
else
    inpNam1 = inputname(1); 
end
if isempty(inpNam1)
    inpNam1 = 'XmlNodInput1';
end
if isempty(inpNam2)
    inpNam2 = 'ArgTyp2';
end
try
    switch(type)
        case 'struct'
            classtyp = type;
            [stDdat, stText, stTextflag] = parseChildNodes(theNode);
            if ~isstruct(stDdat)
                stat =-3;
                errorMsg = ['#%1$i: Rtruct Cast of %2$s = <%4$s>:\n', ...
                    ' Parsing Xml Input to <%5$s> values Failed!'];
                error(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,theNode.getNodeName,type);
            end
            
            % Get data from any childless nodes. This version is faster than below.
            if isempty(fieldnames(stDdat)) && isempty(fieldnames(stText))
                txt = char(getTextContent(theNode));
                if (~isempty(regexp(txt,'\S','once'))) 
                    stText.(stTextflag) = txt;
                end
            end
            textfields = fieldnames(stText);
            if ~isempty(textfields)
                stat = 3;
                warnMsg = sprintf('#%1$i: Unexpected behavior in Parsing Xml Input %2$s <%4$s>.', ...
                    stat,inpNam1,inpNam2,theNode.getNodeName,type);
                warning(['Xml2Struct:',mSubrName,':Warnings'], '%s\n stText =\n  struct with fields:', warnMsg);
                disp(structfun(@(x) x, stText, 'UniformOutput', false))                
            end
            
        otherwise
            stat = 2;
            warnMsg = '#%1$i: %3$s = <%5$s> is not Struct.\n Cell Input has Mixed class Types.';
            warning(['Xml2Struct:',mSubrName,':Warnings'], warnMsg, stat,inpNam1,inpNam2,theNode.getNodeName,type);
    end % switch(cName)
catch ME
    if strcmp(ME.identifier, ['Xml2Struct:',mSubrName,':Errors'])
        stat = -stat;
        warning(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,theNode.getNodeName,type);
    else
        rethrow(ME)
    end
end % try
if(stat==-1),stat=0;end
end

% ----- Subfunction parseLogical -----
function [stat,lgData,classtyp] = parseLogical(chDat,type,sz)
% Logical Sub-element
stat = -1;
mSubrName = 'parseLogical';
inpNam2 = inputname(2);
if strcmp(inpNam2,'dt')
    inpNam1 = inpNam2;
    inpNam2 = inputname(3); 
else
    inpNam1 = inputname(1); 
    inpNam2 = inputname(2); 
end
if isempty(inpNam1)
    inpNam1 = 'XmlTxtInput1';
end
if isempty(inpNam2)
    inpNam2 = 'ItemTyp2';
end
if nargin>2, esiz=prod(sz); else, esiz=1; end
try
    switch(type)
        case 'logical'
            classtyp = type;
            % curElement.setAttribute('ClassType','logical');
            if esiz>1
                % chDatmp = regexprep(chDat,{'((?<=^)\[|\](?=$))','\n','\s'},{'',';',','});
                % Replacing {'\n','\s'} with {';',','} Not neccessary.
                chDatmp = regexprep(chDat,{'((?<=^)\[|\](?=$))'},{''});
                chDatmp = ['[',chDatmp,']'];
            else
                chDatmp = chDat;
            end
            [lgData,tf] = str2num(['[',chDatmp,']']);
            if ~tf
                stat =-3;
                errorMsg = ['#%1$i: Logical Cast of %2$s = <%4$s>:\n', ...
                    ' Parsing Xml Input to <%5$s> values Failed!'];
                error(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
            end
        case 'OnOffSwStat'
            classtyp = 'matlab.lang.OnOffSwitchState';
            % curElement.setAttribute('ClassType','logical');
            if esiz>1
                % chDatmp = regexprep(chDat,{'((?<=^)\[|\](?=$))','\n','\s'},{'',';',','});
                % Replacing {'\n','\s'} with {';',','} Not neccessary.
                chDatmp = regexprep(chDat,{'((?<=^)\[|\](?=$))'},{''});
                chDatmp = ['{',chDatmp,'}'];
            else
                chDatmp = chDat;
            end
            lgData = eval([classtyp,'(',chDatmp,')']);
            if ~isa(lgData,classtyp)
                stat =-4;
                errorMsg = ['#%1$i: OnOffSwitchState enumeration Cast of %2$s = <%4$s>:\n', ...
                    ' Parsing Xml Input to <%5$s> values Failed!'];
                error(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,classtyp);
            end
        otherwise
            stat =-2;
            errorMsg = [' # %i: %s = <%s> is not supported type.\n\nInput has to be',...
                ' a logical type: ''true''\\''false''.'];
            error(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
    end % switch(cName)
catch ME
    if strcmp(ME.identifier, ['Xml2Struct:',mSubrName,':Errors'])
        stat = -stat;
        warning(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
    else
        rethrow(ME)
    end
end % try
if(stat==-1),stat=0;end
end

% ----- Subfunction parseNumeric -----
function [stat,datVals,classtyp] = parseNumeric(chDat,type)
% Numeric Sub-element
stat = -1;
mSubrName = 'parseNumeric';
inpNam2 = inputname(2);
if strcmp(inpNam2,'dt')
    inpNam1 = inpNam2;
    inpNam2 = inputname(3); 
else
    inpNam1 = inputname(1); 
    inpNam2 = inputname(2); 
end
if isempty(inpNam1)
    inpNam1 = 'XmlTxtInput1';
end
if isempty(inpNam2)
    inpNam2 = 'ItemTyp2';
end
try
    switch(type)
        case 'double'
            classtyp = type;
            % dataValues = str2num(clData); %#ok<ST2NM>
            % OR
            datVals = str2double(split(splitlines(chDat)));
            % OR
            % % Following lines are redundant when using str2num. JM 24/5/22 <<<
            % if ~isempty(regexp(clData,'(\[|\]|\;|\n)', 'once'))
            %     % Txt = regexprep(Txt,{'\[','(;|\])'},{'','\n'});
            %     clData = regexprep(clData,{'(\[|\])',';',','},{'','\n',' '});
            %     [C,matches] = strsplit(clData,{' ',newline},'CollapseDelimiters',true);
            %     nlines = sum(strcmp(matches,newline))+1;
            % else
            %     C = strsplit(clData,' ','CollapseDelimiters',true);
            %     nlines = 1;
            % end
            % dataValues = reshape(str2double(C),nlines,[]);
            % % JM 24/5/22 >>>
            if any(isnan(datVals))
                if isscalar(datVals)&&ischar(chDat)&&strcmp(chDat,'[]')
                    datVals = [];
                else
                    stat =-3;
                    errorMsg = ['#%1$i: Numeric Cast of %2$s = <%4$s>:\n', ...
                        ' Parsing Xml Input to <%5$s> values Failed!'];
                    error(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
                end
            end
        case {'uint','single'}
            classtyp = type;
            datVals = str2num(chDat); %#ok<ST2NM>
            if isnan(datVals)
                stat =-4;
                errorMsg = ['#%1$i: Numeric Cast of %2$s = <%4$s>:\n', ...
                    ' Parsing Xml Input to <%5$s> values Failed!'];
                error(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
            end
        otherwise
            stat =-2;
            errorMsg = ['#%1$i: %3$s = <%5$s> is not supported type.\n\nInput has to be',...
                ' a numeric type: ''double''\\''single''.'];
            error(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
    end % switch(cName)
catch ME
    if strcmp(ME.identifier, ['Xml2Struct:',mSubrName,':Errors'])
        stat = -stat;
        warning(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
    else
        rethrow(ME)
    end
end % try
if(stat==-1),stat=0;end
end

% ----- Subfunction parseDTime -----
function [stat,datVals,classtyp] = parseDTime(chDat,type)
% Numeric Sub-element
stat = -1;
mSubrName = 'parseDTime';
inpNam2 = inputname(2);
if strcmp(inpNam2,'dt')
    inpNam1 = inpNam2;
    inpNam2 = inputname(3); 
else
    inpNam1 = inputname(1); 
    inpNam2 = inputname(2); 
end
if isempty(inpNam1)
    inpNam1 = 'XmlTxtInput1';
end
if isempty(inpNam2)
    inpNam2 = 'ItemTyp2';
end
try
    switch(type)
        case 'datetime'
            classtyp = type;
            % datVals = datenum(chDat,'dd-mm-yyyy HH:MM:SS.FFF');
            datVals = NaN;
            if ~isempty(chDat) && ischar(chDat)
                datN = datenum(chDat);
                datst = datestr(datN,'dd-mmm-yyyy HH:MM:SS.FFF');
                datt = datetime(datst,'TimeZone','Asia/Jerusalem','InputFormat','dd-MMM-yyyy HH:mm:ss.SSS');
                if ~isnat(datt) && isdatetime(datt)
                    datVals = datenum(datt);
                end
            end % if ~isempty(chDat) && ...
            if isnan(datVals)
                stat =-3;
                errorMsg = ['#%1$i: Converting date and time %2$s =\n', ...
                            '    ''%4$s''\n  to <%5$s> serial date number Value Failed!'];
                error(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
            end
        case {'double'}
            classtyp = type;
            %test = datetime(chDat,'TimeZone','local','Format','d-MMM-y HH:mm:ss Z');
            %isdatetime(test)
            datVals = NaN;
            if ~isempty(chDat) && isnan(chDat)
                datst = datestr(chDat,'dd-mm-yyyy HH:MM:SS.FFF');
                datt = datetime(datst,'TimeZone','Asia/Jerusalem','InputFormat','dd-MM-yyyy HH:mm:ss.SSS');
                if ~isnat(datt) && isdatetime(datt)
                    datVals = datenum(datt);
                end
            end % if ~isempty(chDat) && ...
            if isnan(datVals)
                stat =-4;
                errorMsg = ['#%1$i: Numeric Cast of %2$s = <%4$s>:\n', ...
                    ' Parsing Xml Input to <%5$s> values Failed!'];
                error(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
            end
        otherwise
            stat =-2;
            errorMsg = ['#%1$i: %3$s = <%5$s> is not supported type.\n\nInput has to be ',...
                'type: ''datetime'' Or ''datenum''.'];
            error(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
    end % switch(cName)
catch ME
    if strcmp(ME.identifier, ['Xml2Struct:',mSubrName,':Errors'])
        stat = -stat;
        warning(['Xml2Struct:',mSubrName,':Errors'], errorMsg, stat,inpNam1,inpNam2,chDat,type);
    else
        rethrow(ME)
    end
end % try
if(stat==-1),stat=0;end
end

% ----- Local function xmlFromString -----
function xmlroot = xmlFromString(iString)
import org.xml.sax.InputSource
import java.io.*

iSource = InputSource();
iSource.setCharacterStream(StringReader(iString));
xmlroot = xmlread(iSource);
end