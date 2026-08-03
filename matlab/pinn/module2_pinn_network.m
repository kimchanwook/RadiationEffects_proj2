function net = module2_pinn_network(opts)
% MODULE2_PINN_NETWORK Build the neural network used by the Module 2 PINN.
%
%   net = MODULE2_PINN_NETWORK(opts) returns an untrained dlnetwork that maps
%
%       [x/Lx; y/Ly]  -->  phi/Vscale.
%
%   The current implementation is the staged, single-electrostatic-case
%   model described in the Module 2 PINN notes.  It uses tanh activations
%   because the Poisson residual needs smooth first and second derivatives.
%
%   Required fields in opts:
%       numHiddenLayers   number of fully connected hidden layers
%       numNeurons        neurons in every hidden layer
%
%   MATLAB requirement: Deep Learning Toolbox.

% Check that the caller supplied the options structure used by this builder.
if nargin < 1 || ~isstruct(opts)
    error('module2_pinn_network:InvalidOptions', ...
        'Input opts must be a structure.');
end

% Check the hidden-layer count before using it to construct layer names.
validateattributes(opts.numHiddenLayers, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, ...
    'opts.numHiddenLayers');

% Check the layer width before passing it to fullyConnectedLayer.
validateattributes(opts.numNeurons, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, ...
    'opts.numNeurons');

% Each observation has two features: normalized x and normalized y.
numInputFeatures = 2;

% Start the layer array with a feature-input layer.
% Normalization is disabled here because x and y are normalized explicitly.
layers = featureInputLayer(numInputFeatures, ...
    'Normalization', 'none', ...
    'Name', 'normalized_xy');

% Append the requested number of fully connected tanh hidden layers.
for layerIndex = 1:opts.numHiddenLayers
    % Give every layer a unique name so the dlnetwork graph is easy to inspect.
    fullyConnectedName = sprintf('fully_connected_%d', layerIndex);
    activationName = sprintf('tanh_%d', layerIndex);

    % Add one affine transformation followed by one smooth nonlinearity.
    layers = [layers
        fullyConnectedLayer(opts.numNeurons, 'Name', fullyConnectedName)
        tanhLayer('Name', activationName)]; %#ok<AGROW>
end

% Add a scalar linear output representing normalized potential phi/Vscale.
layers = [layers
    fullyConnectedLayer(1, 'Name', 'normalized_potential')];

% Convert the layer graph to a dlnetwork for a custom PINN training loop.
net = dlnetwork(layerGraph(layers));
end
