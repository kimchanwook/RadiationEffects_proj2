function [dataset, validation] = main_module2_batch_fem_dataset(options)
% MAIN_MODULE2_BATCH_FEM_DATASET Generate the Module 2 field-to-field pilot.
%
%   dataset = MAIN_MODULE2_BATCH_FEM_DATASET() creates a deterministic set of
%   synthetic Gaussian charge fields on one validated Module 9 mesh, solves
%   the FEM electrostatics for each complete rho field, validates the paired
%   rho -> phi dataset, and saves one compact MAT file.
%
%   IMPORTANT: Gaussian parameters are used only to generate diverse input
%   fields. The v2 surrogate contract is the full nodal rho field mapped to
%   the full nodal phi field.
%
%   [dataset,validation] = MAIN_MODULE2_BATCH_FEM_DATASET(options) accepts an
%   edited structure returned by DEFAULT_MODULE2_BATCH_FEM_OPTIONS_2D.
%
%   Example:
%       setup_project_paths
%       [dataset, report] = main_module2_batch_fem_dataset();

if nargin < 1 || isempty(options)
    options = default_module2_batch_fem_options_2d();
end

dataset = generate_module2_batch_fem_dataset_2d(options);
validation = validate_module2_batch_fem_dataset_2d( ...
    dataset, options.validation, true);

matlabDir = fileparts(mfilename('fullpath'));
outputDir = fullfile(matlabDir, options.outputDir);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

if options.saveDataset
    datasetFile = fullfile(outputDir, options.datasetFileName);
    save(datasetFile, 'dataset', '-v7.3');
else
    datasetFile = '';
end

summaryFile = fullfile(outputDir, options.summaryFileName);
write_module2_batch_fem_summary(dataset, validation, summaryFile, datasetFile);

if options.makeRepresentativePlots
    names = options.representativeCaseNames;
    for k = 1:numel(names)
        caseIndex = find(strcmp(dataset.caseNames, names{k}), 1);
        if isempty(caseIndex)
            error('Module2BatchFEM:UnknownRepresentativeCase', ...
                'Unknown representative case name: %s', names{k});
        end
        plot_module2_batch_fem_case_2d(dataset, caseIndex, outputDir);
    end
end

fprintf('Module 2 field-to-field batch FEM dataset complete.\n');
fprintf('  mapping       : rho(nodes) -> phi(nodes)\n');
fprintf('  cases         : %d (%d train / %d validation / %d test)\n', ...
    dataset.nCases, numel(dataset.trainCases), ...
    numel(dataset.validationCases), numel(dataset.testCases));
fprintf('  mesh          : %d nodes, %d triangles\n', ...
    size(dataset.mesh.nodes, 1), size(dataset.mesh.elems, 1));
fprintf('  assemblies    : %d stiffness, %d source RHS\n', ...
    dataset.provenance.stiffnessAssemblyCount, ...
    dataset.provenance.sourceAssemblyCount);
fprintf('  factorizations: %d\n', dataset.provenance.factorizationCount);
fprintf('  worst residual: %.4e (relative)\n', ...
    validation.maxFreeResidualRelative);
fprintf('  worst balance : %.4e (relative)\n', ...
    validation.maxGlobalBalanceRelative);
fprintf('  output dir    : %s\n', outputDir);
end
