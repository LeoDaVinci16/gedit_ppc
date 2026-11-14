function ppc_sfun_bat(block)
% PPC_SFUN_BAT  Power plant controller with ramp limitation and battery (exercise 5).
%   Level-2 MATLAB S-function, sample time Ts (0.2 s).
%
%   Inputs : 1 = Ppcc_meas      [kW]   measured power at the PCC (PV + battery)
%            2 = Ppcc_setpoint  [kW]   TSO curtailment setpoint
%            3 = alpha_util     [p.u.] max_i(Pavail_i)/Pinv_nom (reported by the inverters)
%            4 = Ppv_meas       [kW]   measured PV plant power
%            5 = SOC            [p.u.] battery state of charge
%   Outputs: 1 = alpha          [p.u.] setpoint sent to every PV inverter
%            2 = Pbat_ref       [kW]   battery power reference (+ discharge, - charge)
%            3 = I              [kW]   integral part of the PV PI
%            4 = P_ref          [kW]   ramp-limited reference for the PCC power
%            5 = Ppv_set        [kW]   setpoint of the PV PI
%
%   Block parameters (in this order):
%       t_sample_ppc, Kp, Ki, Ppv_nom, ctrl5, I0, Pref0, ramp_kWmin, Pbat_max, SOCmin, SOCmax
%     ctrl5  0 = PI on the TSO setpoint, no ramp control (as exercise 2)
%            1 = ramp-limited reference P_ref, PV only follows it (PV PI)
%            2 = ramp-limited reference P_ref, battery fills the gap  Pbat* = P_ref - Ppv
%                (limited by Pbat_max and the SOC limits) and the PV is allowed to produce
%                P_ref + (charge power available), so less PV energy is curtailed.
%
%   Reference:  target = P_TSO if the PV is curtailed (alpha < alpha_util), otherwise (PV at its
%               maximum power point) min(P_TSO, Ppv).  P_ref moves towards target at most
%               ramp_kWmin/60 kW per second (up and down).
%   PV PI:      e = Ppv_set - Ppv_meas; I = clamp(I + Ki*Ts*e, 0, alpha_util*Pnom);
%               alpha = clamp(Kp*e + I, 0, Pnom)/Pnom.

setup(block);
end

%% ------------------------------------------------------------------------
function setup(block)
block.NumInputPorts  = 5;
block.NumOutputPorts = 5;
for k = 1:5
    block.InputPort(k).Dimensions        = 1;
    block.InputPort(k).DatatypeID        = 0;
    block.InputPort(k).Complexity        = 'Real';
    block.InputPort(k).DirectFeedthrough = true;
    block.InputPort(k).SamplingMode      = 'Sample';
    block.OutputPort(k).Dimensions       = 1;
    block.OutputPort(k).DatatypeID       = 0;
    block.OutputPort(k).Complexity       = 'Real';
    block.OutputPort(k).SamplingMode     = 'Sample';
end
block.NumDialogPrms     = 11;
block.DialogPrmsTunable = repmat({'Nontunable'}, 1, 11);
block.SampleTimes       = [block.DialogPrm(1).Data 0];
block.SimStateCompliance = 'DefaultSimState';
block.RegBlockMethod('PostPropagationSetup', @DoPostPropSetup);
block.RegBlockMethod('InitializeConditions', @InitConditions);
block.RegBlockMethod('Outputs',              @Outputs);
block.RegBlockMethod('Update',               @Update);
end

%% ------------------------------------------------------------------------
function DoPostPropSetup(block)
block.NumDworks = 3;
names = {'I', 'Pref', 'alpha_prev'};
for k = 1:3
    block.Dwork(k).Name            = names{k};
    block.Dwork(k).Dimensions      = 1;
    block.Dwork(k).DatatypeID      = 0;
    block.Dwork(k).Complexity      = 'Real';
    block.Dwork(k).UsedAsDiscState = true;
end
end

%% ------------------------------------------------------------------------
function InitConditions(block)
Pnom = block.DialogPrm(4).Data;
I0   = block.DialogPrm(6).Data;
block.Dwork(1).Data = I0;                 % integral part
block.Dwork(2).Data = block.DialogPrm(7).Data;   % P_ref
block.Dwork(3).Data = I0/Pnom;            % alpha of the previous sample
end

%% ------------------------------------------------------------------------
function Outputs(block)
s = ctrl_step(block);
block.OutputPort(1).Data = s.alpha;
block.OutputPort(2).Data = s.pbref;
block.OutputPort(3).Data = s.I;
block.OutputPort(4).Data = s.Pref;
block.OutputPort(5).Data = s.ppvset;
end

%% ------------------------------------------------------------------------
function Update(block)
s = ctrl_step(block);
block.Dwork(1).Data = s.I;
block.Dwork(2).Data = s.Pref;
block.Dwork(3).Data = s.alpha;
end

%% ------------------------------------------------------------------------
function s = ctrl_step(block)
% One controller step (used by Outputs and Update, so both give the same numbers)
Ts    = block.DialogPrm(1).Data;
Kp    = block.DialogPrm(2).Data;
Ki    = block.DialogPrm(3).Data;
Pnom  = block.DialogPrm(4).Data;
ctrl  = block.DialogPrm(5).Data;
ramp  = block.DialogPrm(8).Data;          % kW/min
Pbmax = block.DialogPrm(9).Data;
SOCmn = block.DialogPrm(10).Data;
SOCmx = block.DialogPrm(11).Data;

Pccm  = block.InputPort(1).Data;
Ptso  = block.InputPort(2).Data;
autil = min(max(block.InputPort(3).Data, 0), 1);
Ppvm  = block.InputPort(4).Data;
soc   = block.InputPort(5).Data;

I      = block.Dwork(1).Data;
Pref   = block.Dwork(2).Data;
aprev  = block.Dwork(3).Data;

if ctrl == 0
    Pref_n = Ptso;  ppvset = Ptso;  meas = Pccm;  pbref = 0;
else
    if aprev < autil - 1e-3
        target = Ptso;                    % PV curtailed: follow the TSO
    else
        target = min(Ptso, Ppvm);         % PV at its maximum power point: follow the PV
    end
    r      = ramp/60;                     % kW/s
    Pref_n = Pref + min(max(target - Pref, -r*Ts), r*Ts);
    meas   = Ppvm;
    if ctrl == 2
        if soc <= SOCmn, hi = 0;      else, hi = Pbmax;  end
        if soc >= SOCmx, lo = 0;      else, lo = -Pbmax; end
        pbref  = min(max(Pref_n - Ppvm, lo), hi);
        ppvset = Pref_n - lo;             % PV may produce the reference plus what the battery can charge
    else
        pbref  = 0;
        ppvset = Pref_n;
    end
end

e     = ppvset - meas;
I     = min(max(I + Ki*Ts*e, 0), autil*Pnom);
Pun   = Kp*e + I;
alpha = min(max(Pun, 0), Pnom)/Pnom;

s = struct('alpha', alpha, 'pbref', pbref, 'I', I, 'Pref', Pref_n, 'ppvset', ppvset);
end
