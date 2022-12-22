function targets = extracttargets(dataset, varargin)
	p = inputParser;
	validWinCount = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x == round(x));
	validOverlapped = @(x) islogical(x) && isscalar(x);
	p.addRequired('dataset', @isstruct);
	p.addOptional('winCount', 1, validWinCount);
	p.addOptional('overlapped', false, validOverlapped);
	p.parse(dataset, varargin{:});

	dataset = p.Results.dataset;
	winCount = p.Results.winCount;
	overlapped = p.Results.overlapped;

	ecgMean = []; ecgStd = []; activity = [];
	for s = 1:dataset.subjectCount
		currentSubject = dataset.("s" + string(s));
		for a = dataset.activities(currentSubject.hasActivity)
			fprintf('Extracting targets for subject %d, activity %s...', s, a{1});

			currentTable = currentSubject.(a{1});
			ecgVector = currentTable.ecg;

			winSize = floor(size(ecgVector, 1) / (winCount + overlapped)) * (1 + overlapped);
			winStep = winSize - (overlapped * 1/2 * winSize);
			usedRows = winStep * winCount + (overlapped * winStep);
			ecgVector = ecgVector(1:usedRows, :);

			ecgMean(end+1) = mean(ecgVector);
			ecgStd(end+1) = std(ecgVector);
			activity(end+1) = find(strcmp(a{1}, {'sit', 'walk', 'run'})) - 1;
			fprintf('done.\n');
		end
	end

	targets.ecgMean = ecgMean;
	targets.ecgStd = ecgStd;
	targets.activity = activity;
end
