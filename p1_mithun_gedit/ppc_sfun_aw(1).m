function ppc_sfun_aw(block)
% PPC_SFUN_AW  Power plant controller with optional anti-windup (exercises 3 and 4).
%   Level-2 MATLAB S-function, sample time Ts (0.2 s). Same PI as ppc_sfun.m plus:
%   a third input (alpha_util), three extra outputs to see the windup, and aw_mode.
%
%   Inputs : 1 = Ppcc_meas      [kW]   measured power at the PCC
%            2 = Ppcc_setpoint  [kW]   TSO curtailment setpoint
%            3 = alpha_util     [p.u.] max_i(Pavail_i)/Pinv_nom: the alpha above which
%                                       no inverter can give more power (reported by the inverters)
%   Outputs: 1 = alpha          [p.u.] setpoint sent to every inverter
%            2 = I              [kW]   integral part (integrator state)
%            3 = Ptot_unsat     [kW]   PI output before the limits  (Kp*e + I)
%            4 = Ptot_sat       [kW]   PI output limited to [0, Pnom]
%
%   Block parameters (in this order):
%       t_sample_ppc, Kp, Ki, Ppv_nom, ppc_mode, I0, aw_mode
%     ppc_mode  0 = no controller (alpha = P_TSO/Pnom)    1 = PI on the PCC power
%     aw_mode   0 = no anti-windup (the integrator keeps integrating while Ptot is limited)
%               1 = clamping: I limited to [0, Pnom]      (same limits as the PI output)
%               2 = clamping: I limited to [0, alpha_util*Pnom]  (limits of what the plant
%                   can really deliver: also covers clouds, exercise 4)
%
%   Each sample:  e = Pset - Pmeas;  I = I + Ki*Ts*e;  [clamp I];
%                 Ptot_unsat = Kp*e + I;  Ptot_sat = min(max(Ptot_unsat,0),Pnom);
%                 alpha = Ptot_sat/Pnom

setup(block);
end

%% ------------------------------------------------------------------------
function setup(block)
block.NumInputPorts  = 3;
block.NumOutputPorts = 4;

for k = 1:3
    block.InputPort(k).Dimensions        = 1;
    block.InputPort(k).DatatypeID        = 0;
    block.InputPort(k).Complexity        = 'Real';
    block.InputPort(k).DirectFeedthrough = true;
    block.InputPort(k).SamplingMode      = 'Sample';
end
for k = 1:4
    block.OutputPort(k).Dimensions   = 1;
    block.OutputPort(k).DatatypeID   = 0;
    block.OutputPort(k).Complexity   = 'Real';
    block.OutputPort(k).SamplingMode = 'Sample';
end

block.NumDialogPrms     = 7;
block.DialogPrmsTunable = {'Nontunable', 'Tunable', 'Tunable', 'Nontunable', ...
                           'Nontunable', 'Nontunable', 'Nontunable'};

Ts = block.DialogPrm(1).Data;
block.SampleTimes = [Ts 0];

block.SimStateCompliance = 'DefaultSimState';

block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
block.RegBlockMethod('InitializeConditions', @InitConditions);
block.RegBlockMethod('Outputs',              @Outputs);
block.RegBlockMethod('Update',               @Update);
end

%% ------------------------------------------------------------------------
function DoPostPropSetup(block)
block.NumDworks = 1;
block.Dwork(1).Name            = 'I';
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
Pnom = block.DialogPrm(4).Data;
mode = block.DialogPrm(5).Data;

if mode == 0
    % exercise 1: no controller
    block.OutputPort(1).Data = min(max(block.InputPort(2).Data/Pnom, 0), 1);
    block.OutputPort(2).Data = 0;
    block.OutputPort(3).Data = 0;
    block.OutputPort(4).Data = 0;
else
    [I, Pun, Psat] = pi_step(block);
    block.OutputPort(1).Data = min(max(Psat/Pnom, 0), 1);
    block.OutputPort(2).Data = I;
    block.OutputPort(3).Data = Pun;
    block.OutputPort(4).Data = Psat;
end
end

%% ------------------------------------------------------------------------
function Update(block)
if block.DialogPrm(5).Data ~= 0
    I = pi_step(block);
    block.Dwork(1).Data = I;                       % store I[k]
end
end

%% ------------------------------------------------------------------------
function [I, Pun, Psat] = pi_step(block)
% One PI step (used by Outputs and Update so both give the same numbers)
Ts   = block.DialogPrm(1).Data;
Kp   = block.DialogPrm(2).Data;
Ki   = block.DialogPrm(3).Data;
Pnom = block.DialogPrm(4).Data;
aw   = block.DialogPrm(7).Data;

Pmeas = block.InputPort(1).Data;
Pset  = block.InputPort(2).Data;
autil = min(max(block.InputPort(3).Data, 0), 1);

e = Pset - Pmeas;
I = block.Dwork(1).Data + Ki*Ts*e;
switch aw
    case 1
        I = min(max(I, 0), Pnom);
    case 2
        I = min(max(I, 0), autil*Pnom);
end
Pun  = Kp*e + I;
Psat = min(max(Pun, 0), Pnom);
end
