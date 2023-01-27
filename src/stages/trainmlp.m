function trained = trainmlp(prevData, varargin)
% train an MLP. For activity MLP, see trainmlp_act.m.
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
	target = p.Results.target; % used to select target from extracttargets
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
		% hyperopt executed. We can load optimized hyperparams
		hiddenSizes = prevData.hyperoptmlp.hiddenSizes; % overwrite
		hyperParams = prevData.hyperoptmlp.bestPoint;
	end
	hiddenSizes = hiddenSizes(hiddenSizes > 0); % remove zero size layers

	net = fitnet(hiddenSizes, trainingFunction); % regression
	net.divideFcn = 'dividerand';
	net.divideMode = 'sample';
	net.input.processFcns = {'removeconstantrows'}; % already normalized
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

	% train
	[net, tr] = train(net, featureMatrix, targets, 'useParallel', 'yes', 'useGPU', useGPU);
	trained.network = net;
	trained.trainingRecord = tr;
end
