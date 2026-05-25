% Objective:
%    - Analysis code of Radiation Effects 2 project 
%
% Notes & References:
%    - https://github.com/kimchanwook/RadiationEffects_proj2
%    - For better visibility and navigation of the code, I suggest enabling the code-folding feature
%
% Author: Chan Wook (Luke) Kim

%% ---------------------------------------- Configurations ---------------------------------------------------

%% Change DIR to current WD 
if(~isdeployed)
    cd(fileparts(matlab.desktop.editor.getActiveFilename));
end

%% ---------------------------------------- ReadData ---------------------------------------------------------
%% read_module1_synthetic_mat()                                                                       ReadData
% Directory where the .mat file is saved.
% Edit this path for your local machine.
dataDir = fullfile(pwd, "RadiationEffects_proj2", "preliminary", "module1_synthetic_three_strike_cascade");

% Name of the synthetic Module 1 .mat file.
matFileName = "module1_synthetic_3strike_cascade_20x20x50um_100x100x250.mat";

% Full path to the .mat file.
matPath = fullfile(dataDir, matFileName);

% Read data
% M1 is a struct and of its attribute, Edep_MeV is the 3D histogram we want
M1 = read_module1_synthetic_mat(matPath);

%% ---------------------------------------- Save&Load --------------------------------------------------------



%% ---------------------------------------- Preprocessing ----------------------------------------------------



%% ---------------------------------------- Module_1 ---------------------------------------------------------


%% plot_Edep3D_volSpilt()					                                                    Module_1: Plot


%% plot_Edep3D_scatter3()                                                                       Module_1: Plot
plot_Edep3D = plot_Edep3D_scatter3(M1.Edep_MeV, M1.x_um, M1.y_um, M1.z_um);

%% Edep3D_average_over_y()                                                                      Module_1: Compute
[Edep_xz_avg, x_out_um, z_out_um] = Edep3D_average_over_y(M1.Edep_MeV, M1.x_um, M1.y_um, M1.z_um);

%% plot_Edep_xz_heatmap()                                                                       Module_1: Plot
plot_Edep2D = plot_Edep_xz_heatmap(Edep_xz_avg, x_out_um, z_out_um);

%%
%%
%%
%% ---------------------------------------- Function Declarations --------------------------------------------
%% read_module1_synthetic_mat()                                                                       ReadData
function M1 = read_module1_synthetic_mat(matPath)
%READ_MODULE1_SYNTHETIC_MAT Read synthetic Module 1 radiation data.
%
%   M1 = READ_MODULE1_SYNTHETIC_MAT(matPath)
%
%   Input
%   -----
%   matPath : string or character vector
%       Full path to the MATLAB .mat file containing the synthetic
%       radiation energy-deposition data.
%
%   Output
%   ------
%   M1 : struct
%       Struct containing the loaded Module 1 arrays and metadata.
%
%   Expected fields in the .mat file
%   --------------------------------
%   Edep_MeV      : total deposited energy per voxel [MeV]
%   Edep_J        : total deposited energy per voxel [J]
%   dose_Gy       : absorbed dose per voxel [Gy]
%   E_high_MeV    : high-energy event contribution [MeV]
%   E_medium_MeV  : medium-energy event contribution [MeV]
%   E_low_MeV     : low-energy event contribution [MeV]
%   event_id      : dominant event label
%   x_um, y_um, z_um : cell-centered coordinates [um]
%
%   Coordinate convention
%   ---------------------
%   x = lateral coordinate [um]
%   y = out-of-plane lateral coordinate [um]
%   z = depth into silicon [um]

    arguments
        matPath {mustBeTextScalar}
    end

    matPath = string(matPath);

    if ~isfile(matPath)
        error("read_module1_synthetic_mat:FileNotFound", ...
            "Could not find the .mat file:\n%s", matPath);
    end

    raw = load(matPath);

    requiredFields = [ ...
        "Edep_MeV", ...
        "Edep_J", ...
        "dose_Gy", ...
        "E_high_MeV", ...
        "E_medium_MeV", ...
        "E_low_MeV", ...
        "event_id", ...
        "x_um", ...
        "y_um", ...
        "z_um" ...
    ];

    for n = 1:numel(requiredFields)
        fieldName = requiredFields(n);
        if ~isfield(raw, fieldName)
            error("read_module1_synthetic_mat:MissingField", ...
                "The file is missing the required field: %s", fieldName);
        end
    end

    M1 = struct();

    % File information
    M1.file_path = char(matPath);

    % Main radiation energy-deposition fields
    M1.Edep_MeV     = raw.Edep_MeV;
    M1.Edep_J       = raw.Edep_J;
    M1.dose_Gy      = raw.dose_Gy;

    % Separate event contributions
    M1.E_high_MeV   = raw.E_high_MeV;
    M1.E_medium_MeV = raw.E_medium_MeV;
    M1.E_low_MeV    = raw.E_low_MeV;
    M1.event_id     = raw.event_id;

    % Coordinates
    M1.x_um = raw.x_um(:);
    M1.y_um = raw.y_um(:);
    M1.z_um = raw.z_um(:);

    % Optional bin edges, if present
    if isfield(raw, "x_edges_um")
        M1.x_edges_um = raw.x_edges_um(:);
    end

    if isfield(raw, "y_edges_um")
        M1.y_edges_um = raw.y_edges_um(:);
    end

    if isfield(raw, "z_edges_um")
        M1.z_edges_um = raw.z_edges_um(:);
    end

    % Grid spacing
    if isfield(raw, "dx_um")
        M1.dx_um = double(raw.dx_um);
    else
        M1.dx_um = mean(diff(M1.x_um));
    end

    if isfield(raw, "dy_um")
        M1.dy_um = double(raw.dy_um);
    else
        M1.dy_um = mean(diff(M1.y_um));
    end

    if isfield(raw, "dz_um")
        M1.dz_um = double(raw.dz_um);
    else
        M1.dz_um = mean(diff(M1.z_um));
    end

    % Optional material / voxel metadata
    if isfield(raw, "voxel_volume_m3")
        M1.voxel_volume_m3 = double(raw.voxel_volume_m3);
    else
        M1.voxel_volume_m3 = ...
            (M1.dx_um * 1e-6) * ...
            (M1.dy_um * 1e-6) * ...
            (M1.dz_um * 1e-6);
    end

    if isfield(raw, "rho_Si_kg_m3")
        M1.rho_Si_kg_m3 = double(raw.rho_Si_kg_m3);
    else
        M1.rho_Si_kg_m3 = 2330.0;
    end

    % Basic size checks
    expectedSize = [numel(M1.x_um), numel(M1.y_um), numel(M1.z_um)];

    if ~isequal(size(M1.Edep_MeV), expectedSize)
        error("read_module1_synthetic_mat:SizeMismatch", ...
            "Size mismatch: Edep_MeV has size [%s], but coordinates imply [%s].", ...
            num2str(size(M1.Edep_MeV)), num2str(expectedSize));
    end

    if ~isequal(size(M1.Edep_J), expectedSize)
        error("read_module1_synthetic_mat:SizeMismatch", ...
            "Size mismatch: Edep_J does not match Edep_MeV.");
    end

    if ~isequal(size(M1.dose_Gy), expectedSize)
        error("read_module1_synthetic_mat:SizeMismatch", ...
            "Size mismatch: dose_Gy does not match Edep_MeV.");
    end

    % Energy summary
    M1.energy_summary_MeV = struct();
    M1.energy_summary_MeV.high   = sum(M1.E_high_MeV(:));
    M1.energy_summary_MeV.medium = sum(M1.E_medium_MeV(:));
    M1.energy_summary_MeV.low    = sum(M1.E_low_MeV(:));
    M1.energy_summary_MeV.total  = sum(M1.Edep_MeV(:));
end

%% plot_Edep3D_volSpilt()					                                                    Module_1: Plot
function [fig_hand] = plot_Edep3D_volSpilt(xbinCnt3D, ybinCnt3D, zbinCnt3D, volData)
    %Create figure
    %fig_hand = figure();
    fig_hand = figure(Position=[0, 0, 700, 500]);

    %Shorten var. names
    [x, y, z, v] = deal(xbinCnt3D, ybinCnt3D, zbinCnt3D, volData);

    %Determine the range of the vols by finding the min and max of the data
    xmin = min(x(:));
    ymin = min(y(:));
    zmin = min(z(:));
    xmax = max(x(:));
    ymax = max(y(:));
    zmax = max(z(:));

    %Draw volSlice planes
    hx = slice(x, y, z, v, xmax, [], []);
    hold on;
    hx.FaceColor = 'interp';
    hx.EdgeColor = 'none';
    hy = slice(x, y, z, v, [], ymax, []);
    hy.FaceColor = 'interp';
    hy.EdgeColor = 'none';
    hold on;
    hy = slice(x, y, z, v, [], 0, []);
    hold on;
    hy.FaceColor = 'interp';
    hy.EdgeColor = 'none';
    hz = slice(x, y, z, v, [], [], zmin);
    hold on;
    hz.FaceColor = 'interp';
    hz.EdgeColor = 'none';
    hz = slice(x, y, z, v, [], [], zmax);
    hold on;
    hz.FaceColor = 'interp';
    hz.EdgeColor = 'none';

    %Define the View
    %axis tight;              %fit axis tightly around the volume
    rotate3d();               %Find best view
    %view(-73, 26);
    %view(-12, 18);
    %view(-16, 61);
    view(-41, 27);

    %Specify colormap
    colormap(turbo(24));              %Creates gradient lines
    %clim([0, 400]);                  %Adjust colorlimits
    colorbar();

    %ETC
    title("3D Energy Deposits");
    xlabel("endX");
    ylabel("endY");
    zlabel("endZ");
    zlim([zmin zmax]);
    grid on;
    grid minor;

    %Mkdir for today
    crrnt_Dir = pwd;
    todayDate = char(datetime('today', 'Format', 'MM_dd_yyyy'));
    fin_dir = [crrnt_Dir '\plots\' todayDate];
    if ~exist(fin_dir, 'dir')
        mkdir(fin_dir);
    end

    %Saving
    saveas(fig_hand, strcat(string(fin_dir), "\", "Module_1", "_Edep3D_volSplit", ".png"));
end

%% plot_Edep3D_scatter3()                                                                       Module_1: Plot
function fig = plot_Edep3D_scatter3(Edep3D, x_um, y_um, z_um, qThresh, maxPoints)
%PLOT_MODULE1_CASCADE_3D_SIMPLE Plot high-deposition voxels from a 3D histogram.
%
%   fig = plot_module1_cascade_3d_simple(Edep3D, x_um, y_um, z_um)
%
%   fig = plot_module1_cascade_3d_simple(Edep3D, x_um, y_um, z_um, qThresh, maxPoints)
%
%   Inputs
%   ------
%   Edep3D : 3D array
%       Three-dimensional deposited-energy histogram.
%       Expected indexing:
%
%           Edep3D(ix, iy, iz)
%
%       where ix indexes x, iy indexes y, and iz indexes z.
%
%   x_um : vector
%       Cell-centered x coordinates [um].
%
%   y_um : vector
%       Cell-centered y coordinates [um].
%
%   z_um : vector
%       Cell-centered z coordinates [um].
%
%   qThresh : scalar, optional
%       Quantile threshold used to select high-deposition voxels.
%       Example: qThresh = 0.985 plots the top 1.5 percent of nonzero voxels.
%       Default: 0.985
%
%   maxPoints : integer, optional
%       Maximum number of voxels to plot after thresholding.
%       Default: 8000
%
%   Output
%   ------
%   fig : MATLAB figure handle
%
%   Coordinate convention
%   ---------------------
%   x = lateral coordinate [um]
%   y = out-of-plane lateral coordinate [um]
%   z = depth into silicon [um]
%
%   This function does not sum, average, or project the data.
%   It directly plots selected voxels from the full 3D histogram.

    if nargin < 5 || isempty(qThresh)
        qThresh = 0.985;
    end

    if nargin < 6 || isempty(maxPoints)
        maxPoints = 8000;
    end

    % Force coordinate vectors to columns.
    x_um = x_um(:);
    y_um = y_um(:);
    z_um = z_um(:);

    % Basic validation.
    expectedSize = [numel(x_um), numel(y_um), numel(z_um)];

    if ~isequal(size(Edep3D), expectedSize)
        error("Size mismatch: size(Edep3D) = [%s], but coordinates imply [%s].", ...
              num2str(size(Edep3D)), num2str(expectedSize));
    end

    if qThresh <= 0 || qThresh >= 1
        error("qThresh must be between 0 and 1.");
    end

    if maxPoints <= 0
        error("maxPoints must be positive.");
    end

    % Convert to double for thresholding and plotting.
    E = double(Edep3D);

    positiveVals = E(E > 0);

    if isempty(positiveVals)
        error("Edep3D contains no positive deposited-energy values.");
    end

    % Select high-deposition voxels.
    threshold = quantile(positiveVals, qThresh);

    selectedLinearIdx = find(E >= threshold);

    % Reproducible downsampling if too many voxels are selected.
    if numel(selectedLinearIdx) > maxPoints
        rng(12345, "twister");
        keep = randperm(numel(selectedLinearIdx), maxPoints);
        selectedLinearIdx = selectedLinearIdx(keep);
    end

    % Convert linear indices to x/y/z voxel indices.
    [ix, iy, iz] = ind2sub(size(E), selectedLinearIdx);

    xs = x_um(ix);
    ys = y_um(iy);
    zs = z_um(iz);

    vals = E(selectedLinearIdx);

    % Color by log10 of deposited energy.
    % colorVals = log10(vals + realmin);  

    % ------------------------------------------------------------
    % Academic-style 3D plot
    % ------------------------------------------------------------
    fig = figure();
    % fig = figure(Position=[100 100 900 650]);    
    % fig = figure(Position=[100 100 700 500]);    
    
    ax = axes(fig);
    hold(ax, "on");

    h = scatter3(ax, xs, ys, zs, 7, vals, "filled");
    % h = scatter3(ax, xs, ys, zs, 7, colorVals, "filled");

    colormap(ax, parula(256));
    cb = colorbar(ax);
    cb.Label.String = "Deposited energy [MeV/voxel]";
    % cb.Label.String = "$\log_{10}$ deposited energy [MeV/voxel]";
    cb.Label.Interpreter = "latex";
    cb.Label.FontSize = 13;
    cb.TickLabelInterpreter = "latex";

    xlabel(ax, "$x~[\mu\mathrm{m}]$", "Interpreter", "latex");
    ylabel(ax, "$y~[\mu\mathrm{m}]$", "Interpreter", "latex");
    zlabel(ax, "$z~[\mu\mathrm{m}]$", "Interpreter", "latex");

    title(ax, "3D radiation energy deposition: Synthetic Data", ...
          "FontWeight", "normal");

    xlim(ax, [min(x_um), max(x_um)]);
    ylim(ax, [min(y_um), max(y_um)]);
    zlim(ax, [min(z_um), max(z_um)]);

    %Reverse Z-direction sizne z=0 is top and z increase means going deeper
    set(ax, "ZDir", "reverse");

    grid(ax, "on");
    box(ax, "on");
    view(ax, -42, 24);
    set(ax, ...
        "FontName", "Times New Roman", ...
        "FontSize", 13, ...
        "LineWidth", 1.1, ...
        "TickDir", "out", ...
        "TickLabelInterpreter", "latex", ...
        "Layer", "top");

    % Visual aspect ratio.
    % Since the silicon domain is 20 x 20 x 50 um, true physical aspect
    % makes z look tall. This display aspect is usually clearer for talks.
    pbaspect(ax, [1.0 1.0 1.25]);
    hold(ax, "off");

    %Mkdir for today
    crrnt_Dir = pwd;
    todayDate = char(datetime('today', 'Format', 'MM_dd_yyyy'));
    fin_dir = [crrnt_Dir '\plots\' todayDate];
    if ~exist(fin_dir, 'dir')
        mkdir(fin_dir);
    end

    %Saving
    saveas(fig, strcat(string(fin_dir), "\", "Module_1", "_Edep3D_scatter3", ".png"));

end

%% Edep3D_average_over_y()                                                                      Module_1: Compute
function [Edep_xz_avg, x_out_um, z_out_um] = Edep3D_average_over_y(Edep3D, x_um, y_um, z_um)
%AVERAGE_MODULE1_OVER_Y Average a 3D Module 1 energy-deposition histogram over y.
%
%   [Edep_xz_avg, x_out_um, z_out_um] = average_module1_over_y(Edep3D, x_um, y_um, z_um)
%
%   Inputs
%   ------
%   Edep3D : 3D array
%       Three-dimensional energy-deposition histogram.
%
%       Expected indexing:
%
%           Edep3D(ix, iy, iz)
%
%       where:
%           ix indexes x,
%           iy indexes y,
%           iz indexes z.
%
%   x_um : vector
%       Cell-centered x coordinates [um].
%
%   y_um : vector
%       Cell-centered y coordinates [um].
%
%   z_um : vector
%       Cell-centered z coordinates [um].
%
%   Outputs
%   -------
%   Edep_xz_avg : 2D array
%       y-averaged deposited-energy histogram on the x-z plane.
%
%       Indexing:
%
%           Edep_xz_avg(ix, iz)
%
%       Mathematically:
%
%           Edep_xz_avg(ix, iz) = mean_y Edep3D(ix, iy, iz)
%
%   x_out_um : vector
%       x coordinates [um].
%
%   z_out_um : vector
%       z coordinates [um].
%
%   Coordinate convention
%   ---------------------
%   x = lateral coordinate [um]
%   y = out-of-plane coordinate [um]
%   z = depth into silicon [um]
%
%   Important note
%   --------------
%   This function performs an average over y, not a sum.
%
%       average over y:  Edep_xz_avg = squeeze(mean(Edep3D, 2))
%       sum over y:      Edep_xz_sum = squeeze(sum(Edep3D, 2))
%
%   For converting a 3D volumetric source field into a 2D x-z source field,
%   averaging over the out-of-plane y direction is usually the correct
%   reduction. For conserving total deposited energy in the x-z projection,
%   use summation instead.

    % Force coordinate arrays to column vectors.
    x_um = x_um(:);
    y_um = y_um(:);
    z_um = z_um(:);

    % Validate dimensions.
    expectedSize = [numel(x_um), numel(y_um), numel(z_um)];

    if ~isequal(size(Edep3D), expectedSize)
        error("average_module1_over_y:SizeMismatch", ...
            "size(Edep3D) = [%s], but coordinates imply [%s].", ...
            num2str(size(Edep3D)), num2str(expectedSize));
    end

    % Average over dimension 2, which is the y direction.
    Edep_xz_avg = squeeze(mean(Edep3D, 2));

    % After squeeze, the output should be size Nx by Nz.
    expectedOutputSize = [numel(x_um), numel(z_um)];

    if ~isequal(size(Edep_xz_avg), expectedOutputSize)
        error("average_module1_over_y:OutputSizeMismatch", ...
            "Unexpected output size. Got [%s], expected [%s].", ...
            num2str(size(Edep_xz_avg)), num2str(expectedOutputSize));
    end

    % Return coordinate vectors for the 2D x-z field.
    x_out_um = x_um;
    z_out_um = z_um;

end

%% plot_Edep_xz_heatmap()                                                                       Module_1: Plot
function fig = plot_Edep_xz_heatmap(Edep_xz, x_um, z_um)
%PLOT_MODULE1_XZ_HEATMAP Plot a 2D x-z energy-deposition histogram as a heat map.
%
%   fig = plot_module1_xz_heatmap(Edep_xz, x_um, z_um)
%
%   Inputs
%   ------
%   Edep_xz : 2D array
%       Two-dimensional energy-deposition histogram.
%
%       Expected indexing:
%
%           Edep_xz(ix, iz)
%
%       where:
%           ix indexes x,
%           iz indexes z.
%
%   x_um : vector
%       Cell-centered x coordinates [um].
%
%   z_um : vector
%       Cell-centered z coordinates [um].
%
%   Output
%   ------
%   fig : MATLAB figure handle
%
%   Coordinate convention
%   ---------------------
%   x = lateral coordinate [um]
%   z = depth into silicon [um]
%
%   Display convention
%   ------------------
%   z = 0 is drawn at the top surface.
%   Larger z is drawn downward into the silicon.
%
%   Color convention
%   ----------------
%   The smallest deposited-energy value is mapped to white.

    x_um = x_um(:);
    z_um = z_um(:);

    expectedSize = [numel(x_um), numel(z_um)];

    if ~isequal(size(Edep_xz), expectedSize)
        error("plot_module1_xz_heatmap:SizeMismatch", ...
            "size(Edep_xz) = [%s], but coordinates imply [%s].", ...
            num2str(size(Edep_xz)), num2str(expectedSize));
    end

    E = double(Edep_xz);

    fig = figure( ...
        "Color", "w", ...
        "Units", "pixels", ...
        "Position", [100 100 900 650]);

    ax = axes("Parent", fig);

    % imagesc expects matrix rows to correspond to the vertical axis.
    % E is stored as E(ix, iz), so transpose it for plotting.
    imagesc(ax, x_um, z_um, E.');

    % Put z = 0 at the top and increasing depth downward.
    set(ax, "YDir", "reverse");

    % ------------------------------------------------------------
    % Colormap: white for the smallest/zero value, then turbo.
    % ------------------------------------------------------------
    nColors = 256;
    baseMap = turbo(nColors - 1);
    whiteToColorMap = [1 1 1; baseMap];

    colormap(ax, whiteToColorMap);

    % Force the smallest value to map to white.
    cMin = min(E(:));
    cMax = max(E(:));

    if cMax > cMin
        clim(ax, [cMin cMax]);
    else
        clim(ax, [cMin cMin + eps]);
    end

    cb = colorbar(ax);
    cb.Label.String = "Mean deposited energy [MeV/voxel]";

    xlabel(ax, "x [\mum]");
    ylabel(ax, "depth z [\mum]");
    title(ax, "Y-averaged Module 1 deposited energy");

    axis(ax, "tight");

    % ------------------------------------------------------------
    % Fine grid.
    % ------------------------------------------------------------
    % The heat-map grid is visually controlled by tick spacing.
    % For the current synthetic dataset, dx = dz = 0.2 um.
    % Plotting every voxel grid line is usually too dense, so this uses
    % a fine but readable 1 um grid.
    xMajorSpacing_um = 2.0;
    zMajorSpacing_um = 5.0;

    xMinorSpacing_um = 1.0;
    zMinorSpacing_um = 1.0;

    xlim(ax, [min(x_um), max(x_um)]);
    ylim(ax, [min(z_um), max(z_um)]);

    grid(ax, "on");
    ax.Layer = "top";
    ax.GridColor = [0.35 0.35 0.35];
    ax.MinorGridColor = [0.65 0.65 0.65];
    ax.GridAlpha = 0.35;
    ax.MinorGridAlpha = 0.25;
    ax.XMinorGrid = "on";
    ax.YMinorGrid = "on";

    % Force light-theme appearance even if MATLAB is in dark mode.
    set(fig, ...
        "Color", "w", ...
        "InvertHardcopy", "off");

    set(ax, ...
        "Color", "w", ...
        "XColor", "k", ...
        "YColor", "k", ...
        "FontSize", 16, ...
        "LineWidth", 0.9);

    ax.Title.Color  = "k";
    ax.XLabel.Color = "k";
    ax.YLabel.Color = "k";

    cb.Color = "k";
    cb.Label.Color = "k";

    box(ax, "on");

    %Mkdir for today
    crrnt_Dir = pwd;
    todayDate = char(datetime('today', 'Format', 'MM_dd_yyyy'));
    fin_dir = [crrnt_Dir '\plots\' todayDate];
    if ~exist(fin_dir, 'dir')
        mkdir(fin_dir);
    end

    %Saving
    saveas(fig, strcat(string(fin_dir), "\", "Module_1", "_Edep2D_heatmap", ".png"));    

end

%% ---------------------------------------- Deprecated -------------------------------------------------------
%% ---------------------------------------- END --------------------------------------------------------------
