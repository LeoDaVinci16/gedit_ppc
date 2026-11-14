
% =====================================================================
% Parametros de la planta fotovoltaica y del controlador (PPC)
% Ejecutar antes de simular
% =====================================================================

if ~exist('case_id','var')
    case_id = 1;
end

%% Tabla de casos
%          Kp     Ki    P_disp inv. 1 y 2 [kW]
cases = [  0.5    1     500;     % Caso no-AW
           0.5    1     500 ];   % Caso Anti-Windup

%% Controlador PI
Kp = cases(case_id,1);
Ki = cases(case_id,2);
Pdisp_12 = cases(case_id,3);

Ramp_rate_lim = 200;

%% Inversores
Pn_inv = 2000;       % Potencia nominal [kW]
tau_pv = 0.5;        % Constante de tiempo [s]

%% Potencia disponible inicial [kW]
% Condiciones iniciales del ejercicio 3
P_disp = [Pdisp_12 Pdisp_12 2000 2000 2000];

%% Planta fotovoltaica y comunicaciones
t_delay_com = 20e-3;
sample_time = 0.2;
Ppv_nom = 10000;

%% Consigna TSO
step_time = 10;
P_tso_ini = 5000;
P_tso_fin = 5000;

%% Condiciones iniciales: regimen permanente
if sum(min(Pn_inv, P_disp)) <= P_tso_ini
    alpha_0 = 1;
else
    lo = 0;
    hi = 1;

    for k = 1:60
        mid = (lo + hi)/2;

        if sum(min(mid*Pn_inv, P_disp)) < P_tso_ini
            lo = mid;
        else
            hi = mid;
        end
    end

    alpha_0 = (lo + hi)/2;
end

P_init = min(alpha_0*Pn_inv, P_disp);
Pppc_0 = sum(P_init);

%% Initial values used by Simulink
rate_transition_init_val = alpha_0;
transp_delay_init_outp = alpha_0;
transp_delay_pppc_meas = Pppc_0;
ppc_init_value = alpha_0*Ppv_nom;

%% Simulation title
scopeTitle = sprintf( ...
    'PPC (cas %d): Kp = %g, Ki = %g, P_{disp,1-2} = %g kW', ...
    case_id, Kp, Ki, Pdisp_12);

%% Exercise 4: Dynamic available power
% Cloud covers the entire PV plant at t = 30 s
% Cloud disappears at t = 40 s

t_cloud_on = 30;
t_cloud_off = 40;
P_cloud = 500;

% Time vector
Tp = [0; t_cloud_on; t_cloud_off; 1000];

% Available power profile for each inverter
% Rows correspond to time; columns correspond to inverters

Pav_values = repmat(P_disp, numel(Tp), 1);

% At t = 30 s: all inverters limited to 500 kW
Pav_values(2,:) = P_cloud;

% At t = 40 s: all inverters recover to 2000 kW
Pav_values(3,:) = 2000;

% Create individual timeseries
Pav = cell(1,5);

for k = 1:5
    Pav{k} = timeseries(Pav_values(:,k), Tp);
    setinterpmethod(Pav{k}, 'zoh');
end

% =====================================================================
% End of parameters
% =====================================================================
