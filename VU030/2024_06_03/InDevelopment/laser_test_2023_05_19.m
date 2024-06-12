WaveInitDaq030;
%%
turn_off_analog_output(AO);
ao_mod_params = struct;
ao_mod_params.mod_type = 'square'; % Modulation function
ao_mod_params.freq = 2; % Modulation frequncy (Hz)
ao_mod_params.amp = 1.3; % Modulation voltage (V, 0 to max)
ao_mod_params.T = 5; % Laser on duration (second)
%%
turn_off_analog_output(AO); 
queue_analog_output(AO, ao_mod_params);
%%
startBackground(AO)
%%
turn_off_analog_output(AO); 