close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

%% -- mean -- %%

diaryon('mlpbayesopt_mean');

optVars = [ ...
	optimizableVariable('hiddenLayers', [1,3], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits1', [10,35], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits2', [0,15], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits3', [0,5], 'Type', 'integer') ...
	];

[buildfeaturematrixStage, extracttargetsStage] = pretrainingpipeline('mean', false); % not windowed
trainParams.time = 60*5; % 5 minutes

% add hyperoptmlp to pretraining pipeline, passing optimizable variable to it
hyperoptStage = Stage(@hyperoptmlp, 'bayesopt_mlp_mean.mat');
hyperoptStage.addInputStages(buildfeaturematrixStage, extracttargetsStage);
hyperoptStage.addParams('trainFunction', 'trainbr', 'target', 'mean', 'trainParams', trainParams, 'optimizableVars', optVars);

meanResults = runstages(hyperoptStage);

diary off;

%% -- stddev -- %%

diaryon('mlpbayesopt_stddev');

optVars = [ ...
	optimizableVariable('hiddenLayers', [1,3], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits1', [30,150], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits2', [0,50], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits3', [0,15], 'Type', 'integer') ...
	];

[buildfeaturematrixStage, extracttargetsStage] = pretrainingpipeline('stddev', true); % windowed
trainParams.time = 60*10; % 10 minutes

hyperoptStage = Stage(@hyperoptmlp, 'bayesopt_mlp_stddev.mat');
hyperoptStage.addInputStages(buildfeaturematrixStage, extracttargetsStage);
hyperoptStage.addParams('trainFunction', 'trainlm', 'target', 'stddev', 'trainParams', trainParams, 'optimizableVars', optVars);

stdResults = runstages(hyperoptStage);

diary off;
