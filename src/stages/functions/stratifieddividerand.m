function [trainInd, valInd, testInd] = stratifieddividedrand(groups, trainRatio, valRatio, testRatio)
	allInd = 1:length(groups);
	trainInd = [];
	valInd = [];
	testInd = [];
	uniques = unique(groups);

	for q = 1:length(uniques)
		qInd = allInd(groups == uniques(q));
		Q = length(qInd);
		[train, val, test] = dividerand(Q, trainRatio, valRatio, testRatio);
		trainInd = [trainInd qInd(train)];
		valInd = [valInd qInd(val)];
		testInd = [testInd qInd(test)];
	end

