function ppc(block)
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
  % Parametres: sample_time, Ppv_nom, Ki, Kp, Ramp_rate_lim, ppc_init_value
  % Parametres: sample_time, Ppv_nom, Ki, Kp, Ramp_rate_lim, antiwindup
  block.NumDialogPrms = 6;

  % Tiempo de muestreo discreto (parametro 1)
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
  block.Dwork(1).Name            = 'variables1';
  block.Dwork(1).Dimensions      = 1;
  block.Dwork(1).DatatypeID      = 0;      % double
  block.Dwork(1).Complexity      = 'Real'; % real
  block.Dwork(1).UsedAsDiscState = true;

function InitializeConditions(block)
  %end InitializeConditions

function Start(block)
  block.Dwork(1).Data = 0;
  block.Dwork(1).Data = block.DialogPrm(6).Data;
  %end Start

function Outputs(block)
  Ppcc_meas     = block.InputPort(1).Data;  % [kW]
  Ppcc_setpoint = block.InputPort(2).Data;  % [kW]

  I       = block.Dwork(1).Data;            % integrador [kW]
  Ppv_nom = block.DialogPrm(2).Data;
  Kp      = block.DialogPrm(4).Data;

  e         = Ppcc_setpoint - Ppcc_meas;
  Piout  = I + Kp*e;                     % PI sin saturar [kW]
  alpha = Piout/Ppv_nom;                     % alpha sin saturar
  alpha_sat = max(0, min(1, alpha));         % alpha saturado

  block.OutputPort(1).Data = alpha_sat;
  block.OutputPort(2).Data = e;
  block.OutputPort(3).Data = I;
  block.OutputPort(4).Data = Piout;
  block.OutputPort(5).Data = alpha_sat*Ppv_nom;
  %end Outputs

function Update(block)
    % Integrator update at every sample instant
    Ppcc_meas     = block.InputPort(1).Data;
    Ppcc_setpoint = block.InputPort(2).Data;
    Ts      = block.DialogPrm(1).Data;
    Ppv_nom = block.DialogPrm(2).Data;
    Ki      = block.DialogPrm(3).Data;
    Kp      = block.DialogPrm(4).Data;
    
    antiwindup = 1;                 % 0 = plain PI (shows windup), 1 = anti-windup
    
    I = block.Dwork(1).Data;
    e = Ppcc_setpoint - Ppcc_meas;

    integrate = true;
    if antiwindup
        Piout  = I + Kp*e;            % PI output before saturation [kW]
        sat_hi = (Piout > Ppv_nom) && (e > 0);   % saturated high, error pushes higher
        sat_lo = (Piout < 0)       && (e < 0);   % saturated low, error pushes lower
        integrate = ~(sat_hi || sat_lo);
    end
    
    if integrate
        block.Dwork(1).Data = I + Ki*Ts*e;
    end
    %end Update

function Derivatives(block)
  %end Derivatives
function Terminate(block)
  %end Terminate

