close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

trainFcns = {'trainbfg', 'trainrp', 'traincgb', 'trainoss', 'traingdx'};

diaryon('mlphyperopt_activity');

[bestTrainscgPerf, bestHU, ~] = hyperoptimizemlp([65 80 100 125 150 175 200 220], 'trainscg');
[bestPerf, ~, bestTF] = hyperoptimizemlp(bestHU, trainFcns);

if bestTrainscgPerf < bestPerf
	bestTF = 'trainscg';
	bestPerf = bestTrainscgPerf;
end

fprintf('Results for ACTIVITY:\n\tBest training function: %s\n\tBest n. of hidden units: %d\n\tTest performance: %f\n', bestTF, bestHU, bestPerf);

diary off;


function [bestPerformance, bestHiddenUnits, bestTrainFcn] = hyperoptimizemlp(huRange, trainFcns)
	if isscalar(huRange)
		huRange = [huRange];
	end
	if ~iscell(trainFcns)
		trainFcns = {trainFcns};
	end

	bestPerformance = Inf;
	for trainFcnCell = trainFcns
		trainFcn = trainFcnCell{1};
		for hiddenUnits = huRange
			fprintf('Training for ''activity'' (hiddenUnits=%d, trainingFunction=%s)...\n', hiddenUnits, trainFcn);

			[buildfeaturematrixStage_mean, extracttargetsStage] = pretrainingpipeline('mean', false);
			[buildfeaturematrixStage_std, ~] = pretrainingpipeline('stddev', true);
			mergefeaturematrixStage = Stage(@mergefeaturematrix, 'merged_feature_matrix.mat');
			mergefeaturematrixStage.addInputStages(buildfeaturematrixStage_mean, buildfeaturematrixStage_std);

			outFile = sprintf('trained_mlp_activity_%d_%s.mat', hiddenUnits, trainFcn);
			trainParams.time = 60*60; % 1 hour

			trainStage = Stage(@trainmlp_act, outFile);
			trainStage.addInputStages(mergefeaturematrixStage, extracttargetsStage);
			trainStage.addParams('hiddenSizes', hiddenUnits, 'trainFunction', trainFcn, 'trainParams', trainParams);

			result = runstages(trainStage);

			fprintf('\tPerformance: %f\n', result.trainingRecord.best_perf);
			fprintf('\tValidation performance: %f\n', result.trainingRecord.best_vperf);
			testPerformance = result.trainingRecord.best_tperf;
			fprintf('\tTest performance: %f.\n', testPerformance);

			if testPerformance < bestPerformance
				bestPerformance = testPerformance;
				bestHiddenUnits = hiddenUnits;
				bestTrainFcn = trainFcn;
			end
		end
	end

	fprintf('Best performance for ''activity'': %f (hiddenUnits=%d, trainingFunction=%s).\n', bestPerformance, bestHiddenUnits, bestTrainFcn);
end
