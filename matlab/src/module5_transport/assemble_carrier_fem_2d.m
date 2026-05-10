function fem = assemble_carrier_fem_2d(mesh, scalarCoeff)
% ASSEMBLE_CARRIER_FEM_2D Assemble scalar drift-diffusion-reaction matrices.
%
% The strong form is
%   c_t - div(D grad c + s*mu*E*c) = G - (c-ceq)/tau,
% with s=+1 for electrons and s=-1 for holes.

nodes = mesh.nodes;
elems = mesh.elems;
nNodes = size(nodes,1);

I = [];
J = [];
Mvals = [];
KDvals = [];
KEvals = [];
KRvals = [];
FG = zeros(nNodes,1);
FR = zeros(nNodes,1);

elementArea = zeros(size(elems,1),1);
elementGradN = zeros(3,2,size(elems,1));

for e = 1:size(elems,1)
    idx = elems(e,:);
    xe = nodes(idx,:);
    [area, gradN] = local_triangle_geometry(xe);
    Me = (area/12.0) * [2 1 1; 1 2 1; 1 1 2];

    D_e = mean(scalarCoeff.D(idx));
    mu_e = mean(scalarCoeff.mu(idx));
    Ex_e = mean(scalarCoeff.Ex(idx));
    Ey_e = mean(scalarCoeff.Ey(idx));
    tauInv_e = mean(scalarCoeff.tauInv(idx));
    G_e = mean(scalarCoeff.G(idx));
    ceq_e = mean(scalarCoeff.ceq(idx));
    Evec = [Ex_e, Ey_e];

    Kd = D_e * area * (gradN * gradN.');
    Ke = zeros(3,3);
    for a = 1:3
        advFactor = scalarCoeff.driftSign * mu_e * dot(gradN(a,:), Evec) * area / 3.0;
        for b = 1:3
            Ke(a,b) = advFactor;
        end
    end
    Kr = tauInv_e * Me;
    Fg = (area/3.0) * G_e * ones(3,1);
    Fr = (area/3.0) * tauInv_e * ceq_e * ones(3,1);

    for a = 1:3
        A = idx(a);
        FG(A) = FG(A) + Fg(a);
        FR(A) = FR(A) + Fr(a);
        for b = 1:3
            B = idx(b);
            I(end+1,1) = A; %#ok<AGROW>
            J(end+1,1) = B; %#ok<AGROW>
            Mvals(end+1,1) = Me(a,b); %#ok<AGROW>
            KDvals(end+1,1) = Kd(a,b); %#ok<AGROW>
            KEvals(end+1,1) = Ke(a,b); %#ok<AGROW>
            KRvals(end+1,1) = Kr(a,b); %#ok<AGROW>
        end
    end

    elementArea(e) = area;
    elementGradN(:,:,e) = gradN;
end

fem.M = sparse(I,J,Mvals,nNodes,nNodes);
fem.KD = sparse(I,J,KDvals,nNodes,nNodes);
fem.KE = sparse(I,J,KEvals,nNodes,nNodes);
fem.KR = sparse(I,J,KRvals,nNodes,nNodes);
fem.FG = FG;
fem.FR = FR;
fem.elementArea = elementArea;
fem.elementGradN = elementGradN;
end

function [area, gradN] = local_triangle_geometry(xe)
x1 = xe(1,1); y1 = xe(1,2);
x2 = xe(2,1); y2 = xe(2,2);
x3 = xe(3,1); y3 = xe(3,2);
area2 = (x2-x1)*(y3-y1) - (x3-x1)*(y2-y1);
area = 0.5 * area2;
if area <= 0
    error('Triangle area must be positive. Check node ordering.');
end
b = [y2-y3; y3-y1; y1-y2];
c = [x3-x2; x1-x3; x2-x1];
gradN = [b c] ./ (2.0 * area);
end
