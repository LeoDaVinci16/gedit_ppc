function ppc_ex2(block)
% Level-2 MATLAB S-Function: Power Plant Controller (PPC) - Ejercicio 2
% Controlador PI discreto de potencia activa en el PCC.
%
%   Entradas : 1) Ppcc_meas     [kW]  potencia medida en el PCC
%              2) Ppcc_setpoint [kW]  consigna del TSO
%   Salidas  : 1) alpha         [p.u.] consigna a los inversores (saturada 0..1)
%              2) e             [kW]  error Ppcc_setpoint - Ppcc_meas
%   Parametros (en este orden en el bloque):
%              sample_time, Ppv_nom, Ki, Kp, Ramp_rate_lim
%   Estado   : Dwork(1) = salida del integrador del PI [kW]
%
%   Ley de control (forma paralela):
%       P_tot(k) = I(k-1) + Kp*e(k)
%       I(k)     = I(k-1) + Ki*Ts*e(k)
%       alpha(k) = sat( P_tot(k) / Ppv_nom , 0 , 1 )

setup(block);

%endfunction

function setup(block)
  % Numero de puertos
  block.NumInputPorts  = 2;
  block.NumOutputPorts = 2;

  block.SetPreCompInpPortInfoToDynamic;
  block.SetPreCompOutPortInfoToDynamic;

  % Entradas
  block.InputPort(1).Dimensions        = 1;
  block.InputPort(1).DatatypeID        = 0;  % double
  block.InputPort(1).Complexity        = 'Real';
  block.InputPort(1).DirectFeedthrough = true;

  block.InputPort(2).Dimensions        = 1;
  block.InputPort(2).DatatypeID        = 0;  % double
  block.InputPort(2).Complexity        = 'Real';
  block.InputPort(2).DirectFeedthrough = true;

  % Salidas
  block.OutputPort(1).Dimensions   = 1;
  block.OutputPort(1).DatatypeID   = 0;  % double
  block.OutputPort(1).Complexity   = 'Real';
  block.OutputPort(1).SamplingMode = 'Sample';

  block.OutputPort(2).Dimensions   = 1;
  block.OutputPort(2).DatatypeID   = 0;  % double
  block.OutputPort(2).Complexity   = 'Real';
  block.OutputPort(2).SamplingMode = 'Sample';

  % Parametros: sample_time, Ppv_nom, Ki, Kp, Ramp_rate_lim
  block.NumDialogPrms = 5;

  % Tiempo de muestreo discreto (parametro 1)
  block.SampleTimes = [block.DialogPrm(1).Data 0];

  block.SimStateCompliance = 'DefaultSimState';

  block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
  block.RegBlockMethod('InitializeConditions', @InitializeConditions);
  block.RegBlockMethod('Start',                @Start);
  block.RegBlockMethod('Outputs',              @Outputs);      % Required
  block.RegBlockMethod('Update',               @Update);
  block.RegBlockMethod('Derivatives',          @Derivatives);
  block.RegBlockMethod('Terminate',            @Terminate);    % Required
  %end setup

function DoPostPropSetup(block)
  block.NumDworks = 1;

  block.Dwork(1).Name            = 'variables1';  % integrador del PI [kW]
  block.Dwork(1).Dimensions      = 1;
  block.Dwork(1).DatatypeID      = 0;             % double
  block.Dwork(1).Complexity      = 'Real';
  block.Dwork(1).UsedAsDiscState = true;

function InitializeConditions(block)
  Ppv_nom = block.DialogPrm(2).Data;

  % Valor inicial del integrador [kW]: lo calcula param_ex2.m (ppc_init_value)
  % para que el modelo empiece en regimen permanente con P_tso_ini.
  try
    I0 = evalin('base', 'ppc_init_value');
  catch
    I0 = 0.7*Ppv_nom;
    warning('ppc_ex2:init', ...
      'ppc_init_value no esta en el workspace. Uso I0 = %g kW.', I0);
  end

  block.Dwork(1).Data      = I0;           % integrador [kW]
  block.OutputPort(1).Data = I0/Ppv_nom;   % alpha inicial [p.u.]
  block.OutputPort(2).Data = 0;            % error inicial
  %end InitializeConditions

function Start(block)
  %end Start

function Outputs(block)
  % Entradas
  Ppcc_meas     = block.InputPort(1).Data;  % P medida en el PCC [kW]
  Ppcc_setpoint = block.InputPort(2).Data;  % consigna del TSO [kW]

  % Estado y parametros
  PI_integrador_out = block.Dwork(1).Data;  % salida del integrador [kW]
  Ppv_nom = block.DialogPrm(2).Data;        % P nominal de la planta [kW]
  Kp      = block.DialogPrm(4).Data;        % Kp del PI
  % Ramp_rate_lim = block.DialogPrm(5).Data; % no se usa en el ejercicio 2

  % PI: la parte integral se actualiza en Update
  e      = Ppcc_setpoint - Ppcc_meas;       % error [kW]
  kp_out = Kp*e;
  Piout  = PI_integrador_out + kp_out;      % P_tot [kW]

  alpha     = Piout/Ppv_nom;                % consigna en p.u. (sin saturar)
  alpha_sat = max(0, min(1, alpha));        % saturada entre 0 y 1

  block.OutputPort(1).Data = alpha_sat;
  block.OutputPort(2).Data = e;
  %end Outputs

function Update(block)
  % Actualizacion del integrador en cada instante de muestreo
  Ppcc_meas     = block.InputPort(1).Data;
  Ppcc_setpoint = block.InputPort(2).Data;
  Ts = block.DialogPrm(1).Data;
  Ki = block.DialogPrm(3).Data;

  e = Ppcc_setpoint - Ppcc_meas;
  block.Dwork(1).Data = block.Dwork(1).Data + Ki*Ts*e;
  %end Update

function Derivatives(block)
  %end Derivatives

function Terminate(block)
  %end Terminate