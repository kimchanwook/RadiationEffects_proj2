function metrics = compute_module6_metrics(out)
% COMPUTE_MODULE6_METRICS Collect scalar diagnostics for Module 6.

s = out.stateFinal;
metrics.caseName = out.params.caseName;
metrics.finalTime = s.t;
metrics.maxDefect = max(s.C);
metrics.maxTemperature = max(s.T);
metrics.minTemperature = min(s.T);
metrics.maxPotential = max(s.phi);
metrics.minPotential = min(s.phi);
metrics.maxElectricField = max(sqrt(sum(s.E.^2,2)));
metrics.maxElectronDensity = max(s.n);
metrics.maxHoleDensity = max(s.p);
metrics.finalCouplingMetric = out.convergenceHistory(end, out.iterationCount(end));
metrics.finalIterationCount = out.iterationCount(end);
metrics.finalChargeMismatch = out.chargeMismatchHistory(end);
metrics.finalDefectInventory = out.CInventory(end);
metrics.finalElectronInventory = out.nInventory(end);
metrics.finalHoleInventory = out.pInventory(end);
if isfield(s, 'current')
    metrics.maxTotalCurrentDensity = max(sqrt(sum(s.current.Jtotal.^2,2)));
else
    metrics.maxTotalCurrentDensity = NaN;
end
end
