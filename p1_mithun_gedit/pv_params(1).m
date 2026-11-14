%% pv_params.m - PV plant active power controller (GDTEE practica)
% Parameters and case selection for pv_plant.slx.
% The model runs this file automatically every time you press Run
% (Model Properties > Callbacks > InitFcn = pv_params).
%
% TO CHANGE THE SIMULATION: edit ONLY the line  caso = '...'  below,
% save (Ctrl+S) and press Run in Simulink.
%
%   Exercise 1 (no controller, alpha = P_TSO/Pnom), TSO 10000 -> 5000 kW at t = 10 s
%     '1.1'  all inverters 2000 kW available
%     '1.2'  inverters 1-2 partially cloudy, 1500 kW
%     '1.3'  inverters 1-2 fully cloudy, 500 kW
%   Exercise 2 (PI controller), TSO 7000 -> 5000 kW at t = 10 s
%     '2.1'  Kp = 0.5, Ki = 0
%     '2.2'  Kp = 5,   Ki = 0
%     '2.3'  Kp = 0.5, Ki = 0.1
%     '2.4'  Kp = 0.5, Ki = 1
%     '2.5'  Kp = 0.5, Ki = 10
%     '2.6'  Kp = 0.5, Ki = 1, inverters 1-2 at 500 kW
%   Exercise 5 (model pv_plant_ex5.slx, S-function ppc_sfun_bat.m): ramp max 10 % Pnom/min = 1000 kW/min
%     5a curtailment, TSO 10000 -> 5000 kW at 60 s, 600 s:  '5.1' PI only | '5.2' ramp, PV only |
%        '5.3' ramp + battery 3 MW/1 MWh (SOC0 0.5)
%     5b maximum power point, cloud 60-65 s and back 360-365 s (all inverters 2000 -> 500 kW), 900 s:
%        '5.4' ramp, PV only | '5.5' ramp + battery 8 MW/1 MWh (SOC0 0.8) | '5.6' battery 3 MW/1 MWh
%   Exercises 3-4 (model pv_plant_ex34.slx, S-function ppc_sfun_aw.m), Kp = 0.5, Ki = 1,
%   TSO 5000 -> 10000 kW (t = 10 s) -> 5000 kW (t = 20 s), inverters 1-2 at 500 kW
%     '3.1'  PI without anti-windup
%     '3.2'  PI with anti-windup (integrator clamped to [0, Pnom])
%     '4.1'  as 3.2 + cloud over the whole plant 30-40 s (all inverters 500 kW),
%            anti-windup clamp [0, Pnom]  -> problem
%     '4.2'  as 4.1 but clamp [0, alpha_util*Pnom] (alpha_util = max available/Pinv_nom)

caso = '1.1';                 % <- case used when you press Run in Simulink
if exist('caso_run', 'var') && ~isempty(caso_run)
    caso = caso_run;          % set automatically by run_ejercicios.m
end

%% Plant data (statement, slide 16)
Pinv_nom     = 2000;            % rated power of each inverter [kW]
n_inv        = 5;               % number of inverters
Ppv_nom      = n_inv*Pinv_nom;  % plant rated power [kW] (10000)
tau_pv       = 0.5;             % inverter time constant [s]
comedelay    = 20e-3;           % communication delay [s]
t_sample_ppc = 0.2;             % PPC sample time [s]
t_step       = 10;              % time of the TSO setpoint change [s]

%% Defaults (overwritten by the cases below)
aw_mode  = 0;      % anti-windup: 0 none, 1 clamp I to [0,Pnom], 2 clamp I to [0,alpha_util*Pnom]
cloud    = false;  % cloud over the whole plant between t_c0 and t_c1 (exercise 4)
t_c0     = 30;  t_c1 = 40;  P_cloud = 500;
tso_prof = [];     % TSO profile [time kW]; empty = one step at t_step
t_stop   = 40;     % simulation stop time [s]
cloud_ramp = false;% 5b: cloud over the whole plant, availability ramps 2000->500 kW in 5 s
% Exercise 5 (battery + ramp control, model pv_plant_ex5.slx, S-function ppc_sfun_bat.m)
ctrl5      = 0;           % 0 = PI on TSO (no ramp), 1 = ramp-limited reference + PV only, 2 = ramp + battery
ramp_kWmin = 0.10*Ppv_nom;% maximum ramp: 10 % of Pnom per minute [kW/min]
Pbat_max   = 0;           % battery power (charge = discharge) [kW]
E_bat      = 1000;        % battery energy [kWh]
SOC0       = 0.5;         % initial state of charge [p.u.]
SOCmin     = 0.1;  SOCmax = 0.9;  dSOC = 0.01;   % SOC limits and relay hysteresis
eta_bat    = 0.95;        % charge / discharge efficiency
tau_bat    = 0.2;         % battery response time constant [s]

%% Cases (statement, slides 17-20)
switch caso
    case '1.1'
        ppc_mode = 0; Kp = 0;   Ki = 0;   P_tso_0 = 10000; P_tso_1 = 5000;
        Pavail = [2000 2000 2000 2000 2000];
    case '1.2'
        ppc_mode = 0; Kp = 0;   Ki = 0;   P_tso_0 = 10000; P_tso_1 = 5000;
        Pavail = [1500 1500 2000 2000 2000];
    case '1.3'
        ppc_mode = 0; Kp = 0;   Ki = 0;   P_tso_0 = 10000; P_tso_1 = 5000;
        Pavail = [500 500 2000 2000 2000];
    case '2.1'
        ppc_mode = 1; Kp = 0.5; Ki = 0;   P_tso_0 = 7000;  P_tso_1 = 5000;
        Pavail = [2000 2000 2000 2000 2000];
    case '2.2'
        ppc_mode = 1; Kp = 5;   Ki = 0;   P_tso_0 = 7000;  P_tso_1 = 5000;
        Pavail = [2000 2000 2000 2000 2000];
    case '2.3'
        ppc_mode = 1; Kp = 0.5; Ki = 0.1; P_tso_0 = 7000;  P_tso_1 = 5000;
        Pavail = [2000 2000 2000 2000 2000];
    case '2.4'
        ppc_mode = 1; Kp = 0.5; Ki = 1;   P_tso_0 = 7000;  P_tso_1 = 5000;
        Pavail = [2000 2000 2000 2000 2000];
    case '2.5'
        ppc_mode = 1; Kp = 0.5; Ki = 10;  P_tso_0 = 7000;  P_tso_1 = 5000;
        Pavail = [2000 2000 2000 2000 2000];
    case '2.6'
        ppc_mode = 1; Kp = 0.5; Ki = 1;   P_tso_0 = 7000;  P_tso_1 = 5000;
        Pavail = [500 500 2000 2000 2000];
    case {'5.1','5.2','5.3'}      % 5a: curtailment 10 -> 5 MW at t = 60 s, ramp max 1000 kW/min
        ppc_mode = 1; Kp = 0.5; Ki = 1;   P_tso_0 = 10000; P_tso_1 = 5000;
        Pavail   = [2000 2000 2000 2000 2000];
        tso_prof = [0 10000; 60 5000];  t_stop = 600;  aw_mode = 2;
        switch caso
            case '5.1', ctrl5 = 0;                                     % PI only (no ramp control)
            case '5.2', ctrl5 = 1;                                     % ramp on the PV only
            case '5.3', ctrl5 = 2; Pbat_max = 3000; SOC0 = 0.5;        % ramp + battery 3 MW / 1 MWh
        end
    case {'5.4','5.5','5.6'}      % 5b: maximum power point, cloud 60-65 s (and back 360-365 s)
        ppc_mode = 1; Kp = 0.5; Ki = 1;   P_tso_0 = 10000; P_tso_1 = 10000;
        Pavail   = [2000 2000 2000 2000 2000];
        tso_prof = [0 10000; 1000 10000];  t_stop = 900;  aw_mode = 2;  cloud_ramp = true;
        switch caso
            case '5.4', ctrl5 = 1;                                     % ramp on the PV only
            case '5.5', ctrl5 = 2; Pbat_max = 8000; SOC0 = 0.8;        % battery 8 MW / 1 MWh
            case '5.6', ctrl5 = 2; Pbat_max = 3000; SOC0 = 0.8;        % battery 3 MW / 1 MWh (too small)
        end
    case {'3.1','3.2','4.1','4.2'}
        ppc_mode = 1; Kp = 0.5; Ki = 1;   P_tso_0 = 5000;  P_tso_1 = 5000;
        Pavail   = [500 500 2000 2000 2000];
        tso_prof = [0 5000; 10 10000; 20 5000];
        t_stop   = 60;
        switch caso
            case '3.1', aw_mode = 0;
            case '3.2', aw_mode = 1;
            case '4.1', aw_mode = 1; cloud = true;
            case '4.2', aw_mode = 2; cloud = true;
        end
    otherwise
        error('pv_params: unknown case "%s"', caso);
end

%% Initial steady state at t = 0 (so the simulation starts without a transient)
if ppc_mode == 0
    % no controller: alpha is simply the TSO setpoint in p.u.
    alpha0 = min(P_tso_0/Ppv_nom, 1);
else
    % PI: alpha that gives the TSO setpoint (or the maximum available power)
    target = min(P_tso_0, sum(Pavail));
    f = @(a) sum(min(a*Pinv_nom, Pavail)) - target;
    if f(1) <= 0
        alpha0 = 1;
    else
        alpha0 = fzero(f, [0 1]);
    end
end
Ppcc0 = sum(min(alpha0*Pinv_nom, Pavail));   % initial plant power [kW]
I0    = alpha0*Ppv_nom;                      % initial PI integrator [kW]

%% Profiles read by the model (From Workspace blocks, zero-order hold between points)
if isempty(tso_prof), tso_prof = [0 P_tso_0; t_step P_tso_1]; end
tso_ts = timeseries(tso_prof(:,2), tso_prof(:,1));          % TSO setpoint [kW]
Tp = [0; t_c0; t_c1; 1000];                                  % availability time points
Vp = repmat(Pavail, numel(Tp), 1);                           % one column per inverter
if cloud
    Vp(2,:) = min(Pavail, P_cloud);                          % cloud from t_c0 to t_c1
end
for kk = 1:n_inv
    eval(sprintf('Pav%d_ts = timeseries(Vp(:,kk), Tp);', kk));
end
if cloud_ramp
    Tp = [0; 60; 65; 360; 365; 1000];
    Vp = [Pavail; Pavail; min(Pavail, P_cloud); min(Pavail, P_cloud); Pavail; Pavail];
    for kk = 1:n_inv
        eval(sprintf('Pav%d_ts = timeseries(Vp(:,kk), Tp);', kk));
    end
end
Pref0 = min(P_tso_0, Ppcc0);                                 % initial ramp-limited reference [kW]
alpha_util_ts = timeseries(max(Vp, [], 2)/Pinv_nom, Tp);     % max_i Pavail_i/Pinv_nom

fprintf('pv_params: case %s | mode %d | Kp = %g, Ki = %g | TSO %g -> %g kW | Pavail = [%s] kW\n', ...
    caso, ppc_mode, Kp, Ki, P_tso_0, P_tso_1, num2str(Pavail));
fprintf('           alpha0 = %.3f | Ppcc0 = %.0f kW | I0 = %.0f kW\n', alpha0, Ppcc0, I0);
