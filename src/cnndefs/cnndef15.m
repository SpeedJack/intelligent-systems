function [layers, options, desc] = cnndef15
	layers = [
		sequenceInputLayer(11, 'Normalization', 'rescale-symmetric')

		convolution1dLayer(9, 16, 'Stride', 3, 'Padding', 'same')
		batchNormalizationLayer
		leakyReluLayer
		averagePooling1dLayer(3, 'Stride', 2, 'Padding', 'same')

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
	desc = "Pooling: avg; Global pooling: avg (from cnndef7)";
end
