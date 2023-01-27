function selectedFeatures = selectfeatures_fuzzy(prevData, varargin)
	p = inputParser;
	validPositiveInt = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x == round(x));
	p.addRequired('prevData', @isstruct);
	p.addParameter('cv', 10, validPositiveInt);
	p.addParameter('nfeatures', 3, validPositiveInt);
	p.parse(prevData, varargin{:});

	prevData = p.Results.prevData;
	cvnum = p.Results.cv;
	nfeatures = p.Results.nfeatures;

	activity = prevData.extracttargets.activity;
	if isfield(prevData, 'mergefeatures')
		features = prevData.mergefeatures;
	elseif isfield(prevData, 'normalizefeatures')
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

	stratifyGroups = findgroups(activity);
	cv = cvpartition(stratifyGroups, 'KFold', cvnum, 'Stratify', true);

	targets = [activity == 0; activity == 1; activity == 2];

	fprintf('Running sequentialfs...\n');
	sfsResult = runsequentialfs(windows, targets', numel(featureNames), cv, nfeatures);
	selectedFeatures.fuzzy = sfsResult;
	selectedFeatures.fuzzy.featureNames = string(featureNames(sfsResult.inmodel));
	selectedFeatures.fuzzy.finalCriterion = sfsResult.history.Crit(end);
	fprintf('Selected features: %s\n', ...
		strjoin(selectedFeatures.fuzzy.featureNames, ', '));
end

function sfsResult = runsequentialfs(windows, target, featureCount, cv, nfeatures)
	dummyMatrix = repmat(1:featureCount, length(target), 1);

	opts = statset('Display', 'iter', 'UseParallel', true);
	[inmodel, history] = sequentialfs(@sfscriterion, dummyMatrix, target, ...
			windows{:}, 'cv', cv, 'options', opts, ...
			'nfeatures', nfeatures, 'direction', 'backward');
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

	hidden1 = ceil((165*size(inputTrain, 1))/45);
	hidden2 = ceil((31*size(inputTrain, 1))/45);

	net = patternnet([hidden1 hidden2]);
	net.input.processFcns = {'removeconstantrows'};
	net.output.processFcns = {'removeconstantrows', 'mapminmax'};
	net.divideParam.trainRatio = 1;
	net.divideParam.valRatio = 0;
	net.divideParam.testRatio = 0;
	net.divideFcn = 'dividetrain';
	net.trainFcn = 'trainscg';
	net.performFcn = 'crossentropy';
	net.trainParam.showWindow = false;
	net.trainParam.showCommandLine = false;
	net.trainParam.epochs = 1000;
	nt.trainParam.time = Inf;
	net.trainParam.mu = 0.00503782845709468;
	net.trainParam.sigma = 5.24912243184705e-5;
	net.trainParam.lambda = 2.39459690552712e-7;

	useGPU = 'no';
	if license('test', 'Distrib_Computing_Toolbox') && gpuDeviceCount > 0
		useGPU = 'yes';
	end

	net = train(net, inputTrain, targetsTrain, 'useGPU', useGPU);

	response = net(inputTest);
	performance = perform(net, targetsTest, response);
end
