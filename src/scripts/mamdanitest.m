close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

% Load mamdani FIS
fis = readfis('mamdani.fis');

%% -- run fuzzy pipeline -- %%

[normalizefeaturesStage, extracttargetsStage] = fuzzypipeline;

buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_fuzzy.mat');
buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

result = runstages(buildfeaturematrixStage, extracttargetsStage);

% get inputs and targets
targets = categorical(result.extracttargets.activity);
inputs = result.buildfeaturematrix';

%% -- evaluate FIS -- %%

outputs = evalfis(fis, inputs);

% predicted class is the class with the higher membership degree
predicted = zeros(size(outputs));
predicted(outputs >= 0.87) = 1; % values are intersections between FIS output's MFs
predicted(outputs > 1.13) = 2;

%% -- plot confusion matrix -- %%

confFig = figure('Name', 'Mamdani Confusion Matrix', 'NumberTitle', 'off', 'Visible', 'off');
plotconfusion(targets, categorical(predicted'), 'Mamdani Confusion Matrix');
if SHOW_FIGURES
	confFig.Visible = 'on';
	fprintf('Press a key to continue...\n');
	pause;
end
exportfigure(confFig, 'mamdani-confusion', [10 10 500 500]);
close(confFig);
