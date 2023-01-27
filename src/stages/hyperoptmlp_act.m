function results = hyperoptmlp_act(prevData, varargin)
% Adapted from hyperoptmlp.m to be used for activity MLP.
	p = inputParser;
	validPositiveInt = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x == round(x));
	validVars = @(x) isvector(x) && isa(x, 'optimizableVariable');
	p.addRequired('prevData', @isstruct);
	p.addParameter('trainFunction', 'trainlm', @ischar);
	p.addParameter('trainParams', struct(), @isstruct);
	p.addParameter('optimizableVars', [], validVars);
	p.addParameter('maxEvaluations', 500, validPositiveInt);
	p.addParameter('seedPoints', 50, validPositiveInt);

	p.parse(prevData, varargin{:});

	prevData = p.Results.prevData;
	trainFunction = p.Results.trainFunction;
	trainParams = p.Results.trainParams;
	optimizableVars = p.Results.optimizableVars;
	maxEvaluations = p.Results.maxEvaluations;
	seedPoints = p.Results.seedPoints;
	if isfield(prevData, 'mergefeaturematrix')
		featureMatrix = prevData.mergefeaturematrix;
	else
		featureMatrix = prevData.buildfeaturematrix;
	end
	targets = prevData.extracttargets.activity;

	% here stratification is important
	stratifyGroups = findgroups(targets);
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

function cvce = KFoldCVLoss(X, targets, cv, trainFunction, trainParams, vars)
	if vars.hiddenLayers == 2
		hiddenSizes = [vars.hiddenUnits1, vars.hiddenUnits2];
	elseif vars.hiddenLayers == 3
		hiddenSizes = [vars.hiddenUnits1, vars.hiddenUnits2, vars.hiddenUnits3];
	else
		hiddenSizes = vars.hiddenUnits1;
	end
	vars = removevars(vars, {'hiddenLayers', 'hiddenUnits1', 'hiddenUnits2', 'hiddenUnits3'});

	Y = logical(full(ind2vec(targets + 1)));

	ce = [];
	testObservations = 0;
	for i = 1:cv.NumTestSets
		trainIdx = cv.training(i);
		testIdx = cv.test(i);

		Xtrain = X(:, trainIdx);
		Ytrain = Y(:, trainIdx);
		Xtest = X(:, testIdx);
		Ytest = Y(:, testIdx);
		Ytargets = targets(:, trainIdx);

		% patternnet, instead of fitnet. Of course, now is
		% classification and not regression.
		net = patternnet(hiddenSizes, trainFunction);
		net.divideFcn = 'divideind';
		net.divideMode = 'sample';
		net.input.processFcns = {'removeconstantrows'}; % already normalized
		net.output.processFcns = {'removeconstantrows', 'mapminmax'};
		net.performFcn = 'crossentropy'; % crossentropy is good for classification
		net.trainParam.showWindow = false;
		net.trainParam.showCommandLine = false;
		net.trainParam.show = NaN;
		net.trainParam.epochs = 1000;
		net.trainParam.time = Inf;
		for f = fieldnames(trainParams)'
			% fixed
			net.trainParam.(f{1}) = trainParams.(f{1});
		end
		for f = vars.Properties.VariableNames
			% optimizable
			net.trainParam.(f{1}) = vars.(f{1});
		end

		% random divide train set with stratification into actual train
		% set and validation set. Test set already created by
		% cvpartition.
		[trainInd, valInd, ~] = stratifieddividerand(findgroups(Ytargets), 0.85, 0.15 ,0);
		net.divideParam.trainInd = trainInd;
		net.divideParam.valInd = valInd;
		net.divideParam.testInd = [];

		useGPU = 'no';
		if license('test', 'Distrib_Computing_Toolbox') && gpuDeviceCount > 0
			useGPU = 'yes';
		end

		net = train(net, Xtrain, Ytrain, 'useParallel', 'no', 'useGPU', useGPU);

		Ypred = net(Xtest);

		ce(i) = crossentropy(Ypred, Ytest);
		testObservations = testObservations + size(Ytest, 2);
	end

	cvce = sum(ce) / testObservations;
end
