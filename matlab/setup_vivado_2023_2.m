%% setup_vivado_2023_2.m
% Run this once in every MATLAB session, BEFORE opening HDL Workflow Advisor.
%
% MATLAB R2025b is tested with Vivado 2024.1, but we keep Vivado 2023.2.
% AllowUnsupportedToolVersion lets the deep learning processor IP be built
% with 2023.2; the Vivado side is handled by the patched Tcl scripts in
% ../vivado2023_2 (see README.md).
%
% NOTE: this script does NOT build a bitstream. It only rebuilds the AI IP.

clear; clc;

vivadoPath = 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat';
if exist(vivadoPath, 'file') ~= 2
    error(['Vivado 2023.2 not found at: ' vivadoPath ...
        newline 'Edit vivadoPath at the top of setup_vivado_2023_2.m.']);
end
hdlsetuptoolpath('ToolName', 'Xilinx Vivado', 'ToolPath', vivadoPath);

%% 1. Deep learning processor configuration (same as the MathWorks example)
hPC = dlhdl.ProcessorConfig;
hPC.InputRunTimeControl  = "register";
hPC.OutputRunTimeControl = "register";
hPC.TargetPlatform = 'Generic Deep Learning Processor';
hPC.setModuleProperty('conv', 'LRNBlockGeneration', 'on');
hPC.setModuleProperty('conv', 'SegmentationBlockGeneration', 'off');
hPC.setModuleProperty('conv', 'ConvThreadNumber', 9);

%% 2. Allow the unsupported tool version (required for 2023.2)
hWC = hdlcoder.WorkflowConfig( ...
    'SynthesisTool',  'Xilinx Vivado', ...
    'TargetWorkflow', 'Deep Learning Processor');
if isprop(hWC, 'AllowUnsupportedToolVersion')
    hWC.AllowUnsupportedToolVersion = true;
else
    warning('AllowUnsupportedToolVersion is not exposed in this release; continuing without it.');
end

%% 3. Build / package the AI IP core
projectFolder = fullfile(pwd, 'genericipcore');
dlhdl.buildProcessor(hPC, ...
    'ProjectFolder', projectFolder, ...
    'ProcessorName', 'GenericProcessor', ...
    'WorkflowConfig', hWC);

%% 4. What to copy into HDL Workflow Advisor step 1.2
fprintf('\n=========================================================\n');
fprintf('AI IP built in: %s\n', projectFolder);
fprintf('Open  testbench_ip_core_report.html  in that folder and copy\n');
fprintf('  "IP core name", "IP core folder" and "IP core vendor"\n');
fprintf('into step 1.2:  DL Processor IP Name / Location / Vendor.\n');
fprintf('Do NOT assume the name is dlprocessor: ProcessorName above\n');
fprintf('controls it. The batch runner needs the same values.\n');
fprintf('=========================================================\n\n');

% Optional: make the Workflow Advisor itself accept 2023.2 instead of only
% relying on AllowUnsupportedToolVersion. Requires write access to the
% installed support package.
% patch_reference_design_tool_version;
