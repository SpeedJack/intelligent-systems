function [layers, options, desc] = cnndef24
	nf = 16;
	layers = [
		sequenceInputLayer(11, 'Normalization', 'rescale-symmetric')

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

		globalAveragePooling1dLayer

		fullyConnectedLayer(45)
		fullyConnectedLayer(10)

		fullyConnectedLayer(1)

		regressionLayer
	];
	options = trainingOptions('adam', ...
		'Shuffle', 'every-epoch', ...
		'InitialLearnRate', 0.01, ...
		'LearnRateSchedule', 'piecewise', ...
		'LearnRateDropFactor', 0.2, ...
		'LearnRateDropPeriod', 15 ...
	);
	desc = "3 convolutional layers";
end
