
function  [t, SignalStruct] = create_vcd(logsout,fout)

if ~exist('logsout','var')
   logsout = evalin('base', 'logsout');
 
end

if ~exist('fout','var')
    fout = './vcd/test';
end

signals = logsout;

t = parse_dataset(signals);
%%

for r = 1:height(t)
    SignalStruct(r).Name = t.Name{r};
    SignalStruct(r).Type = t.DataType{r};
    SignalStruct(r).Path = t.Path{r};
    SignalStruct(r).Value = t.Data{r};
end
TimeArray = t.TimeSeries(1).Time;
CreateVCD(fout,TimeArray,SignalStruct);

end


function t = parse_dataset(signals)


%% Create table
t = table({},{},{},{},{},{});
t.Properties.VariableNames = {'Path','Name','TimeSeries','Data','DataType','cv'};

for i = 1:signals.numElements
    s = signals{i};
    
    bp = s.BlockPath.convertToCell;
    bp = bp{1};
    str_path = strrep(strrep(bp,' ','_'),'/','.');
    
    t = parse_dataset_step(t,str_path,s.Values,s);
end
end

function t = parse_dataset_step(t,str_path,s,sfull)

% Bus
if isstruct(s)
    for fn = fieldnames(s)'
        fn = fn{:};
        new_s = s.(fn);
        if isstruct(new_s)
            new_str_path = [str_path '.' fn];
        else
            new_str_path = str_path;
        end
        t = parse_dataset_step(t,new_str_path,new_s);
    end
else
    %% Add the signal
    str_name = s.Name;
    
    if isempty(str_name)
        str_name = ['port_' num2str(sfull.PortIndex)];
    end
    
    [isv,ndim,sz,nel,tfirst] = is_vector(s);
    if isv
        
        szargs = cell( 1, ndim ); % We'll use this with ind2sub in the loop
        for ii=1:nel
            [ szargs{:} ] = ind2sub( sz, ii ); % Convert linear index back to subscripts
            ind_cell = cellfun(@(x) {num2str(x)}, szargs);
            ind_str = strjoin(ind_cell,',');
            suffix_str = strjoin(ind_cell,'_');
            new_str_name = [str_name '_' suffix_str];
            if tfirst
                eval(['data=squeeze(s.Data(:,' ind_str '));'])
            else
                eval(['data=squeeze(s.Data(' ind_str ',:));'])
            end
            t = parse_dataset_entry(t,str_path,new_str_name,s,data);
        end
        
        
    else
        data = s.Data;
        t = parse_dataset_entry(t,str_path,str_name,s,data);
    end
end
end

function t = parse_dataset_entry(t,str_path,str_name,s,data)
disp(class(data));

switch class(data)
    case 'double'
        datatype = 'F32';
    case 'embedded.fi'
        d = data(1);
        if d.WordLength == 1 && d.FractionLength == 0 && ~d.Signed
            datatype = 'B';
        else
            datatype = 'F32';
        end
    case 'logical'
        datatype = 'B';
    otherwise
        datatype = 'F32';
end



data = double(data);
str_name = regexprep(str_name,'>|<','');
t_new = cell2table({str_path,str_name,s,data,datatype,{}});
t_new.Properties.VariableNames = t.Properties.VariableNames;
disp(['Adding signal ' str_path '.' str_name]);
t = [t ; t_new];
end


function t = init_vars(writer,t)
for r = 1:height(t)
    str_path = t.Path{r};
    str_name = t.Name{r};
    disp(['Registered variable ' str_path '.' str_name]);
    t.cv{r} = writer.register_var(str_path,str_name,'real');
end
end

function write_sig(writer,t)

timepoints = length(t.Data{1});
for time = 1:timepoints
    for r = 1:height(t)
        data = t.Data{r};
        value=data(time);
        if time>1
            last_value=data(time-1);
        else
            last_value = nan;
        end
        cv = t.cv{r};
        if value ~= last_value
            writer.change(cv,time,value)
        end
    end
end
end

function [isv,ndim,sz,nel,tfirst] = is_vector(s)
%%
tfirst = s.IsTimeFirst;

ndim = ndims(s.Data)-1; % Skip the time dimension
sz = size( s.Data );

ind_str = strjoin(repmat({':'},1,ndim),',');
if tfirst
    eval(['d=s.Data(1,' ind_str ');'])
    sz = sz(2:end);
else
    eval(['d=s.Data(' ind_str ',1);'])
    sz = sz(1:end-1);
end

nel = numel( d );

if any(sz>1)
    isv = true;
else
    isv = false;
end
end

