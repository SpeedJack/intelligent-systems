function normalized = normalizefeatures(features)
	varNames = fieldnames(features);
	for varNameIndex = 1:length(varNames)
		currentVar = varNames{varNameIndex};
		currentVarData = features.(currentVar);
		featureFuncs = fieldnames(currentVarData);
		for featureFuncIndex = 1:length(featureFuncs)
			featureFunc = featureFuncs{featureFuncIndex};
			featureMatrix = currentVarData.(featureFunc);
			fprintf('Normalizing feature ''%s:%s'' over %d windows...', currentVar, featureFunc, size(featureMatrix, 1));
			maxValue = max(featureMatrix(:));
			minValue = min(featureMatrix(:));
			normalized.(currentVar).(featureFunc) = 2*((featureMatrix - minValue) ./ (maxValue - minValue)) - 1;
			fprintf('done.\n');
		end
	end
end
