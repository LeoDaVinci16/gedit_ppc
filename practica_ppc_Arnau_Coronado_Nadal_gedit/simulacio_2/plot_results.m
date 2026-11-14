% Plots from the CSV files in 'resultados'. Run as a script.
outdir = 'resultados';

%% --- Exercise 3: plain PI vs PI with anti-windup -----------------------
A = readtable(fullfile(outdir,'ex3_noAW.csv'));
B = readtable(fullfile(outdir,'ex3_AW.csv'));

figure('Name','Ex3','Position',[100 100 900 750]);
tl = tiledlayout(3,1,'TileSpacing','compact');

nexttile
plot(A.time_s, A.Pppc_setpoint, 'k--', 'DisplayName','TSO setpoint'); hold on
plot(A.time_s, A.Pppc, 'DisplayName','Plant, plain PI')
plot(B.time_s, B.Pppc, 'DisplayName','Plant, anti-windup')
ylabel('Power [kW]'); legend('Location','best'); grid on

nexttile
plot(A.time_s, A.I_kW, 'DisplayName','Plain PI'); hold on
plot(B.time_s, B.I_kW, 'DisplayName','Anti-windup')
ylabel('Integrator [kW]'); legend('Location','best'); grid on

nexttile
plot(A.time_s, A.Piout_kW, 'DisplayName','PI not saturated'); hold on
plot(A.time_s, A.Piout_sat_kW, 'DisplayName','PI saturated')
ylabel('Plain PI [kW]'); legend('Location','best'); grid on
xlabel(tl,'t [s]')
title(tl,'Exercise 3: effect of the anti-windup')

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