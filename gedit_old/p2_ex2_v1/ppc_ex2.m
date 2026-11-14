function ppc_ex2(block)
%MSFUNTMPL_BASIC A Template for a Level-2 MATLAB S-Function
%   The MATLAB S-function is written as a MATLAB function with the
%   same name as the S-function. Replace 'msfuntmpl_basic' with the
%   name of your S-function.

%   Copyright 2003-2018 The MathWorks, Inc.

%%
%% The setup method is used to set up the basic attributes of the
%% S-function such as ports, parameters, etc. Do not add any other
%% calls to the main body of the function.
%%
setup(block);

%endfunction

%% Function: setup ===================================================
%% Abstract:
%%   Set up the basic characteristics of the S-function block such as:
%%   - Input ports
%%   - Output ports
%%   - Dialog parameters
%%   - Options
%%
%%   Required         : Yes
%%   C MEX counterpart: mdlInitializeSizes
%%
function setup(block)

  % Register number of ports
  block.NumInputPorts  = 2;
  block.NumOutputPorts = 2;

  % Setup port properties to be inherited or dynamic
  block.SetPreCompInpPortInfoToDynamic;
  block.SetPreCompOutPortInfoToDynamic;

  % Override input port properties
  block.InputPort(1).Dimensions        = 1;
  block.InputPort(1).DatatypeID  = 0;  % double
  block.InputPort(1).Complexity  = 'Real';
  block.InputPort(1).DirectFeedthrough = true;

  block.InputPort(2).Dimensions        = 1;
  block.InputPort(2).DatatypeID  = 0;  % double
  block.InputPort(2).Complexity  = 'Real';
  block.InputPort(2).DirectFeedthrough = true;


  % Override output port properties
  block.OutputPort(1).Dimensions       = 1;
  block.OutputPort(1).DatatypeID  = 0; % double
  block.OutputPort(1).Complexity  = 'Real';
  block.OutputPort(1).SamplingMode = 'Sample'; % ARNAU: Añadir esta linea

  % Register parameters
  block.NumDialogPrms  =  5; % ARNAU: Canviar el numero de parametros 0 -> 5

  % Register sample times
  %  [0 offset]            : Continuous sample time
  %  [positive_num offset] : Discrete sample time
  %
  %  [-1, 0]               : Inherited sample time
  %  [-2, 0]               : Variable sample time
  block.SampleTimes = [block.DialogPrm(1).Data 0]; % ARNAU: cambiar el sampleTimes. [0 0] -> [block.DialogPrm(1).Data 0]

  % Specify the block simStateCompliance. The allowed values are:
  %    'UnknownSimState', < The default setting; warn and assume DefaultSimState
  %    'DefaultSimState', < Same sim state as a built-in block
  %    'HasNoSimState',   < No sim state
  %    'CustomSimState',  < Has GetSimState and SetSimState methods
  %    'DisallowSimState' < Error out when saving or restoring the model sim state
  block.SimStateCompliance = 'DefaultSimState';

  %% -----------------------------------------------------------------
  %% The MATLAB S-function uses an internal registry for all
  %% block methods. You should register all relevant methods
  %% (optional and required) as illustrated below. You may choose
  %% any suitable name for the methods and implement these methods
  %% as local functions within the same file. See comments
  %% provided for each function for more information.
  %% -----------------------------------------------------------------

  block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
  block.RegBlockMethod('InitializeConditions', @InitializeConditions);
  block.RegBlockMethod('Start', @Start);
  block.RegBlockMethod('Outputs', @Outputs);     % Required
  block.RegBlockMethod('Update', @Update);
  block.RegBlockMethod('Derivatives', @Derivatives);
  block.RegBlockMethod('Terminate', @Terminate); % Required

  %end setup

  %%
  %% PostPropagationSetup:
  %%   Functionality    : Setup work areas and state variables. Can
  %%                      also register run-time methods here
  %%   Required         : No
  %%   C MEX counterpart: mdlSetWorkWidths
  %%
function DoPostPropSetup(block)
  block.NumDworks = 1;

  block.Dwork(1).Name            = 'variables1'; % ARNAU: Cambio de nombre. 'x1' -> 'variables1'
  block.Dwork(1).Dimensions      = 1;
  block.Dwork(1).DatatypeID      = 0;      % double
  block.Dwork(1).Complexity      = 'Real'; % real
  block.Dwork(1).UsedAsDiscState = true;


  %%
  %% InitializeConditions:
  %%   Functionality    : Called at the start of simulation and if it is
  %%                      present in an enabled subsystem configured to reset
  %%                      states, it will be called when the enabled subsystem
  %%                      restarts execution to reset the states.
  %%   Required         : No
  %%   C MEX counterpart: mdlInitializeConditions
  %%
function InitializeConditions(block)
  block.Dwork(1).Data = 7000; % ARNAU: Añadir esta linea

  block.OutputPort(1).Data = 1; % ARNAU: Añadir esta linea

  %end InitializeConditions


  %%
  %% Start:
  %%   Functionality    : Called once at start of model execution. If you
  %%                      have states that should be initialized once, this
  %%                      is the place to do it.
  %%   Required         : No
  %%   C MEX counterpart: mdlStart
  %%
function Start(block)

  % block.Dwork(1).Data = 0;

  %end Start

  %%
  %% Outputs:
  %%   Functionality    : Called to generate block outputs in
  %%                      simulation step
  %%   Required         : Yes
  %%   C MEX counterpart: mdlOutputs
  %%
function Outputs(block)
  %% Inputs
  Ppcc_meas = block.InputPort(1).Data;      % P media al PCC [kW]
  Ppcc_setpoint = block.InputPort(2).Data;  % Consigna de curtilment [kW] Power point of common coupling (Ppcc) / point of interconnection (POI)

  %% Def. variables
  PI_integrador_out = block.Dwork(1).Data;  % Sortida integrador

  %% Def. parameters
  sample_time = block.DialogPrm(1).Data;    % Temps de sampleig del PPC [s]
  Ppv_nom = block.DialogPrm(2).Data;        % P nominal PV [kW]
  Ki = block.DialogPrm(3).Data;             % Ki del PI del PPC per la fotovoltaica
  Kp = block.DialogPrm(4).Data;             % Kp del PI del PPC per la fotovoltaica
  Ramp_rate_lim = block.DialogPrm(5).Data;  % Limit ramp rate [% Ppv_nom/min]

  %% Outputs
  e = Ppcc_setpoint-Ppcc_meas;
  disp([block.CurrentTime, Ppcc_meas, Ppcc_setpoint, e]);
  kp_out = e*Kp;
  ki_out = e*Ki;
  PI_integrador_out=PI_integrador_out+ki_out*sample_time;
  Piout=PI_integrador_out+kp_out;

  alpha = Piout / Ppv_nom;   % consigna TSO [kW] → p.u.

  block.Dwork(1).Data = PI_integrador_out;

  block.OutputPort(1).Data = alpha;
  block.OutputPort(2).Data = e;
  %end Outputs

  %%
  %% Update:
  %%   Functionality    : Called to update discrete states
  %%                      during simulation step
  %%   Required         : No
  %%   C MEX counterpart: mdlUpdate
  %%
function Update(block)

  % block.Dwork(1).Data = block.InputPort(1).Data;


  %end Update

  %%
  %% Derivatives:
  %%   Functionality    : Called to update derivatives of
  %%                      continuous states during simulation step
  %%   Required         : No
  %%   C MEX counterpart: mdlDerivatives
  %%
function Derivatives(block)

  %end Derivatives

  %%
  %% Terminate:
  %%   Functionality    : Called at the end of simulation for cleanup
  %%   Required         : Yes
  %%   C MEX counterpart: mdlTerminate
  %%
function Terminate(block)

  %end Terminate


