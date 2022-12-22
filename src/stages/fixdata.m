function fixedDataset = fixdata(dataset, varargin)
	p = inputParser;
	validMaxDelta = @(x) isscalar(x) && isduration(x) && (x > 0);
	p.addRequired('dataset', @isstruct);
	p.addOptional('maxDelta', milliseconds(200), validMaxDelta);
	p.parse(dataset, varargin{:});

	dataset = p.Results.dataset;
	maxDelta = p.Results.maxDelta;

	for s = 1:dataset.subjectCount
		currentSubject = dataset.("s" + string(s));
		nextIndex = dataset.subjectCount + 1;
		for a = dataset.activities(currentSubject.hasActivity)
			currentTable = currentSubject.(a{1});
			delta = diff(currentTable.time);
			delta.Format = delta.Format + ".SSS";
			uniquedelta = unique(delta);
			deltacount = size(uniquedelta, 1);
			if deltacount > 1
				fprintf('Subject %d, activity %s: %d DIFFERENT time deltas (largest: %s).', s, a{1}, deltacount, max(uniquedelta));
				if any(delta > maxDelta)
					fprintf(' Some are too large. Splitting...');
					indexes = find(delta > maxDelta);
					indexes = [indexes; numel(currentTable.time)];
					startIndex = 1;
					for endIndex = indexes'
						fprintf('%d-%d', startIndex, endIndex);
						subtable = currentTable(startIndex:endIndex, :);
						if startIndex == 1
							dataset.("s" + string(s)).(a{1}) = subtable;
						else
							fprintf('(->s%d)', nextIndex);
							dataset.("s" + string(nextIndex)).(a{1}) = subtable;
							dataset.subjectCount = nextIndex;
							if any(strcmp('hasActivity', fieldnames(dataset.("s" + string(nextIndex)))))
								hasActivity = dataset.("s" + string(nextIndex)).hasActivity;
							else
								hasActivity = repmat(false, 1, 3);
							end
							dataset.("s" + string(nextIndex)).hasActivity = hasActivity | strcmp(a{1}, dataset.activities);

						end
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
