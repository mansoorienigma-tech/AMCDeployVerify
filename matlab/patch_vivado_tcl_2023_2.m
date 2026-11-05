function n = patch_vivado_tcl_2023_2(folder)
%PATCH_VIVADO_TCL_2023_2 Patch HDL Coder Tcl scripts for Vivado 2023.2.
%   This is the MATLAB version of tools/patch_vivado_tcl_for_2023_2.py.
%   No Python installation is needed. It patches every *.tcl under FOLDER
%   (recursively), keeps a .2024_1.bak backup, and copies
%   vivado2023_2/compat_2023_2.tcl next to every patched file.
%
%   n = patch_vivado_tcl_2023_2('C:\work\hdl_prj\vivado_ip_prj');
%   patch_vivado_tcl_2023_2;      % opens a folder picker
%
%   Run it AFTER HDL Workflow Advisor step 4.1 and BEFORE the batch build.

if nargin < 1 || isempty(folder)
    folder = uigetdir(pwd, 'Select the hdl_prj\vivado_ip_prj folder');
    if isequal(folder, 0)
        n = 0;
        return;
    end
end
if exist(folder, 'dir') ~= 7
    error('Folder not found: %s', folder);
end

repoRoot = fileparts(fileparts(mfilename('fullpath')));
compat = fullfile(repoRoot, 'vivado2023_2', 'compat_2023_2.tcl');
if exist(compat, 'file') ~= 2
    error('Compatibility library not found: %s', compat);
end

marker = '# >>> MW-2023.2 PATCH';
triggers = {'scripts_vivado_version', 'create_bd_cell -type ip -vlnv', ...
            'set_property -dict', 'regenerate_bd_layout', ...
            'start_gui', 'DLIPcoreName', 'get_ipdefs -all', 'read_xdc', ...
            'source '};

listing = dir(fullfile(folder, '**', '*.tcl'));
n = 0;
for k = 1:numel(listing)
    f = fullfile(listing(k).folder, listing(k).name);
    if strcmp(listing(k).name, 'compat_2023_2.tcl') || contains(f, '.2024_1.bak')
        continue;
    end
    txt = fileread(f);
    if contains(txt, marker)
        continue;
    end
    hit = false;
    for t = 1:numel(triggers)
        if contains(txt, triggers{t})
            hit = true;
            break;
        end
    end
    if ~hit
        continue;
    end

    patched = mw_patch_text(txt);
    backup = [f '.2024_1.bak'];
    if exist(backup, 'file') ~= 2
        copyfile(f, backup);
    end
    fid = fopen(f, 'w');
    if fid < 0
        warning('Cannot write %s (check permissions).', f);
        continue;
    end
    fwrite(fid, patched, 'char');
    fclose(fid);
    copyfile(compat, fullfile(listing(k).folder, 'compat_2023_2.tcl'), 'f');
    fprintf('Patched: %s\n', f);
    n = n + 1;
end
fprintf('%d Tcl file(s) patched for Vivado 2023.2.\n', n);
fprintf('Next: run vivado2023_2/run_vivado_2023_2.bat (or build_2023_2.tcl).\n');
end

% -------------------------------------------------------------------------
function out = mw_patch_text(txt)

header = [ ...
'# >>> MW-2023.2 PATCH (matlab/patch_vivado_tcl_2023_2.m) ---------------' sprintf('\n') ...
'# Generated for Vivado 2024.1, patched to run under Vivado 2023.2.' sprintf('\n') ...
'if {![info exists ::mwcompat::loaded]} {' sprintf('\n') ...
'    source [file join [file dirname [file normalize [info script]]] "compat_2023_2.tcl"]' sprintf('\n') ...
'}' sprintf('\n') ...
'mw_check_version' sprintf('\n') ...
'# <<< MW-2023.2 PATCH -------------------------------------------------------' sprintf('\n')];

versionBlock = [ ...
'set scripts_vivado_version 2023.2' sprintf('\n') ...
'set current_vivado_version [version -short]' sprintf('\n') ...
'if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {' sprintf('\n') ...
'   mw_log "WARNING: script was generated for Vivado $scripts_vivado_version, running on $current_vivado_version. Continuing with the 2023.2 compatibility layer."' sprintf('\n') ...
'}'];

dlipBlock = [ ...
'# MW-2023.2: add the deep learning (AI) IP core next to the subsystem IPs.' sprintf('\n') ...
'if {![info exists DLIPcoreName] || $DLIPcoreName eq ""} {' sprintf('\n') ...
'    if {[info exists ::env(MW_DLIP_NAME)]} { set DLIPcoreName $::env(MW_DLIP_NAME) }' sprintf('\n') ...
'}' sprintf('\n') ...
'if {[info exists DLIPcoreName] && $DLIPcoreName ne ""} {' sprintf('\n') ...
'    mw_log "adding DL IP core <$DLIPcoreName> via add_DLIP.tcl"' sprintf('\n') ...
'    if {[catch {mw_source_required "add_DLIP.tcl"} e]} {' sprintf('\n') ...
'        error "MW-2023.2: could not add the DL IP core: $e . Check DL Processor IP Name, Location and Vendor in step 1.2, and make sure the IP folder is in ip_repo_paths."' sprintf('\n') ...
'    }' sprintf('\n') ...
'} else {' sprintf('\n') ...
'    mw_log "WARNING: DLIPcoreName is empty, so the AI IP will NOT be added. Set it in step 1.2 or set MW_DLIP_NAME."' sprintf('\n') ...
'}'];

footer = [ ...
sprintf('\n') '# >>> MW-2023.2 PATCH footer' sprintf('\n') ...
'if {[info exists design_name]} {' sprintf('\n') ...
'    mw_log "block design <$design_name> finished on Vivado [version -short] (no GUI layout used)."' sprintf('\n') ...
'}' sprintf('\n') ...
'# <<< MW-2023.2 PATCH footer' sprintf('\n')];

% 1. Hard version check -> warning.
m = regexp(txt, 'set scripts_vivado_version\s+[^\n]*\n[\s\S]*?return 1\s*\n\}', 'match', 'once');
if ~isempty(m)
    if iscell(m), m = m{1}; end
    txt = strrep(txt, m, versionBlock);
else
    txt = regexprep(txt, 'set scripts_vivado_version\s+\d{4}\.\d+', ...
                    'set scripts_vivado_version 2023.2', 'once');
end

% 2. IP VLNV resolution.
txt = regexprep(txt, 'create_bd_cell -type ip -vlnv (\S+) (\S+)', ...
                'mw_create_bd_ip $1 $2');

% 3. IP catalog pre-check.
txt = strrep(txt, 'set ip_obj [get_ipdefs -all $ip_vlnv]', ...
                  'set ip_obj [mw_ip_exists $ip_vlnv]');
txt = strrep(txt, 'if { $ip_obj eq "" }', 'if { !$ip_obj }');
txt = strrep(txt, 'if {$ip_obj eq ""}', 'if {!$ip_obj}');

% 4. CONFIG blocks -> mw_apply_ip_config (literal string surgery).
blocks = regexp(txt, 'set_property -dict[^\n]*\n[\s\S]*?\n\] \$\w+', 'match');
if ischar(blocks), blocks = {blocks}; end
for k = 1:numel(blocks)
    block = blocks{k};
    tok = regexp(block, '\] (\$\w+)\s*$', 'tokens', 'once');
    obj = '';
    if ~isempty(tok)
        if iscell(tok{1}), obj = tok{1}{1}; else, obj = tok{1}; end
    end
    prefix = 'set_property -dict ';
    if isempty(obj) || ~strncmp(block, prefix, numel(prefix))
        continue;
    end
    rest = block(numel(prefix) + 1:end);
    idx = strfind(rest, obj);
    if isempty(idx), continue; end
    dictPart = strtrim(rest(1:idx(end) - 1));
    txt = strrep(txt, block, ['mw_apply_ip_config ' obj ' ' dictPart]);
end

% 5. Path-independent sourcing of the MathWorks support Tcl files.
pairs = { ...
 'source $mw_hdl_dir/mw_compile_dma.tcl', 'mw_source_required "mw_compile_dma.tcl"'; ...
 'source $mw_hdl_dir/hsb_xil.tcl',       'mw_source_required "hsb_xil.tcl"'; ...
 'source $mw_hdl_dir/add_DLIP.tcl',      'mw_source_required "add_DLIP.tcl"'; ...
 'source add_pl_ddr.tcl',                'mw_source_required "add_pl_ddr.tcl"'; ...
 'source add_rfdc_ip.tcl',               'mw_source_required "add_rfdc_ip.tcl"'};
for k = 1:size(pairs, 1)
    txt = strrep(txt, pairs{k, 1}, pairs{k, 2});
end

% 6. Explicit AI IP insertion with clear diagnostics.
m = regexp(txt, 'if \{\[info exists DLIPcoreName\]\}[\s\S]*?mw_source_required "add_DLIP\.tcl"[\s\S]*?\n\}', 'match', 'once');
if ~isempty(m)
    if iscell(m), m = m{1}; end
    txt = strrep(txt, m, dlipBlock);
end

% 7. Validation must not abort the batch run silently.
txt = strrep(txt, sprintf('\nvalidate_bd_design\n'), ...
    sprintf('\nif {[catch {validate_bd_design} e]} { mw_log "WARNING: validate_bd_design reported: $e" }\n'));

% 8. Constraints from the project folder.
txt = strrep(txt, 'read_xdc $mts_constr_filename', ...
                  'read_xdc [mw_required_file $mts_constr_filename]');

% 9. GUI commands: this is what closed Vivado before.
txt = strrep(txt, 'regenerate_bd_layout', 'mw_regenerate_layout');
txt = regexprep(txt, '^\s*start_gui[^\n]*$', ...
                'mw_ignore_gui "start_gui (batch mode)"', 'lineanchors');

% 10. Standalone projects need the ZCU111 board part.
txt = strrep(txt, ...
    'create_project project_1 myproj -part xczu28dr-ffvg1517-2-e', ...
    ['create_project project_1 myproj -part xczu28dr-ffvg1517-2-e' sprintf('\n') ...
     'catch {set_property board_part xilinx.com:zcu111:part0:1.1 [current_project]}']);

out = [header txt footer];
end
