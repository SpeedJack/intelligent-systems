function cnntrain(varargin)
	global DATA_FOLDER
	global SHOW_FIGURES

	validPositiveInt = @(x) isscalar(x) && isnumeric(x) && (x >= 0) && (x == round(x));
	validPositiveChar = @(x) ischar(x) && (str2num(x) >= 0) && (str2num(x) == round(str2num(x)));
	validRatio = @(x) isscalar(x) && isnumeric(x) && (x >= 0) && (x <= 1);
	p = inputParser;
	p.addOptional('defnum', 0, @(x) validPositiveInt(x) || validPositiveChar(x));
	p.addParameter('epochs', 30, validPositiveInt);
	p.addParameter('analyze', false, @(x) isscalar(x) && islogical(x));
	p.addParameter('valRatio', 0, validRatio);
	p.addParameter('testRatio', 0, validRatio);
	p.addParameter('removeOutliers', false, @(x) isscalar(x) && islogical(x));
	p.parse(varargin{:});

	defnum = p.Results.defnum;
	if ischar(defnum)
		defnum = str2num(defnum);
	end
	epochs = p.Results.epochs;
	analyzeNet = p.Results.analyze;
	valRatio = p.Results.valRatio;
	testRatio = p.Results.testRatio;
	removeOutliers = p.Results.removeOutliers;

	saveCnn = false;
	defFunc = "cnndef";
	if defnum > 0
		defFunc = defFunc + string(defnum);
		diaryon("cnntrain_" + defFunc);
	else
		diaryon('cnntrain');
		saveCnn = true;
	end
	defFunc = str2func(defFunc);

	preparedataStage = Stage(@preparedata, 'dataset.mat');
	preparedataStage.addDatasetParam();

	fixdataStage = Stage(@fixdata, 'fixed_dataset.mat');
	fixdataStage.addInputStages(preparedataStage);
	fixdataStage.ClearMemoryAfterExecution = true;

	augmentdataStage = Stage(@augmentdata, 'augmented_dataset_deep.mat');
	augmentdataStage.addInputStages(fixdataStage);
	augmentdataStage.addParams('fixedTimeSteps', true);
	augmentdataStage.ClearMemoryAfterExecution = true;

	extracttargetsStage = Stage(@extracttargets, 'targets_deep.mat');
	extracttargetsStage.addInputStages(augmentdataStage);

	result = runstages(extracttargetsStage, augmentdataStage);

	dataset = result.augmentdata;
	ecgStd = result.extracttargets.ecgStd;

	data = {};
	for s = 1:dataset.subjectCount
		currentSubject = dataset.("s" + string(s));
		for a = dataset.activities(currentSubject.hasActivity)
			currentTable = currentSubject.(a{1});
			dataTable = currentTable(:, 1:end-1);
			data{end+1} = table2array(dataTable)';
		end
	end

	if removeOutliers
		[ecgStd, idx] = rmoutliers(ecgStd);
		data = data(~idx);
		fprintf('Removed %d outliers.\n', numel(idx));
	end

	inputs = {[]; []; []};
	targets = {[]; []; []};
	if valRatio + testRatio > 0
		firstPartition = cvpartition(numel(data), 'Holdout', valRatio + testRatio);
		inputs{1} = data(firstPartition.training)';
		targets{1} = ecgStd(firstPartition.training)';
		remainingInputs = data(firstPartition.test);
		remainingTargets = ecgStd(firstPartition.test);
		if valRatio > 0 && testRatio > 0
			secondPartition = cvpartition(numel(remainingTargets), 'Holdout', testRatio/(valRatio + testRatio));
			inputs{2} = remainingInputs(secondPartition.training)';
			targets{2} = remainingTargets(secondPartition.training)';
			inputs{3} = remainingInputs(secondPartition.test)';
			targets{3} = remainingTargets(secondPartition.test)';
		else
			inputs{2} = remainingInputs';
			targets{2} = remainingTargets';
		end
	else
		inputs{1} = data';
		targets{1} = ecgStd';
	end
	fprintf('Training set size: %d\nValidation set size: %d\nTest set size: %d\n', numel(targets{1}), numel(targets{2}), numel(targets{3}));

	[layers, options, cnnDesc] = defFunc();

	if epochs > 0
		options.MaxEpochs = epochs;
	end
	options.ExecutionEnvironment = 'parallel';
	options.Verbose = true;
	options.VerboseFrequency = 1;
	if SHOW_FIGURES
		options.Plots = 'training-progress';
	else
		options.Plots = 'none';
	end
	if valRatio > 0
		options.ValidationData = {inputs{2}, targets{2}};
	else
		options.OutputNetwork = 'last-iteration';
		options.ValidationPatience = Inf;
	end
	if strcmp(options.BatchNormalizationStatistics, 'moving')
		options.ExecutionEnvironment = 'auto'; % parallel unsupported
	end

	if analyzeNet
		analyzeNetwork(layers);
	end

	clearvars -except -regexp ^[A-Z0-9_]+$ inputs targets layers options valRatio testRatio defFunc saveCnn cnnDesc;

	[net, info] = trainNetwork(inputs{1}, targets{1}, layers, options);

	if saveCnn
		projectRoot = currentProject().RootFolder;
		dataDir = fullfile(projectRoot, DATA_FOLDER);
		outFile = fullfile(dataDir, 'cnn.mat');
		if ~exist(dataDir, 'dir');
			mkdir(dataDir);
		end
		save(outFile, 'net', 'info', 'options');
		fprintf('Output network saved in ''%s''.\n', outFile);
	end

	fprintf('\n=======\n');
	fprintf('# Output network infos:\n');
	it = info.OutputNetworkIteration;
	fprintf('\tIteration: %d (%s)\n', it, options.OutputNetwork);
	fprintf('\tTraining:\n');
	fprintf('\t\tRMSE: %f\n', info.TrainingRMSE(it));
	fprintf('\t\tLOSS: %f\n', info.TrainingLoss(it));
	if valRatio > 0
		fprintf('\tValidation:\n');
		fprintf('\t\tRMSE: %f\n', info.FinalValidationRMSE);
		fprintf('\t\tLOSS: %f\n', info.FinalValidationLoss);
	end

	if strcmp(options.OutputNetwork, 'last-iteration')
		fprintf('# Last iteration infos: *see output network*\n');
	else
		fprintf('# Last iteration infos:\n');
		fprintf('\tIteration: %d\n', length(info.TrainingLoss));
		fprintf('\tTraining:\n');
		fprintf('\t\tRMSE: %f\n', info.TrainingRMSE(end));
		fprintf('\t\tLOSS: %f\n', info.TrainingLoss(end));
		if valRatio > 0
			fprintf('\tValidation:\n');
			fprintf('\t\tRMSE: %f\n', info.ValidationRMSE(end));
			fprintf('\t\tLOSS: %f\n', info.ValidationLoss(end));
		end
	end

	fprintf('# Best (training) LOSS iteration infos:\n');
	it = find(info.TrainingLoss == min(info.TrainingLoss));
	fprintf('\tIteration: %d\n', it);
	fprintf('\tTraining:\n');
	fprintf('\t\tRMSE: %f\n', info.TrainingRMSE(it));
	fprintf('\t\tLOSS: %f\n', info.TrainingLoss(it));
	if valRatio > 0
		fprintf('\tValidation:\n');
		fprintf('\t\tRMSE: %f\n', info.ValidationRMSE(it));
		fprintf('\t\tLOSS: %f\n', info.ValidationLoss(it));
	end

	fprintf('# Best (training) RMSE iteration infos:\n');
	it = find(info.TrainingRMSE == min(info.TrainingRMSE));
	fprintf('\tIteration: %d\n', it);
	fprintf('\tTraining:\n');
	fprintf('\t\tRMSE: %f\n', info.TrainingRMSE(it));
	fprintf('\t\tLOSS: %f\n', info.TrainingLoss(it));
	if valRatio > 0
		fprintf('\tValidation:\n');
		fprintf('\t\tRMSE: %f\n', info.ValidationRMSE(it));
		fprintf('\t\tLOSS: %f\n', info.ValidationLoss(it));
	end

	if valRatio > 0
		if strcmp(options.OutputNetwork, 'best-validation-loss')
			fprintf('# Best (validation) LOSS iteration infos: *see output network*\n');
		else
			fprintf('# Best (validation) LOSS iteration infos:\n');
			it = find(info.ValidationLoss == min(info.ValidationLoss));
			fprintf('\tIteration: %d\n', it);
			fprintf('\tTraining:\n');
			fprintf('\t\tRMSE: %f\n', info.TrainingRMSE(it));
			fprintf('\t\tLOSS: %f\n', info.TrainingLoss(it));
			fprintf('\tValidation:\n');
			fprintf('\t\tRMSE: %f\n', info.ValidationRMSE(it));
			fprintf('\t\tLOSS: %f\n', info.ValidationLoss(it));
		end

		fprintf('# Best (validation) RMSE iteration infos:\n');
		it = find(info.ValidationRMSE == min(info.ValidationRMSE));
		fprintf('\tIteration: %d\n', it);
		fprintf('\tTraining:\n');
		fprintf('\t\tRMSE: %f\n', info.TrainingRMSE(it));
		fprintf('\t\tLOSS: %f\n', info.TrainingLoss(it));
		fprintf('\tValidation:\n');
		fprintf('\t\tRMSE: %f\n', info.ValidationRMSE(it));
		fprintf('\t\tLOSS: %f\n', info.ValidationLoss(it));
	end
	fprintf('=======\n');

	clearvars -except -regexp ^[A-Z0-9_]+$ inputs targets net options valRatio testRatio defFunc cnnDesc;

	outputs = {[], [], []};
	outputs{1} = predict(net, inputs{1}, 'ExecutionEnvironment', options.ExecutionEnvironment, 'MiniBatchSize', options.MiniBatchSize);
	[R, P, RL, RU] = corrcoef(targets{1}, outputs{1});
	fprintf('Training stats:\n');
	fprintf('\tR: %f (95%% CI: %f - %f)\n', R(1, 2), RL(1, 2), RU(1, 2));
	fprintf('\tP-value: %f\n', P(1, 2));
	if valRatio > 0
		outputs{2} = predict(net, inputs{2}, 'ExecutionEnvironment', options.ExecutionEnvironment, 'MiniBatchSize', options.MiniBatchSize);
		[R, P, RL, RU] = corrcoef(targets{2}, outputs{2});
		fprintf('Validation stats:\n');
		fprintf('\tR: %f (95%% CI: %f - %f)\n', R(1, 2), RL(1, 2), RU(1, 2));
		fprintf('\tP-value: %f\n', P(1, 2));
	end
	if testRatio > 0
		outputs{3} = predict(net, inputs{3}, 'ExecutionEnvironment', options.ExecutionEnvironment, 'MiniBatchSize', options.MiniBatchSize);
		[R, P, RL, RU] = corrcoef(targets{3}, outputs{3});
		fprintf('Test stats:\n');
		fprintf('\tR: %f (95%% CI: %f - %f)\n', R(1, 2), RL(1, 2), RU(1, 2));
		fprintf('\tP-value: %f\n', P(1, 2));
	end

	fprintf('=======\nCNN:\n');
	fprintf('\tName: %s\n', func2str(defFunc));
	fprintf('\tDescription: %s\n', cnnDesc);

	if ~SHOW_FIGURES
		diary off;
		return;
	end

	regressionParams = {};
	regressionParams{end+1} = targets{1};
	regressionParams{end+1} = outputs{1};
	regressionParams{end+1} = 'Training';
	numFig = 1;
	if valRatio > 0
		regressionParams{end+1} = targets{2};
		regressionParams{end+1} = outputs{2};
		regressionParams{end+1} = 'Validation';
		numFig = numFig + 1;
	end
	if testRatio > 0
		regressionParams{end+1} = targets{3};
		regressionParams{end+1} = outputs{3};
		regressionParams{end+1} = 'Test';
		numFig = numFig + 1;
	end

	plotregression(regressionParams{:});

	diary off;
end
