close all; clearvars -except -regexp ^[A-Z0-9_]+$; clc;

diaryon('wangmendel');

[normalizefeaturesStage, extracttargetsStage] = fuzzypipeline;

buildfeaturematrixStage = Stage(@buildfeaturematrix, 'feature_matrix_fuzzy.mat');
buildfeaturematrixStage.addInputStages(normalizefeaturesStage);

result = runstages(extracttargetsStage, buildfeaturematrixStage);
featureMatrix = result.buildfeaturematrix';
targets = result.extracttargets.activity' + 1;

mfs = {'low', 'low-med', 'med-high', 'high';
	'low', 'low-med', 'med-high', 'high';
	'low', 'med', 'med-high', 'high'};
mfdefs = [0.5 2 -0.8; 0.25 2 -0.3; 0.4 2 0.2; 0.5 2 0.8]';
mfdefs(:,:,2) = [0.5 2 -0.9; 0.3 2 -0.2; 0.2 2 0.2; 0.2 2 1]';
mfdefs(:,:,3) = [0.5 2 -0.9; 0.4 2 0; 0.25 2 0.35; 0.3 2 1]';
activities = {'sit', 'walk', 'run'};
featureNames = {'lc1mean', 'pleth1mean', 'pleth2mean'};

rulesMat = combvec(1:2, 0:4, 0:4, 0:4, 1:3)';
rulesMat = rulesMat(any((rulesMat(:, 2:4) ~= 0)'), :);
rulesMat = [rulesMat, zeros(size(rulesMat, 1), 3)];

memMat = zeros(size(featureMatrix, 1), 3);
degMat = zeros(size(featureMatrix, 1), 3);

for i = 1:size(featureMatrix, 1)
	for j = 1:size(featureMatrix, 2)
		elem = featureMatrix(i, j);
		maxMem = 0;
		maxIdx = 0;
		idx = 0;
		for mf = mfdefs(:,:,j)
			idx = idx + 1;
			mem = gbellmf(elem, mf');
			if mem > maxMem
				maxMem = mem;
				maxIdx = idx;
			end
		end
		memMat(i, j) = maxIdx;
		degMat(i, j) = maxMem;
	end
end

for i = 1:size(rulesMat, 1)
	goodMask = targets == rulesMat(i, 5);
	nearMask = abs(targets - rulesMat(i, 5)) == 1;
	farMask = abs(targets - rulesMat(i, 5)) == 2;
	ruleMask = [];
	for j = 1:3
		mask = (rulesMat(i, j+1) == 0) | (memMat(:, j) == rulesMat(i, j+1));
		if isempty(ruleMask)
			ruleMask = mask;
		elseif rulesMat(i, 1) == 1
			ruleMask = (ruleMask) & (mask);
		else
			ruleMask = (ruleMask) | (mask);
		end
	end
	goodMask = (ruleMask) & (goodMask);
	nearMask = (ruleMask) & (nearMask);
	farMask = (ruleMask) & (farMask);
	goodInputs = degMat(goodMask, :);
	nearInputs = degMat(nearMask, :);
	farInputs = degMat(farMask, :);
	farInputs = farInputs * 2;
	allInputs = [goodInputs; nearInputs; farInputs];
	rulesMat(i, 6) = sum(prod(goodInputs'));	
	rulesMat(i, 7) = sum(prod(allInputs'));
	rulesMat(i, 8) = rulesMat(i, 6) / rulesMat(i, 7);

end

rulesMat = rulesMat(~isnan(rulesMat(:, 8)), :);
rulesMat = rulesMat(rulesMat(:, 8) >= 0.5, :);
rulesMat(:, 8) = rescale(rulesMat(:, 8));
rulesMat = rulesMat(rulesMat(:, 8) >= 0.01, :);

rulesGroups = findgroups(rulesMat(:, 1), rulesMat(:, 2), rulesMat(:, 3), rulesMat(:, 4));
selectedRules = [];
for i = unique(rulesGroups)'
	conflictRules = rulesMat(find(rulesGroups == i), :);
	conflictRules = sortrows(conflictRules, -8);
	selectedRules = [selectedRules; conflictRules(1, :)];
end

selectedRules = sortrows(selectedRules, -8);

alreadySeen = [];
for i = 1:size(selectedRules, 1)
	fprintf('[%3d] IF    ', i);
	conjunction = 'AND';
	if selectedRules(i, 1) == 2
		conjunction = 'OR';
	end
	first = true;
	for j = 2:4
		membership = selectedRules(i, j);
		if membership == 0
			fprintf('%36s', '');
			continue;
		end
		mf = mfs{j-1, membership};
		feat = featureNames{j-1};
		if ~first
			fprintf('    %3s    ', conjunction);
		end
		first = false;
		fprintf('%10s  IS  %8s ', feat, mf);
	end
	activity = activities{selectedRules(i, 5)};
	weight = selectedRules(i, 8);
	fprintf('    THEN activity IS    %4s  (%0.2f)', activity, weight);

	included = false;
	if ~isempty(alreadySeen)
		included = ismember(alreadySeen(:, 1:4), selectedRules(i, 1:4), 'rows');
	end
	if any(included)
		fprintf('  [INCLUDED: %3d]', alreadySeen(included, 5));
	else
		alreadySeen = [alreadySeen; selectedRules(i, 1:4), i];
		for n = find(selectedRules(i, 2:4) == 0)
			for m = 1:4
				alreadySeen = [alreadySeen; selectedRules(i, 1:n), m, selectedRules(i, n+2:4), i];
			end
		end
	end
	fprintf('\n');
end

diary off;
