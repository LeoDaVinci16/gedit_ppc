% =====================================================================
% Parametros de la planta fotovoltaica y del controlador (PPC)
% Ejecutar este fichero antes de simular (o ponerlo en el InitFcn
% del modelo: Model Settings > Model Properties > Callbacks > InitFcn)
% =====================================================================

%% Inversores
Pn_inv = 2000;              % Potencia nominal de cada inversor [kW]
tau_pv = 0.5;               % Constante de tiempo del inversor [s]

%% Potencia disponible de cada inversor [kW] (nubes)
% Caso 1 (despejado):              [2000 2000 2000 2000 2000]
% Caso 2 (inversores 1-2 a 1500):  [1500 1500 2000 2000 2000]
% Caso 3 (inversores 1-2 a 500):   [500  500  2000 2000 2000]
P_disp = [2000 2000 2000 2000 2000];

%% Planta fotovoltaica
t_delay_com = 20e-3;        % Retraso de comunicaciones [s]
sample_time = 0.2;          % Tiempo de sampleo del PPC [s]
Ppv_nom = 10000;            % Potencia nominal de la planta [kW]

%% Controlador (PI)
Ki = 0;
Kp = 0;
Ramp_rate_lim = 200;

%% Consigna del TSO (bloque Step)
step_time  = 10;             % [s]   instante del cambio de consigna
P_tso_ini = 10000;           % [kW]  consigna antes del cambio
P_tso_fin = 5000;            % [kW]  consigna despues del cambio



%% Condicion inicial de los bloques Transport Delay
alpha_0   = P_tso_ini / Ppv_nom;   % alpha inicial (camino consigna)
Pppc_0    = sum(P_disp);           % potencia inicial (camino medida)
Pppc_meas = 10000;
