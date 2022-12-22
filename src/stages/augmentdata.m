function augmented = augmentdata(dataset, varargin)
	p = inputParser;
	validDuration = @(x) isscalar(x) && isduration(x) && (x > 0);
	validPositiveInt = @(x) isscalar(x) && isnumeric(x) && (x > 0) && (x == round(x));
	p.addRequired('dataset', @isstruct);
	p.addOptional('samplesPerActivity', 2000, validPositiveInt);
	p.addParameter('minDuration', seconds(25), validDuration);
	p.addParameter('maxDuration', seconds(40), validDuration);
	p.addParameter('rngSeed', 0xdeadbeef, validPositiveInt);
	p.parse(dataset, varargin{:});

	dataset = p.Results.dataset;
	samplesPerActivity = p.Results.samplesPerActivity;
	minDuration = floor(p.Results.minDuration / milliseconds(2));
	maxDuration = ceil(p.Results.maxDuration / milliseconds(2));
	rngSeed = p.Results.rngSeed;

	augmented.subjectCount = samplesPerActivity;
	augmented.activities = dataset.activities;

	fprintf('Using seed: %d.\n', rngSeed);
	rng(rngSeed);

	rowCounts = {};
	totalRows = [];
	for a = dataset.activities
		actRowCounts = [];
		for s = 1:dataset.subjectCount
			currentSubject = dataset.("s" + string(s));
			if ~isfield(currentSubject, a{1})
				continue;
			end
			currentTable = currentSubject.(a{1});
			currentRowCount = height(currentTable);
			actRowCounts = [actRowCounts; [currentRowCount, s]];
		end
		if ~isempty(actRowCounts)
			rowCounts{end + 1} = actRowCounts;
			totalRows = [totalRows sum(actRowCounts(:, 1))];
		end
	end

	for a = 1:length(dataset.activities)
		activity = dataset.activities{a};
		fprintf('Augmenting data via subsampling for activity ''%s'' (samplesPerActivity = %d)...', activity, samplesPerActivity);
		for curSample = 1:samplesPerActivity
			if mod(curSample, 100) == 0
				fprintf('%d...', curSample);
			end
			select = randi(totalRows(a));
			actRowCounts = rowCounts{a};
			rowCountIndex = find(cumsum(actRowCounts(:, 1)) >= select, 1);
			subjectIndex = actRowCounts(rowCountIndex, 2);
			currentSubject = dataset.("s" + string(subjectIndex));
			currentTable = currentSubject.(activity);
			rowCount = actRowCounts(subjectIndex, 1);
			sampleRowCount = randi([minDuration, maxDuration]);
			startIndex = randi(rowCount - sampleRowCount);
			endIndex = startIndex + sampleRowCount - 1;
			augmented.("s" + string(curSample)).(activity) = currentTable(startIndex:endIndex, :);
			augmented.("s" + string(curSample)).hasActivity = true(1, 3);
			augmented.("s" + string(curSample)).from.subject = subjectIndex;
			augmented.("s" + string(curSample)).from.index = startIndex;
		end
		fprintf('done.\n');
	end
end
