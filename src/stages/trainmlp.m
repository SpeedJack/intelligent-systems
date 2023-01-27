function trained = trainmlp(prevData, varargin)
	p = inputParser;
	validPositiveIntVector = @(x) isnumeric(x) && isvector(x) && (x(1) > 0) && all(x >= 0) && all(x == round(x));
	validTarget = @(x) ischar(x) && any(strcmp(x, {'mean', 'stddev'}));
	validBool = @(x) islogical(x) && isscalar(x);
	p.addRequired('prevData', @isstruct);
	p.addParameter('hiddenSizes', 50, validPositiveIntVector);
	p.addParameter('trainFunction', 'trainlm', @ischar);
	p.addParameter('target', 'mean', validTarget);
	p.addParameter('trainParams', struct(), @isstruct);

	p.parse(prevData, varargin{:});

	prevData = p.Results.prevData;
	trainingFunction = p.Results.trainFunction;
	target = p.Results.target;
	trainParams = p.Results.trainParams;
	if isfield(prevData, 'mergefeaturematrix')
		featureMatrix = prevData.mergefeaturematrix;
	else
		featureMatrix = prevData.buildfeaturematrix;
	end
	if strcmp(target, 'mean')
		targets = prevData.extracttargets.ecgMean;
	else
		targets = prevData.extracttargets.ecgStd;
	end
	hiddenSizes = p.Results.hiddenSizes;
	hyperParams = table();
	if isfield(prevData, 'hyperoptmlp')
		hiddenSizes = prevData.hyperoptmlp.hiddenSizes;
		hyperParams = prevData.hyperoptmlp.bestPoint;
	end
	hiddenSizes = hiddenSizes(hiddenSizes > 0);

	net = fitnet(hiddenSizes, trainingFunction);
	net.divideFcn = 'dividerand';
	net.divideMode = 'sample';
	net.input.processFcns = {'removeconstantrows'};
	net.output.processFcns = {'removeconstantrows', 'mapminmax'};
	net.performFcn = 'mse';
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
	if isinf(net.trainParam.max_fail) || net.trainParam.max_fail == 0 % trainbr
		net.divideParam.trainRatio = 0.85;
		net.divideParam.valRatio = 0;
		net.divideParam.testRatio = 0.15;
	else
		net.divideParam.trainRatio = 0.7;
		net.divideParam.valRatio = 0.15;
		net.divideParam.testRatio = 0.15;
	end
	net.plotFcns = {'plotperform', 'plottrainstate', 'ploterrhist', 'plotregression'};

	useGPU = 'no';
	if license('test', 'Distrib_Computing_Toolbox') && gpuDeviceCount > 0
		useGPU = 'yes';
	end

	[net, tr] = train(net, featureMatrix, targets, 'useParallel', 'yes', 'useGPU', useGPU);
	trained.network = net;
	trained.trainingRecord = tr;
end
