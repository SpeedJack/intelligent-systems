function features = extractfeatures(prevData, varargin)
% Extract features. It builds a structure containing fields such as
% features.pleth_1.mean which contains a matrix NxM where N is the number of
% windows and M is the number of samples/observations.
	p = inputParser;
	validWinCount = @(x) isnumeric(x) && isscalar(x) && (x > 0) && (x == round(x));
	validOverlapped = @(x) islogical(x) && isscalar(x);
	validTarget = @(x) ischar(x) && any(strcmp(x, {'mean', 'stddev'}));
	p.addRequired('prevData', @isstruct);
	p.addOptional('winCount', 1, validWinCount);
	p.addOptional('overlapped', true, validOverlapped);
	p.addParameter('target', 'mean', validTarget);
	p.parse(prevData, varargin{:});

	% data may come from different input stages
	if isfield(p.Results.prevData, 'augmentdata')
		dataset = p.Results.prevData.augmentdata;
	else
		dataset = p.Results.prevData.fixdata;
	end
	target = p.Results.target;	% this is used to select the features to
					% extract, in case we load the list
					% from stage selectfeatures
	if isfield(p.Results.prevData, 'selectfeatures')
		fieldName = 'ecgMean';
		if strcmp(target, 'stddev')
			fieldName = 'ecgStd';
		end
		featureList = p.Results.prevData.selectfeatures.(fieldName).featureNames';
	elseif isfield(p.Results.prevData, 'selectfeatures_fuzzy')
		featureList = p.Results.prevData.selectfeatures_fuzzy.fuzzy.featureNames';
	else
		featureList = p.Results.prevData.getfeatures;
	end

	for featureCell = featureList
		winCount = p.Results.winCount;
		overlapped = p.Results.overlapped;

		% for each feature, extract signal name and name of function to
		% execute
		feature = featureCell{1};
		splitted = split(feature, ':');
		varName = splitted{1};
		featFieldName = splitted{2};
		features.(varName).(featFieldName) = [];

		featureFunc = featFieldName;
		if contains(featFieldName, '_')
			splitted = split(featFieldName, '_');
			featureFunc = splitted{1};
		end

		if winCount == 1
			overlapped = false;
		end

		currentFeatures = [];
		for s = 1:dataset.subjectCount
			currentSubject = dataset.("s" + string(s));
			for a = dataset.activities(currentSubject.hasActivity)
				fprintf('Extracting feature ''%s'' for subject %d, activity %s... ', feature, s, a{1});
				hasNaNs = false;

				currentTable = currentSubject.(a{1});
				currentColumn = currentTable.(varName);

				% compute winSize and winStep
				windowedFeatures = [];
				winSize = floor(size(currentColumn, 1) / (winCount + overlapped)) * (1 + overlapped);
				winStep = winSize - (overlapped * 1/2 * winSize);
				if strcmp(varName, 'temp_3')
					% temp_3 (ambient temp) is ALWAYS extracted in a single window
					winSize = winStep * winCount + (overlapped * winStep);
					winCount = 1;
					overlapped = false;
					winStep = winSize;
				end

				% features are extract by calling iteratively
				% the function to compute the features on every
				% window
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
					% values for different windows are
					% merged vertically
					windowedFeatures = [windowedFeatures; windowFeature];
				end
				fprintf('done.\n');

				if hasNaNs
					warning('IS:STAGE:extractfeatures:nansInFeatures', "NaNs in feature ''%s'' for subject %d, activity %s.", feature, s, a{1});
				end

				% values for different samples are merged
				% horizontally
				currentFeatures = [currentFeatures windowedFeatures];
			end
		end

		% build structure
		features.(varName).(featFieldName) = [features.(varName).(featFieldName) currentFeatures];
	end

end


%% -- Other functions used to extract features -- %%

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
