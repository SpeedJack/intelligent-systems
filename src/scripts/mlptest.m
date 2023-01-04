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

sfsStage = Stage(@selectfeatures, 'selected_features.mat', RunPolicy.NEVER);

extractfeaturesStage = Stage(@extractfeatures, 'features_test_mean.mat');
extractfeaturesStage.addInputStages(augmentdataStage, sfsStage);
extractfeaturesStage.addParams('target', 'mean');

normalizefeaturesStage = Stage(@normalizefeatures, 'normalized_features_test_mean.mat');
normalizefeaturesStage.addInputStages(extractfeaturesStage);

buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_test_mean.mat');
buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

trainStage = Stage(@trainmlp, 'final_trained_mlp_mean.mat', RunPolicy.NEVER);

meanData = runstages(buildfeaturematrixStage, extracttargetsStage, trainStage);

meanNetwork = meanData.trainmlp.network;
meanFeatureMatrix = meanData.buildfeaturematrix;
meanTargets = meanData.extracttargets.ecgMean;

meanOutputs = meanNetwork(meanFeatureMatrix);

regressionFig = figure('Name', 'Mean Regression Plot', 'NumberTitle', 'off', 'Visible', 'off');
plotregression(meanTargets, meanOutputs);
exportfigure(regressionFig, 'mean_regression_plot', [18 18 1000 1000]);
if SHOW_FIGURES
	regressionFig.Visible = 'on';
	fprintf('Press a key to continue...');
	pause;
end
close all;

errorFig = figure('Name', 'Mean Error Histogram', 'NumberTitle', 'off', 'Visible', 'off');
ploterrhist(meanTargets - meanOutputs, 'bins', 50);
exportfigure(errorFig, 'mean_error_histogram', [18 18 1400 800]);
if SHOW_FIGURES
	errorFig.Visible = 'on';
	fprintf('Press a key to continue...');
	pause;
end
close all;

diary off;


diaryon('mlptest_stddev');

extracttargetsStage = Stage(@extracttargets, 'targets_test_windowed.mat');
extracttargetsStage.addInputStages(augmentdataStage);
extracttargetsStage.addParams(5, true);

sfsStage = Stage(@selectfeatures, 'selected_features_windowed.mat', RunPolicy.NEVER);

extractfeaturesStage = Stage(@extractfeatures, 'features_test_stddev.mat');
extractfeaturesStage.addInputStages(augmentdataStage, sfsStage);
extractfeaturesStage.addParams(5, true);
extractfeaturesStage.addParams('target', 'stddev');

normalizefeaturesStage = Stage(@normalizefeatures, 'normalized_features_test_stddev.mat');
normalizefeaturesStage.addInputStages(extractfeaturesStage);

buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_test_stddev.mat');
buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

trainStage = Stage(@trainmlp, 'final_trained_mlp_stddev.mat', RunPolicy.NEVER);

stdData = runstages(buildfeaturematrixStage, extracttargetsStage, trainStage);

stdNetwork = stdData.trainmlp.network;
stdFeatureMatrix = stdData.buildfeaturematrix;
stdTargets = stdData.extracttargets.ecgMean;

stdOutputs = stdNetwork(stdFeatureMatrix);

regressionFig = figure('Name', 'Stddev Regression Plot', 'NumberTitle', 'off', 'Visible', 'off');
plotregression(stdTargets, stdOutputs);
exportfigure(regressionFig, 'stddev_regression_plot', [18 18 1000 1000]);
if SHOW_FIGURES
	regressionFig.Visible = 'on';
	fprintf('Press a key to continue...');
	pause;
end
close all;

errorFig = figure('Name', 'Stddev Error Histogram', 'NumberTitle', 'off', 'Visible', 'off');
ploterrhist(stdTargets - stdOutputs, 'bins', 50);
exportfigure(errorFig, 'stddev_error_histogram', [18 18 1400 800]);
if SHOW_FIGURES
	errorFig.Visible = 'on';
	fprintf('Press a key to continue...');
	pause;
end
close all;

diary off;
