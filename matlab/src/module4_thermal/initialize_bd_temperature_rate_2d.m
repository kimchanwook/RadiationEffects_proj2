function dTdt = initialize_bd_temperature_rate_2d(gridData, init)
if isfield(init, 'dTdt0')
    if isscalar(init.dTdt0)
        dTdt = init.dTdt0 * ones(gridData.Ny, gridData.Nx);
    else
        dTdt = init.dTdt0;
    end
else
    dTdt = zeros(gridData.Ny, gridData.Nx);
end
end
