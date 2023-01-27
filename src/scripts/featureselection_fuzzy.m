close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

diaryon('featureselection_fuzzy');

% load normalized features. RunPolicy.NEVER: data must be available in cache
% files.
featuresStage = Stage(@normalizefeatures, 'normalized_train_features_mean.mat', RunPolicy.NEVER);
featuresStage_win = Stage(@normalizefeatures, 'normalized_train_features_stddev_windowed.mat', RunPolicy.NEVER);

mergefeaturesStage = Stage(@mergefeatures, 'merged_features.mat');
mergefeaturesStage.addInputStages(featuresStage, featuresStage_win);

extracttargetsStage = Stage(@extracttargets, 'targets.mat', RunPolicy.NEVER);

% Find best features used for activity MLP
sfsStage = Stage(@selectfeatures_fuzzy, 'selected_features_fuzzy.mat');
sfsStage.addInputStages(mergefeaturesStage, extracttargetsStage);

result = runstages(sfsStage);
diary off;
