function trained = trainmlp_act(prevData, varargin)
	p = inputParser;
	validPositiveIntVector = @(x) isnumeric(x) && isvector(x) && (x(1) > 0) && all(x >= 0) && all(x == round(x));
	validBool = @(x) islogical(x) && isscalar(x);
	p.addRequired('prevData', @isstruct);
	p.addParameter('hiddenSizes', 50, validPositiveIntVector);
	p.addParameter('trainFunction', 'trainscg', @ischar);
	p.addParameter('trainParams', struct(), @isstruct);

	p.parse(prevData, varargin{:});

	prevData = p.Results.prevData;
	trainingFunction = p.Results.trainFunction;
	trainParams = p.Results.trainParams;
	if isfield(prevData, 'mergefeaturematrix')
		featureMatrix = prevData.mergefeaturematrix;
	else
		featureMatrix = prevData.buildfeaturematrix;
	end
	activity = prevData.extracttargets.activity;
	hiddenSizes = p.Results.hiddenSizes;
	hyperParams = table();
	if isfield(prevData, 'hyperoptmlp_act')
		hiddenSizes = prevData.hyperoptmlp_act.hiddenSizes;
		hyperParams = prevData.hyperoptmlp_act.bestPoint;
	end
	hiddenSizes = hiddenSizes(hiddenSizes > 0);

	targets = logical(full(ind2vec(activity + 1)));

	net = patternnet(hiddenSizes, trainingFunction);
	net.divideFcn = 'divideind';
	net.divideMode = 'sample';
	net.input.processFcns = {'removeconstantrows'};
	net.output.processFcns = {'removeconstantrows', 'mapminmax'};
	net.performFcn = 'crossentropy';
	net.trainParam.showWindow = false;
	net.trainParam.showCommandLine = true;
	net.trainParam.show = 25;
	net.trainParam.epochs = 100000;
	net.trainParam.time = Inf;
	for f = hyperParams.Properties.VariableNames
		net.trainParam.(f{1}) = hyperParams.(f{1});
	end
	for f = fieldnames(trainParams)'
		net.trainParam.(f{1}) = trainParams.(f{1});
	end
	[trainInd, valInd, testInd] = stratifieddividerand(findgroups(activity), 0.7, 0.15 ,0.15);
	net.divideParam.trainInd = trainInd;
	net.divideParam.valInd = valInd;
	net.divideParam.testInd = testInd;
	net.plotFcns = {'plotperform', 'plottrainstate', 'ploterrhist', 'plotconfusion', 'plotroc'};

	useGPU = 'no';
	if license('test', 'Distrib_Computing_Toolbox') && gpuDeviceCount > 0
		useGPU = 'yes';
	end

	[net, tr] = train(net, featureMatrix, targets, 'useParallel', 'yes', 'useGPU', useGPU);
	trained.network = net;
	trained.trainingRecord = tr;
end
