function features = extractfeatures(prevData, varargin)
	p = inputParser;
	validWinCount = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x == round(x));
	validOverlapped = @(x) islogical(x) && isscalar(x);
	validTarget = @(x) ischar(x) && any(strcmp(x, {'mean', 'stddev'}));
	p.addRequired('prevData', @isstruct);
	p.addOptional('winCount', 1, validWinCount);
	p.addOptional('overlapped', false, validOverlapped);
	p.addParameter('target', 'mean', validTarget);
	p.parse(prevData, varargin{:});

	if isfield(p.Results.prevData, 'augmentdata')
		dataset = p.Results.prevData.augmentdata;
	else
		dataset = p.Results.prevData.fixdata;
	end
	target = p.Results.target;
	if isfield(p.Results.prevData, 'selectfeatures')
		fieldName = 'ecgMean';
		if strcmp(target, 'stddev')
			fieldName = 'ecgStd';
		end
		featureList = p.Results.prevData.selectfeatures.(fieldName).featureNames';
	else
		featureList = p.Results.prevData.getfeatures;
	end
	winCount = p.Results.winCount;
	overlapped = p.Results.overlapped;

	for featureCell = featureList
		feature = featureCell{1};
		splitted = split(feature, ':');
		varName = splitted{1};
		featureFunc = splitted{2};
		features.(varName).(featureFunc) = [];

		currentFeatures = [];
		for s = 1:dataset.subjectCount
			currentSubject = dataset.("s" + string(s));
			for a = dataset.activities(currentSubject.hasActivity)
				fprintf('Extracting feature ''%s'' for subject %d, activity %s... ', feature, s, a{1});
				hasNaNs = false;

				currentTable = currentSubject.(a{1});
				currentColumn = currentTable.(varName);

				windowedFeatures = [];
				winSize = floor(size(currentColumn, 1) / (winCount + overlapped)) * (1 + overlapped);
				winStep = winSize - (overlapped * 1/2 * winSize);
				if strcmp(varName, 'temp_3')
					winSize = winStep * winCount + (overlapped * winStep);
					winCount = 1;
					overlapped = false;
					winStep = winSize;
				end

				fprintf('(rows=%d, winSize=%d, winStep=%d, winCount=%d, overlapped=%s)... ', size(currentColumn, 1), winSize, winStep, winCount, string(overlapped));
				for i = 1:winStep:(winStep * winCount)
					fprintf('%d', i);
					currentWindow = currentColumn(i:(i + winSize - 1));
					featureFuncHandle = str2func(featureFunc);
					windowFeature = featureFuncHandle(currentWindow);
					if isnan(windowFeature)
						fprintf('(NaNs)');
						hasNaNs = true;
					end
					fprintf('..');
					windowedFeatures = [windowedFeatures; windowFeature];
				end
				fprintf('done.\n');

				if strcmp(varName, 'temp_3')
					winCount = p.Results.winCount;
					overlapped = p.Results.overlapped;
				end

				if hasNaNs
					warning('IS:STAGE:extractfeatures:nansInFeatures', "NaNs in feature ''%s'' for subject %d, activity %s.", feature, s, a{1});
				end

				currentFeatures = [currentFeatures windowedFeatures];
			end
		end

		features.(varName).(featureFunc) = [features.(varName).(featureFunc) currentFeatures];
	end

end

function y = meandiff(x)
	y = mean(diff(x));
end

function y = lofreq(x)
	[~, y, ~] = obw(x);
end

function y = hifreq(x)
	[~, ~, y] = obw(x);
end

function y = powerfreq(x)
	[~, ~, ~, y] = obw(x);
end

function y = cumsumrange(x)
	y = range(cumsum(x));
end
