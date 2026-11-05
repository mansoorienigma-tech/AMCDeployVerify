function n = patch_reference_design_tool_version(supportPackageRoot)
%PATCH_REFERENCE_DESIGN_TOOL_VERSION Let HDL Workflow Advisor accept Vivado 2023.2.
%   The RFSoC deep-learning reference designs shipped with R2025b declare
%   SupportedToolVersion = {'2024.1'} in their plugin_rd.m files. This helper
%   adds '2023.2' to that list, with a .2024_1.bak backup, so step 1.1/4.3
%   no longer rejects the installed Vivado.
%
%   n = patch_reference_design_tool_version();
%   n = patch_reference_design_tool_version('C:\path\to\MATLAB Add-Ons\Toolboxes');
%
%   It is OPTIONAL: setup_vivado_2023_2.m already sets
%   AllowUnsupportedToolVersion = true. Run MATLAB as administrator if the
%   support package is installed under Program Files.

if nargin < 1 || isempty(supportPackageRoot)
    supportPackageRoot = getenv('MW_SUPPORT_PACKAGE_ROOT');
end

roots = {};
if ~isempty(supportPackageRoot)
    roots{end+1} = supportPackageRoot; %#ok<AGROW>
end
if ispc
    addons = fullfile(getenv('USERPROFILE'), 'AppData', 'Roaming', ...
                      'MathWorks', 'MATLAB Add-Ons', 'Toolboxes');
else
    addons = fullfile(getenv('HOME'), 'Documents', 'MATLAB', 'Add-Ons', 'Toolboxes');
end
roots = [roots {addons, matlabroot, fullfile(userpath, 'MATLAB Add-Ons', 'Toolboxes')}];

files = {};
for k = 1:numel(roots)
    r = roots{k};
    if isempty(r) || exist(r, 'dir') ~= 7
        continue;
    end
    d = dir(fullfile(r, '**', 'plugin_rd.m'));
    for j = 1:numel(d)
        files{end+1} = fullfile(d(j).folder, d(j).name); %#ok<AGROW>
    end
end
files = unique(files);

if isempty(files)
    fprintf(['No plugin_rd.m found. Set MW_SUPPORT_PACKAGE_ROOT to the folder\n' ...
             'that contains the SoC Blockset support package, or simply rely on\n' ...
             'AllowUnsupportedToolVersion = true in setup_vivado_2023_2.m.\n']);
    n = 0;
    return;
end

n = 0;
for k = 1:numel(files)
    f = files{k};
    txt = fileread(f);
    if ~contains(txt, 'SupportedToolVersion')
        continue;
    end
    if contains(txt, '''2023.2''')
        continue;
    end

    lines = regexp(txt, '\r?\n', 'split');
    changed = false;
    for i = 1:numel(lines)
        line = lines{i};
        if ~contains(line, 'SupportedToolVersion')
            continue;
        end
        tok = regexp(line, 'SupportedToolVersion\s*=\s*\{(.*)\}', 'tokens', 'once');
        if isempty(tok)
            continue;
        end
        items = strtrim(tok{1});
        if isempty(items)
            newItems = '''2023.2''';
        else
            newItems = [items ', ''2023.2'''];
        end
        lines{i} = regexprep(line, '\{.*\}', ['{' newItems '}']);
        changed = true;
    end

    if changed
        backup = [f '.2024_1.bak'];
        if exist(backup, 'file') ~= 2
            copyfile(f, backup);
        end
        fid = fopen(f, 'w');
        if fid < 0
            warning('Cannot write %s (run MATLAB as administrator).', f);
            continue;
        end
        fwrite(fid, strjoin(lines, sprintf('\n')), 'char');
        fclose(fid);
        fprintf('Patched: %s\n', f);
        n = n + 1;
    end
end
fprintf('%d reference design file(s) patched for Vivado 2023.2.\n', n);
end
