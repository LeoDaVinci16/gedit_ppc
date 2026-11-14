% Plots from the CSV files in 'resultados'. Run as a script.
outdir = 'resultados';

%% --- Exercise 2: all six cases on one figure ---------------------------
figure('Name','Ex2','Position',[150 150 900 600]);
kp = [0.5 5 0.5 0.5 0.5 0.5];  ki = [0 0 0.1 1 10 1];  pd = [2000 2000 2000 2000 2000 500];
for c = 1:6
    f = fullfile(outdir, sprintf('case%d.csv',c));
    if ~isfile(f), continue, end
    T = readtable(f);
    subplot(2,3,c)
    plot(T.time_s, T.Pppc_setpoint, 'k--'); hold on
    plot(T.time_s, T.Pppc)
    title(sprintf('Case %d: Kp=%g, Ki=%g, P_{1,2}=%g kW', c, kp(c), ki(c), pd(c)), 'FontSize',8)
    xlabel('t [s]'); ylabel('P [kW]'); grid on
end
