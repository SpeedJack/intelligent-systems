function selectedFeatures = selectfeatures(prevData, varargin)
	p = inputParser;
	validPositiveInt = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x == round(x));
	p.addRequired('prevData', @isstruct);
	p.addParameter('cv', 10, validPositiveInt);
	p.addParameter('nfeatures', 10, validPositiveInt);
	p.parse(prevData, varargin{:});

	prevData = p.Results.prevData;
	cv = p.Results.cv;
	nfeatures = p.Results.nfeatures;

	targets = prevData.extracttargets;
	if isfield(prevData, 'normalizefeatures')
		features = prevData.normalizefeatures;
	elseif isfield(prevData, 'dropcorrelatedfeatures')
		features = prevData.dropcorrelatedfeatures;
	elseif isfield(prevData, 'dropfeatures')
		features = prevData.dropfeatures;
	else
		features = prevData.extractfeatures;
	end

	fprintf('Preparing data for sequentialfs...');
	windows = {};
	featureNames = {};
	varNames = fieldnames(features);
	for varNameIndex = 1:length(varNames)
		currentVar = varNames{varNameIndex};
		currentVarData = features.(currentVar);
		featuresFuncs = fieldnames(currentVarData);
		for featureFuncIndex = 1:length(featuresFuncs)
			featureFunc = featuresFuncs{featureFuncIndex};
			featureMatrix = currentVarData.(featureFunc);
			for win = 1:size(featureMatrix, 1)
				if numel(windows) < win
					windows{win} = [];
				end
				windows{win} = [windows{win} featureMatrix(win, :)'];
			end
			featureNames = [featureNames; strcat(currentVar, ':', featureFunc)];
		end
	end
	fprintf('done!\n');

	fprintf('Running sequentialfs for ecg mean...\n');
	sfsResult = runsequentialfs(windows, targets.ecgMean', numel(featureNames), cv, nfeatures);
	selectedFeatures.ecgMean = sfsResult;
	selectedFeatures.ecgMean.featureNames = getorderednames(featureNames, sfsResult.history.In);
	selectedFeatures.ecgMean.finalCriterion = sfsResult.history.Crit(end);
	fprintf('Selected features for ecg mean: %s\n', ...
		strjoin(selectedFeatures.ecgMean.featureNames, ', '));

	fprintf('Running sequentialfs for ecg stddev...\n');
	sfsResult = runsequentialfs(windows, targets.ecgStd', numel(featureNames), cv, nfeatures);
	selectedFeatures.ecgStd = sfsResult;
	selectedFeatures.ecgStd.featureNames = getorderednames(featureNames, sfsResult.history.In);
	selectedFeatures.ecgStd.finalCriterion = sfsResult.history.Crit(end);
	fprintf('Selected features for ecg stddev: %s\n', ...
		strjoin(selectedFeatures.ecgStd.featureNames, ', '));
end

function sfsResult = runsequentialfs(windows, target, featureCount, cv, nfeatures)
	dummyMatrix = repmat(1:featureCount, length(target), 1);

	opts = statset('Display', 'iter', 'UseParallel', true);
	[inmodel, history] = sequentialfs(@sfscriterion, dummyMatrix, target, ...
			windows{:}, 'cv', cv, 'options', opts, ...
			'nfeatures', nfeatures, 'direction', 'forward');
	sfsResult.inmodel = inmodel;
	sfsResult.history = history;
end

function performance = sfscriterion(trainMatrix, targetsTrain, varargin)
	winCount = (length(varargin) / 2) - 1;
	inputTrain = [];
	trainIndexes = trainMatrix(1, :);
	for win = 1:winCount
		curWin = varargin{win};
		curTrainIndexes = trainIndexes(find(trainIndexes <= size(curWin, 2)));
		curWinFeatures = curWin(:, curTrainIndexes);
		inputTrain = [inputTrain; curWinFeatures'];
	end
	targetsTrain = targetsTrain';

	inputTest = [];
	testIndexes = trainIndexes;
	for win = (winCount + 3):length(varargin)
		curWin = varargin{win};
		curTestIndexes = testIndexes(find(testIndexes <= size(curWin, 2)));
		curWinFeatures = curWin(:, curTestIndexes);
		inputTest = [inputTest; curWinFeatures'];
	end
	targetsTest = varargin{winCount + 2}';

	hiddenNeurons = max(5, floor(size(inputTrain, 1)/2));

	net = fitnet(hiddenNeurons);
	net.input.processFcns = {'removeconstantrows'};
	net.output.processFcns = {'removeconstantrows', 'mapminmax'};
	net.divideParam.trainRatio = 1;
	net.divideParam.valRatio = 0;
	net.divideParam.testRatio = 0;
	net.divideFcn = 'dividetrain';
	net.trainFcn = 'trainbr';
	net.performFcn = 'mse';
	net.trainParam.showWindow = false;

	useGPU = 'no';
	if license('test', 'Distrib_Computing_Toolbox') && gpuDeviceCount > 0
		useGPU = 'yes';
	end

	net = train(net, inputTrain, targetsTrain, 'useGPU', useGPU);

	response = net(inputTest);
	performance = perform(net, targetsTest, response);
end

function names = getorderednames(featureNames, historyIn)
	names = {};
	for i = 1:size(historyIn, 1)
		if i > 1
			added = historyIn(i, :) - historyIn(i - 1, :);
		else
			added = historyIn(i, :);
		end
		names = [names; string(featureNames(logical(added)))];
	end
end
