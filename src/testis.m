function testis(isname)
% TESTIS  Test intelligent system, on small dataset.
%
%    TESTIS mlpmean  tests the ECG mean estimation MLP.
%    TESTIS mlpstddev  tests the ECG standard deviation estimation MLP.
%    TESTIS mlpact  tests the activity classification MLP.
%    TESTIS mamdani  runs mamdanitest script (does not execute the pipeline).
%    TESTIS anfis  tests the ANFIS TSK for activity recognition.
%    TESTIS cnn  tests the ECG standard deviation estimation CNN.
%    TESTIS lstm  tests the ECG prediction RNN LSTM.
%
%    Script is provided just as a way to show how to run these ISs.
%    Performances may be poorer than those shown during design/training.

	switch(isname)
	case 'mlpmean'
		testmlpmean;
	case {'mlpstddev', 'mlpstd'}
		testmlpstddev;
	case {'mlpact', 'mlpactivity'}
		testmlpact;
	case {'mamdani', 'mamdanifis'}
		testmamdani;
	case {'anfis', 'tsk'}
		testanfis;
	case 'cnn'
		testcnn;
	case {'lstm', 'rnn'}
		testlstm;
	otherwise
		error('IS:testis:invalidISName', 'Error: Invalid intelligent system name: ''%s''.', isname);
	end
end


%% -- functions -- %%

function testmlpmean
	preparedataStage = Stage(@preparedata, 'dataset_TEST.mat');
	preparedataStage.addDatasetParam();
	preparedataStage.addParams('includedSubjects', 1:3);

	fixdataStage = Stage(@fixdata, 'fixed_dataset_TEST.mat');
	fixdataStage.addInputStages(preparedataStage);

	augmentdataStage = Stage(@augmentdata, 'augmented_dataset_TEST.mat');
	augmentdataStage.addInputStages(fixdataStage);
	augmentdataStage.addParams(100);

	extracttargetsStage = Stage(@extracttargets, 'targets_TEST.mat');
	extracttargetsStage.addInputStages(augmentdataStage);

	sfsStage = Stage(@selectfeatures, 'selected_features.mat', RunPolicy.NEVER);

	extractfeaturesStage = Stage(@extractfeatures, 'features_mean_TEST.mat');
	extractfeaturesStage.addInputStages(augmentdataStage, sfsStage);
	extractfeaturesStage.addParams('target', 'mean');

	normalizefeaturesStage = Stage(@normalizefeatures, 'normalized_features_mean_TEST.mat');
	normalizefeaturesStage.addInputStages(extractfeaturesStage);

	buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_mean_TEST.mat');
	buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

	trainStage = Stage(@trainmlp, 'final_trained_mlp_mean.mat', RunPolicy.NEVER);

	meanData = runstages(buildfeaturematrixStage, extracttargetsStage, trainStage);

	meanNetwork = meanData.trainmlp.network;
	meanFeatureMatrix = meanData.buildfeaturematrix;
	meanTargets = meanData.extracttargets.ecgMean;

	meanOutputs = meanNetwork(meanFeatureMatrix);

	figure;
	plotregression(meanTargets, meanOutputs);

	figure;
	ploterrhist(meanTargets - meanOutputs, 'bins', 50);
end

function testmlpstddev
	preparedataStage = Stage(@preparedata, 'dataset_TEST.mat');
	preparedataStage.addDatasetParam();
	preparedataStage.addParams('includedSubjects', 1:3);

	fixdataStage = Stage(@fixdata, 'fixed_dataset_TEST.mat');
	fixdataStage.addInputStages(preparedataStage);

	augmentdataStage = Stage(@augmentdata, 'augmented_dataset_TEST.mat');
	augmentdataStage.addInputStages(fixdataStage);
	augmentdataStage.addParams(100);

	extracttargetsStage = Stage(@extracttargets, 'targets_windowed_TEST.mat');
	extracttargetsStage.addInputStages(augmentdataStage);
	extracttargetsStage.addParams(5, true);

	sfsStage = Stage(@selectfeatures, 'selected_features_windowed.mat', RunPolicy.NEVER);

	extractfeaturesStage = Stage(@extractfeatures, 'features_stddev_windowed_TEST.mat');
	extractfeaturesStage.addInputStages(augmentdataStage, sfsStage);
	extractfeaturesStage.addParams(5, true);
	extractfeaturesStage.addParams('target', 'stddev');

	normalizefeaturesStage = Stage(@normalizefeatures, 'normalized_features_stddev_windowed_TEST.mat');
	normalizefeaturesStage.addInputStages(extractfeaturesStage);

	buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_stddev_windowed_TEST.mat');
	buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

	trainStage = Stage(@trainmlp, 'final_trained_mlp_stddev.mat', RunPolicy.NEVER);

	stdData = runstages(buildfeaturematrixStage, extracttargetsStage, trainStage);

	stdNetwork = stdData.trainmlp.network;
	stdFeatureMatrix = stdData.buildfeaturematrix;
	stdTargets = stdData.extracttargets.ecgMean;

	stdOutputs = stdNetwork(stdFeatureMatrix);

	figure;
	plotregression(stdTargets, stdOutputs);

	figure;
	ploterrhist(stdTargets - stdOutputs, 'bins', 50);
end

function testmlpact
	preparedataStage = Stage(@preparedata, 'dataset_TEST.mat');
	preparedataStage.addDatasetParam();
	preparedataStage.addParams('includedSubjects', 1:3);

	fixdataStage = Stage(@fixdata, 'fixed_dataset_TEST.mat');
	fixdataStage.addInputStages(preparedataStage);

	augmentdataStage = Stage(@augmentdata, 'augmented_dataset_TEST.mat');
	augmentdataStage.addInputStages(fixdataStage);
	augmentdataStage.addParams(100);

	extracttargetsStage = Stage(@extracttargets, 'targets_TEST.mat');
	extracttargetsStage.addInputStages(augmentdataStage);

	sfsStage = Stage(@selectfeatures, 'selected_features.mat', RunPolicy.NEVER);

	extractfeaturesStage = Stage(@extractfeatures, 'features_mean_TEST.mat');
	extractfeaturesStage.addInputStages(augmentdataStage, sfsStage);
	extractfeaturesStage.addParams('target', 'mean');

	normalizefeaturesStage = Stage(@normalizefeatures, 'normalized_features_mean_TEST.mat');
	normalizefeaturesStage.addInputStages(extractfeaturesStage);

	buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_mean_TEST.mat');
	buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

	extracttargetsStage_std = Stage(@extracttargets, 'targets_windowed_TEST.mat');
	extracttargetsStage_std.addInputStages(augmentdataStage);
	extracttargetsStage_std.addParams(5, true);

	sfsStage_std = Stage(@selectfeatures, 'selected_features_windowed.mat', RunPolicy.NEVER);

	extractfeaturesStage_std = Stage(@extractfeatures, 'features_stddev_windowed_TEST.mat');
	extractfeaturesStage_std.addInputStages(augmentdataStage, sfsStage_std);
	extractfeaturesStage_std.addParams(5, true);
	extractfeaturesStage_std.addParams('target', 'stddev');

	normalizefeaturesStage_std = Stage(@normalizefeatures, 'normalized_features_stddev_windowed_TEST.mat');
	normalizefeaturesStage_std.addInputStages(extractfeaturesStage_std);

	buildfeaturematrixStage_std = Stage(@buildfeaturematrix, 'feature_matrix_stddev_windowed_TEST.mat');
	buildfeaturematrixStage_std.addInputStages(normalizefeaturesStage_std);

	mergefeaturematrixStage = Stage(@mergefeaturematrix, 'merged_feature_matrix_TEST.mat');
	mergefeaturematrixStage.addInputStages(buildfeaturematrixStage, buildfeaturematrixStage_std);

	trainStage = Stage(@trainmlp_act, 'final_trained_mlp_activity.mat', RunPolicy.NEVER);

	actData = runstages(mergefeaturematrixStage, extracttargetsStage, trainStage);

	actNetwork = actData.trainmlp_act.network;
	actFeatureMatrix = actData.mergefeaturematrix;
	actTargets = categorical(actData.extracttargets.activity);

	actOutputs = actNetwork(actFeatureMatrix);
	actOutputs = onehotdecode(actOutputs, [0; 1; 2], 1);

	figure;
	plotconfusion(actTargets, actOutputs);
end

function testmamdani
	global DEFAULT_RUNPOLICY
	global EXPORT_FIGURES
	global SHOW_FIGURES
	% mamdanitest script already does the job. Just ensure that the entire
	% pipeline is not executed to save time. This will work only if cached
	% data is available.

	ORIG_RP = DEFAULT_RUNPOLICY;
	ORIG_EF = EXPORT_FIGURES;
	ORIG_SF = SHOW_FIGURES;
	DEFAULT_RUNPOLICY = RunPolicy.NEVER;
	EXPORT_FIGURES = false;
	SHOW_FIGURES = true;

	mamdanitest

	DEFAULT_RUNPOLICY = ORIG_RP;
	EXPORT_FIGURES = ORIG_EF;
	SHOW_FIGURES = ORIG_SF;
end

function testanfis
	preparedataStage = Stage(@preparedata, 'dataset_TEST.mat');
	preparedataStage.addDatasetParam();
	preparedataStage.addParams('includedSubjects', 1:3);

	fixdataStage = Stage(@fixdata, 'fixed_dataset_TEST.mat');
	fixdataStage.addInputStages(preparedataStage);

	augmentdataStage = Stage(@augmentdata, 'augmented_dataset_TEST.mat');
	augmentdataStage.addInputStages(fixdataStage);
	augmentdataStage.addParams(100);

	extracttargetsStage = Stage(@extracttargets, 'targets_TEST.mat');
	extracttargetsStage.addInputStages(augmentdataStage);

	sfsStage = Stage(@selectfeatures_fuzzy, 'selected_features_fuzzy.mat', RunPolicy.NEVER);

	extractfeaturesStage = Stage(@extractfeatures, 'features_fuzzy_TEST.mat');
	extractfeaturesStage.addInputStages(augmentdataStage, extracttargetsStage, sfsStage);

	normalizefeaturesStage = Stage(@normalizefeatures, 'normalized_features_fuzzy_TEST.mat');
	normalizefeaturesStage.addInputStages(extractfeaturesStage);

	buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_fuzzy_TEST.mat');
	buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

	generatefisStage = Stage(@generatefis, 'fis.mat', RunPolicy.NEVER);

	result = runstages(generatefisStage, extracttargetsStage, buildfeaturematrixStage);

	fis = result.generatefis.fis;
	chkfis = result.generatefis.chkFIS;
	targets = categorical(result.extracttargets.activity);
	inputs = result.buildfeaturematrix';

	outputs = evalfis(fis, inputs);
	outputs = categorical(max(min(round(outputs'), 2), 0));
	chkOutputs = evalfis(chkfis, inputs);
	chkOutputs = categorical(max(min(round(chkOutputs'), 2), 0));

	figure;
	plotconfusion(targets, outputs, 'TrainFIS', targets, chkOutputs, 'ChkFIS');
end

function testcnn
	global DATA_FOLDER

	preparedataStage = Stage(@preparedata, 'dataset_TEST.mat');
	preparedataStage.addDatasetParam();
	preparedataStage.addParams('includedSubjects', 1:3);

	fixdataStage = Stage(@fixdata, 'fixed_dataset_TEST.mat');
	fixdataStage.addInputStages(preparedataStage);

	augmentdataStage = Stage(@augmentdata, 'augmented_dataset_deep_TEST.mat');
	augmentdataStage.addInputStages(fixdataStage);
	augmentdataStage.addParams(100, 'fixedTimeSteps', true);

	extracttargetsStage = Stage(@extracttargets, 'targets_deep_TEST.mat');
	extracttargetsStage.addInputStages(augmentdataStage);

	result = runstages(extracttargetsStage, augmentdataStage);

	dataset = result.augmentdata;
	targets = result.extracttargets.ecgStd';

	inputs = {};
	for s = 1:dataset.subjectCount
		currentSubject = dataset.("s" + string(s));
		for a = dataset.activities(currentSubject.hasActivity)
			currentTable = currentSubject.(a{1});
			dataTable = currentTable(:, 1:end-1);
			inputs{end+1} = table2array(dataTable)';
		end
	end
	inputs = inputs';

	projectRoot = currentProject().RootFolder;
	cnn = load(fullfile(projectRoot, DATA_FOLDER, 'cnn.mat'));

	outputs = predict(cnn.net, inputs);

	figure;
	plotregression(targets, outputs);
end

function testlstm
	global DATA_FOLDER

	preparedataStage = Stage(@preparedata, 'dataset_TEST.mat');
	preparedataStage.addDatasetParam();
	preparedataStage.addParams('includedSubjects', 1:3);

	fixdataStage = Stage(@fixdata, 'fixed_dataset_noholes_TEST.mat');
	fixdataStage.addInputStages(preparedataStage);
	fixdataStage.addParams(milliseconds(2));

	augmentdataStage = Stage(@augmentdata, 'augmented_dataset_recurrent_TEST.mat');
	augmentdataStage.addInputStages(fixdataStage);
	augmentdataStage.addParams(100, 'fixedTimeSteps', true, 'timeSteps', 61);

	dataset = runstages(augmentdataStage);

	projectRoot = currentProject().RootFolder;
	rnn = load(fullfile(projectRoot, DATA_FOLDER, 'rnn.mat'));

	winSize = rnn.winSize;

	inputs = {};
	targets = [];
	for s = 1:dataset.subjectCount
		currentSubject = dataset.("s" + string(s));
		for a = dataset.activities(currentSubject.hasActivity)
			currentTable = currentSubject.(a{1});
			currentTable = currentTable(1:(winSize + 1), [1:6,11,12]);
			inputs{end+1} = table2array(currentTable(1:end - 1, :))';
			targets(end+1) = currentTable.ecg(end);
		end
	end
	inputs = inputs';
	targets = targets';

	outputs = predict(rnn.net, inputs);

	figure;
	plotregression(targets, outputs);
end
