close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

trainFcns = {'trainbfg', 'trainrp', 'trainscg', 'traincgb', 'trainoss', 'traingdx', 'trainbr'};

diaryon('mlphyperopt');

[bestTrainlmMeanPerf, bestMeanHU, ~] = hyperoptimizemlp('mean', [6 10 15 20 25 30 40], 'trainlm', false);
[bestMeanPerf, ~, bestMeanTF] = hyperoptimizemlp('mean', bestMeanHU, trainFcns, false);

if bestTrainlmMeanPerf < bestMeanPerf
	bestMeanTF = 'trainlm';
	bestMeanPerf = bestTrainlmMeanPerf;
end

[bestTrainlmStdPerf, bestStdHU, ~] = hyperoptimizemlp('stddev', [6 10 15 20 25 30 40], 'trainlm', false);
[bestStdPerf, ~, bestStdTF] = hyperoptimizemlp('stddev', bestStdHU, trainFcns, false);

if bestTrainlmStdPerf < bestStdPerf
	bestStdTF = 'trainlm';
	bestStdPerf = bestTrainlmStdPerf;
end

fprintf('Results for ECG MEAN (no windowed):\n\tBest training function: %s\n\tBest n. of hidden units: %d\n\tTest performance: %f\n', bestMeanTF, bestMeanHU, bestMeanPerf);
fprintf('Results for ECG STDDEV (no windowed):\n\tBest training function: %s\n\tBest n. of hidden units: %d\n\tTest performance: %f\n', bestStdTF, bestStdHU, bestStdPerf);

diary off;

diaryon('mlphyperopt_windowed');

[bestTrainlmMeanPerf_win, bestMeanHU_win, ~] = hyperoptimizemlp('mean', [50 65 80 100 115 130 150 180], 'trainlm', true);
[bestMeanPerf_win, ~, bestMeanTF_win] = hyperoptimizemlp('mean', bestMeanHU_win, trainFcns, true);

if bestTrainlmMeanPerf_win < bestMeanPerf_win
	bestMeanTF_win = 'trainlm';
	bestMeanPerf_win = bestTrainlmMeanPerf_win;
end

[bestTrainlmStdPerf_win, bestStdHU_win, ~] = hyperoptimizemlp('stddev', [50 65 80 100 115 130 150 180], 'trainlm', true);
[bestStdPerf_win, ~, bestStdTF_win] = hyperoptimizemlp('stddev', bestStdHU_win, trainFcns, true);

if bestTrainlmStdPerf_win < bestStdPerf_win
	bestStdTF_win = 'trainlm';
	bestStdPerf_win = bestTrainlmStdPerf_win;
end

fprintf('Results for ECG MEAN (windowed):\n\tBest training function: %s\n\tBest n. of hidden units: %d\n\tTest performance: %f\n', bestMeanTF_win, bestMeanHU_win, bestMeanPerf_win);
fprintf('Results for ECG STDDEV (windowed):\n\tBest training function: %s\n\tBest n. of hidden units: %d\n\tTest performance: %f\n', bestStdTF_win, bestStdHU_win, bestStdPerf_win);

diary off;


function [bestPerformance, bestHiddenUnits, bestTrainFcn] = hyperoptimizemlp(target, huRange, trainFcns, windowed)
	if isscalar(huRange)
		huRange = [huRange];
	end
	if ~iscell(trainFcns)
		trainFcns = {trainFcns};
	end

	windowedString = '';
	if windowed
		windowedString = '_windowed';
	end

	bestPerformance = Inf;
	for trainFcnCell = trainFcns
		trainFcn = trainFcnCell{1};
		for hiddenUnits = huRange
			fprintf('Training for ''%s'' (hiddenUnits=%d, trainingFunction=%s)...\n', target, hiddenUnits, trainFcn);

			[buildfeaturematrixStage, extracttargetsStage] = pretrainingpipeline(target, windowed);
			outFile = sprintf('trained_mlp%s_%s_%d_%s.mat', windowedString, target, hiddenUnits, trainFcn);
			trainParams.time = 60*60; % 1 hour

			trainStage = Stage(@trainmlp, outFile);
			trainStage.addInputStages(buildfeaturematrixStage, extracttargetsStage);
			trainStage.addParams('target', target, 'hiddenSizes', hiddenUnits, 'trainFunction', trainFcn, 'trainParams', trainParams);

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

	fprintf('Best performance for ''%s'': %f (hiddenUnits=%d, trainingFunction=%s).\n', target, bestPerformance, bestHiddenUnits, bestTrainFcn);
end