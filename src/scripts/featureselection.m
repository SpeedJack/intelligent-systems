close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

diaryon('featureselection');

preparedataStage = Stage(@preparedata, 'dataset.mat');
preparedataStage.addDatasetParam();

fixdataStage = Stage(@fixdata, 'fixed_dataset.mat');
fixdataStage.addInputStages(preparedataStage);
fixdataStage.ClearMemoryAfterExecution = true;

augmentdataStage = Stage(@augmentdata, 'augmented_dataset.mat');
augmentdataStage.addInputStages(fixdataStage);
augmentdataStage.ClearMemoryAfterExecution = true;

getfeaturesStage = Stage(@getfeatures, 'full_feature_list.mat');

extractfeaturesStage = Stage(@extractfeatures, 'full_features.mat');
extractfeaturesStage.addInputStages(augmentdataStage, getfeaturesStage);

extracttargetsStage = Stage(@extracttargets, 'targets.mat');
extracttargetsStage.addInputStages(augmentdataStage);

findcorrelatedfeaturesStage = Stage(@findcorrelatedfeatures, 'correlated_features.mat');
findcorrelatedfeaturesStage.addInputStages(extractfeaturesStage);

result = runstages(findcorrelatedfeaturesStage);

corrFig = result.correlationHeatmap;
corrFig.Name = corrFig.Name + " (no windows)";
corrFig.Children.Title = corrFig.Children.Title + " (no windows)";
exportfigure(corrFig, 'full-correlation-matrix', [18 18 1665 1665]);

if SHOW_FIGURES
	corrFig.Visible = 'on';
	fprintf('Press a key to continue...');
	pause;
end
close all;

dropcorrelatedfeaturesStage = Stage(@dropcorrelatedfeatures, 'uncorrelated_features.mat');
dropcorrelatedfeaturesStage.addInputStages(extractfeaturesStage, findcorrelatedfeaturesStage);

% analyzecorrelationStage = Stage(@findcorrelatedfeatures, 'correlation_matrix.mat');
% analyzecorrelationStage.addInputStages(dropcorrelatedfeaturesStage);
%
% result = runstages(analyzecorrelationStage);
%
% afterFig = result.correlationHeatmap;
% afterFig.Name = afterFig.Name + " (no windows) [AFTER]";
% afterFig.Children.Title = afterFig.Children.Title + " (no windows) [AFTER]";
% exportfigure(afterFig, 'filtered-correlation-matrix', [18 18 1665 1665]);
% if SHOW_FIGURES
% 	afterFig.Visible = 'on';
% 	fprintf('Press a key to continue...');
% 	pause;
% end
% close all;

normalizefeaturesStage = Stage(@normalizefeatures, 'normalized_features.mat');
normalizefeaturesStage.addInputStages(dropcorrelatedfeaturesStage);
normalizefeaturesStage.ClearMemoryAfterExecution = true;

sfsStage = Stage(@selectfeatures, 'selected_features.mat');
sfsStage.addInputStages(normalizefeaturesStage, extracttargetsStage);

result = runstages(sfsStage);
diary off;


diaryon('featureselection_windowed');

extractfeaturesStage_win = Stage(@extractfeatures, 'full_features_windowed.mat');
extractfeaturesStage_win.addInputStages(augmentdataStage, getfeaturesStage);
extractfeaturesStage_win.addParams(5, true);

extracttargetsStage_win = Stage(@extracttargets, 'targets_windowed.mat');
extracttargetsStage_win.addInputStages(augmentdataStage);
extracttargetsStage_win.addParams(5, true);

findcorrelatedfeaturesStage_win = Stage(@findcorrelatedfeatures, 'correlated_features_windowed.mat');
findcorrelatedfeaturesStage_win.addInputStages(extractfeaturesStage_win);

result = runstages(findcorrelatedfeaturesStage_win);

corrFig = result.correlationHeatmap;
corrFig.Name = corrFig.Name + " (windowed)";
corrFig.Children.Title = corrFig.Children.Title + " (windowed)";
exportfigure(corrFig, 'full-correlation-matrix-windowed-250', [18 18 1665 1665]);
if SHOW_FIGURES
	corrFig.Visible = 'on';
	fprintf('Press a key to continue...');
	pause;
end
close all;

dropcorrelatedfeaturesStage_win = Stage(@dropcorrelatedfeatures, 'uncorrelated_features_windowed.mat');
dropcorrelatedfeaturesStage_win.addInputStages(extractfeaturesStage_win, findcorrelatedfeaturesStage_win);

normalizefeaturesStage_win = Stage(@normalizefeatures, 'normalized_features_windowed.mat');
normalizefeaturesStage_win.addInputStages(dropcorrelatedfeaturesStage_win);
normalizefeaturesStage_win.ClearMemoryAfterExecution = true;

sfsStage_win = Stage(@selectfeatures, 'selected_features_windowed.mat');
sfsStage_win.addInputStages(normalizefeaturesStage_win, extracttargetsStage_win);
sfsStage_win.addParams('nfeatures', 7);

result = runstages(sfsStage_win);
diary off;
