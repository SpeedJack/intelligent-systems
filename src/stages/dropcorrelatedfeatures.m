function reduced = dropcorrelatedfeatures(prevData)
% remove correlated features from input structure.
	if isfield(prevData, 'normalizefeatures')
		features = prevData.normalizefeatures;
	else
		features = prevData.extractfeatures;
	end
	correlatedFeatures = prevData.findcorrelatedfeatures.correlatedFeatures;
	reduced = dropfeatures(features, correlatedFeatures);
end
