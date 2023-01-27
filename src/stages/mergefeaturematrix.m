function featureMatrix = mergefeaturematrix(prevData)
	featureMatrix = [];
	matrices = prevData.buildfeaturematrix;
	for matrix = matrices
		featureMatrix = [featureMatrix; matrix{1}];
	end
end
