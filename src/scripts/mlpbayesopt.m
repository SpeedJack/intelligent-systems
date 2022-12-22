close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

targets = {'mean', 'stddev'};
trainFcns = {'trainbr', 'trainlm'};
windowed = [true, true];
optVars = [ ...
	optimizableVariable('hiddenLayers', [1,3], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits1', [10,200], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits2', [0,75], 'Type', 'integer'), ...
	optimizableVariable('hiddenUnits3', [0,15], 'Type', 'integer'), ...
	optimizableVariable('mu', [1e-4,0.1], 'Type', 'real', 'Transform', 'log'), ...
	optimizableVariable('mu_dec', [1e-3,0.1], 'Type', 'real'), ...
	optimizableVariable('mu_inc', [1,100], 'Type', 'real'), ...
	optimizableVariable('mu_max', [1e7,1e15], 'Type', 'real', 'Transform', 'log'), ...
	optimizableVariable('max_fail', [4,20], 'Type', 'integer'), ...
	];

diaryon('mlpbayesopt');

for i = 1:numel(targets)
	target = targets{i};
	trainFcn = trainFcns{i};

	[buildfeaturematrixStage, extracttargetsStage] = pretrainingpipeline(target, windowed(i));
	trainParams.time = 60*20; % 20 minutes

	hyperoptStage = Stage(@hyperoptmlp, ['bayesopt_mlp_' target '.mat']);
	hyperoptStage.addInputStages(buildfeaturematrixStage, extracttargetsStage);
	hyperoptStage.addParams('trainFunction', trainFcn, 'target', target, 'trainParams', trainParams, 'optimizableVars', optVars);
	hyperoptStage.addParams('maxEvaluations', 20, 'seedPoints', 3);

	results = runstages(hyperoptStage);
	fprintf('Best hyperparameters for target=%s:\n', target);
	disp(results.bestPoint);
end

diary off;
