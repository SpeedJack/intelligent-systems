function reduced = dropfeatures(features, dropList, varargin)
	p = inputParser;
	validMode = @(x) any(validatestring(x, {'drop', 'keep'}));
	p.addRequired('features', @isstruct);
	p.addRequired('dropList', @iscell);
	p.addParameter('mode', 'drop', validMode);
	p.parse(features, dropList, varargin{:});

	features = p.Results.features;
	dropList = p.Results.dropList;
	dropMode = true;
	if p.Results.mode == 'keep'
		dropMode = false;
	end

	dropped = {};
	varNames = fieldnames(features);
	for varNameIndex = 1:length(varNames)
		currentVar = varNames{varNameIndex};
		currentVarData = features.(currentVar);
		featureFuncs = fieldnames(currentVarData);
		for featureFuncIndex = 1:length(featureFuncs)
			featureFunc = featureFuncs{featureFuncIndex};
			featureName = strcat(currentVar, ':', featureFunc);
			if xor(dropMode, any(strcmp(dropList, featureName)))
				reduced.(currentVar).(featureFunc) = currentVarData.(featureFunc);
			else
				dropped = [dropped; featureName];
			end
		end
	end

	fprintf('Dropped %d features: %s.\n', numel(dropped), strjoin(dropped, ', '));
end

% function reduced = dropfeatures(features, todrop)
% 	reduced = features;
%
% 	for i = 1:numel(todrop)
% 		toRemove = todrop{i};
% 		if isnumeric(toRemove)
% 			toRemoveName = features.names{toRemove};
% 		else
% 			toRemoveName = toRemove;
% 			toRemove = find(strcmp(features.names, toRemove));
% 		end
% 		reduced.names(toRemove) = [];
% 		reduced.featureMatrix(:, toRemove) = [];
% 	end
%
% 	fprintf('Dropped %d features: %s.\n', size(features, 2) - size(reduced, 2), strjoin(setdiff(features.names, reduced.names), ', '));
% end
