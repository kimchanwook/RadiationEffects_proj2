function amp = evaluate_boundary_emission_2d(side, tRet)
% EVALUATE_BOUNDARY_EMISSION_2D
% Return boundary-emitted temperature perturbation amplitude [K].

amp = zeros(size(tRet));
if ~isfield(side, 'type')
    return;
end

type = lower(side.type);
if strcmp(type, 'off') || strcmp(type, 'zero')
    return;
end

if ~isfield(side, 'deltaT')
    side.deltaT = 0.0;
end
if ~isfield(side, 't0')
    side.t0 = 0.0;
end

switch type
    case 'step'
        amp(tRet >= side.t0) = side.deltaT;

    case 'ramp'
        if ~isfield(side, 'riseTime') || side.riseTime <= 0
            error('Boundary type ''ramp'' requires a positive riseTime.');
        end
        mask = tRet >= side.t0;
        amp(mask) = side.deltaT .* (1.0 - exp(-(tRet(mask) - side.t0) ./ side.riseTime));

    case 'square_pulse'
        if ~isfield(side, 'duration')
            error('Boundary type ''square_pulse'' requires duration.');
        end
        mask = (tRet >= side.t0) & (tRet <= side.t0 + side.duration);
        amp(mask) = side.deltaT;

    case 'gaussian_pulse'
        if ~isfield(side, 'sigmaT')
            error('Boundary type ''gaussian_pulse'' requires sigmaT.');
        end
        amp = side.deltaT .* exp(-0.5 .* ((tRet - side.t0) ./ side.sigmaT).^2);
        amp(tRet < 0) = 0.0;

    otherwise
        error('Unknown boundary emission type: %s', side.type);
end

amp(tRet < 0) = 0.0;
end
