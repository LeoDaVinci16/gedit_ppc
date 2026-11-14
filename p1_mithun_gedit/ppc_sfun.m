function ppc_sfun(block)
% PPC_SFUN  Power plant controller (PPC) as a Level-2 MATLAB S-function.
%   Executes every Ts seconds (0.2 s in the practica).
%
%   Inputs : 1 = Ppcc_meas      [kW]  measured power at the PCC
%            2 = Ppcc_setpoint  [kW]  TSO curtailment setpoint
%   Output : 1 = alpha          [p.u.] setpoint sent to every inverter
%
%   Block parameters (in this order):
%       t_sample_ppc, Kp, Ki, Ppv_nom, ppc_mode, I0
%     1 Ts    sample time [s]
%     2 Kp    proportional gain [-]
%     3 Ki    integral gain [1/s]
%     4 Pnom  plant rated power [kW]
%     5 mode  0 = no controller: alpha = Ppcc_setpoint/Pnom     (exercise 1)
%             1 = PI controller on the PCC power                (exercise 2)
%     6 I0    initial value of the integral part [kW]
%
%   PI controller (positional form, output limited to [0, Pnom]):
%       e     = Ppcc_setpoint - Ppcc_meas          [kW]
%       I     = I + Ki*Ts*e                        integral part
%       Ptot  = Kp*e + I                           PI output (not limited)
%       Ptot  = min(max(Ptot, 0), Pnom)            PI output (limited)
%       alpha = Ptot/Pnom
%   The integral part has no anti-windup: it keeps integrating even when
%   the output is limited (this is what exercise 3 investigates).

setup(block);
end

%% ------------------------------------------------------------------------
function setup(block)
block.NumInputPorts  = 2;
block.NumOutputPorts = 1;

for k = 1:2
    block.InputPort(k).Dimensions        = 1;
    block.InputPort(k).DatatypeID        = 0;      % double
    block.InputPort(k).Complexity        = 'Real';
    block.InputPort(k).DirectFeedthrough = true;
    block.InputPort(k).SamplingMode      = 'Sample';
end

block.OutputPort(1).Dimensions   = 1;
block.OutputPort(1).DatatypeID   = 0;
block.OutputPort(1).Complexity   = 'Real';
block.OutputPort(1).SamplingMode = 'Sample';

block.NumDialogPrms     = 6;
block.DialogPrmsTunable = {'Nontunable', 'Tunable', 'Tunable', ...
                           'Nontunable', 'Nontunable', 'Nontunable'};

Ts = block.DialogPrm(1).Data;
block.SampleTimes = [Ts 0];                        % discrete, period Ts

block.SimStateCompliance = 'DefaultSimState';

block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
block.RegBlockMethod('InitializeConditions', @InitConditions);
block.RegBlockMethod('Outputs',              @Outputs);
block.RegBlockMethod('Update',               @Update);
end

%% ------------------------------------------------------------------------
function DoPostPropSetup(block)
block.NumDworks = 1;

block.Dwork(1).Name            = 'I';              % integral part [kW]
block.Dwork(1).Dimensions      = 1;
block.Dwork(1).DatatypeID      = 0;
block.Dwork(1).Complexity      = 'Real';
block.Dwork(1).UsedAsDiscState = true;
end

%% ------------------------------------------------------------------------
function InitConditions(block)
block.Dwork(1).Data = block.DialogPrm(6).Data;     % I0
end

%% ------------------------------------------------------------------------
function Outputs(block)
Ts   = block.DialogPrm(1).Data;
Kp   = block.DialogPrm(2).Data;
Ki   = block.DialogPrm(3).Data;
Pnom = block.DialogPrm(4).Data;
mode = block.DialogPrm(5).Data;

Pmeas = block.InputPort(1).Data;
Pset  = block.InputPort(2).Data;

if mode == 0
    % Exercise 1: no controller, the TSO setpoint goes straight to the inverters
    alpha = Pset/Pnom;
else
    % Exercise 2: PI controller
    e     = Pset - Pmeas;
    I     = block.Dwork(1).Data + Ki*Ts*e;
    Ptot  = Kp*e + I;
    Ptot  = min(max(Ptot, 0), Pnom);
    alpha = Ptot/Pnom;
end

block.OutputPort(1).Data = min(max(alpha, 0), 1);
end

%% ------------------------------------------------------------------------
function Update(block)
Ts   = block.DialogPrm(1).Data;
Ki   = block.DialogPrm(3).Data;
mode = block.DialogPrm(5).Data;

if mode ~= 0
    e = block.InputPort(2).Data - block.InputPort(1).Data;
    block.Dwork(1).Data = block.Dwork(1).Data + Ki*Ts*e;   % store I[k]
end
end
