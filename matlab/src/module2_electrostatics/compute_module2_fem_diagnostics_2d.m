function diagnostics = compute_module2_fem_diagnostics_2d( ...
    K, rhs, phi, fixedNodes, fixedValues)
% COMPUTE_MODULE2_FEM_DIAGNOSTICS_2D Residual, BC, and balance checks.
%
%   The unconstrained residual K*phi-rhs vanishes at every free node.  Its
%   values at Dirichlet nodes are the constraint reactions.  For homogeneous
%   natural Neumann boundaries, the sum of those reactions plus the assembled
%   volume source must vanish; this supplies a discrete global balance check.

numNodes = numel(phi);
allNodes = (1:numNodes).';
freeNodes = setdiff(allNodes, fixedNodes(:));
residual = K * phi - rhs;

if isempty(freeNodes)
    freeResidualInf = 0.0;
    freeScale = 1.0;
else
    freeResidualInf = norm(residual(freeNodes), inf);
    % Use the magnitude of the individual assembled matrix contributions as
    % the cancellation scale.  Using norm(K*phi) would equal the residual in
    % a zero-source Laplace problem and would incorrectly report a relative
    % residual of one even for a floating-point-accurate solve.
    matrixContributionScale = norm( ...
        abs(K(freeNodes, :)) * abs(phi), inf);
    freeScale = max([norm(rhs(freeNodes), inf), ...
        matrixContributionScale, realmin]);
end

if isempty(fixedNodes)
    dirichletErrorInf = NaN;
    reactionSum = NaN;
else
    dirichletErrorInf = norm(phi(fixedNodes) - fixedValues(:), inf);
    reactionSum = sum(residual(fixedNodes));
end

sourceSum = sum(rhs);
globalBalance = reactionSum + sourceSum;
balanceScale = max([sum(abs(rhs)), ...
    sum(abs(residual(fixedNodes))), realmin]);

diagnostics.residual = residual;
diagnostics.freeNodes = freeNodes;
diagnostics.freeResidualInf = freeResidualInf;
diagnostics.freeResidualRelative = freeResidualInf / freeScale;
diagnostics.dirichletErrorInf = dirichletErrorInf;
diagnostics.constraintReactionSum = reactionSum;
diagnostics.assembledSourceSum = sourceSum;
diagnostics.globalBalance = globalBalance;
diagnostics.globalBalanceRelative = abs(globalBalance) / balanceScale;
end
