function [layers, options, winSize, rnnDesc] = rnndef19
	layers = [
		sequenceInputLayer(8, 'Normalization', 'zscore')
		lstmLayer(80, 'OutputMode', 'last')
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
	rnnDesc = "80 neurons";
end