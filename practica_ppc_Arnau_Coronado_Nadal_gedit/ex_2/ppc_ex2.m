function ppc_ex2(block)

setup(block);

%endfunction

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

  block.OutputPort(2).Dimensions       = 1;
  block.OutputPort(2).DatatypeID  = 0; % double
  block.OutputPort(2).Complexity  = 'Real';
  block.OutputPort(2).SamplingMode = 'Sample'; % ARNAU: Añadir esta linea

  % Register parameters
  block.NumDialogPrms  =  5; 

  % Register sample times
  %  [0 offset]            : Continuous sample time
  %  [positive_num offset] : Discrete sample time
  %
  %  [-1, 0]               : Inherited sample time
  %  [-2, 0]               : Variable sample time
  block.SampleTimes = [block.DialogPrm(1).Data 0]; % Temps de mostratge discret definit pel paràmetre 1 (sample_time)

  % Specify the block simStateCompliance. The allowed values are:
  %    'UnknownSimState', < The default setting; warn and assume DefaultSimState
  %    'DefaultSimState', < Same sim state as a built-in block
  %    'HasNoSimState',   < No sim state
  %    'CustomSimState',  < Has GetSimState and SetSimState methods
  %    'DisallowSimState' < Error out when saving or restoring the model sim state
  block.SimStateCompliance = 'DefaultSimState';

  block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
  block.RegBlockMethod('InitializeConditions', @InitializeConditions);
  block.RegBlockMethod('Start', @Start);
  block.RegBlockMethod('Outputs', @Outputs);     % Required
  block.RegBlockMethod('Update', @Update);
  block.RegBlockMethod('Derivatives', @Derivatives);
  block.RegBlockMethod('Terminate', @Terminate); % Required
  %end setup

function DoPostPropSetup(block)
  block.NumDworks = 1;

  block.Dwork(1).Name            = 'variables1'; % ARNAU: Cambio de nombre. 'x1' -> 'variables1'
  block.Dwork(1).Dimensions      = 1;
  block.Dwork(1).DatatypeID      = 0;      % double
  block.Dwork(1).Complexity      = 'Real'; % real
  block.Dwork(1).UsedAsDiscState = true;

function InitializeConditions(block)
  block.Dwork(1).Data = 7000; % Inicialitza l'integrador a 7000 kW (consigna inicial de l'Exercici 2)

  block.OutputPort(1).Data =  0.7; % alpha inicial (7000/10000)
  block.OutputPort(2).Data = 0;
  %end InitializeConditions

function Start(block)

  % block.Dwork(1).Data = 0;

  %end Start
function Outputs(block)
  % Inputs
  Ppcc_meas = block.InputPort(1).Data;      % P media al PCC [kW]
  Ppcc_setpoint = block.InputPort(2).Data;  % Consigna de curtilment [kW] Power point of common coupling (Ppcc) / point of interconnection (POI)

  % Def. variables i parameters
  PI_integrador_out = block.Dwork(1).Data;  % Sortida integrador
  sample_time = block.DialogPrm(1).Data;    % Temps de sampleig del PPC [s]
  Ppv_nom = block.DialogPrm(2).Data;        % P nominal PV [kW]
  Ki = block.DialogPrm(3).Data;             % Ki del PI del PPC per la fotovoltaica
  Kp = block.DialogPrm(4).Data;             % Kp del PI del PPC per la fotovoltaica
  Ramp_rate_lim = block.DialogPrm(5).Data;  % Limit ramp rate [% Ppv_nom/min]

  % Outputs
  % disp([block.CurrentTime, Ppcc_meas, Ppcc_setpoint, e]);
  % ki_out = e*Ki;
  % PI_integrador_out=PI_integrador_out+ki_out*sample_time;
  
  e = Ppcc_setpoint-Ppcc_meas;
  kp_out = e*Kp;
  Piout=PI_integrador_out+kp_out;
  alpha = Piout / Ppv_nom;   % consigna TSO [kW] → p.u.
  alpha_sat = max(0, min(1, alpha));

  block.OutputPort(1).Data = alpha_sat;
  block.OutputPort(2).Data = e;
  %end Outputs

function Update(block)
    % Actualització de l'estat integrador en cada pas de mostratge
    Ppcc_meas     = block.InputPort(1).Data;
    Ppcc_setpoint = block.InputPort(2).Data;
    sample_time   = block.DialogPrm(1).Data;
    Ki            = block.DialogPrm(3).Data;
    
    e = Ppcc_setpoint - Ppcc_meas;
    
    % Acumulació integral
    block.Dwork(1).Data = block.Dwork(1).Data + (e * Ki) * sample_time;


  %end Update

function Derivatives(block)

  %end Derivatives

function Terminate(block)

  %end Terminate


