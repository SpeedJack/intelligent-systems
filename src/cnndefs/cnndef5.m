function [layers, options, desc] = cnndef5
	layers = [
		sequenceInputLayer(11, 'Normalization', 'rescale-symmetric')

		convolution1dLayer(25, 16, 'Stride', 4, 'Padding', 'same')
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
	desc = "Increased convolutional stride from 2 to 4, filter size = 25 (from cnndef3)";
end
