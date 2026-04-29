function [Q, dQdt] = evaluate_bd_source_term_2d(sourceState, t)
% EVALUATE_BD_SOURCE_TERM_2D
% Return volumetric heat source Q [W/m^3] and its time derivative.

switch lower(sourceState.type)
    case 'zero'
        Q = sourceState.spatialPattern;
        dQdt = zeros(size(Q));

    case 'gaussian'
        if isfield(sourceState, 'A')
            amp = sourceState.A;
        else
            amp = 1.0;
        end
        Q = amp .* sourceState.spatialPattern;
        dQdt = zeros(size(Q));

    case 'gaussian_pulse'
        if ~isfield(sourceState, 'A0')
            sourceState.A0 = 1.0;
        end
        if ~isfield(sourceState, 't0')
            sourceState.t0 = 0.0;
        end
        if ~isfield(sourceState, 'sigmaT')
            error('gaussian_pulse source requires sigmaT.');
        end
        tau = (t - sourceState.t0) ./ sourceState.sigmaT;
        amp = sourceState.A0 .* exp(-0.5 .* tau.^2);
        dampdt = amp .* (-(t - sourceState.t0) ./ (sourceState.sigmaT.^2));
        Q = amp .* sourceState.spatialPattern;
        dQdt = dampdt .* sourceState.spatialPattern;

    case {'csv_map', 'damage_map_csv'}
        if isfield(sourceState, 'A')
            amp = sourceState.A;
        else
            amp = 1.0;
        end
        Q = amp .* sourceState.spatialPattern;
        dQdt = zeros(size(Q));

    otherwise
        error('Unknown source.type for Module 4: %s', sourceState.type);
end
end
