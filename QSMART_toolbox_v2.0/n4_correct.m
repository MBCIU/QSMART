function n4_correct(in_file, out_file, params)
%N4_CORRECT ANTs N4 bias field correction of IN_FILE, written to OUT_FILE.
%   N4 rounds differently with different thread counts, and BET and every later step follow
%   those differences, so the thread count is fixed (params.n4_threads, default 1) to make
%   repeated runs give the same result.

threads = 1;
if isfield(params, 'n4_threads') && ~isempty(params.n4_threads)
    threads = params.n4_threads;
end

run_tool('N4BiasFieldCorrection', sprintf('-i %s -o %s', in_file, out_file), ...
    sprintf('ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=%d', threads));
