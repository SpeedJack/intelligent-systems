function fixedDataset = fixdata(dataset, varargin)
% fix the dataset by removing holes (jumps in timestamps) in timetables. If a
% hole is found, data is divided into 2 timetables, creating a new subject.
	p = inputParser;
	validMaxDelta = @(x) isscalar(x) && isduration(x) && (x > 0);
	validPositiveInt = @(x) isscalar(x) && isnumeric(x) && (x >= 0) && (x == round(x));
	p.addRequired('dataset', @isstruct);
	p.addOptional('maxDelta', milliseconds(200), validMaxDelta);
	p.addParameter('minTimeSteps', 2500, validPositiveInt);
	p.parse(dataset, varargin{:});

	dataset = p.Results.dataset;
	maxDelta = p.Results.maxDelta; % max allowed duration of a hole

	% min number of timestamps a timetable must have to constitute a record (otherwise discarded)
	minTimeSteps = p.Results.minTimeSteps;

	for s = 1:dataset.subjectCount
		currentSubject = dataset.("s" + string(s));
		nextIndex = dataset.subjectCount + 1;
		for a = dataset.activities(currentSubject.hasActivity)
			currentTable = currentSubject.(a{1});
			delta = diff(currentTable.time);
			delta.Format = delta.Format + ".SSS";
			uniquedelta = unique(delta); % find holes of different sizes
			deltacount = size(uniquedelta, 1);
			if deltacount > 1 % hole found
				fprintf('Subject %d, activity %s: %d DIFFERENT time deltas (largest: %s).', s, a{1}, deltacount, max(uniquedelta));
				if any(delta > maxDelta) % hole is too large, need to fix
					fprintf(' Some are too large. Splitting...');
					indexes = find(delta > maxDelta);
					indexes = [indexes; numel(currentTable.time)];
					startIndex = 1;
					for endIndex = indexes'
						fprintf('%d-%d', startIndex, endIndex);
						subtable = currentTable(startIndex:endIndex, :);
						if (endIndex - startIndex) < minTimeSteps
							% new table is too small, discard
							fprintf('(too short, discarding)...');
							startIndex = endIndex + 1;
							continue;
						end
						if startIndex == 1
							% overwrite previous record
							dataset.("s" + string(s)).(a{1}) = subtable;
						else
							% create new record
							fprintf('(->s%d)', nextIndex);
							dataset.("s" + string(nextIndex)).(a{1}) = subtable;
							dataset.subjectCount = nextIndex;
							% set hasActivity field
							if any(strcmp('hasActivity', fieldnames(dataset.("s" + string(nextIndex)))))
								hasActivity = dataset.("s" + string(nextIndex)).hasActivity;
							else
								hasActivity = repmat(false, 1, 3);
							end
							dataset.("s" + string(nextIndex)).hasActivity = hasActivity | strcmp(a{1}, dataset.activities);

						end
						% next chunk
						startIndex = endIndex + 1;
						fprintf('...');
					end
					fprintf('done!');
				end
				fprintf('\n');
			else
				fprintf('Subject %d, activity %s: UNIQUE time delta = %s.\n', s, a{1}, uniquedelta(1));
			end
		end
	end
	fixedDataset = dataset;
end
