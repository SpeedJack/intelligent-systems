close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

% Like in mlptrain.m, but here we need 2 pretraining pipelines, like it was
% needed in mlphyperopt_act.m and mlpbayesopt_act.m.

diaryon('mlptraining_activity');

[buildfeaturematrixStage_mean, extracttargetsStage] = pretrainingpipeline('mean', false);
[buildfeaturematrixStage_std, ~] = pretrainingpipeline('stddev', true);

mergefeaturematrixStage = Stage(@mergefeaturematrix, 'merged_feature_matrix.mat');
mergefeaturematrixStage.addInputStages(buildfeaturematrixStage_mean, buildfeaturematrixStage_std);

hyperoptStage = Stage(@hyperoptmlp_act, 'bayesopt_mlp_activity.mat', RunPolicy.NEVER);

trainParams.showWindow = true;

trainStage = Stage(@trainmlp_act, 'final_trained_mlp_activity.mat', RunPolicy.ALWAYS);
trainStage.addInputStages(mergefeaturematrixStage, extracttargetsStage, hyperoptStage);
trainStage.addParams('trainFunction', 'trainscg', 'trainParams', trainParams);

meanNet = runstages(trainStage);

diary off;
