function design = make_module2_batch_parameter_design_2d()
% MAKE_MODULE2_BATCH_PARAMETER_DESIGN_2D Legacy compatibility wrapper.
%
%   The old name is retained so external scripts do not break. The returned
%   values now explicitly describe a synthetic Gaussian FIELD GENERATOR,
%   not the Module 2 surrogate input contract.

designV2 = make_module2_gaussian_field_pilot_design_2d();
design = designV2;

% Legacy aliases retained temporarily for older scripts/tests. New code
% should use generatorParameterNames, generatorParameterUnits, and
% generatorParameters.
design.parameterNames = designV2.generatorParameterNames;
design.parameterUnits = designV2.generatorParameterUnits;
design.parameters = designV2.generatorParameters;
end
