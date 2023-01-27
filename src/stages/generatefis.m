function generated = generatefis(prevData, varargin)
% Generate a TSK with genfis and tune it using ANFIS.
	p = inputParser;
	validMethod = @(x) ischar(x) && any(strcmp(x, {'grid', 'subcluster', 'fcmcluster'}));
	validPositiveInt = @(x) isnumeric(x) && all(x > 0) && all(x == round(x));
	validNumCluster = @(x) (ischar(x) && strcmp(x, 'auto')) || (isscalar(x) && validPositiveInt(x));
	validRatio = @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 1;
	p.addRequired('prevData', @isstruct);
	p.addOptional('method', 'grid', validMethod);
	p.addOptional('numMF', 6, validPositiveInt);
	p.addOptional('typeMF', 'gbellmf', @ischar);
	p.addParameter('epochs', 1000, @(x) validPositiveInt(x) && isscalar(x));
	p.addParameter('testRatio', 0.15, validRatio);

	p.parse(prevData, varargin{:});

	prevData = p.Results.prevData;
	method = p.Results.method;
	numMF = p.Results.numMF; % # of numbership functions for each input
	typeMF = p.Results.typeMF; % type o membership functions
	epochs = p.Results.epochs;
	testRatio = p.Results.testRatio; % test set

	featureMatrix = prevData.buildfeaturematrix';
	output = prevData.extracttargets.activity'; % actually targets
	datamat = [featureMatrix, output];

	% divide in training and test set, with stratification
	stratifyGroups = findgroups(output);
	cv = cvpartition(stratifyGroups, 'HoldOut', testRatio, 'Stratify', true);

	trainingData = datamat(cv.training, :);
	testData = datamat(cv.test, :);

	% set options for selected method
	switch method
	case 'grid'
		options = genfisOptions('GridPartition');
		options.NumMembershipFunctions = numMF;
		options.InputMembershipFunctionType = typeMF;
	case 'subcluster'
		options = genfisOptions('SubtractiveClustering');
		options.Verbose = true;
	case 'fcmcluster'
		options = genfisOptions('FCMClustering');
		options.Verbose = true;
	end

	% generate and tune

	fisin = genfis(trainingData(:, 1:end-1), trainingData(:, end), options);

	anfisOpts = anfisOptions('InitialFIS', fisin, 'EpochNumber', epochs, ...
		'DisplayANFISInformation', 1, 'DisplayErrorValues', 1, ...
		'DisplayStepSize', 1, 'DisplayFinalResults', 1, ...
		'ValidationData', testData, 'OptimizationMethod', 1);
	[fis, trainError, stepSize, chkFIS, chkError] = anfis(trainingData, anfisOpts);

	generated.fis = fis;
	generated.trainError = trainError;
	generated.stepSize = stepSize;
	generated.chkFIS = chkFIS;
	generated.chkError = chkError;
	generated.cv = cv;
end
