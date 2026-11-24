function v = to_voxels(size_value, params)
%TO_VOXELS Convert a size setting (a morphology radius or a Frangi scale) to voxels.
%   With params.size_units 'mm' (default), SIZE_VALUE is in mm and is divided by the mean voxel
%   size, so the same settings give the same physical sizes at any resolution. With 'voxels',
%   SIZE_VALUE is returned unchanged, as in QSMART v1.0.

if ~isfield(params, 'size_units') || strcmp(params.size_units, 'mm')
    v = size_value / mean(params.iminfo.resolution);
elseif strcmp(params.size_units, 'voxels')
    v = size_value;
else
    error('QSMART:sizeUnits', 'size_units must be ''mm'' or ''voxels'' (got ''%s'').', params.size_units);
end
