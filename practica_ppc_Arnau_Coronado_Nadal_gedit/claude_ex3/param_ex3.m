% =====================================================================
% Parametros de la planta fotovoltaica y del controlador (PPC)
% EJERCICIOS 3 y 4 - Saturacion del PI, windup y anti-windup
%
% Uso:   case_id = 2;  sim('modelo_ex3')
% Si case_id no existe en el workspace, se usa el caso 1.
%
%   case_id | ejercicio | anti-windup | descripcion
%   --------+-----------+-------------+------------------------------------
%      1    |     3     |     0       | consigna 5000-10000-5000, inv. 1 y 2 nublados
%      2    |     3     |     1       | igual, con clamping anti-windup
%      3    |     4     |     0       | consigna 5000, nube global t=30..40 s
%      4    |     4     |     1       | igual, con clamping anti-windup
% =====================================================================
if ~exist('case_id','var'), case_id = 1; end

%% Tabla de casos
%          ejercicio  antiwindup
cases = [  3          0;      % caso 1
           3          1;      % caso 2
           4          0;      % caso 3
           4          1 ];    % caso 4
exercise  = cases(case_id,1);
antiwindup = cases(case_id,2);

%% Controlador (PI) - valores elegidos en el ejercicio 2
Kp = 0.5;
Ki = 1;
Ramp_rate_lim = 200;        % no se usa en estos ejercicios

%% Inversores
Pn_inv = 2000;              % Potencia nominal de cada inversor [kW]
tau_pv = 0.5;               % Constante de tiempo del inversor [s]

%% Planta fotovoltaica y comunicaciones
t_delay_com = 20e-3;        % Retraso de comunicaciones [s]
sample_time = 0.2;          % Tiempo de sampleo del PPC [s]
Ppv_nom     = 10000;        % Potencia nominal de la planta [kW]

%% Escenario: consigna del TSO, potencia disponible y tiempos
if exercise == 3
    % Consigna: 5000 kW (t=0..10 s), 10000 kW (t=10..20 s), 5000 kW (t>20 s)
    t_tso     = [0   10     20  ];            % [s]
    P_tso_vec = [5000 10000 5000];            % [kW]
    % Inversores 1 y 2 nublados todo el tiempo: capacidad real = 7000 kW
    P_disp     = [500 500 2000 2000 2000];    % [kW]
    cloud_drop = zeros(1,5);                  % sin nube temporal
    cloud_on   = 30;  cloud_off = 40;         % (no se usan)
    t_stop     = 40;                          % [s]
else
    % Ejercicio 4: consigna constante 5000 kW
    t_tso     = 0;
    P_tso_vec = 5000;
    % Todos los inversores a 2000 kW, nube global de t=30 s a t=40 s (500 kW)
    P_disp     = 2000*ones(1,5);              % [kW] disponible fuera de la nube
    cloud_on   = 30;                          % [s] llega la nube
    cloud_off  = 40;                          % [s] se va la nube
    cloud_drop = 500 - P_disp;                % [kW] variacion en cloud_on (-1500)
    t_stop     = 50;                          % [s]
end

% Parametros de los bloques Step de la consigna:
%   Step  : tiempo step_time,  valor inicial P_tso_ini, valor final P_tso_fin
%   Step1 : tiempo step2_time, valor inicial 0,         valor final step2_amp
P_tso_ini = P_tso_vec(1);
if numel(t_tso) >= 3
    step_time  = t_tso(2);
    P_tso_fin  = P_tso_vec(2);
    step2_time = t_tso(3);
    step2_amp  = P_tso_vec(3) - P_tso_vec(2);
else
    % sin cambios de consigna: los escalones no hacen nada
    step_time  = t_stop;
    P_tso_fin  = P_tso_ini;
    step2_time = t_stop;
    step2_amp  = 0;
end

% Para el ejercicio 4, la potencia disponible de cada inversor es:
%   P_disp(i)                      para t < cloud_on
%   P_disp(i) + cloud_drop(i)      para cloud_on <= t < cloud_off
%   P_disp(i)                      para t >= cloud_off
% (en el ejercicio 3 cloud_drop = 0, asi que P_disp(i) es constante)

%% Condicion inicial = regimen permanente con P_tso_ini
% alpha_0 hace que la planta entregue P_tso_ini:
%   sum_i min(alpha*Pn_inv, P_disp(i)) = P_tso_ini   (alpha limitado a 1)
if sum(min(Pn_inv, P_disp)) <= P_tso_ini
    alpha_0 = 1;
else
    lo = 0; hi = 1;
    for k = 1:60            % biseccion
        mid = (lo + hi)/2;
        if sum(min(mid*Pn_inv, P_disp)) < P_tso_ini
            lo = mid;
        else
            hi = mid;
        end
    end
    alpha_0 = (lo + hi)/2;  % ej.3: ~0.667   ej.4: 0.5
end

P_init = min(alpha_0*Pn_inv, P_disp);   % potencia inicial de cada inversor [kW]
Pppc_0 = sum(P_init);                   % potencia inicial en el PCC [kW]

rate_transition_init_val = alpha_0;
transp_delay_init_outp   = alpha_0;
transp_delay_pppc_meas   = Pppc_0;
ppc_init_value           = alpha_0*Ppv_nom;   % integrador inicial [kW]

%% Titulo de la simulacion
scopeTitle = sprintf('PPC ej. %d (caso %d): Kp = %g, Ki = %g, anti-windup = %d', ...
                     exercise, case_id, Kp, Ki, antiwindup);