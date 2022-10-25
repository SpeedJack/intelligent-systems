function features = extractfeatures(prevData, varargin)
	p = inputParser;
	validWinCount = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x == round(x));
	validOverlapped = @(x) islogical(x) && isscalar(x);
	addRequired(p, 'prevData', @isstruct);
	addOptional(p, 'winCount', 1, validWinCount);
	addOptional(p, 'overlapped', false, validOverlapped);
	parse(p, prevData, varargin{:});

	dataset = p.Results.prevData.preparedata;
	featureList = p.Results.prevData.selectfeatures;
	winCount = p.Results.winCount;
	overlapped = p.Results.overlapped;

	features = [];
	for s = 1:dataset.subjectCount
		currentSubject = dataset.("s" + string(s));
		for a = dataset.activities(currentSubject.hasActivity)
			fprintf('Extracting features for subject %d, activity %s... ', s, a{1});

			currentTable = currentSubject.(a{1});
			currentMatrix = table2array(currentTable(:,1:end-1));

			currentFeatures = [];
			winSize = floor(size(currentMatrix, 1) / (winCount + overlapped)) * (1 + overlapped);
			winStep = winSize - (overlapped * 1/2 * winSize);
			fprintf('(rows=%d, winSize=%d, winStep=%d, winCount=%d, overlapped=%s)... ', size(currentMatrix, 1), winSize, winStep, winCount, string(overlapped));
			for i = 1:winStep:(winStep * winCount)
				fprintf('%d..', i);
				currentWindow = currentMatrix(i:(i + winSize - 1), :);
				windowFeatures = computefeatures(currentWindow, featureList);
				if any(any(isnan(windowFeatures)))
					warning("\nWarning. NaNs in features for subject %d, activity %s, window %d.", s, a{1}, i);
				end
				currentFeatures = [currentFeatures; windowFeatures];
			end
			fprintf('done.\n');

			features = [features currentFeatures];
		end
	end
end
