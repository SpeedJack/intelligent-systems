close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

diaryon('plotfeatdistrib');

%% -- run fuzzy pipeline -- %%

[normalizefeaturesStage, extracttargetsStage] = fuzzypipeline;

result = runstages(extracttargetsStage, normalizefeaturesStage);
features = result.normalizefeatures;
targets = result.extracttargets.activity;

%% -- plot histograms, classes merged in single figure -- %%

activities = {'Sit', 'Walk', 'Run'};
barFig = figure('Name', 'Complete histograms', 'NumberTitle', 'off', 'Visible', 'off');
tl = tiledlayout(barFig, 3, 1);
varNames = fieldnames(features);
for varNameIndex = 1:length(varNames)
	currentVar = varNames{varNameIndex};
	currentVarData = features.(currentVar);
	featureFuncs = fieldnames(currentVarData);
	for featureFuncIndex = 1:length(featureFuncs)
		ax = nexttile(tl);
		featureFunc = featureFuncs{featureFuncIndex};
		featureMatrix = currentVarData.(featureFunc);
		% histogram() do not support multiple colors. Need to get
		% histcounts first and the use a custom bar plot.
		for activity = 0:2
			counts(activity + 1, :) = histcounts(featureMatrix(:, targets == activity), -1:0.05:1);
		end
		bar(ax, -0.975:0.05:0.975, counts, 'stacked');
		title(ax, sprintf('Histogram of %s.%s', currentVar, featureFunc));
		xlabel(ax, 'Normalized Value');
		ylabel(ax, 'Count');
		legend(ax, activities{:});
	end
end
if SHOW_FIGURES
	barFig.Visible = 'on';
	fprintf('Press a key to continue...\n');
	pause;
end
exportfigure(barFig, 'complete-histograms', [10 10 800 1200]);
close(barFig);

%% -- plot histograms, classes separated in different figures -- %%

varNames = fieldnames(features);
for varNameIndex = 1:length(varNames)
	currentVar = varNames{varNameIndex};
	currentVarData = features.(currentVar);
	featureFuncs = fieldnames(currentVarData);
	for featureFuncIndex = 1:length(featureFuncs)
		featureFunc = featureFuncs{featureFuncIndex};
		featureMatrix = currentVarData.(featureFunc);
		histFig = figure('Name', sprintf('Histogram of %s.%s', currentVar, featureFunc), 'NumberTitle', 'off', 'Visible', 'off');
		tl = tiledlayout(histFig, 3, 1);
		for activity = 0:2
			ax = nexttile(tl);
			histogram(ax, featureMatrix(:, targets == activity), 'NumBins', 40, 'BinLimits', [-1, 1]);
			title(ax, sprintf('Histogram of %s.%s activity %s', currentVar, featureFunc, activities{activity+1}));
		end
		if SHOW_FIGURES
			histFig.Visible = 'on';
			fprintf('Press a key to continue...\n');
			pause;
		end
		exportfigure(histFig, sprintf('histograms-%s.%s', currentVar, featureFunc), [10 10 800 1200]);
		close(histFig);
	end
end

%% -- 3D scatter plot of classes in the feature space -- %%

fullFig = figure('Name', 'Classes on the Feature Space', 'NumberTitle', 'off', 'Visible', 'off');
ax = axes(fullFig);
plot3(ax, features.lc_1.mean_5(targets == 0), features.pleth_1.mean(targets == 0), features.pleth_2.mean_5(targets == 0), 'or', 'DisplayName', 'Sit');
hold(ax, 'on');
plot3(ax, features.lc_1.mean_5(targets == 1), features.pleth_1.mean(targets == 1), features.pleth_2.mean_5(targets == 1), 'xg', 'DisplayName', 'Walk');
plot3(ax, features.lc_1.mean_5(targets == 2), features.pleth_1.mean(targets == 2), features.pleth_2.mean_5(targets == 2), 'squareb', 'DisplayName', 'Run');
hold(ax, 'off');

grid(ax, 'on');
legend(ax);
xlabel(ax, 'lc_1 mean');
ylabel(ax, 'pleth_1 mean');
zlabel(ax, 'pleth_2 mean');

if SHOW_FIGURES
	fullFig.Visible = 'on';
	fprintf('Press a key to continue...\n');
	pause;
end
exportfigure(fullFig, 'classes-over-features-3d', [18 18 1600 1200]);
close(fullFig);

diary off;
