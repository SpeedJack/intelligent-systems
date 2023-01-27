close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

diaryon('mlpbayesopt_activity');

optVars = [ ...
	optimizableVariable('hiddenLayers', [1,3], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits1', [40,180], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits2', [0,65], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits3', [0,20], 'Type', 'integer'), ...
	optimizableVariable('mu', [0.001, 0.01], 'Type', 'real', 'Transform', 'log'), ...
	optimizableVariable('sigma', [1.0e-5, 1.0e-4], 'Type', 'real', 'Transform', 'log'), ...
	optimizableVariable('lambda', [1.0e-7, 1.0e-6], 'Type', 'real', 'Transform', 'log') ...
	];

[buildfeaturematrixStage_mean, extracttargetsStage] = pretrainingpipeline('mean', false);
[buildfeaturematrixStage_std, ~] = pretrainingpipeline('stddev', true);
mergefeaturematrixStage = Stage(@mergefeaturematrix, 'merged_feature_matrix.mat');
mergefeaturematrixStage.addInputStages(buildfeaturematrixStage_mean, buildfeaturematrixStage_std);

trainParams.time = 60*5; % 5 minutes

hyperoptStage = Stage(@hyperoptmlp_act, 'bayesopt_mlp_activity.mat');
hyperoptStage.addInputStages(mergefeaturematrixStage, extracttargetsStage);
hyperoptStage.addParams('trainFunction', 'trainscg', 'trainParams', trainParams, 'optimizableVars', optVars);

meanResults = runstages(hyperoptStage);

diary off;
