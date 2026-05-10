function current = compute_current_density_fem_2d(mesh, n, p, coeff, elementGradN)
% COMPUTE_CURRENT_DENSITY_FEM_2D Elementwise Module 5 current densities.

q = 1.602176634e-19;
if isfield(coeff, 'q')
    q = coeff.q;
end

elems = mesh.elems;
nElem = size(elems,1);
centers = zeros(nElem,2);
Jn = zeros(nElem,2);
Jp = zeros(nElem,2);

elem_n = zeros(nElem,1);
elem_p = zeros(nElem,1);

for e = 1:nElem
    idx = elems(e,:);
    centers(e,:) = mean(mesh.nodes(idx,:),1);
    gradN = elementGradN(:,:,e);
    gradn = (n(idx).') * gradN;
    gradp = (p(idx).') * gradN;
    navg = mean(n(idx));
    pavg = mean(p(idx));
    mu_n = mean(coeff.mu_n(idx));
    mu_p = mean(coeff.mu_p(idx));
    D_n = mean(coeff.D_n(idx));
    D_p = mean(coeff.D_p(idx));
    E = [mean(coeff.Ex(idx)), mean(coeff.Ey(idx))];
    Jn(e,:) = q * mu_n * navg * E + q * D_n * gradn;
    Jp(e,:) = q * mu_p * pavg * E - q * D_p * gradp;
    elem_n(e) = navg;
    elem_p(e) = pavg;
end

current.centers = centers;
current.Jn = Jn;
current.Jp = Jp;
current.Jtotal = Jn + Jp;
current.nElement = elem_n;
current.pElement = elem_p;
end
