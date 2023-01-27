function augmented = augmentdata(dataset, varargin)
% Perform data augmentation via random subsampling.
	p = inputParser;
	validDuration = @(x) isscalar(x) && isduration(x) && (x > 0);
	validPositiveInt = @(x) isscalar(x) && isnumeric(x) && (x > 0) && (x == round(x));
	p.addRequired('dataset', @isstruct);
	p.addOptional('samplesPerActivity', 2000, validPositiveInt);
	p.addParameter('fixedTimeSteps', false, @(x) isscalar(x) && islogical(x));
	p.addParameter('minDuration', seconds(25), validDuration);
	p.addParameter('maxDuration', seconds(40), validDuration);
	p.addParameter('timeSteps', 2500, validPositiveInt);
	p.addParameter('rngSeed', 0xdeadbeef, validPositiveInt);
	p.parse(dataset, varargin{:});

	dataset = p.Results.dataset;
	samplesPerActivity = p.Results.samplesPerActivity; % how many samples are needed per activity
	% min and max duration of extracted samples...
	minDuration = floor(p.Results.minDuration / milliseconds(2));
	maxDuration = ceil(p.Results.maxDuration / milliseconds(2));
	% ...or use a fixed number of time steps for each sample
	fixedTimeSteps = p.Results.fixedTimeSteps;
	timeSteps = p.Results.timeSteps;
	% RNG
	rngSeed = p.Results.rngSeed;

	augmented.subjectCount = samplesPerActivity;
	augmented.activities = dataset.activities;

	fprintf('Using seed: %d.\n', rngSeed);
	rng(rngSeed);

	% For each activity, we need to select randomly a subject where to
	% extract the next subsample. To do this, a random integer is later
	% (last 'for' loop) compared with values computed here. Here we extract
	% the number of time steps in each record, and also compute th total
	% number of time steps available for each activity. After, the random
	% integer (from 1 to the total just computed) extracted, will be
	% compared to the cumulative sum of the time steps in order to select
	% randomly a subject. Note that subject that have longer records will
	% be selected for subsampling more often (this is wanted: they have
	% more data).
	rowCounts = {};
	totalRows = [];
	for a = dataset.activities
		actRowCounts = [];
		for s = 1:dataset.subjectCount
			currentSubject = dataset.("s" + string(s));
			if ~isfield(currentSubject, a{1})
				actRowCounts = [actRowCounts; [0, s]];
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

	% Now perform subsampling, for each activity.
	for a = 1:length(dataset.activities)
		activity = dataset.activities{a};
		fprintf('Augmenting data via subsampling for activity ''%s'' (samplesPerActivity = %d)...', activity, samplesPerActivity);
		for curSample = 1:samplesPerActivity
			if mod(curSample, 100) == 0
				fprintf('%d...', curSample);
			end
			% select randomly a subject from which to extract next
			% sample for current activity
			select = randi(totalRows(a));
			actRowCounts = rowCounts{a};
			rowCountIndex = find(cumsum(actRowCounts(:, 1)) >= select, 1);
			subjectIndex = actRowCounts(rowCountIndex, 2);
			currentSubject = dataset.("s" + string(subjectIndex));
			currentTable = currentSubject.(activity);
			% now select randomly the duration that the sample
			% must have, based on user provided limits.
			rowCount = actRowCounts(subjectIndex, 1);
			if fixedTimeSteps
				sampleRowCount = timeSteps;
			else
				sampleRowCount = randi([minDuration, maxDuration]);
			end
			% select start index randomly
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
