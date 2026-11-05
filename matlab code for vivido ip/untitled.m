% Set Vivado path
hdlsetuptoolpath( ...
    'ToolName', 'Xilinx Vivado', ...
    'ToolPath', 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat');

% Configure Deep Learning Processor
hPC = dlhdl.ProcessorConfig;

hPC.InputRunTimeControl = "register";
hPC.OutputRunTimeControl = "register";
hPC.TargetPlatform = 'Generic Deep Learning Processor';

hPC.setModuleProperty('conv', 'LRNBlockGeneration', 'on');
hPC.setModuleProperty('conv', 'SegmentationBlockGeneration', 'off');
hPC.setModuleProperty('conv', 'ConvThreadNumber', 9);

% Allow unsupported Vivado version
hWC = hdlcoder.WorkflowConfig( ...
    'SynthesisTool', 'Xilinx Vivado', ...
    'TargetWorkflow', 'Deep Learning Processor');

hWC.AllowUnsupportedToolVersion = true;

% Build processor IP
dlhdl.buildProcessor(hPC, ...
    'ProjectFolder', 'genericipcore', ...
    'ProcessorName', 'GenericProcessor', ...
    'WorkflowConfig', hWC);
