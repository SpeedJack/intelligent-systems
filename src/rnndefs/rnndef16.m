function [layers, options, winSize, rnnDesc] = rnndef16
	layers = [
		sequenceInputLayer(8, 'Normalization', 'zscore')
		lstmLayer(30, 'OutputMode', 'last')
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
	rnnDesc = "30 neurons";
end
