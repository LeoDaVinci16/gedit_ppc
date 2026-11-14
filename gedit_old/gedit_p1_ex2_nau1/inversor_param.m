% =====================================================================
% Parametros de la planta fotovoltaica y del controlador (PPC)
% Ejecutar este fichero antes de simular (o ponerlo en el InitFcn
% del modelo: Model Settings > Model Properties > Callbacks > InitFcn)
% =====================================================================

%% Inicialitzacio
P_init = [1400 1400 1400 1400 1400];
alpha_init = 0.5;
Ppv_setpoint_init = 0.5;
Pppc_meas_init = 7000;
Ppv_nom = 7000;            % Potencia nominal de la planta [kW]



%% Consigna del TSO (bloque Step)
step_time  = 50;             % [s]   instante del cambio de consigna
P_tso_ini = 7000;            % [kW]  consigna antes del cambio
P_tso_fin = 5000;            % [kW]  consigna despues del cambio

%% Controlador (PI)
Ki = 1;
Kp = 0.5;
Ramp_rate_lim = 200;

%% Potencia disponible de cada inversor [kW] (nubes)
P_disp = [1400 1400 2000 2000 2000];

%% Inversores
Pn_inv = 2000;              % Potencia nominal de cada inversor [kW]
tau_pv = 0.5;               % Constante de tiempo del inversor [s]


%% Planta fotovoltaica
t_delay_com = 20e-3;        % Retraso de comunicaciones [s]
sample_time = 0.2;          % Tiempo de sampleo del PPC [s]


%% Condicion inicial de los bloques Transport Delay
alpha_0   = P_tso_ini / Ppv_nom;   % alpha inicial (camino consigna)
Pppc_0    = sum(P_disp);           % potencia inicial (camino medida)