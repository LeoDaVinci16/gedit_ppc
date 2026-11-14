% Run ONCE. Adds a second Step (Step2) and an Add block so the TSO setpoint can change twice:
%   P_tso = Step(step_time: P_tso_ini -> P_tso_fin) + Step2(step_time2: 0 -> P_tso_delta2)
% In exercise 2 P_tso_delta2 = 0, so Step2 does nothing.
mdl = 'inversor';
load_system(mdl)

s1  = [mdl '/Step'];
ph1 = get_param(s1, 'PortHandles');
ln  = get_param(ph1.Outport(1), 'Line');
dst = get_param(ln, 'DstPortHandle');      % inport of the Goto (Pppc_setpoint)
delete_line(ln)

pos = get_param(s1, 'Position');           % [left top right bottom]
s2  = add_block(s1, [mdl '/Step2'], 'Position', pos + [0 70 0 70]);   % copy of Step
dp   = fieldnames(get_param(s1, 'DialogParameters'));
pre  = intersect(dp, {'Before','InitialValue'});    % name depends on release
post = intersect(dp, {'After','FinalValue'});
set_param(s2, 'Time', 'step_time2', pre{1}, '0', post{1}, 'P_tso_delta2');

sm = add_block('simulink/Math Operations/Add', [mdl '/Add_tso'], 'Inputs', '++', ...
               'Position', [pos(3)+40 pos(2)+10 pos(3)+70 pos(2)+60]);

phs = get_param(sm, 'PortHandles');
add_line(mdl, ph1.Outport(1), phs.Inport(1));
add_line(mdl, get_param(s2,'PortHandles').Outport(1), phs.Inport(2));
add_line(mdl, phs.Outport(1), dst);

save_system(mdl)
disp('Second TSO step added.')
