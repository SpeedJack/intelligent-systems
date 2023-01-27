function [layers, options, desc] = cnndef39
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
		fullyConnectedLayer(50)
		fullyConnectedLayer(12)

		fullyConnectedLayer(1)

		regressionLayer
	];
	options = trainingOptions('sgdm', ...
		'Momentum', 0.9, ...,
		'Shuffle', 'every-epoch', ...
		'InitialLearnRate', 0.01, ...
		'GradientThreshold', 1, ...
		'LearnRateSchedule', 'piecewise', ...
		'LearnRateDropFactor', 0.1, ...
		'LearnRateDropPeriod', 10 ...
	);
	desc = "Training algorithm: sgdm";
end
