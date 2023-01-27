function [layers, options, desc] = cnndef18
	layers = [
		sequenceInputLayer(11, 'Normalization', 'rescale-symmetric')

		convolution1dLayer(9, 16, 'Stride', 3, 'Padding', 'same')
		batchNormalizationLayer
		leakyReluLayer
		maxPooling1dLayer(3, 'Stride', 1, 'Padding', 'same')

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
	desc = "Decreased pooling stride from 2 to 1 (from cnndef7)";
end
