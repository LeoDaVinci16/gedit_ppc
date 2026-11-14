function ppc_ex3(block)
% Level-2 MATLAB S-Function: Power Plant Controller (PPC) - Ejercicio 3
% PI discreto de potencia activa con salida saturada y anti-windup opcional.
%
%   Entradas : 1) Ppcc_meas     [kW]   potencia medida en el PCC
%              2) Ppcc_setpoint [kW]   consigna del TSO
%   Salidas  : 1) alpha          [p.u.] consigna a los inversores (saturada 0..1)
%              2) e              [kW]   error Ppcc_setpoint - Ppcc_meas
%              3) I              [kW]   salida del integrador
%              4) Ptot_unsat     [kW]   salida del PI sin saturar (I + Kp*e)
%              5) Ptot_sat       [kW]   salida del PI saturada (alpha*Ppv_nom)
%   Parametros (en este orden en el bloque):
%              sample_time, Ppv_nom, Ki, Kp, Ramp_rate_lim, antiwindup
%   Estado   : Dwork(1) = salida del integrador del PI [kW]
%
%   Ley de control:
%       P_tot(k) = I(k-1) + Kp*e(k)
%       alpha(k) = sat( P_tot(k)/Ppv_nom , 0 , 1 )
%       I(k)     = I(k-1) + Ki*Ts*e(k)         (sin anti-windup)
%   Anti-windup (clamping, antiwindup = 1): no se integra si P_tot esta
%   saturado y el error empuja en la misma direccion de la saturacion.

setup(block);

%endfunction

function setup(block)
  block.NumInputPorts  = 2;
  block.NumOutputPorts = 5;

  block.SetPreCompInpPortInfoToDynamic;
  block.SetPreCompOutPortInfoToDynamic;

  for i = 1:2
    block.InputPort(i).Dimensions        = 1;
    block.InputPort(i).DatatypeID        = 0;  % double
    block.InputPort(i).Complexity        = 'Real';
    block.InputPort(i).DirectFeedthrough = true;
  end

  for i = 1:5
    block.OutputPort(i).Dimensions   = 1;
    block.OutputPort(i).DatatypeID   = 0;  % double
    block.OutputPort(i).Complexity   = 'Real';
    block.OutputPort(i).SamplingMode = 'Sample';
  end

  % Parametros: sample_time, Ppv_nom, Ki, Kp, Ramp_rate_lim, antiwindup
  block.NumDialogPrms = 6;

  block.SampleTimes = [block.DialogPrm(1).Data 0];

  block.SimStateCompliance = 'DefaultSimState';

  block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
  block.RegBlockMethod('InitializeConditions', @InitializeConditions);
  block.RegBlockMethod('Start',                @Start);
  block.RegBlockMethod('Outputs',              @Outputs);     % Required
  block.RegBlockMethod('Update',               @Update);
  block.RegBlockMethod('Derivatives',          @Derivatives);
  block.RegBlockMethod('Terminate',            @Terminate); % Required
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

  % Valor inicial del integrador [kW], calculado en param_ex3.m
  try
    I0 = evalin('base', 'ppc_init_value');
  catch
    I0 = 0.7*Ppv_nom;
    warning('ppc_ex3:init', ...
      'ppc_init_value no esta en el workspace. Uso I0 = %g kW.', I0);
  end

  block.Dwork(1).Data      = I0;
  block.OutputPort(1).Data = I0/Ppv_nom;  % alpha
  block.OutputPort(2).Data = 0;           % e
  block.OutputPort(3).Data = I0;          % integrador
  block.OutputPort(4).Data = I0;          % PI sin saturar
  block.OutputPort(5).Data = I0;          % PI saturado
  %end InitializeConditions

function Start(block)
  %end Start

function Outputs(block)
  Ppcc_meas     = block.InputPort(1).Data;  % [kW]
  Ppcc_setpoint = block.InputPort(2).Data;  % [kW]

  I       = block.Dwork(1).Data;            % integrador [kW]
  Ppv_nom = block.DialogPrm(2).Data;
  Kp      = block.DialogPrm(4).Data;

  e         = Ppcc_setpoint - Ppcc_meas;
  Ptot_un   = I + Kp*e;                     % PI sin saturar [kW]
  alpha_sat = max(0, min(1, Ptot_un/Ppv_nom));

  block.OutputPort(1).Data = alpha_sat;
  block.OutputPort(2).Data = e;
  block.OutputPort(3).Data = I;
  block.OutputPort(4).Data = Ptot_un;
  block.OutputPort(5).Data = alpha_sat*Ppv_nom;
  %end Outputs

function Update(block)
  Ppcc_meas     = block.InputPort(1).Data;
  Ppcc_setpoint = block.InputPort(2).Data;
  Ts      = block.DialogPrm(1).Data;
  Ppv_nom = block.DialogPrm(2).Data;
  Ki      = block.DialogPrm(3).Data;
  Kp      = block.DialogPrm(4).Data;
  aw      = block.DialogPrm(6).Data;

  I       = block.Dwork(1).Data;
  e       = Ppcc_setpoint - Ppcc_meas;
  Ptot_un = I + Kp*e;

  % Clamping anti-windup: congelar el integrador si el PI esta saturado
  % y el error sigue empujando hacia la saturacion
  saturando = (Ptot_un >= Ppv_nom && e > 0) || (Ptot_un <= 0 && e < 0);

  if ~(aw && saturando)
    block.Dwork(1).Data = I + Ki*Ts*e;
  end
  %end Update

function Derivatives(block)
  %end Derivatives

function Terminate(block)
  %end Terminate
