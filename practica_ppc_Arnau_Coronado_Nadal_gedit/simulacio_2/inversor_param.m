% =====================================================================
% Parametros de la planta fotovoltaica y del controlador (PPC)
% Ejecutar este fichero antes de simular (o ponerlo en el InitFcn
% del modelo: Model Settings > Model Properties > Callbacks > InitFcn)
% =====================================================================
if ~exist('escenario','var'),  escenario  = 'ex2'; end   % 'ex2' | 'ex3'
if ~exist('case_id','var'),    case_id    = 1;     end   % solo para ex2
if ~exist('antiwindup','var'), antiwindup = 0;     end   % 0 = PI normal, 1 = anti-windup

%% Inversores y planta
Pn_inv = 2000;              % Potencia nominal de cada inversor [kW]
tau_pv = 0.5;               % Constante de tiempo del inversor [s]
t_delay_com = 20e-3;        % Retraso de comunicaciones [s]
sample_time = 0.2;          % Tiempo de sampleo del PPC [s]
Ppv_nom     = 10000;        % Potencia nominal de la planta [kW]
Ramp_rate_lim = 200;        % no se usa en los ejercicios 2-3

%% Escenario
switch escenario
    case 'ex2'
        % Tabla de casos (enunciado, diapositiva 18)
        %          Kp     Ki    P_disp inv. 1 y 2 [kW]
        cases = [  0.5    0     2000;     % caso 1
            5      0     2000;     % caso 2
            0.5    0.1   2000;     % caso 3
            0.5    1     2000;     % caso 4
            0.5    10    2000;     % caso 5
            0.5    1     500  ];   % caso 6
        Kp = cases(case_id,1);  Ki = cases(case_id,2);  Pdisp_12 = cases(case_id,3);
        P_disp = [Pdisp_12 Pdisp_12 2000 2000 2000];
        % Consigna TSO: P_tso_ini -> P_tso_fin en step_time (+ delta2 en step_time2)
        step_time = 10;  P_tso_ini = 7000;  P_tso_fin = 5000;
        step_time2 = 20; P_tso_delta2 = 0;                 % sin segundo escalon

    case 'ex3'
        Kp = 0.5;  Ki = 1;                                 % mismos valores que el caso 4
        Pdisp_12 = 500;
        P_disp = [500 500 2000 2000 2000];                 % inversores 1 y 2 nublados
        % 5000 kW -> 10000 kW (t=10 s) -> 5000 kW (t=20 s)
        step_time = 10;  P_tso_ini = 5000;  P_tso_fin = 10000;
        step_time2 = 20; P_tso_delta2 = 5000 - 10000;      % segundo escalon: -5000 kW
end

%% Condicion inicial = regimen permanente con P_tso_ini
% alpha_0 hace que la planta entregue P_tso_ini:
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

%% Titulo de la simulacion
scopeTitle = sprintf('PPC (%s, cas %d, AW=%d): Kp = %g, Ki = %g, P_{disp,1-2} = %g kW', ...
    escenario, case_id, antiwindup, Kp, Ki, Pdisp_12);