function profile = evaluate_boundary_profile_2d(side, coord)
% EVALUATE_BOUNDARY_PROFILE_2D
% Tangential boundary-emission profile.

if ~isfield(side, 'profile')
    side.profile = 'uniform';
end

switch lower(side.profile)
    case 'uniform'
        profile = ones(size(coord));

    case 'gaussian'
        if ~isfield(side, 'profileCenter') || ~isfield(side, 'profileWidth')
            error('Gaussian boundary profile requires profileCenter and profileWidth.');
        end
        profile = exp(-((coord - side.profileCenter).^2) ./ (2 * side.profileWidth^2));

    otherwise
        error('Unknown boundary profile type: %s', side.profile);
end
end
