close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

diaryon('mlptraining_mean');

[buildfeaturematrixStage, extracttargetsStage] = pretrainingpipeline('mean', false);
hyperoptStage = Stage(@hyperoptmlp, 'bayesopt_mlp_mean.mat', RunPolicy.NEVER);

trainParams.showWindow = true;

trainStage = Stage(@trainmlp, 'final_trained_mlp_mean.mat', RunPolicy.ALWAYS);
trainStage.addInputStages(buildfeaturematrixStage, extracttargetsStage, hyperoptStage);
trainStage.addParams('target', 'mean', 'trainFunction', 'trainbr', 'trainParams', trainParams);

meanNet = runstages(trainStage);

diary off;

fprintf('Press a key to continue...');
pause;

diaryon('mlptraining_stddev');

[buildfeaturematrixStage, extracttargetsStage] = pretrainingpipeline('stddev', true);
hyperoptStage = Stage(@hyperoptmlp, 'bayesopt_mlp_stddev.mat', RunPolicy.NEVER);

trainParams.showWindow = true;

trainStage = Stage(@trainmlp, 'final_trained_mlp_stddev.mat');
trainStage.addInputStages(buildfeaturematrixStage, extracttargetsStage, hyperoptStage);
trainStage.addParams('target', 'stddev', 'trainFunction', 'trainlm', 'trainParams', trainParams);

stddevNet = runstages(trainStage);

diary off;
