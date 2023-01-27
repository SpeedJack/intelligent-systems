function features = mergefeatures(prevData)
% merge features of multiple feature structures into 1. Feature structures must
% all come from stages of the same type.
	if isfield(prevData, 'normalizefeatures')
		featureStructures = prevData.normalizefeatures;
	elseif isfield(prevData, 'dropcorrelatedfeatures')
		featureStructures = prevData.dropcorrelatedfeatures;
	elseif isfield(prevData, 'dropfeatures')
		featureStructures = prevData.dropfeatures;
	else
		featureStructures = prevData.extractfeatures;
	end

	for featureStructCell = featureStructures
		featureStruct = featureStructCell{1};
		varNames = fieldnames(featureStruct);
		for varNameIndex = 1:length(varNames)
			currentVar = varNames{varNameIndex};
			currentVarData = featureStruct.(currentVar);
			featureFuncs = fieldnames(currentVarData);
			for featureFuncIndex = 1:length(featureFuncs)
				featureFunc = featureFuncs{featureFuncIndex};
				featureMatrix = currentVarData.(featureFunc);
				winCount = size(featureMatrix, 1);
				if winCount > 1
					% we must include winCount in name, to
					% avoid name clashing
					featureFunc = [featureFunc '_' num2str(winCount)];
				end
				features.(currentVar).(featureFunc) = featureMatrix;
			end
		end
	end
end
