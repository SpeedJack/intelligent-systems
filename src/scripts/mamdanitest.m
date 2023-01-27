close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

fis = readfis('mamdani.fis');

[normalizefeaturesStage, extracttargetsStage] = fuzzypipeline;

buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_fuzzy.mat');
buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

result = runstages(buildfeaturematrixStage, extracttargetsStage);

targets = categorical(result.extracttargets.activity);
inputs = result.buildfeaturematrix';

outputs = evalfis(fis, inputs);
predicted = zeros(size(outputs));
predicted(outputs >= 0.87) = 1;
predicted(outputs > 1.13) = 2;

confFig = figure('Name', 'Mamdani Confusion Matrix', 'NumberTitle', 'off', 'Visible', 'off');
plotconfusion(targets, categorical(predicted'), 'Mamdani Confusion Matrix');
if SHOW_FIGURES
	confFig.Visible = 'on';
	fprintf('Press a key to continue...\n');
	pause;
end
exportfigure(confFig, 'mamdani-confusion', [10 10 500 500]);
close(confFig);
