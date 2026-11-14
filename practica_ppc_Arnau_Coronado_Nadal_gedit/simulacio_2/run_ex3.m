% Run as a SCRIPT. Exercise 3: TSO 5000 -> 10000 (t=10 s) -> 5000 (t=20 s),
% inverters 1-2 clouded (500 kW). Runs plain PI and PI with anti-windup.
mdl        = 'inversor';
param_file = 'inversor_param.m';
stop_time  = '50';                   % [s] (plain PI needs ~40 s to recover)
outdir     = 'resultados';
if ~exist(outdir, 'dir'), mkdir(outdir); end

names = {'Pppc','Pppc_meas','Pppc_setpoint', ...
         'alpha_ppc','error_kW','I_kW','Piout_kW','Piout_sat_kW'};
labels = {'noAW','AW'};

escenario = 'ex3';
for aw = [0 1]
    antiwindup = aw;                 % read by the parameter file and the PPC block
    run(param_file);
    out = sim(mdl, 'StopTime', stop_time);

    T = table(out.(names{1}).Time(:), 'VariableNames', {'time_s'});
    for k = 1:numel(names)
        T.(names{k}) = out.(names{k}).Data(:);
    end
    f = fullfile(outdir, sprintf('ex3_%s.csv', labels{aw+1}));
    writetable(T, f);
    fprintf('Saved %s  (%d rows)\n', f, height(T));
end
escenario = 'ex2'; antiwindup = 0;   % leave the workspace ready for run_cases.m
