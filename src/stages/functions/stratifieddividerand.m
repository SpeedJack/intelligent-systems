function [trainInd, valInd, testInd] = stratifieddividedrand(groups, trainRatio, valRatio, testRatio)
% STRATIFIEDDIVIDEDRAND  Divide data into training, validation and test sets
%    with stratification. First argument must be an array containing groups for
%    stratification.
	allInd = 1:length(groups);
	trainInd = [];
	valInd = [];
	testInd = [];
	uniques = unique(groups);

	for q = 1:length(uniques)
		% for each group, use dividerand
		qInd = allInd(groups == uniques(q));
		Q = length(qInd);
		[train, val, test] = dividerand(Q, trainRatio, valRatio, testRatio);
		trainInd = [trainInd qInd(train)];
		valInd = [valInd qInd(val)];
		testInd = [testInd qInd(test)];
	end

