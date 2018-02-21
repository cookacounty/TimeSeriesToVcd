%% File Info
%   File Name       : CreateVCD.m
%   Version         : v1.2
%   Created By      : Tabrez Alam (TAB)
%   Last updated on : 11 June,2012
%   -----------------------------
%       Change Log
%   -----------------------------
%   Initial
%   v1.1    -   Fixed the bug which was causing error when 
%               sample time >= 1sec
%   v1.2    -   Revome the characters $, # from identifier name.
%           -   Modified resolution calculation to support upto 1 fs resolution.            
%               

%% VCD File Formate

%     ---* HEADER SECTION *---
%     $date                                                                       Data and time the file was generated.
%     23-Sep-2003 14:38:11
%     $end
% 
%     $version HDL Verifier version 1.0 $ end                                     Version of the VCD block that generated the file.
% 
%     ---* VARIABLE DEFINATION SECTION *---
%     $timescale 1 ns $ end                                                       The time scale that was used during the simulation.
% 
%     $scope module model $end                                                    The scope of the module being dumped.
% 
%     $var wire 1 ! Original Data [0] $end                                        Variable definitions. Each definition associates a signal with character identification code (symbol).
%     $var wire 1 " Recovered Clock [0] $end                                      The symbols are derived from printable characters in the ASCII character set from ! to ~. 
%     $var wire 1 # Recovered Data [0] $end                                       Variable definitions also include the variable type (wire) and size in bits.                                       
% 
%     $upscope $end                                                               Marks a change to the next higher level in the HDL design hierarchy.
% 
%     $enddefinitions $end                                                        Marks the end of the header and definitions section.
% 
%     ---* SIMULATION START TIME *---
%     #0                                                                          Simulation start time.
%     
%     ---* INITIAL VALUE DUMP SECTION *---
%     $dumpvars                                                                   Lists the values of all defined variables at time equals 0.
%         0!
%         0"
%         0#
%     $end
% 
%     ---* VALUE CHANGES DUMP SECTION *---
%     #630
%         1!                                                                      The starting point of logged value changes 
% 
%         .
%         .
%         .
%         .
%     #1160
%         1"
%         1#
% 
%     ---* END OF DUMP SECTION *---
%     $dumpoff                                                                    Marks the end of the file by dumping the values of all variables as the value x.
%         x!
%         x"
%         x#
%     $end

%% SignalStruct (Array of structure containing information of all signals)

%     SignalStruct(n).Name  --> Contains name of the signal
%     SignalStruct(n).Type  --> contains type of signal
%     SignalStruct(n).Path  --> Hierarctical path (seperated by .)
%     SignalStruct(n).Value --> Values (Length is same for all signal)

%% Start of main function

function CreateVCD(FileName, TimeArray, SignalStruct)

    %----------------------------------------------------------------------
    % Create & Reset the waitbar
    %----------------------------------------------------------------------
    WaiBarh = waitbar(0,'Creating VCD File, Please wait...');              

    %----------------------------------------------------------------------
    % Tables and constant data
    %----------------------------------------------------------------------
    ResolMultprTable = [1   10   100  1000  10000 100000 1000000 10000000 100000000 1000000000 10000000000 100000000000 1000000000000 10000000000000 100000000000000 1000000000000000];
    ResolValTable    = [1   100  10   1     100   10     1       100      10        1          100         10           1             100            10              1               ];
    ResolUnitTable   = {'s','ms','ms','ms', 'us', 'us',  'us',   'ns',    'ns',     'ns'       'ps'        'ps'         'ps'          'fs'           'fs'            'fs'            };

    VCDIdfrPrfxTable = '!"%&''()*+,-./:;<=>?@[\]^_`{|}~';                                   % 30 Characters
    VCDIdfrCharTable = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';    % 62 Characters
    
    SignCount = uint32(length(SignalStruct));                               % Get the total number of signals
    
    WaiBarSeg = 0.8/(double(SignCount+1));
    WaiBarCtr = 0.1;

    %---------------------------------------------------------------------
    % Process the hierarchy
    %---------------------------------------------------------------------
    SignalStruct = ProcessSigHier(SignCount,SignalStruct);
    
    %---------------------------------------------------------------------
    % Create cell to store signal info
    %---------------------------------------------------------------------
    SigInfo = cell(SignCount,1);

    %----------------------------------------------------------------------
    % Choose identifier for each signal (Using identifier of 2 characters)
    % This script can support 30x62 = 1860 signals
    %----------------------------------------------------------------------
    VCDIdfrPrfx_Idx = uint8(1);
    VCDIdfrChar_Idx = uint8(1);

    for x = 1:SignCount
        SigInfo{x} = ProcessSigName(SignalStruct(x).Type);
        SigInfo{x}.VCDIdfr = [VCDIdfrPrfxTable(VCDIdfrPrfx_Idx) VCDIdfrCharTable(VCDIdfrChar_Idx)];

        VCDIdfrChar_Idx = VCDIdfrChar_Idx+1;

        if(VCDIdfrChar_Idx>length(VCDIdfrCharTable))
            VCDIdfrChar_Idx = 1;
            VCDIdfrPrfx_Idx = VCDIdfrPrfx_Idx+1;
            
            if(VCDIdfrPrfx_Idx>length(VCDIdfrPrfxTable))
                error('[VCDCreate] Function supports 1860 signals only. Please modify the script for identifier assignment to support more signals.');
            end
            
        end
    end

    %----------------------------------------------------------------------
    % Calculate time resolution and time unit
    %----------------------------------------------------------------------
    TimeRes       = TimeArray(2)-TimeArray(1);
    TimeScale     = 0;
    TimeScaleUnit = 'Unknown';
    ResolMultpr   = 0;
    
    for x=1:length(ResolMultprTable)
        RoundVal  = TimeRes*ResolMultprTable(x);
        TRf       = RoundVal-fix(RoundVal);                                  % Fractional part
        
        if TRf==0.0
            ResolMultpr   = ResolMultprTable(x);
            TimeScale     = ResolValTable(x);
            TimeScaleUnit = ResolUnitTable{x};
            break;
        end
    end
    
    if TimeScale==0 || ResolMultpr==0 || strcmp(TimeScaleUnit,'Unknown')
        error('[VCDCreate] Can not decide time resolution. Note that time resoluion is limited to 1 fs');
    end

    % Update waitbar
    waitbar(WaiBarCtr,WaiBarh,'Creating VCD File, Please wait...');
    
    %----------------------------------------------------------------------
    % Convert all signal data to string
    %----------------------------------------------------------------------
    DataBuffer = cell(SignCount,1);
    for x=1:SignCount
        if(SigInfo{x}.VCDValueStrType==1)
            DataBuffer{x} = strrep(cellstr(dec2bin(SignalStruct(x).Value)),' ','');
        else
            DataBuffer{x} = strrep(cellstr(num2str(SignalStruct(x).Value)),' ','');
        end
        
        % Update waitbar
        WaiBarCtr = WaiBarCtr + WaiBarSeg;
        waitbar(WaiBarCtr,WaiBarh,'Creating VCD File, Converting Data to String Please wait...');
    end

    %----------------------------------------------------------------------
    % Convert time array to string
    %----------------------------------------------------------------------
    TimeBuffer = strrep(cellstr(num2str(TimeArray*ResolMultpr)),' ','');
    
    % Update waitbar
    WaiBarCtr = WaiBarCtr + WaiBarSeg;
    waitbar(WaiBarCtr,WaiBarh,'Creating VCD File, Converting Time to String Please wait...');
    
    %----------------------------------------------------------------------
    % Write the data to VCD file 
    %----------------------------------------------------------------------
    mexWriteVCD([FileName '.vcd'],datestr(now),num2str(TimeScale),TimeScaleUnit,TimeBuffer,SignalStruct,DataBuffer,SigInfo);
    
    % Update waitbar
    waitbar(1,WaiBarh,'Creating VCD File, Writing to File Please wait...');

    close(WaiBarh);

end

%% Sub-function to create the hierarchy
function SigStruct=ProcessSigHier(SignCount,SigStruct)
    for i = 1:SignCount
        SigStruct(i).ScopeHeader = '';
        SigStruct(i).ScopeFooter = '';
        path_split = strsplit(SigStruct(i).Path,'.');
        depth = length(path_split);
        for d = 1:depth
            SigStruct(i).ScopeHeader = [SigStruct(i).ScopeHeader '$scope module ' path_split{d} ' $end '];
            SigStruct(i).ScopeFooter = [SigStruct(i).ScopeFooter '$upscope $end '];
        end
    end
end

%% Sub-function to determone signal info 

function SigInfo = ProcessSigName(SigType)
    
    persistent TypeSearchTable;
    persistent TypeSize;
    persistent VCDType;
     
    if isempty(TypeSearchTable)
       TypeSearchTable = {'B'   ,'U8'     ,'U16'    ,'U32'    ,'U64'    ,'S8'  ,'S16' ,'S32' ,'S64' ,'F32','F64'};
       TypeSize        = {'1'   ,'8'      ,'16'     ,'32'     ,'64'     ,'1'   ,'1'   ,'1'   ,'1'   ,'1'   ,'2'};
       VCDType        = {'wire','integer','integer','integer','integer','real','real','real','real','real','real'};
    end
   
       
    SigInfo.VCDType = '';
    SigInfo.VCDSize = '';
    SigInfo.VCDValuePref = '';
    SigInfo.VCDValueSuf = '';
    SigInfo.VCDValueStrType = uint8(0);
    
    TypeIdx = uint8(find(strcmp(TypeSearchTable,SigType), 1));
    if(isempty(TypeIdx))
        error('[VCDCreate]Unexpected Signal type "%s"',SigType);
    end
    
    SigInfo.VCDType = VCDType{TypeIdx};
    SigInfo.VCDSize = TypeSize{TypeIdx};
    
    if TypeIdx==1                       % For B
        SigInfo.VCDValuePref = '';
        SigInfo.VCDValueStrType = 1;
    elseif TypeIdx>=2 && TypeIdx<=5     % For U8 ,U16 ,U32 ,U64
        SigInfo.VCDValuePref = 'B';
        SigInfo.VCDValueStrType = 1;
    else                                % For S8 ,S16 ,S32 ,S64 ,F32 ,F64
        SigInfo.VCDValuePref = 'R';
        SigInfo.VCDValueStrType = 2;
    end
    
    if TypeIdx==1
        SigInfo.VCDValueSuf = '';
    else
        SigInfo.VCDValueSuf = ' ';
    end
    
    
end