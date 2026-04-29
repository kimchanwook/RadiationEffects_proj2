function plot_module4_bd_history_metrics_2d(tHistory, energyHistory, tmaxHistory, rateNormHistory, qbmaxHistory, l2ErrorHistory, params, savePath)
figure('Visible', 'off');
plot(tHistory, energyHistory, 'LineWidth', 1.5); hold on;
plot(tHistory, tmaxHistory, 'LineWidth', 1.5);
plot(tHistory, rateNormHistory, 'LineWidth', 1.5);
plot(tHistory, qbmaxHistory, 'LineWidth', 1.5);
legendEntries = {'Thermal energy', 'T_{max}', 'RMS(dT/dt)', 'q_{b,max}'};
if any(~isnan(l2ErrorHistory))
    plot(tHistory, l2ErrorHistory, 'LineWidth', 1.5);
    legendEntries{end+1} = 'L2 error'; %#ok<AGROW>
end
legend(legendEntries, 'Location', 'best');
grid on;
xlabel('Time [s]');
ylabel('Metric value');
title(sprintf('Module 4 metrics: %s', params.verification.type));
if nargin >= 8 && ~isempty(savePath)
    exportgraphics(gcf, savePath, 'Resolution', 150);
end
close(gcf);
end
