function run_tool(tool, args, env)
%RUN_TOOL Run an external command-line tool (ANTs, FSL) and stop if it fails.
%   RUN_TOOL(TOOL, ARGS) runs TOOL with the argument string ARGS. RUN_TOOL(TOOL, ARGS, ENV)
%   puts the string ENV (e.g. 'VAR=value') in front of the command. TOOL must be on the
%   system path that MATLAB sees.

if nargin < 3
    env = '';
end

[status, ~] = system(['command -v ' tool]);
if status ~= 0
    error('QSMART:missingTool', ['%s was not found on the system path. Install it (see README.md) ' ...
        'and make sure MATLAB can see it, e.g. with setenv(''PATH'', ...).'], tool);
end

[status, out] = system(strtrim([env ' ' tool ' ' args]));
if status ~= 0
    error('QSMART:toolFailed', '%s failed (exit status %d):\n%s', tool, status, out);
end
