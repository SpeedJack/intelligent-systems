function featureMatrix = mergefeaturematrix(prevData)
% merge multiple feature matrices into 1
	featureMatrix = [];
	matrices = prevData.buildfeaturematrix;
	for matrix = matrices
		featureMatrix = [featureMatrix; matrix{1}];
	end
end
