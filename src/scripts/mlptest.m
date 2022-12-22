close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

diaryon('mlptest_mean');

preparedataStage = Stage(@preparedata, 'dataset.mat');
preparedataStage.addDatasetParam();

fixdataStage = Stage(@fixdata, 'fixed_dataset.mat');
fixdataStage.addInputStages(preparedataStage);

augmentdataStage = Stage(@augmentdata, 'augmented_dataset_test.mat');
augmentdataStage.addInputStages(fixdataStage);
augmentdataStage.addParams('rngSeed', 0xbadbabe5);

extracttargetsStage = Stage(@extracttargets, 'targets_test.mat');
extracttargetsStage.addInputStages(augmentdataStage);
% extracttargetsStage.addParams(5, true);

sfsStage = Stage(@selectfeatures, 'selected_features.mat', RunPolicy.NEVER);
% sfsStage = Stage(@selectfeatures, 'selected_features_windowed.mat', RunPolicy.NEVER);

extractfeaturesStage = Stage(@extractfeatures, 'features_test_mean.mat');
extractfeaturesStage.addInputStages(augmentdataStage, sfsStage);
% extractfeaturesStage.addParams(5, true);
extractfeaturesStage.addParams('target', 'mean');

normalizefeaturesStage = Stage(@normalizefeatures, 'normalized_features_test_mean.mat');
normalizefeaturesStage.addInputStages(extractfeaturesStage);

buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_test_mean.mat');
buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

trainStage = Stage(@trainmlp, 'final_trained_mlp_mean.mat', RunPolicy.NEVER);

meanData = runstages(buildfeaturematrixStage, extracttargetsStage, trainStage);

% TODO

diary off;

diaryon('mlptest_stddev');

extractfeaturesStage = Stage(@extractfeatures, 'features_test_stddev.mat');
extractfeaturesStage.addInputStages(augmentdataStage, sfsStage);
% extractfeaturesStage.addParams(5, true);
extractfeaturesStage.addParams('target', 'stddev');

normalizefeaturesStage = Stage(@normalizefeatures, 'normalized_features_test_stddev.mat');
normalizefeaturesStage.addInputStages(extractfeaturesStage);

buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_test_stddev.mat');
buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

trainStage = Stage(@trainmlp, 'final_trained_mlp_stddev.mat', RunPolicy.NEVER);

stdData = runstages(buildfeaturematrixStage, extracttargetsStage, trainStage);

% TODO

diary off;
