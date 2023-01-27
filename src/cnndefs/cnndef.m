function [layers, options, desc] = cnndef
	nf = 64;
	layers = [
		sequenceInputLayer(11, 'Normalization', 'zscore')

		convolution1dLayer(9, 1*nf, 'Stride', 3, 'Padding', 'same')
		batchNormalizationLayer
		leakyReluLayer
		maxPooling1dLayer(3, 'Stride', 2, 'Padding', 'same')

		convolution1dLayer(9, 2*nf, 'Stride', 3, 'Padding', 'same')
		batchNormalizationLayer
		leakyReluLayer
		maxPooling1dLayer(3, 'Stride', 2, 'Padding', 'same')

		convolution1dLayer(9, 3*nf, 'Stride', 3, 'Padding', 'same')
		batchNormalizationLayer
		leakyReluLayer
		maxPooling1dLayer(3, 'Stride', 2, 'Padding', 'same')

		convolution1dLayer(9, 4*nf, 'Stride', 3, 'Padding', 'same')
		batchNormalizationLayer
		leakyReluLayer
		maxPooling1dLayer(3, 'Stride', 2, 'Padding', 'same')

		convolution1dLayer(9, 5*nf, 'Stride', 3, 'Padding', 'same')
		batchNormalizationLayer
		leakyReluLayer
		maxPooling1dLayer(3, 'Stride', 2, 'Padding', 'same')

		globalAveragePooling1dLayer

		fullyConnectedLayer(180)
		dropoutLayer(0.2)
		fullyConnectedLayer(50)
		dropoutLayer(0.1)
		fullyConnectedLayer(10)

		fullyConnectedLayer(1)

		regressionLayer
	];
	% ValidationPatience allows for 25 epochs @ 35 iterations per epoch
	options = trainingOptions('adam', ...
		'Shuffle', 'every-epoch', ...
		'InitialLearnRate', 0.01, ...
		'LearnRateSchedule', 'piecewise', ...
		'LearnRateDropFactor', 0.25, ...
		'LearnRateDropPeriod', 25, ...
		'BatchNormalizationStatistics', 'population', ...
		'L2Regularization', 0.0001, ...
		'MiniBatchSize', 120, ...
		'ValidationFrequency', 5, ...
		'ValidationPatience', 175, ...
		'OutputNetwork', 'best-validation-loss', ...
		'GradientDecayFactor', 0.9, ...
		'SquaredGradientDecayFactor', 0.999, ...
		'Epsilon', 1e-8 ...
	);
	desc = "Final CNN";
end

% DEFAULTS (if unset)
% LearnRateSchedule: 'none'
% LearnRateDropFactor: 0.1
% LearnRateDropPeriod: 10
% L2Regularization: 0.0001
% GradientThresholdMethod: 'l2norm'
% GradientThreshold: Inf
% MaxEpochs: (set by cnntrain, default 30)
% MiniBatchSize: 128
% Verbose: true (forced by cnntrain)
% VerboseFrequency: 1 (forced by cnntrain)
% ValidationData: (set by cnntrain)
% ValidationFrequency: 50
% ValidationPatience: Inf
% Shuffle: 'once'
% CheckpointPath: ''
% CheckpointFrequency: 1
% CheckpointFrequencyUnit: 'epoch'
% ExecutionEnvironment: 'parallel' ('auto' if BatchNormalizationStatistics is 'moving') (forced by cnntrain)
% WorkerLoad: []
% OutputFcn: []
% Plots: (set by cnntrain)
% SequenceLength: 'longest'
% SequencePaddingValue: 0
% SequencePaddingDirection: 'right'
% DispatchInBackground: false
% ResetInputNormalization: true
% BatchNormalizationStatistics: 'population'
% OutputNetwork: 'last-iteration'
%
% ADAM DEFAULTS:
% GradientDecayFactor: 0.9
% SquaredGradientDecayFactor: 0.999
% Epsilon: 1.0e-08
% InitialLearnRate: 0.001
%
% SGDM DEFAULTS:
% Momentum: 0.9
% InitialLearnRate: 0.01
%
% RMSPROP DEFAULTS:
% SquaredGradientDecayFactor: 0.9
% Epsilon: 1.0e-08
% InitialLearnRate: 0.001
