% Run this as a SCRIPT (not a function) so the variables live in the base workspace.
mdl        = 'inversor';
param_file = 'parametres.m';     % <-- name of your parameter file
cases      = 1:6;                    % case_id values to run (slide 18 table)
stop_time  = '40';                   % [s]
outdir     = 'resultados';
if ~exist(outdir, 'dir'), mkdir(outdir); end

names = {'Pppc','Pppc_meas','Pppc_setpoint', ...
    'alpha_ppc','error_kW','I_kW','Piout_kW','Piout_sat_kW'};

for c = cases
    case_id = c;                     % read by the parameter file
    run(param_file);
    out = sim(mdl, 'StopTime', stop_time);

    T = table(out.(names{1}).Time(:), 'VariableNames', {'time_s'});
    for k = 1:numel(names)
        T.(names{k}) = out.(names{k}).Data(:);
    end
    f = fullfile(outdir, sprintf('case%d.csv', c));
    writetable(T, f);
    fprintf('Saved %s  (%d rows)\n', f, height(T));
end