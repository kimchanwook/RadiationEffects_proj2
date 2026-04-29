function ballistic = compute_ballistic_flux_reduced_2d(gridData, t, physics, boundary)
% COMPUTE_BALLISTIC_FLUX_REDUCED_2D
% Reduced rectangular-domain ballistic flux closure.
%
% Each emitting boundary contributes an attenuated, retarded flux traveling
% normal to that boundary. This is intentionally a first executable closure,
% not a full angular quadrature or ray-tracing solve.

X = gridData.X;
Y = gridData.Y;
qbx = zeros(size(X));
qby = zeros(size(X));

xmin = gridData.x(1);
xmax = gridData.x(end);
ymin = gridData.y(1);
ymax = gridData.y(end);

v = physics.vBallistic;
mfp = physics.mfp;
prefactor = physics.ballisticPrefactor * physics.Cvol * physics.vBallistic;

% Left boundary -> +x
if isfield(boundary, 'left')
    dist = X - xmin;
    tRet = t - dist ./ max(v, eps);
    amp = evaluate_boundary_emission_2d(boundary.left, tRet);
    profile = evaluate_boundary_profile_2d(boundary.left, Y);
    qbx = qbx + prefactor .* amp .* profile .* exp(-dist ./ max(mfp, eps));
end

% Right boundary -> -x
if isfield(boundary, 'right')
    dist = xmax - X;
    tRet = t - dist ./ max(v, eps);
    amp = evaluate_boundary_emission_2d(boundary.right, tRet);
    profile = evaluate_boundary_profile_2d(boundary.right, Y);
    qbx = qbx - prefactor .* amp .* profile .* exp(-dist ./ max(mfp, eps));
end

% Bottom boundary -> +y
if isfield(boundary, 'bottom')
    dist = Y - ymin;
    tRet = t - dist ./ max(v, eps);
    amp = evaluate_boundary_emission_2d(boundary.bottom, tRet);
    profile = evaluate_boundary_profile_2d(boundary.bottom, X);
    qby = qby + prefactor .* amp .* profile .* exp(-dist ./ max(mfp, eps));
end

% Top boundary -> -y
if isfield(boundary, 'top')
    dist = ymax - Y;
    tRet = t - dist ./ max(v, eps);
    amp = evaluate_boundary_emission_2d(boundary.top, tRet);
    profile = evaluate_boundary_profile_2d(boundary.top, X);
    qby = qby - prefactor .* amp .* profile .* exp(-dist ./ max(mfp, eps));
end

ballistic = struct();
ballistic.qbx = qbx;
ballistic.qby = qby;
ballistic.qmag = sqrt(qbx.^2 + qby.^2);
end
