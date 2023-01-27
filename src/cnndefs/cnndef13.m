function [layers, options, desc] = cnndef13
	layers = [
		sequenceInputLayer(11, 'Normalization', 'rescale-symmetric')

		convolution1dLayer(11, 16, 'Stride', 2, 'Padding', 'same')
		batchNormalizationLayer
		leakyReluLayer
		maxPooling1dLayer(3, 'Stride', 2, 'Padding', 'same')

		globalAveragePooling1dLayer

		fullyConnectedLayer(30)
		fullyConnectedLayer(5)

		fullyConnectedLayer(1)

		regressionLayer
	];
	options = trainingOptions('adam', ...
		'Shuffle', 'every-epoch', ...
		'InitialLearnRate', 0.01, ...
		'LearnRateSchedule', 'piecewise' ...
	);
	desc = "Filter size = 11; Convolutional stride = 2";
end
