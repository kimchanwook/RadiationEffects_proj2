function coeff = evaluate_module5_fem_coefficients_2d(mesh, params, t)
% EVALUATE_MODULE5_FEM_COEFFICIENTS_2D Build nodal fields for a Module 5 FEM step.
%
% This reduced implementation supports uniform electric fields, optional
% Gaussian defect-degraded mobility, linear lifetime recombination, and
% simple volumetric generation sources.

if nargin < 3
    t = 0.0; %#ok<NASGU>
end

x = mesh.nodes(:,1);
y = mesh.nodes(:,2);
N = size(mesh.nodes,1);

T = params.physics.temperature * ones(N,1);
mu_n0 = params.physics.mu_n_ref * (T ./ params.physics.Tref).^(-params.physics.gamma_n);
mu_p0 = params.physics.mu_p_ref * (T ./ params.physics.Tref).^(-params.physics.gamma_p);

switch lower(params.defects.type)
    case 'none'
        C = zeros(N,1);
    case 'uniform'
        C = params.defects.C0 * ones(N,1);
    case 'gaussian'
        r2 = (x - params.defects.x0).^2 + (y - params.defects.y0).^2;
        C = params.defects.C0 * exp(-r2 ./ (2.0 * params.defects.sigma^2));
    otherwise
        error('Unknown defect field type: %s', params.defects.type);
end

mu_n = mu_n0 ./ (1.0 + params.defects.alpha_n .* C);
mu_p = mu_p0 ./ (1.0 + params.defects.alpha_p .* C);

if params.physics.useEinstein
    Vt = params.physics.kB .* T ./ params.physics.q;
    D_n = mu_n .* Vt;
    D_p = mu_p .* Vt;
else
    D_n = params.physics.D_n * ones(N,1);
    D_p = params.physics.D_p * ones(N,1);
end

switch lower(params.field.type)
    case 'uniform'
        Ex = params.field.Ex * ones(N,1);
        Ey = params.field.Ey * ones(N,1);
    otherwise
        error('Unknown electric-field type: %s', params.field.type);
end

switch lower(params.source.type)
    case 'none'
        G = zeros(N,1);
    case 'uniform'
        G = params.source.G0 * ones(N,1);
    case 'gaussian'
        r2 = (x - params.source.x0).^2 + (y - params.source.y0).^2;
        G = params.source.G0 * exp(-r2 ./ (2.0 * params.source.sigma^2));
    otherwise
        error('Unknown generation source type: %s', params.source.type);
end

switch lower(params.recombination.type)
    case 'none'
        tauInv_n = zeros(N,1);
        tauInv_p = zeros(N,1);
        n_eq = zeros(N,1);
        p_eq = zeros(N,1);
    case 'linear_lifetime'
        tauInv_n = (1.0 / params.recombination.tau_n) * ones(N,1);
        tauInv_p = (1.0 / params.recombination.tau_p) * ones(N,1);
        n_eq = params.recombination.n_eq * ones(N,1);
        p_eq = params.recombination.p_eq * ones(N,1);
    otherwise
        error('Unknown recombination type: %s', params.recombination.type);
end

coeff.T = T;
coeff.Cdef = C;
coeff.Ex = Ex;
coeff.Ey = Ey;
coeff.mu_n = mu_n;
coeff.mu_p = mu_p;
coeff.D_n = D_n;
coeff.D_p = D_p;
coeff.G = G;
coeff.tauInv_n = tauInv_n;
coeff.tauInv_p = tauInv_p;
coeff.n_eq = n_eq;
coeff.p_eq = p_eq;
end
