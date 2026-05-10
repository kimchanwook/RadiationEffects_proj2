function state = initialize_module6_fem_state(mesh, params)
% INITIALIZE_MODULE6_FEM_STATE Build initial nodal fields for Module 6.

nodes = mesh.nodes;
x = nodes(:,1);
y = nodes(:,2);
N = size(nodes,1);

switch lower(params.init.C.type)
    case 'gaussian'
        C = params.init.C.background + params.init.C.peak .* ...
            exp(-0.5*((x-params.init.C.x0)./params.init.C.sigmaX).^2 ...
                -0.5*((y-params.init.C.y0)./params.init.C.sigmaY).^2);
    case 'uniform'
        C = params.init.C.value * ones(N,1);
    otherwise
        error('Unknown Module 6 defect initial condition: %s', params.init.C.type);
end

T = params.init.T.value * ones(N,1);
n = params.init.n.value * ones(N,1);
p = params.init.p.value * ones(N,1);
phi = zeros(N,1);
E = zeros(N,2);

state.C = C;
state.T = T;
state.n = n;
state.p = p;
state.phi = phi;
state.E = E;
state.t = 0.0;
end
