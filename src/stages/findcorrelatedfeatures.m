function analyzed = findcorrelatedfeatures(features, varargin)
	p = inputParser;
	validCorrelationLimit = @(x) isscalar(x) && isnumeric(x) && (x >= 0) && (x <= 1);
	p.addRequired('features', @isstruct);
	p.addOptional('correlationLimit', 0.8, validCorrelationLimit);
	p.parse(features, varargin{:});

	features = p.Results.features;
	correlationLimit = p.Results.correlationLimit;

	fprintf('Merging features into a single matrix...');
	featureMatrix = [];
	names = {};
	varNames = fieldnames(features);
	for varNameIndex = 1:length(varNames)
		currentVar = varNames{varNameIndex};
		currentVarData = features.(currentVar);
		featuresFuncs = fieldnames(currentVarData);
		for featureFuncIndex = 1:length(featuresFuncs)
			featureFunc = featuresFuncs{featureFuncIndex};
			featureVector = features.(currentVar).(featureFunc)(:);
			if ~isempty(featureMatrix) && size(featureMatrix, 1) ~= size(featureVector, 1)
				if size(featureVector, 1) > size(featureMatrix, 1) ...
						|| mod(size(featureMatrix, 1), size(featureVector, 1)) ~= 0
					error('IS:STAGE:findcorrelatedfeatures:wrongNumberOfWindows', ...
						'Error: the number of windows in the feature matrix is not a multiple of the number of windows in the feature vector for %s.', strcat(currentVar, ':', featureFunc))
				end
				repeatFactor = size(featureMatrix, 1) / size(featureVector, 1);
				featureVector = repelem(featureVector, repeatFactor);
				fprintf('(%s repeated %d times)...', ...
					strcat(currentVar, ':', featureFunc), repeatFactor);
			end
			featureMatrix = [featureMatrix featureVector];
			names = [names; strcat(currentVar, ':', featureFunc)];
		end
	end
	fprintf('done.\n');

	fprintf('Calculating correlation matrix...');
	analyzed.correlationMatrix = abs(corrcoef(featureMatrix));

	analyzed.correlationHeatmap = figure('Name', 'Correlation Matrix', 'NumberTitle', 'off', 'Visible', 'off');
	hm = heatmap(analyzed.correlationMatrix, 'Parent', analyzed.correlationHeatmap);
	hm.Title = 'Correlation Matrix';
	hm.XLabel = 'Features';
	hm.YLabel = 'Features';
	hm.Colormap = jet;
	hm.ColorLimits = [0 1];
	hm.XDisplayLabels = names;
	hm.YDisplayLabels = names;
	fprintf('done.\n');

	fprintf('Finding correlated features (correlation coefficient > %d):', correlationLimit);
	[indexes, ~] = find(tril(analyzed.correlationMatrix > correlationLimit, -1));
	indexes = unique(sort(indexes));
	analyzed.correlatedFeatures = names(indexes);
	analyzed.uncorrelatedFeatures = names(setdiff(1:end, indexes));
	for i = 1:length(analyzed.correlatedFeatures)
		if i > 1
			fprintf(',');
		end
		fprintf(' %s', analyzed.correlatedFeatures{i});
	end
	fprintf('. done.\n');
end
