function [layers, options, desc] = cnndef3
	layers = [
		sequenceInputLayer(11, 'Normalization', 'rescale-symmetric')

		convolution1dLayer(25, 16, 'Stride', 2, 'Padding', 'same')
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
	desc = "Increased filter size from 15 to 25";
end
