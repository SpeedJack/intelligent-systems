close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

%% -- mean estimation network -- %%

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

%% -- stddev estimation network -- %%

diaryon('mlptraining_stddev');

% actually, the parameters set here manually have proven to work better than
% those selected via bayesopt

[buildfeaturematrixStage, extracttargetsStage] = pretrainingpipeline('stddev', true);
% hyperoptStage = Stage(@hyperoptmlp, 'bayesopt_mlp_stddev.mat', RunPolicy.NEVER);

trainParams.showWindow = true;

trainStage = Stage(@trainmlp, 'final_trained_mlp_stddev.mat', RunPolicy.ALWAYS);
trainStage.addInputStages(buildfeaturematrixStage, extracttargetsStage);
trainStage.addParams('hiddenSizes', [74 29], 'target', 'stddev', 'trainFunction', 'trainlm', 'trainParams', trainParams);
% trainStage.addInputStages(buildfeaturematrixStage, extracttargetsStage, hyperoptStage);
% trainStage.addParams('target', 'stddev', 'trainFunction', 'trainlm', 'trainParams', trainParams);

stddevNet = runstages(trainStage);

diary off;
