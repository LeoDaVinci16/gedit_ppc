% =====================================================================
% Parametros de la planta fotovoltaica y del controlador (PPC)
% EJERCICIO 2 - se elige el caso con case_id (1..6)
%
% Uso:   case_id = 4;  sim('nombre_del_modelo')
% Si case_id no existe en el workspace, se usa el caso 4 por defecto.
% Este fichero se ejecuta desde el InitFcn del modelo.
% =====================================================================
if ~exist('case_id','var'), case_id = 4; end

%% Tabla de casos (enunciado, diapositiva 18)
%          Kp     Ki    P_disp inv. 1 y 2 [kW]
cases = [  0.5    0     2000;     % caso 1
    5      0     2000;     % caso 2
    0.5    0.1   2000;     % caso 3
    0.5    1     2000;     % caso 4
    0.5    10    2000;     % caso 5
    0.5    1     500  ];   % caso 6 (inversores 1 y 2 nublados)

%% Controlador (PI)
Kp       = cases(case_id,1);
Ki       = cases(case_id,2);
Pdisp_12 = cases(case_id,3);
Ramp_rate_lim = 200;        % no se usa en el ejercicio 2

%% Inversores
Pn_inv = 2000;              % Potencia nominal de cada inversor [kW]
tau_pv = 0.5;               % Constante de tiempo del inversor [s]

%% Potencia disponible de cada inversor [kW]
P_disp = [Pdisp_12 Pdisp_12 2000 2000 2000];

%% Planta fotovoltaica y comunicaciones
t_delay_com = 20e-3;        % Retraso de comunicaciones [s]
sample_time = 0.2;          % Tiempo de sampleo del PPC [s]
Ppv_nom     = 10000;        % Potencia nominal de la planta [kW]

%% Consigna del TSO
step_time = 10;             % [s] instante del cambio de consigna
P_tso_ini = 7000;           % [kW] consigna antes del cambio
P_tso_fin = 5000;           % [kW] consigna despues del cambio

%% Condicion inicial = regimen permanente con P_tso_ini
% alpha_0 es el valor de alpha que hace que la planta entregue P_tso_ini:
%   sum_i min(alpha*Pn_inv, P_disp(i)) = P_tso_ini   (alpha limitado a 1)
if sum(min(Pn_inv, P_disp)) <= P_tso_ini
    alpha_0 = 1;            % la planta no llega a la consigna
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
    alpha_0 = (lo + hi)/2;
end

P_init = min(alpha_0*Pn_inv, P_disp);   % potencia inicial de cada inversor [kW]
Pppc_0 = sum(P_init);                   % potencia inicial en el PCC [kW]

% Valores que usa el modelo
rate_transition_init_val = alpha_0;     % Rate Transition
transp_delay_init_outp   = alpha_0;     % Transport Delay de alpha
transp_delay_pppc_meas   = Pppc_0;      % Transport Delay de la medida
ppc_init_value           = alpha_0*Ppv_nom;  % integrador inicial del PI [kW]
% (usar en InitializeConditions)

%% Titulo de la simulacion
scopeTitle = sprintf('PPC (cas %d): Kp = %g, Ki = %g, P_{disp,1-2} = %g kW', ...
    case_id, Kp, Ki, Pdisp_12);