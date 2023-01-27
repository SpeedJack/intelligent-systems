function results = hyperoptmlp(prevData, varargin)
	p = inputParser;
	validPositiveInt = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x == round(x));
	validTarget = @(x) ischar(x) && any(strcmp(x, {'mean', 'stddev'}));
	validVars = @(x) isvector(x) && isa(x, 'optimizableVariable');
	p.addRequired('prevData', @isstruct);
	p.addParameter('trainFunction', 'trainlm', @ischar);
	p.addParameter('target', 'mean', validTarget);
	p.addParameter('trainParams', struct(), @isstruct);
	p.addParameter('optimizableVars', [], validVars);
	p.addParameter('maxEvaluations', 100, validPositiveInt);
	p.addParameter('seedPoints', 10, validPositiveInt);

	p.parse(prevData, varargin{:});

	prevData = p.Results.prevData;
	trainFunction = p.Results.trainFunction;
	target = p.Results.target;
	trainParams = p.Results.trainParams;
	optimizableVars = p.Results.optimizableVars;
	maxEvaluations = p.Results.maxEvaluations;
	seedPoints = p.Results.seedPoints;
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

	stratifyGroups = findgroups(prevData.extracttargets.activity);
	cv = cvpartition(stratifyGroups, 'KFold', 5, 'Stratify', true);

	minimizeFcn = @(vars) KFoldCVLoss(featureMatrix, targets, cv, trainFunction, trainParams, vars);

	fprintf('Starting hyperparameters optimization...\n');

	bayesoptResults = bayesopt(minimizeFcn, optimizableVars, 'IsObjectiveDeterministic', false, ...
		'AcquisitionFunctionName', 'expected-improvement-plus', 'UseParallel', true, ...
		'MaxObjectiveEvaluations', maxEvaluations, 'NumSeedPoints', seedPoints, ...
		'XConstraintFcn', @xconstraint);

	results.bayesoptResults = bayesoptResults;
	bp = bestPoint(bayesoptResults, 'Criterion', 'min-observed');
	results.hiddenSizes = [bp.hiddenUnits1, bp.hiddenUnits2, bp.hiddenUnits3];
	results.hiddenLayers = bp.hiddenLayers;
	results.bestPoint = removevars(bp, {'hiddenLayers', 'hiddenUnits1', 'hiddenUnits2', 'hiddenUnits3'});
end

function tf = xconstraint(X)
	tf1 = X.hiddenLayers == 1 & X.hiddenUnits2 == 0 & X.hiddenUnits3 == 0;
	tf2 = X.hiddenLayers == 2 & X.hiddenUnits2 > 0 & X.hiddenUnits3 == 0;
	tf3 = X.hiddenLayers == 3 & X.hiddenUnits2 > 0 & X.hiddenUnits3 > 0;
	tf4 = X.hiddenUnits3 < X.hiddenUnits2 & X.hiddenUnits2 < X.hiddenUnits1;
	tf = (tf1 | tf2 | tf3) & tf4;
end

function cvmse = KFoldCVLoss(X, Y, cv, trainFunction, trainParams, vars)
	if vars.hiddenLayers == 2
		hiddenSizes = [vars.hiddenUnits1, vars.hiddenUnits2];
	elseif vars.hiddenLayers == 3
		hiddenSizes = [vars.hiddenUnits1, vars.hiddenUnits2, vars.hiddenUnits3];
	else
		hiddenSizes = vars.hiddenUnits1;
	end
	vars = removevars(vars, {'hiddenLayers', 'hiddenUnits1', 'hiddenUnits2', 'hiddenUnits3'});

	mse = [];
	testObservations = 0;
	for i = 1:cv.NumTestSets
		trainIdx = cv.training(i);
		testIdx = cv.test(i);

		Xtrain = X(:, trainIdx);
		Ytrain = Y(:, trainIdx);
		Xtest = X(:, testIdx);
		Ytest = Y(:, testIdx);

		net = fitnet(hiddenSizes, trainFunction);
		net.divideFcn = 'dividerand';
		net.divideMode = 'sample';
		net.input.processFcns = {'removeconstantrows'};
		net.output.processFcns = {'removeconstantrows', 'mapminmax'};
		net.performFcn = 'mse';
		net.trainParam.showWindow = false;
		net.trainParam.showCommandLine = false;
		net.trainParam.show = NaN;
		net.trainParam.epochs = 1000;
		net.trainParam.time = Inf;
		for f = fieldnames(trainParams)'
			net.trainParam.(f{1}) = trainParams.(f{1});
		end
		for f = vars.Properties.VariableNames
			net.trainParam.(f{1}) = vars.(f{1});
		end
		if isinf(net.trainParam.max_fail) || net.trainParam.max_fail == 0 % trainbr
			net.divideParam.trainRatio = 1;
			net.divideParam.valRatio = 0;
			net.divideParam.testRatio = 0;
		else
			net.divideParam.trainRatio = 0.85;
			net.divideParam.valRatio = 0.15;
			net.divideParam.testRatio = 0;
		end

		useGPU = 'no';
		if license('test', 'Distrib_Computing_Toolbox') && gpuDeviceCount > 0
			useGPU = 'yes';
		end

		net = train(net, Xtrain, Ytrain, 'useParallel', 'no', 'useGPU', useGPU);

		Ypred = net(Xtest);

		mse(i) = immse(Ytest, Ypred);
		testObservations = testObservations + numel(Ytest);
	end

	cvmse = sum(mse) / testObservations;
end
