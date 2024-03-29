function [layers, options, winSize, rnnDesc] = rnndef6
	layers = [
		sequenceInputLayer(8, 'Normalization', 'rescale-symmetric')
		lstmLayer(50, 'OutputMode', 'last')
		fullyConnectedLayer(1)
		regressionLayer
	];
	options = trainingOptions('adam', ...
		'MiniBatchSize', 300, ...
		'InitialLearnRate', 0.1, ...
		'Shuffle', 'every-epoch', ...
		'SequencePaddingDirection', 'left' ...
	);
	winSize = 60;
	rnnDesc = "winSize = 60";
end
