% Run ONCE. Adds To Workspace blocks to the model so every run logs the signals
% you want, sampled every 10 ms (same time vector for all of them).
mdl = 'inversor';
load_system(mdl)

% --- signals taken from the PPC S-function outputs (ports 1..5)
blk = find_system(mdl, 'SearchDepth', 1, 'BlockType', 'M-S-Function');
ph  = get_param(blk{1}, 'PortHandles');
ppc_names = {'alpha_ppc','error_kW','I_kW','Piout_kW','Piout_sat_kW'};

% --- signals taken from the Goto tags already in the model
tags = {'Pppc','Pppc_meas','Pppc_setpoint'};

x0 = 1100; y0 = 50; dy = 45; n = 0;

for k = 1:numel(ppc_names)
    n = n + 1; y = y0 + n*dy;
    ws = add_block('simulink/Sinks/To Workspace', [mdl '/log_' ppc_names{k}], ...
        'VariableName', ppc_names{k}, 'SaveFormat', 'Timeseries', ...
        'SampleTime', '0.01', 'MaxDataPoints', 'inf', ...
        'Position', [x0 y x0+80 y+30]);
    wph = get_param(ws, 'PortHandles');
    add_line(mdl, ph.Outport(k), wph.Inport(1));
end

for k = 1:numel(tags)
    n = n + 1; y = y0 + n*dy;
    fr = add_block('simulink/Signal Routing/From', [mdl '/log_from_' tags{k}], ...
        'GotoTag', tags{k}, 'Position', [x0-150 y x0-80 y+30]);
    ws = add_block('simulink/Sinks/To Workspace', [mdl '/log_' tags{k}], ...
        'VariableName', tags{k}, 'SaveFormat', 'Timeseries', ...
        'SampleTime', '0.01', 'MaxDataPoints', 'inf', ...
        'Position', [x0 y x0+80 y+30]);
    add_line(mdl, get_param(fr,'PortHandles').Outport(1), ...
        get_param(ws,'PortHandles').Inport(1));
end

save_system(mdl)
disp('Logging blocks added.')