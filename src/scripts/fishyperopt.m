close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

diaryon('fishyperopt');

[normalizefeaturesStage, extracttargetsStage] = fuzzypipeline;

buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_fuzzy.mat');
buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

configs = {{'grid', 4, 'gbellmf', 'epochs', 100};
	{'grid', 4, 'trapmf', 'epochs', 100};
	{'grid', 5, 'gbellmf', 'epochs', 100};
	{'grid', 5, 'trapmf', 'epochs', 100};
	{'grid', 6, 'gbellmf', 'epochs', 100};
	{'grid', 6, 'trapmf', 'epochs', 100};
	{'subcluster', 'epochs', 100};
	{'fcmcluster', 'epochs', 100}};
minTrainError = [];
minTestError = [];

for config = configs'
	config = config{1};
	suffix = strjoin(string(config), '_');

	generatefisStage = Stage(@generatefis, strcat('fis_', suffix, '.mat'), RunPolicy.ALWAYS);
	generatefisStage.addInputStages(buildfeaturematrixStage, extracttargetsStage);
	generatefisStage.addParams(config{:});

	result = runstages(generatefisStage);
	minTrainError = [minTrainError; min(result.trainError)];
	minTestError = [minTestError; min(result.chkError)];
end

for i = 1:length(configs)
	config = configs{i};
	fprintf('Result for %s:\n\tTrain error: %d\n\tTest error: %d\n', strjoin(string(config), ','), minTrainError(i), minTestError(i));
	if minTrainError(i) == min(minTrainError)
		fprintf('\t* BEST TRAIN *\n');
	end
	if minTestError(i) == min(minTestError)
		fprintf('\t* BEST TEST *\n');
	end
end

diary off;
