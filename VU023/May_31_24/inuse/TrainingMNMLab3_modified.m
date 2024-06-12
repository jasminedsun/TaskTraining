function TrainingMNMLab3(varargin)
%  Changes to code
%  04-01-05, Changed frame1-frame4 to one variable frametime(1-4). TM
%  04-11-05, Changed AllData structure to save trials as a vector. TM
%  04-15-05, Added code to allow the use of either the old class structure,
%   without frametime, or the new class structure.
%  08-18-05, Adding Target and saccade sections.
%  10-26-05, moved gateofftime to begining of trial loop (before flushing
%  ai), made subWrong a constant 1, and moved FixOff to right after the
%  last TTL pulse at the end of the trial, TM
%  3-29-06, changed name to TrainMNM and added the ability to switch every
%  10 correct trials.  To change the luminance of the distractor, go to
%  CreateWindowStruct2 and manually change the RGB value of the distractor
%  to [0 0 0].

[mousex,mousey] = GetMouse;
warning off all
Screen('closeall');
daqreset;
clc
load('C:\Users\CCLAB\Documents\MATLAB\inuse\Feature_classesphase34.mat'); %this file for phase 3 and 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sc%%%%%%%%%%%%%%%%%%
if nargin < 1                      %  If there are no arguments given
    datain(1:4) = [1 .5 .25 .5];    %  Default waiting times for each frame
    datain(5) = 3;                 %  Trial type
    datain(6) = 100;                %  Number of blocks
    datain(7) = 10;                %  Stimulus eccentricity
    datain(8) = 3.5;                 %  Radius in pixels of fixation window
    datain(9) = 5;                 %  Radius in pixels of target window
    datain(10) = 100;               %  Luminance
    datasin = 'FIO';
    
    Target_aquisition_time = 1;
    switch_threshold = 1000;
    burst_amount = 1;
    SwitchClass_Match    = [1 2 1 2 1 2 1 2 1 2 1 2];
    SwitchClass_NonMatch = [3 4 3 4 3 4 3 4 3 4 3 4];
    SwitchClass_both     = [1:4];
    
    MNM = 'NonMatch';
    numtargets = 2;
    disp('using default values')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   Visual Settings
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    vstruct.res = [1920 1080];    % screen resolution
    vstruct.siz = [103 57.5];        % screen size in cm
    vstruct.dis = 69;             % viewing distance in cm
    vstruct.voltage = 3.5;        % Analog to degree conversion constant
    vstruct.radius = datain(7);   % Stimulus excentricity
    vstruct.angs = [360 45 90 135 180 225 270 315];  % Stimulus angles
else
    % arguments exist from Gui, use them
    dataintemp = varargin(1);      % varargin is cell and convert to structure
    datain(1:11) = dataintemp{1,1};
    MNM = varargin{4};
    datasin = varargin{2};
    vstruct = varargin{3};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Initialize Nidaq board   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global trial_eye_data trial_eye_timestamp
WaveInitDaq2
outputSingleScan(DO,[0,0,0,0,0,0,0,0]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              Load External Protocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%[protocolname, loadpath] = uigetfile('C:\MATLAB6p5p1\work\PassiveMNM\class\*.mat','Load Protocol',100,100);
%if protocolname == 0
%    return
%else
%    load([loadpath protocolname]);
%end 
GeneralVars.ClassStructure = GeneralVars.ClassStructure;

%%%%%%%%%%%%%%%%%%%%%% Training Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This section allows you to control whether they are in blocks or randomly
% intermixed.  To do it in blocks, choose MNM = 'Both' at the top of the
% script, and under case 'Both' that cvar_max = 2, and SwitchClass = [X X]
% is uncommented.  The monkey starts off with these classes.  Then when the
% switchthreshold is met, the classes are switched 'see below around lines
% 388.
switch MNM
    case 'Match'
        totaltrials = length(GeneralVars.ClassStructure);
        realtrials = totaltrials/2;        
        SwitchClass = SwitchClass_Match;
        cvar_max = length(SwitchClass);
    case 'NonMatch'
        totaltrials = length(GeneralVars.ClassStructure);
        realtrials = totaltrials/2;
        SwitchClass = SwitchClass_NonMatch;
        cvar_max = length(SwitchClass);
    case 'Both'
        totaltrials = length(GeneralVars.ClassStructure);
        realtrials = totaltrials;
        SwitchClass = SwitchClass_both;
        cvar_max = length(SwitchClass);
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             Name Output File 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OutputFileNames = fileoutdlg({'Behavior output file',}, 'Output Files',[1 30],{'FIO'});
% OutputFileNames ={'GRU00x_xx'};
if isempty(OutputFileNames)
    return;
else
    savename = OutputFileNames{1};
end

go = 1;
filenamecheck = ['C:\Users\CCLAB\Documents\MATLAB\Behavioral_Data\' savename '.mat'];
filecheck = dir(filenamecheck);
if ~isempty(filecheck)
    button = questdlg(['File name ' datasin '.mat exists, do you want to continue?'],...
        'Continue Operation','Yes','No','Help','No');
    if strcmp(button,'Yes')
        disp('Creating file')
        go = 1;
    elseif strcmp(button,'No')
        disp('Canceled file operation')
        go = 0;
    elseif strcmp(button,'Help')
        disp('Sorry, no help available')
        go = 0;
    end
end
if  go == 1
    cd C:\Users\CCLAB\Documents\MATLAB\inuse\
else
    return
end
% filename = ['/DataFiles/NIN/',datasin,'.apm'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize eye display figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

btnColor=get(0,'DefaultUIControlBackgroundColor');

% Position the figure on right extended screen at the bottom
screenUnits=get(0,'Units');
screenSize=get(0,'ScreenSize');
set(0,'Units',screenUnits);
figWidth=640;
figHeight=512;
figPos=[0 40  ...
    figWidth                    figHeight];

% Create the figure window.
hFig=figure(...
    'Color'             ,btnColor                 ,...
    'IntegerHandle'     ,'off'                    ,...
    'DoubleBuffer'      ,'on'                     ,...
    'MenuBar'           ,'none'                   ,...
    'HandleVisibility'  ,'on'                     ,...
    'Name'              ,'Eye Position'  ,...
    'Tag'               ,'Eye Position'  ,...
    'NumberTitle'       ,'off'                    ,...
    'Units'             ,'pixels'                 ,...
    'Position'          ,figPos                   ,...
    'UserData'          ,[]                       ,...
    'Colormap'          ,[]                       ,...
    'Pointer'           ,'arrow'                  ,...
    'Visible'           ,'off'                     ...
    );

% Create target,fixation window,eye position xy plot

hAxes(1) = axes(...
    'Position'          , [0.08 0.3 0.55 0.55],...
    'Parent'            , hFig,...
    'XLim'              , [-25 25],...
    'YLim'              , [-25 25]...
    );

i=1:33;
xcoord(i)=cos(i*pi/16);
ycoord(i)=sin(i*pi/16);
FixWindow=datain(8)*[xcoord;ycoord];
TargetWindow=datain(9)*[xcoord;ycoord];
hLine(3) = plot(1*xcoord,1*ycoord,'Parent',hAxes(1));
hLine(2) = line('XData',0,'YData',0,'marker','+');  % eye position
hLine(1) = line('XData',0,'YData',0,'marker','s'); % stim position
% markerradii = ((4/2.54)*72)/4;

% Label the plot.
xlabel('X');
ylabel('Y');

% Create Eye X subplot.

hAxes(2) = axes(...
    'Position'          , [0.6700 0.650 0.30 0.15],...
    'Parent'            , hFig,...
    'XLim'              , [0 400],...
    'YLim'              , [-10 10]...
    );
hLine(4) = plot(200,0);
% Label the plot.
title('Eye X');

% Create Eye Y subplot.

hAxes(3) = axes(...
    'Position'          , [0.670 0.350 0.30 0.15],...
    'Parent'            , hFig,...
    'XLim'              , [0 400],...
    'YLim'              , [-10 10]...
    );
hLine(5) = plot(0,0);
% Label the plot.
xlabel('Time');
title('Eye Y');

data.handle.figure = hFig;
data.handle.axes = hAxes;
data.handle.line = hLine;
set(hFig,'Visible','on','UserData',data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Calculate Pixels/Degree constants and coordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[vstruct, Display] = WaveDisplayParams_old(vstruct, datain);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Declare Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%FixWindowSize(1,:) = datain(8)*Figdata.xcoord;
%FixWindowSize(2,:) = datain(8)*Figdata.ycoord;
%TargWindowSize(1,:) = datain(9)*Figdata.xcoord;
%TargWindowSize(2,:) = datain(9)*Figdata.ycoord;
totalblocks = datain(6);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
version = 'TrainingMNMLab3 4NOV2014' ; % after code changes, change version
filename = ['/DataFiles/ADR/',datasin,'.apm'];
switch_correct = 0;
p_correctcounter = 0;
BreakState = 0;
outputcounter = 0;
save_counter = 1;
correctcounter = 0;
blockcounter = 1;
gate_off_time = 1;
intertrial_interval_correct = 2.5;
intertrial_interval_error   = 2.5;
aquisition_time = 2;
black = BlackIndex(0);
white = WhiteIndex(0);
gray = datain(10);
ReactionTime = 0;
subWrong = 1;
fix_error = 0;
target_error = 0;
p_correct = 0;

cvar = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fixation times in seconds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
    frametime = GeneralVars.ClassStructure(1).frametime; % Must add frametime(6) for target.
    using_new_classes = 1;
catch
    using_new_classes = 0;
    frametime = [datain(1:3) datain(2) datain(3) datain(4)];  %fixation time for fixation point
%     frametime = [datain(1:3) 1 0 datain(4)];  %fixation time for fixation point
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stimulus Windows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[window, f, r, WindowStructure, AllCoordinates] = CreateWindowStruct5_old2(Display, vstruct, GeneralVars.ClassStructure,MNM,numtargets,1);


    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Save Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%start(ai)
AllData.parameters.Display = Display;
AllData.version = version;
AllData.ClassStructure = GeneralVars.ClassStructure;
AllData.parameters.fixationDuration = datain(1);
AllData.parameters.stimulusDuration = datain(2);
AllData.parameters.delayDuration = datain(3);
AllData.parameters.targetDuration = datain(4);
AllData.parameters.totalBlocks = datain(6);
AllData.parameters.stimulusEccentricity = datain(7);
AllData.parameters.fixationWindow = datain(8);
AllData.parameters.targetWindow = datain(9);
AllData.parameters.luminance = datain(10);
AllData.parameters.vstruct = vstruct;
AllData.parameters.ITI_Correct = intertrial_interval_correct;
AllData.parameters.ITI_Error   = intertrial_interval_error;
AllData.parameters.FixAquisition = aquisition_time;
AllData.parameters.Number_of_targets = numtargets;
AllData.synctime = clock;
AllData.starttime = GetSecs;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %outputSingleScan(ao,-5);
%try
    while (BreakState ~= 1) & (blockcounter <= totalblocks)
        trialcounter = 1;
        repeatcounter = 1;
        outputcounter = outputcounter + 1;
        dataout(outputcounter,1:7) = {'Trial' 'Class #' 'Correct' ...
                'Success' 'C-(%)' 'Notes','State'};
        IndexHist = zeros(1,totaltrials);
        IndexTotl = randperm(length(GeneralVars.ClassStructure));
        switch MNM
            case 'Match'
                IndexTotl = IndexTotl(rem(IndexTotl,4) == 1 | rem(IndexTotl,4) == 2);
            case 'NonMatch'
                IndexTotl = IndexTotl(rem(IndexTotl,4) == 3 | rem(IndexTotl,4) == 0);
        end
        CurrentClass = IndexTotl(1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Only use Class in SwitchClass Variable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            cvar = randperm(cvar_max);
            CurrentClass = SwitchClass(cvar(1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while (repeatcounter <= realtrials) & (BreakState ~=1)            
            trial_eye_data      = [];
            trial_eye_timestamp = [];        
            WaitSecs(gate_off_time)
            startBackground(ai);  
            %waitsecs(1)%xq 2013 6-3; wait to get ai sample
            outputSingleScan(DO,[0,0,0,0,0,0,1,0]);
         %   outputSingleScan(ao,-5+0.02*save_counter);
            AllData.trials(save_counter).time = GetSecs;
            AllData.trials(save_counter).Class = CurrentClass;
            AllData.outputcounter = outputcounter;
            outputcounter = outputcounter + 1;
         %   CurrentClassBin = dec2binvec(CurrentClass,6);
         %   putvalue(dio.Line(2:7), CurrentClassBin);%xq 
         %   waitsecs(0.1)
         %   putvalue(dio,[0 0 0 0 0 0 0 0]); 
            if using_new_classes
                frametime = GeneralVars.ClassStructure(CurrentClass).frametime;
            end                
            while 1
                Statecode = 1;
                FixState = 0;
                Result = 0;
                %  Display Fixation
                Screen(window,'WaitBlanking');
                outputSingleScan(DO,[0,0,0,0,1,0,1,0]);
                Screen('CopyWindow',f,window);
                Screen(window,'Flip');
                AllData.trials(save_counter).FixOn = GetSecs;
                outputSingleScan(DO,[0,0,0,0,0,0,1,0]);
                WaveUpdateEyeDisplay(AllCoordinates.fRect, FixWindow, AllCoordinates.fRect,vstruct, hLine,'on')
                breaktime = GetSecs;
                %  Give subject 2 seconds to move to fixation window
                while (FixState <= 0) & ((GetSecs - breaktime) < aquisition_time)
                    [eyeX, eyeY] = DisplayEye(Display, hAxes, hLine, ai);    
                    degree_fcenter=[1,-1].*(AllCoordinates.fCenter-vstruct.res/2).*vstruct.degpix;
                    [FixState] = CheckFixation(degree_fcenter, Display.FixationWindow, ai, vstruct);
                end
                %  If subject didn't get to window within 2 seconds, or break
                %  button was pushed, break out of trial
                if FixState == 0
                    wavesoundplay('abort.wav',0.8);
                    break;
                end
                Statecode = 2;
                breaktime = GetSecs;
                %  Eye must stay within fixation window for frame1 time
                while (FixState == 1) & ((GetSecs - breaktime) < frametime(1))
                    [eyeX, eyeY] = DisplayEye(Display, hAxes, hLine, ai);
                    degree_fcenter=[1,-1].*(AllCoordinates.fCenter-vstruct.res/2).*vstruct.degpix;
                    [FixState] = CheckFixation(degree_fcenter, Display.FixationWindow, ai, vstruct);
                end            
                if FixState == 0
                    wavesoundplay('abort.wav',0.8);
                    break;
                end
                Statecode = 3;
                %  Display Fixation plus stimulus                
                Screen(window,'WaitBlanking');                   
                outputSingleScan(DO,[0,0,0,0,1,0,1,0]);
                Screen('CopyWindow',WindowStructure(CurrentClass).frame(1).end,window);                         
                Screen(window,'Flip');
                outputSingleScan(DO,[0,0,0,0,0,0,1,0]);
                WaveUpdateEyeDisplay(AllCoordinates.cRect(CurrentClass,:,1), FixWindow, AllCoordinates.fRect,vstruct, hLine,'on')
                breaktime = GetSecs;
                %  Check that eye stays within fixation window for frame2
                while (FixState == 1) & ((GetSecs - breaktime) < frametime(2))
                    [eyeX, eyeY] = DisplayEye(Display, hAxes, hLine, ai);
                    degree_fcenter=[1,-1].*(AllCoordinates.fCenter-vstruct.res/2).*vstruct.degpix;
                    [FixState] = CheckFixation(degree_fcenter, Display.FixationWindow, ai, vstruct);
                end
                if FixState == 0
                    wavesoundplay('abort.wav',0.8);
                    break;
                end
                Statecode = 4;
                %  Display fixation only                
                Screen(window,'WaitBlanking');
                outputSingleScan(DO,[0,0,0,0,1,0,1,0]);                
                Screen('CopyWindow',f,window);
                Screen(window,'Flip');
                outputSingleScan(DO,[0,0,0,0,0,0,1,0]);
                WaveUpdateEyeDisplay(AllCoordinates.fRect, FixWindow, AllCoordinates.fRect,vstruct, hLine,'on')
                breaktime = GetSecs;
                %  Make sure eye stays in window for frame3 time
                while (FixState == 1) & ((GetSecs - breaktime) < frametime(3))
                    [eyeX, eyeY] = DisplayEye(Display, hAxes, hLine, ai);
                    degree_fcenter=[1,-1].*(AllCoordinates.fCenter-vstruct.res/2).*vstruct.degpix;
                    [FixState] = CheckFixation(degree_fcenter, Display.FixationWindow, ai, vstruct);
                end
                if FixState == 0
                    wavesoundplay('abort.wav',0.8);
                    break;
                end                
                if frametime(6) ~= 0
                    %  Display 2nd Fixation plus stimulus                
                    Screen(window,'WaitBlanking');                
                    outputSingleScan(DO,[0,0,0,0,1,0,1,0]);
                    Screen('CopyWindow',WindowStructure(CurrentClass).frame(2).end,window);              
                    Screen(window,'Flip');
                    outputSingleScan(DO,[0,0,0,0,0,0,1,0]);
                    WaveUpdateEyeDisplay(AllCoordinates.cRect(CurrentClass,:,2), FixWindow, AllCoordinates.fRect,vstruct, hLine,'on')
                    breaktime = GetSecs;
                    %  Check that eye stays within fixation window for frame2
                    while (FixState == 1) & ((GetSecs - breaktime) < frametime(4))
                        [eyeX, eyeY] = DisplayEye(Display, hAxes, hLine, ai);
                        degree_fcenter=[1,-1].*(AllCoordinates.fCenter-vstruct.res/2).*vstruct.degpix;
                        [FixState] = CheckFixation(degree_fcenter, Display.FixationWindow, ai, vstruct);
                    end
                    if FixState == 0
                        wavesoundplay('abort.wav',0.8);
                        break;
                    end
                    Statecode = 5;
                    %  Display fixation only
                    Screen(window,'WaitBlanking');
                    outputSingleScan(DO,[0,0,0,0,1,0,1,0]);
                    Screen('CopyWindow',f,window);
                    Screen(window,'Flip');
                    outputSingleScan(DO,[0,0,0,0,0,0,1,0]);
                    WaveUpdateEyeDisplay(AllCoordinates.fRect, FixWindow, AllCoordinates.fRect,vstruct, hLine,'on')
                    breaktime = GetSecs;
                    %  Make sure eye stays in window for frame3 time
                    while (FixState == 1) & ((GetSecs - breaktime) < frametime(5))
                        [eyeX, eyeY] = DisplayEye(Display, hAxes, hLine, ai);
                        degree_fcenter=[1,-1].*(AllCoordinates.fCenter-vstruct.res/2).*vstruct.degpix;
                        [FixState] = CheckFixation(degree_fcenter, Display.FixationWindow, ai, vstruct);
                    end
                    if FixState == 0
                        wavesoundplay('abort.wav',0.8);
                        break;
                    end
                    Statecode = 6;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % Saccading to Target.  Display target and wait for
                    % monkey to saccade to target.
                    FixState = 0;
                    Screen(window,'WaitBlanking');                
                    outputSingleScan(DO,[0,0,0,0,1,0,1,0]);
                    Screen('CopyWindow',WindowStructure(CurrentClass).frame(3).end,window);              
                    Screen(window,'Flip');
                    outputSingleScan(DO,[0,0,0,0,0,0,1,0]);
                    WaveUpdateEyeDisplay(AllCoordinates.cRect(CurrentClass,:,3), TargetWindow, AllCoordinates.cRect(CurrentClass,:,3),vstruct, hLine,'on')
                    breaktime = GetSecs;
                    %  Give subject 2 seconds to move to fixation window
                    while (FixState <= 0) & ((GetSecs - breaktime) < Target_aquisition_time)
                        [eyeX, eyeY] = DisplayEye(Display, hAxes, hLine, ai);   
                        degree_fcenter=[1,-1].*(AllCoordinates.cCenter(CurrentClass,:,3)-vstruct.res/2).*vstruct.degpix;                         
                        [FixState] = CheckFixation(degree_fcenter, Display.TargetWindow, ai, vstruct);
                    end                    
                    breaktime = GetSecs;
                    %  Eye must stay within target window for frametime(6)
                    while (FixState == 1) & ((GetSecs - breaktime) < frametime(6))
                        [eyeX, eyeY] = DisplayEye(Display, hAxes, hLine, ai);
                        degree_fcenter=[1,-1].*(AllCoordinates.cCenter(CurrentClass,:,3)-vstruct.res/2).*vstruct.degpix;                         
                        [FixState] = CheckFixation(degree_fcenter, Display.TargetWindow, ai, vstruct);
                    end            
                    if FixState == 0
                        wavesoundplay('abort.wav',0.8);
                        break;
                    end
                    Statecode = 7;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                end
                %  If this point in the code is reached, the subject completed
                %  the trial successfully and Result is changed from 0 to 1
                Result = 1;
                break
            end
            breaktime = GetSecs;
            outputSingleScan(DO,[0,0,0,0,1,0,1,0]);
            Screen(window,'FillRect',black)  % Clear screen
            Screen(window,'Flip');
            AllData.trials(save_counter).FixOff = GetSecs;
         %   Screen(window,'FillRect',white,[0 0 60 50]);
         %   Screen(window,'Flip');
            outputSingleScan(DO,[0,0,0,0,0,0,1,0]);
%             if Result == 0
%                 if CurrentClass == SwitchClass(1)
%                     screen(window,'FillRect',black,[100 100 1200 600])
%                 else
%                     screen(window,'FillRect',black,[100 600 1200 1000])
%                 end
%             else
%                 Screen(window,'FillRect',black)  % Clear screen
%             end
%             putvalue(dio, [0 0 0 0 0 0 0 1]);
            WaveUpdateEyeDisplay(AllCoordinates.fRect, TargetWindow, AllCoordinates.fRect,vstruct, hLine,'off')
            AllData.trials(save_counter).EndofTrialtime = GetSecs;
            clc
            AllData.trials(save_counter).Statecode = Statecode;
            if Result == 1
                p_correctcounter = p_correctcounter + 1;
                correctcounter = correctcounter + 1;
                p_correct = round(p_correctcounter/(target_error+p_correctcounter)*100);
                AllData.trials(save_counter).Reward = 'Yes';
%                 APMSendReward(outputcounter-blockcounter,1,APMConn)
                dataout(outputcounter,1:7) = {outputcounter-blockcounter, CurrentClass,correctcounter, 1,p_correct,GeneralVars.ClassStructure(CurrentClass).Notes,Statecode}
                %  Correct auditory feedback            
                wavesoundplay('correct.wav',0.6);
                for b = 1:burst_amount
                outputSingleScan(DO, [1 0 0 0 0 0 1 0]);
                outputSingleScan(DO, [0 0 0 0 0 0 1 0]);
                WaitSecs(0.75);
                end
                intertrial_interval = intertrial_interval_correct-gate_off_time;
                repeatcounter = repeatcounter + 1;
                IndexHist(CurrentClass) = CurrentClass;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                switch_correct = switch_correct + 1;
                if (switch_correct >= switch_threshold) & (switch_correct < switch_threshold*2) 
                    if switch_correct == switch_threshold & strcmp(MNM,'Match')
                        disp('switching to Non-Match')
                        p_correctcounter = 0;
                        target_error = 0;
                        SwitchClass = SwitchClass_NonMatch;
                        MNM = 'NonMatct';
                    elseif switch_correct == switch_threshold & strcmp(MNM,'NonMatch')
                        disp('switching to Match')
                        p_correctcounter = 0;
                        target_error = 0;
                        SwitchClass = SwitchClass_Match;
                        switch_correct = 0;
                        MNM = 'Match';
                    end                    
%                 elseif switch_correct >= switch_threshold*2
%                     disp('switching to Match')
%                     p_correctcounter = 0;
%                     target_error = 0;
%                     SwitchClass = SwitchClass_Match;
%                     switch_correct = 0;
                end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
            else
                if Statecode == 6
%                     intertrial_interval_error   = 10;
                    target_error = target_error + 1;
                    p_correct = round(p_correctcounter/(target_error+p_correctcounter)*100);
                elseif Statecode == 1
%                     intertrial_interval_error   = 10;
                else
%                     intertrial_interval_error   = 2.5;
                end
                AllData.trials(save_counter).Reward = 'No';                
%                 APMSendReward(outputcounter-blockcounter,0,APMConn)               
                dataout(outputcounter,1:7) = {outputcounter-blockcounter, CurrentClass, correctcounter, 0,p_correct,GeneralVars.ClassStructure(CurrentClass).Notes,Statecode}  ;                 
                %  Incorrect auditory feedback
                wavesoundplay('wrong.wav',0.6);                
                intertrial_interval = intertrial_interval_error-gate_off_time;
            end
            WaitSecs(subWrong);
                all_eye     = trial_eye_data;
                all_eyetime = trial_eye_timestamp;
                stop(ai);
                set(hLine(4), 'XData',all_eyetime,...
                    'YData', all_eye(:,1));
                set(hLine(5), 'XData',all_eyetime,...
                    'YData', all_eye(:,2));
                set(hAxes(2),'YLim', [-15 15],'XLim', [0 sum(datain(1:4))+2*aquisition_time]);
                set(hAxes(3),'YLim', [-15 15],'XLim', [0 sum(datain(1:4))+2*aquisition_time]);
                drawnow
%             IndexTotl = randperm(totaltrials);
%             switch MNM
%                 case 'Match'
%                     IndexTotl = IndexTotl(rem(IndexTotl,4) == 1 | rem(IndexTotl,4) == 2);
%                 case 'NonMatch'
%                     IndexTotl = IndexTotl(rem(IndexTotl,4) == 3 | rem(IndexTotl,4) == 0);
%             end
%             IndexTemp = IndexTotl(~ismember(IndexTotl,IndexHist));
%             if ~isempty(IndexTemp)
%                 CurrentClass = IndexTemp(1);
%             end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           Only use Class in SwitchClass Variable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cvar = randperm(cvar_max);
CurrentClass = SwitchClass(cvar(1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
outputSingleScan(DO, [0 0 0 0 0 0 0 0]);
%outputSingleScan(ao,0);
Screen(window,'FillRect',black)  % Clear screen
            %  Intertrial inverval
            while ((GetSecs - breaktime) < intertrial_interval) & (BreakState ~=1)
%                 [eyeX, eyeY] = DisplayEye(Display, hAxes, hLine, ai);
                BreakState = CheckBreakState;
            end
            if (BreakState == 1)
                break;
            end
         %   SND('Quiet');  %  Clear soundcard buffer
            trialcounter = trialcounter + 1;
            save_counter = save_counter + 1;
        end
        blockcounter = blockcounter + 1;
    end
%catch
 %   lasterr
%end
save(['C:\Users\CCLAB\Documents\MATLAB\Behavioral_Data\' savename],'AllData');
%CleanUp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [eyeX, eyeY] = DisplayEye(Display, hAxes, hLine, ai);

global trial_eye_data
% trial_eye_data
% eye=inputSingleScan(ai);
if isempty(trial_eye_data)
    eye =[0, 0];
else
    eye = trial_eye_data(end, :);

end
eyeX = (((eye(1,1)-0)*3.5));
eyeY = -1*(((eye(1,2)-0)*3.5));
set(hAxes(1), 'XLim', [-25 25],'YLim', [-25 25]);    
set(hLine(2), 'XData', eyeX, 'YData', eyeY); % eye position
drawnow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [FixState,BreakState] = CheckFixation(cCenter, WindowRadius, ai, vstruct)
%  CheckFixation is a subfunction that inputs rectangular coordinates and
%  duration to check that the mouse coordinates stay within the inputed
%  rectangle for the duration and send back to the main function whether 
%  the subject was successful or errored or clicked the mouse button.  

global trial_eye_data
% trial_eye_data
% eye=inputSingleScan(ai);
if isempty(trial_eye_data)
    eye =[0, 0];
else
    eye = trial_eye_data(end, :);

end
eyeX = (((eye(1,1)-0)*3.5));
eyeY = -1*(((eye(1,2)-0)*3.5));

%  Compare distance from mouse coordinates from inputed window center
if (((cCenter(1,1)-eyeX)^2)+((cCenter(1,2)-eyeY)^2))^.5 <= WindowRadius
    %  If distance between mouse and window is less than inputted radius,
    %  then mouse is in correct position
    FixState = 1;
else
    %  If not then it is outside of the radius
    FixState = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [BreakState] = CheckBreakState

[MouseX, ~, Breakbutton] = GetMouse;
 
%  Check for mouse click
if any(Breakbutton)
    Breakbuttons = 0;
    disp('Program paused, click once for continue, twice to exit')
    WaitSecs(1)
    while 1
        Breakbuttons = GetClicks;
        if Breakbuttons == 1
            BreakState = 0;
            Breakbuttons
            return
        elseif Breakbuttons > 1
            BreakState = 1;
            Breakbuttons
            return
        end
    end
else
    BreakState = 0;
end