function plot_history_metrics_2d(tHistory, massHistory, cmaxHistory, l2ErrorHistory, params, savePath)
figure('Visible', 'off');
plot(tHistory, massHistory, 'LineWidth', 1.5); hold on;
plot(tHistory, cmaxHistory, 'LineWidth', 1.5);
if any(~isnan(l2ErrorHistory))
    plot(tHistory, l2ErrorHistory, 'LineWidth', 1.5);
    legend({'Mass', 'C_{max}', 'L2 error'}, 'Location', 'best');
else
    legend({'Mass', 'C_{max}'}, 'Location', 'best');
end
grid on;
xlabel('Time');
ylabel('Metric value');
title(sprintf('Module 3 metrics: %s', params.verification.type));
if nargin >= 6 && ~isempty(savePath)
    exportgraphics(gcf, savePath, 'Resolution', 150);
end
close(gcf);
end
