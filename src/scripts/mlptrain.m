close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

diaryon('mlptraining_mean');

[buildfeaturematrixStage, extracttargetsStage] = pretrainingpipeline('mean', true);
hyperoptStage = Stage(@hyperoptmlp, 'bayesopt_mlp_mean.mat', RunPolicy.NEVER);

trainStage = Stage(@trainmlp, 'final_trained_mlp_mean.mat');
trainStage.addInputStages(buildfeaturematrixStage, extracttargetsStage, hyperoptStage);
trainStage.addParams('target', 'mean', 'trainFunction', 'trainbr');

meanNet = runstages(trainStage);

diary off;

diaryon('mlptraining_stddev');

[buildfeaturematrixStage, extracttargetsStage] = pretrainingpipeline('stddev', true);
hyperoptStage = Stage(@hyperoptmlp, 'bayesopt_mlp_stddev.mat', RunPolicy.NEVER);

trainStage = Stage(@trainmlp, 'final_trained_mlp_stddev.mat');
trainStage.addInputStages(buildfeaturematrixStage, extracttargetsStage, hyperoptStage);
trainStage.addParams('target', 'stddev', 'trainFunction', 'trainbr');

stddevNet = runstages(trainStage);

diary off;
