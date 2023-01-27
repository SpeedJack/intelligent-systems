function [layers, options, desc] = cnndef41
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
	options = trainingOptions('adam', ...
		'Shuffle', 'every-epoch', ...
		'InitialLearnRate', 0.01, ...
		'LearnRateSchedule', 'piecewise', ...
		'LearnRateDropFactor', 0.2, ...
		'LearnRateDropPeriod', 15, ...
		'MiniBatchSize', 100, ...
		'ValidationFrequency', 5, ...
		'OutputNetwork', 'best-validation-loss' ...
	);
	desc = "Dropout: 0.2";
end
