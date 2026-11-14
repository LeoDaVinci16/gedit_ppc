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

  % Parameters: sample_time, Ppv_nom, Ki, Kp, Ramp_rate_lim, ppc_init_value, antiwindup
  block.NumDialogPrms = 7;

  % Discrete sample time (parameter 1)
  block.SampleTimes = [block.DialogPrm(1).Data 0];

  block.SimStateCompliance = 'DefaultSimState';

  block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
  block.RegBlockMethod('InitializeConditions', @InitializeConditions);
  block.RegBlockMethod('Start',                @Start);
  block.RegBlockMethod('Outputs',              @Outputs);     % Required
  block.RegBlockMethod('Update',               @Update);
  block.RegBlockMethod('Derivatives',          @Derivatives);
  block.RegBlockMethod('Terminate',            @Terminate);   % Required
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
  block.Dwork(1).Data = block.DialogPrm(6).Data;   % ppc_init_value [kW]
  %end Start

function Outputs(block)
  Ppcc_meas     = block.InputPort(1).Data;  % [kW]
  Ppcc_setpoint = block.InputPort(2).Data;  % [kW]

  I       = block.Dwork(1).Data;            % integrator [kW]
  Ppv_nom = block.DialogPrm(2).Data;
  Kp      = block.DialogPrm(4).Data;

  e         = Ppcc_setpoint - Ppcc_meas;
  Piout     = I + Kp*e;                     % PI not saturated [kW]
  alpha     = Piout/Ppv_nom;                % alpha not saturated
  alpha_sat = max(0, min(1, alpha));        % alpha saturated

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
  Ts          = block.DialogPrm(1).Data;
  Ppv_nom     = block.DialogPrm(2).Data;
  Ki          = block.DialogPrm(3).Data;
  Kp          = block.DialogPrm(4).Data;
  antiwindup  = block.DialogPrm(7).Data;    % 0 = plain PI, 1 = conditional integration

  I = block.Dwork(1).Data;
  e = Ppcc_setpoint - Ppcc_meas;

  integrate = true;
  if antiwindup ~= 0
    Piout  = I + Kp*e;
    sat_hi = (Piout > Ppv_nom) && (e > 0);  % saturated high and error pushes higher
    sat_lo = (Piout < 0)       && (e < 0);  % saturated low and error pushes lower
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
