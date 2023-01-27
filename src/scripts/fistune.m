close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

diaryon('fistune');

%% -- build and run pipeline to create and tune the ANFIS TSK -- %%

[normalizefeaturesStage, extracttargetsStage] = fuzzypipeline;

buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_fuzzy.mat');
buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

generatefisStage = Stage(@generatefis, 'fis.mat');
generatefisStage.addInputStages(buildfeaturematrixStage, extracttargetsStage);
generatefisStage.addParams('grid', 6, 'gbellmf');

result = runstages(generatefisStage, extracttargetsStage, buildfeaturematrixStage);

% renaming
cv = result.generatefis.cv;
chkError = result.generatefis.chkError;
trainError = result.generatefis.trainError;
fis = result.generatefis.fis;
chkfis = result.generatefis.chkFIS;

targets = categorical(result.extracttargets.activity);
inputs = result.buildfeaturematrix';

% print training, checking performances
fprintf('\nTrain error: %d\nTest error: %d\n', min(trainError), min(chkError));

%% -- evaluate the performance of the tuned ANFIS TSK -- %%

outputs = evalfis(fis, inputs);
outputs = categorical(max(min(round(outputs'), 2), 0));
trainOutputs = outputs(cv.training);
testOutputs = outputs(cv.test);

chkOutputs = evalfis(chkfis, inputs);
chkOutputs = categorical(max(min(round(chkOutputs'), 2), 0));
chkTrainOutputs = chkOutputs(cv.training);
chkTestOutputs = chkOutputs(cv.test);

%% -- plot confusion matrices, for both TrainFIS and ChkFIS -- %%

confFig = figure('Name', 'Confusion Matrix', 'NumberTitle', 'off', 'Visible', 'off');
plotconfusion(targets(cv.training), trainOutputs, 'TrainFIS on Training set', ...
	targets(cv.test), testOutputs, 'TrainFIS on Test set', ...
	targets, outputs, 'TrainFIS on All set', ...
	targets(cv.training), chkTrainOutputs, 'ChkFIS on Training set', ...
	targets(cv.test), chkTestOutputs, 'ChkFIS on Test set', ...
	targets, chkOutputs, 'ChkFIS on All set');
if SHOW_FIGURES
	confFig.Visible = 'on';
	fprintf('Press a key to continue...\n');
	pause;
end
exportfigure(confFig, 'fis-confusion', [10 10 1000 1200]);
close(confFig);

diary off;
