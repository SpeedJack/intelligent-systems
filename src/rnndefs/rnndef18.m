function [layers, options, winSize, rnnDesc] = rnndef18
	layers = [
		sequenceInputLayer(8, 'Normalization', 'zscore')
		lstmLayer(65, 'OutputMode', 'last')
		fullyConnectedLayer(1)
		regressionLayer
	];
	options = trainingOptions('adam', ...
		'MiniBatchSize', 300, ...
		'InitialLearnRate', 0.1, ...
		'Shuffle', 'every-epoch', ...
		'SequencePaddingDirection', 'left' ...
	);
	winSize = 10;
	rnnDesc = "65 neurons";
end
