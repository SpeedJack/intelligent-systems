% This function is a copy of cnntrain.m with some adaptations. I will not
% repeat all the comments, script is almost the same: I'll just comment the
% differences.
function rnntrain(varargin)
	global DATA_FOLDER
	global SHOW_FIGURES

	validPositiveInt = @(x) isscalar(x) && isnumeric(x) && (x >= 0) && (x == round(x));
	validPositiveChar = @(x) ischar(x) && (str2num(x) >= 0) && (str2num(x) == round(str2num(x)));
	validRatio = @(x) isscalar(x) && isnumeric(x) && (x >= 0) && (x <= 1);
	p = inputParser;
	p.addOptional('defnum', 0, @(x) validPositiveInt(x) || validPositiveChar(x));
	p.addParameter('epochs', 50, validPositiveInt);
	p.addParameter('valRatio', 0, validRatio);
	p.addParameter('testRatio', 0, validRatio);
	p.addParameter('predictEcg', false, @(x) isscalar(x) && islogical(x));
	p.parse(varargin{:});

	defnum = p.Results.defnum;
	if ischar(defnum)
		defnum = str2num(defnum);
	end
	epochs = p.Results.epochs;
	valRatio = p.Results.valRatio;
	testRatio = p.Results.testRatio;
	% this parameter is used to plot an example of a prediction of ECG made
	% by the network. Line plot where one line is the real ECG and the
	% other is the predicted ECG.
	predictEcg = p.Results.predictEcg;

	saveRnn = false;
	defFunc = "rnndef";
	if defnum > 0
		defFunc = defFunc + string(defnum);
		diaryon("rnntrain_" + defFunc);
	else
		diaryon('rnntrain');
		saveRnn = true;
	end
	defFunc = str2func(defFunc);

	preparedataStage = Stage(@preparedata, 'dataset.mat');
	preparedataStage.addDatasetParam();

	fixdataStage = Stage(@fixdata, 'fixed_dataset_noholes.mat');
	fixdataStage.addInputStages(preparedataStage);
	fixdataStage.addParams(milliseconds(2)); % absolutely, I don't want any hole in data for an RNN
	fixdataStage.ClearMemoryAfterExecution = true;

	augmentdataStage = Stage(@augmentdata, 'augmented_dataset_recurrent.mat');
	augmentdataStage.addInputStages(fixdataStage);
	augmentdataStage.addParams(20000, 'fixedTimeSteps', true, 'timeSteps', 61); % total of 60.000 samples extracted!
	augmentdataStage.ClearMemoryAfterExecution = true;

	dataset = runstages(augmentdataStage);

	[layers, options, winSize, rnnDesc] = defFunc();

	data = {};
	ecgValues = [];
	for s = 1:dataset.subjectCount
		currentSubject = dataset.("s" + string(s));
		for a = dataset.activities(currentSubject.hasActivity)
			currentTable = currentSubject.(a{1});
			currentTable = currentTable(1:(winSize + 1), [1:6,11,12]); % extract pleth_*, temp_3, ecg
			data{end+1} = table2array(currentTable(1:end - 1, :))';
			ecgValues(end+1) = currentTable.ecg(end);
		end
	end

	inputs = {[]; []; []};
	targets = {[]; []; []};
	if valRatio + testRatio > 0
		firstPartition = cvpartition(numel(data), 'Holdout', valRatio + testRatio);
		inputs{1} = data(firstPartition.training)';
		targets{1} = ecgValues(firstPartition.training)';
		remainingInputs = data(firstPartition.test);
		remainingTargets = ecgValues(firstPartition.test);
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
		targets{1} = ecgValues';
	end
	fprintf('Training set size: %d\nValidation set size: %d\nTest set size: %d\n', numel(targets{1}), numel(targets{2}), numel(targets{3}));

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

	clearvars -except -regexp ^[A-Z0-9_]+$ winSize inputs targets layers options valRatio testRatio defFunc saveRnn rnnDesc predictEcg;

	[net, info] = trainNetwork(inputs{1}, targets{1}, layers, options);

	if saveRnn
		projectRoot = currentProject().RootFolder;
		dataDir = fullfile(projectRoot, DATA_FOLDER);
		outFile = fullfile(dataDir, 'rnn.mat');
		if ~exist(dataDir, 'dir');
			mkdir(dataDir);
		end
		save(outFile, 'net', 'info', 'options', 'winSize');
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

	clearvars -except -regexp ^[A-Z0-9_]+$ winSize inputs targets net options valRatio testRatio defFunc rnnDesc predictEcg;

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

	fprintf('=======\nRNN:\n');
	fprintf('\tName: %s\n', func2str(defFunc));
	fprintf('\tDescription: %s\n', rnnDesc);

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

	if ~predictEcg
		diary off;
		return;
	end

	% plot an example of ECG prediction done by the network, if requested

	preparedataStage = Stage(@preparedata, 'dataset.mat');
	preparedataStage.addDatasetParam();

	fixdataStage = Stage(@fixdata, 'fixed_dataset_noholes.mat');
	fixdataStage.addInputStages(preparedataStage);
	fixdataStage.addParams(milliseconds(2));
	fixdataStage.ClearMemoryAfterExecution = true;

	% extract just 1 sample per activity
	augmentdataStage = Stage(@augmentdata, 'augmented_dataset_recurrent_reduced.mat');
	augmentdataStage.addInputStages(fixdataStage);
	augmentdataStage.addParams(1, 'fixedTimeSteps', true, 'rngSeed', 0xbadbabe5); % default timesteps=2500 (5 seconds)
	augmentdataStage.ClearMemoryAfterExecution = true;

	dataset = runstages(augmentdataStage);

	% actually, I will produce 3 plots: 1 per activity
	sitRecord = table2array(dataset.s1.sit(:, [1:6,11,12]))';
	walkRecord = table2array(dataset.s1.walk(:, [1:6,11,12]))';
	runRecord = table2array(dataset.s1.run(:, [1:6,11,12]))';

	recSize = size(sitRecord, 2);

	% run predictions for each record.
	outputs = {[]; []; []};
	for i = 1:3
		inputs = {};
		% build cell array where each input is of winSize time steps
		% and each subsequent element is just shifted forward by 1 time
		% step.
		for j = (winSize+1):recSize
			inputs{end+1} = sitRecord(:, j-winSize:j);
		end
		% predict
		outputs{i} = predict(net, inputs, 'ExecutionEnvironment', options.ExecutionEnvironment, 'MiniBatchSize', options.MiniBatchSize);
	end

	% actually plot

	recSize = recSize - winSize;

	ecgFig = figure('Name', 'ECG predictions', 'NumberTitle', 'off');
	tl = tiledlayout(ecgFig, 3, 1);

	ax = nexttile(tl);
	plot(ax, 1:recSize, sitRecord(end, (winSize+1):end), '-b', 'DisplayName', 'Real');
	hold(ax, 'on');
	plot(ax, 1:recSize, outputs{1}, '--r', 'DisplayName', 'Predicted');
	hold(ax, 'off');
	title(ax, 'Sit Sample');
	legend(ax);
	xlabel(ax, 'Time step');
	ylabel(ax, 'ECG');

	ax = nexttile(tl);
	plot(ax, 1:recSize, walkRecord(end, (winSize+1):end), '-b', 'DisplayName', 'Real');
	hold(ax, 'on');
	plot(ax, 1:recSize, outputs{2}, '--r', 'DisplayName', 'Predicted');
	hold(ax, 'off');
	title(ax, 'Walk Sample');
	legend(ax);
	xlabel(ax, 'Time step');
	ylabel(ax, 'ECG');

	ax = nexttile(tl);
	plot(ax, 1:recSize, runRecord(end, (winSize+1):end), '-b', 'DisplayName', 'Real');
	hold(ax, 'on');
	plot(ax, 1:recSize, outputs{3}, '--r', 'DisplayName', 'Predicted');
	hold(ax, 'off');
	title(ax, 'Run Sample');
	legend(ax);
	xlabel(ax, 'Time step');
	ylabel(ax, 'ECG');

	exportfigure(ecgFig, 'rnn-predictions', [10 10 1000 1450]);

	diary off;
end
