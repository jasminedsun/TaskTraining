ai = daq.createSession('ni');
Ach=addAnalogInputChannel(ai,'Dev1',[0:2],'Voltage');
Ach(1).TerminalConfig = 'SingleEnded';
Ach(1).Range = [-5.0 5.0];
Ach(2).TerminalConfig = 'SingleEnded';
Ach(2).Range = [-5.0 5.0];
Ach(3).TerminalConfig = 'SingleEnded';
Ach(3).Range = [-5.0 5.0];
lh=addlistener(ai,'DataAvailable',@saveeyeData);
ai.Rate =500;
ai.DurationInSeconds=40;
ai.NotifyWhenDataAvailableExceeds = 1;

DO=daq.createSession('ni');
Dch=addDigitalChannel(DO,'Dev1','Port0/Line0:7','OutputOnly');

%%
addpath('OpenEphys');
url = 'tcp://10.32.133.176:5556'; % or, e.g., //'tcp://10.71.212.19:5556 if GUI runs on another machine...
tcp_handle = zeroMQwrapper('StartConnectThread',url);
%%

% function saveeyeData(src,event)
% global trial_eye_data
% trial_eye_data=[trial_eye_data;event.Data];
% end
function saveeyeData(src,event)
global trial_eye_data trial_eye_timestamp
trial_eye_data=[trial_eye_data; event.Data];
trial_eye_timestamp=[trial_eye_timestamp; event.TimeStamps];
end

