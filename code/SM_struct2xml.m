function varargout = SM_struct2xml( s, varargin )
%Convert a MATLAB structure into a xml file 
% [ ] = struct2xml( s, file )
% xml = struct2xml( s )
%
% A structure containing:
% s.XMLname.Attributes.attrib1 = "Some value";
% s.XMLname.Element.Text = "Some text";
% s.XMLname.DifferentElement{1}.Attributes.attrib2 = "2";
% s.XMLname.DifferentElement{1}.Text = "Some more text";
% s.XMLname.DifferentElement{2}.Attributes.attrib3 = "2";
% s.XMLname.DifferentElement{2}.Attributes.attrib4 = "1";
% s.XMLname.DifferentElement{2}.Text = "Even more text";
%
% Will produce:
% <XMLname attrib1="Some value">
%   <Element>Some text</Element>
%   <DifferentElement attrib2="2">Some more text</Element>
%   <DifferentElement attrib3="2" attrib4="1">Even more text</DifferentElement>
% </XMLname>
%
% Please note that the following strings are substituted
% '_dash_' by '-', '_colon_' by ':' and '_dot_' by '.'
%
% Written by J. Malina, 29-08-2022
% Adapted from function originally written by W. Falkena, ASTI, TUDelft, 27-08-2010
% On-screen output functionality added by P. Orth, 01-12-2010
% Multiple space to single space conversion adapted for speed by T. Lohuis, 11-04-2011
% Val2str subfunction bugfix by H. Gsenger, 19-9-2011
% Modified by Chao-Yuan Yeh, 2016
    
    if (nargin ~= 2)
        if(nargout ~= 1 || nargin ~= 1)
            error(['Supported function calls:' newline...
                   '[ ] = struct2xml( s, file )' newline...
                   'xml = struct2xml( s )']);
        end
    end

    if(nargin == 2)
        file = varargin{1};

        if (isempty(file))
            error('Filename can not be empty');
        end

        if (~contains(file,'.xml'))
            file = [file '.xml'];
        end
    end
    
    if (~isstruct(s))
        error([inputname(1) ' is not a structure']);
    else
        xmlname = fieldnames(s);
        if (length(xmlname) > 1)
            error(['Error processing the structure:' newline 'There should be a single field in the main structure.']);
        end
    end
    xmlname = xmlname{1};
    
    %substitute special characters
    xmlname_sc = replace(xmlname,{'_dash_';'_colon_';'_dot_';},{'-';':';'.'});

    %create xml structure
    docNode = com.mathworks.xml.XMLUtils.createDocument(xmlname_sc);

    %process the rootnode
    docRootNode = docNode.getDocumentElement;

    %append childs
    parseStruct(s.(xmlname),docNode,docRootNode,[inputname(1) '.' xmlname '.']);

    if(nargout == 0)
        %save xml file
        xmlwrite(file,docNode);
    else
        varargout{1} = xmlwrite(docNode);
    end  
end

% ----- Subfunction parseStruct -----
function [] = parseStruct(s,docNode,curNode,pName)
    
    fnames = fieldnames(s);
    nFnames = length(fnames);
    if nFnames
        for i = 1:nFnames
            curfield = fnames{i};
            
            %substitute special characters
            curfield_sc = replace(curfield,{'_dash_';'_colon_';'_dot_';},{'-';':';'.'});
            if (strcmp(curfield,'Attributes'))
                %Attribute data
                if (isstruct(s.(curfield)))
                    attr_names = fieldnames(s.Attributes);
                    for a = 1:length(attr_names)
                        cur_attr = attr_names{a};
                        
                        %substitute special characters
                        cur_attr_sc = replace(cur_attr,{'_dash_';'_colon_';'_dot_';},{'-';':';'.'});
                        
                        [cur_str,succes] = val2str(s.Attributes.(cur_attr));
                        if (succes)
                            curNode.setAttribute(cur_attr_sc,cur_str);
                        else
                            disp(['Warning. The text in ' pName curfield '.' cur_attr ' could not be processed.']);
                        end
                    end
                else
                    disp(['Warning. The attributes in ' pName curfield ' could not be processed.']);
                    disp(['The correct syntax is: ' pName curfield '.attribute_name = ''Some text''.']);
                end
                %         elseif (strcmp(curfield,'Text'))
                %             %Text data
                %             [txt,succes] = val2str(s.Text);
                %             if (succes)
                %                 curNode.appendChild(docNode.createTextNode(txt));
                %             else
                %                 disp(['Warning. The text in ' pName curfield ' could not be processed.']);
                %             end
            elseif isstruct(s.(curfield))
                %single Sub-element
                curElement = docNode.createElement(curfield_sc);
                curNode.appendChild(curElement);
                parseStruct(s.(curfield),docNode,curElement,[pName curfield '.'])
            elseif iscell(s.(curfield))
                %cell Sub-element
                curElement = docNode.createElement(curfield_sc);
                curNode.appendChild(curElement);
                parseCell(s.(curfield),docNode,curElement,[pName curfield '.'])
            elseif islogical(s.(curfield))
                % Logical Sub-element
                dataValues = s.(curfield);
                parseLogical(dataValues,docNode,curNode,curfield_sc,class(dataValues));
                
            elseif isnumeric(s.(curfield))
                % Numeric Sub-element
                dataValues = s.(curfield);
                parseNumeric(dataValues,docNode,curNode,curfield_sc,class(dataValues));
                
            elseif isdatetime(s.(curfield))
                % DateTime Txt Sub-element
                curElement = docNode.createElement(curfield_sc);
                curNode.appendChild(curElement);
                cls = class(s.(curfield)); nodeName = curfield_sc;
                if ~strcmp(cls,nodeName)
                    curElement.setAttribute('ItemType',cls);
                end
                dts = datestr(s.(curfield),'dd-mmm-yyyy HH:MM:SS.FFF');
                curElement.appendChild(docNode.createTextNode(dts));
            else
                %eventhough the fieldname is not text, the field could
                %contain text. Create a new element and use this text
                curElement = docNode.createElement(curfield_sc);
                curNode.appendChild(curElement);
                [txt,succes] = val2str(s.(curfield));
                if (succes)
                    curElement.appendChild(docNode.createTextNode(txt));
                else
                    disp(['Warning. The text in ' pName curfield ' could not be processed.']);
                end
            end
        end % for i = 1:nFnames
    else
        curNode.appendChild(docNode.createTextNode("struct with no fields."));
    end % if nFnames
end

% ----- Subfunction parseCell -----
function [] = parseCell(s,docNode,curNode,pName)

% curfield_sc - special characters - allowed in NodeName
%      char ASCII: 33 - 35  37 -      42 44 - 47 58 59 63 64 91 - 93 95 123 125
%    Punct chars   !  "  #  % & ' ( ) *  , - . / :  ;  ?  @  [  \ ]  _  {   }                    dash dot colon   58,46) - :'-', colon:';', dot:'.'
%  Allowed          dash,dot,colon,us     45 46  58                  95
%  Not Allowed           +        + +                  +     +    +     +   +
%  Probably not    +  +     + + +     +  +     +    +     +     +                 
curfield = curNode.getNodeName;
%substitute special characters - allowed in NodeName
curfield_sc = replace(char(curfield),{'_dash_';'_colon_';'_dot_';},{'-';':';'.'});
sz = size(s);
len = prod(sz);
if len>0
    curNode.setAttribute('ClasType','Cell');
    cls = class(s{1});
    clsArr = cellfun(@class,s,'UniformOutput',false);
    if len>1
        %[siz_str,succes] = val2str(sz);
        siz_str = num2str(sz);
        curNode.setAttribute('Size',siz_str);
    end
    if all(strcmp(cls,clsArr))
        % Array  Sub-element
        curCellitem = cls;
    else
        % Cell  Sub-element
        curNode.setAttribute('ItemType','Mixed');
    end
    
    for c = 1:length(s)
        if curNode.hasAttribute('ItemType') && strcmp(curNode.getAttribute('ItemType'),'Mixed')
            curCellitem = [curfield_sc '_' num2str(c)];
        end
        if isstruct(s{c})
            % struct Sub-element
            curElement = docNode.createElement(curCellitem);
            curNode.appendChild(curElement);
            parseStruct(s{c}, docNode,curElement,[pName '{' num2str(c) '}.'])
        elseif iscell(s{c})
            % cell Sub-element
            curElement = docNode.createElement(curCellitem);
            curNode.appendChild(curElement);
            parseCell(s{c},docNode,curElement,[pName curfield '{' num2str(c) '}.'])
        else
            if islogical(s{c})
                % Logical Sub-element
                dataValues = s{c};
                %dataValues = logical([0 0 1;1 0 1;0 1 1]);
                parseLogical(dataValues,docNode,curNode,curCellitem,cls)

            elseif isnumeric(s{c})
                % Numeric Sub-element
                dataValues = s{c};
                parseNumeric(dataValues,docNode,curNode,curCellitem,cls);

            elseif ischar(s{c})
                curElement = docNode.createElement(curCellitem);
                curNode.appendChild(curElement);
                curElement.appendChild(docNode.createTextNode(s{c}));
            else
                % curNode.removeChild(curElement);
                disp(['Warning. The text in ' pName curfield '.{' num2str(c) '} could not be processed!']);
            end
        end % if isstruct(s{c})
    end % for c = 1:length(s)
else
    curNode.setAttribute('ClasType','Cell');
    curNode.setAttribute('Size','0');
    disp(['Warning. ' pName(1:end-1) ' is empty!']);
end % if len>0
end

% ----- Subfunction parseLogical -----
function [] = parseLogical(dataValues,docNode,curNode,nodeName,cls)
% Logical Sub-element
curElement = docNode.createElement(nodeName);
curNode.appendChild(curElement);
if numel(dataValues)>1
    %[siz_str,succes] = val2str(sz);
    siz_str = num2str(size(dataValues));
    curElement.setAttribute('Size',siz_str);
end
if ~strcmp(cls,nodeName)
    switch cls
        case 'matlab.lang.OnOffSwitchState'
            cls = 'OnOffSwitchState';
            dataValues = logical(dataValues);
    end % switch cls
    curElement.setAttribute('ItemType',cls);
end
Txt = mat2str(dataValues);
% Following lines are redundant. JM 24/5/22 <<<
if numel(dataValues)>1
    Txt = regexprep(Txt,{'(\[|\])',';'},{'','\n'});
    Txt = regexprep(Txt,'true','true ');
end
% JM 24/5/22 >>>
if  strcmp(cls,'OnOffSwitchState')
    Txt = regexprep(Txt,{'false','true'},{'''off''','''on'''});
end
curElement.appendChild(docNode.createTextNode(Txt));
end

% ----- Subfunction parseNumeric -----
function [] = parseNumeric(dataValues,docNode,curNode,nodeName,cls)
% Numeric Sub-element
curElement = docNode.createElement(nodeName);
curNode.appendChild(curElement);
if numel(dataValues)>1
    siz_str = num2str(size(dataValues));
    curElement.setAttribute('Size',siz_str);
end
if ~strcmp(cls,nodeName)
    curElement.setAttribute('ItemType',cls);
end
Txt = mat2str(dataValues);
% Following lines are redundant. JM 24/5/22 <<<
if numel(dataValues)>1
    Txt = regexprep(Txt,{'(\[|\])',';'},{'','\n'});
    % Txt = regexprep(Txt,{'\[','(;|\])'},{'','\n'});
end
% JM 24/5/22 >>>
curElement.appendChild(docNode.createTextNode(Txt));
end

%----- Subfunction val2str -----
function [str,succes] = val2str(val)
    
    succes = true;
    str = '';
    
    if (isempty(val))
        return; %bugfix from H. Gsenger
    elseif (ischar(val))
        %do nothing
    elseif (isnumeric(val))
        val = num2str(val);
    else
        succes = false;
    end
    
    if (ischar(val))
        %add line breaks to all lines except the last (for multiline strings)
        lines = size(val,1);
        val = [val char(newline*[ones(lines-1,1);0])];
        
        %transpose is required since indexing (i.e., val(nonspace) or val(:)) produces a 1-D vector. 
        %This should be row based (line based) and not column based.
        valt = val';
        
        remove_multiple_white_spaces = true;
        if (remove_multiple_white_spaces)
            %remove multiple white spaces using isspace, suggestion of T. Lohuis
            whitespace = isspace(val);
            nonspace = (whitespace + [zeros(lines,1) whitespace(:,1:end-1)])~=2;
            nonspace(:,end) = [ones(lines-1,1);0]; %make sure line breaks stay intact
            str = valt(nonspace');
        else
            str = valt(:);
        end
    end
end
