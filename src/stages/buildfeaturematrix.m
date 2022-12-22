function featureMatrix = buildfeaturematrix(features)
	featureMatrix = [];
	varNames = fieldnames(features);
	for varNameIndex = 1:length(varNames)
		currentVar = varNames{varNameIndex};
		currentVarData = features.(currentVar);
		featuresFuncs = fieldnames(currentVarData);
		for featureFuncIndex = 1:length(featuresFuncs)
			featureFunc = featuresFuncs{featureFuncIndex};
			curFeatureMatrix = currentVarData.(featureFunc);
			featureMatrix = [featureMatrix; curFeatureMatrix];
		end
	end
end
