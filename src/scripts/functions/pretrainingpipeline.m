function [buildfeaturematrixStage, extracttargetsStage] = pretrainingpipeline(target, windowed)
	preparedataStage = Stage(@preparedata, 'dataset.mat');
	preparedataStage.addDatasetParam();

	fixdataStage = Stage(@fixdata, 'fixed_dataset.mat');
	fixdataStage.addInputStages(preparedataStage);

	augmentdataStage = Stage(@augmentdata, 'augmented_dataset.mat');
	augmentdataStage.addInputStages(fixdataStage);

	matSuffix = '';
	if windowed
		matSuffix = '_windowed';
	end

	extracttargetsStage = Stage(@extracttargets, ['targets' matSuffix '.mat']);
	extracttargetsStage.addInputStages(augmentdataStage);
	if windowed
		extracttargetsStage.addParams(5, true);
	end

	sfsStage = Stage(@selectfeatures, ['selected_features' matSuffix '.mat'], RunPolicy.NEVER);

	matSuffix = ['_' target matSuffix];

	extractfeaturesStage = Stage(@extractfeatures, ['features' matSuffix '.mat']);
	extractfeaturesStage.addInputStages(augmentdataStage, sfsStage);
	if windowed
		extractfeaturesStage.addParams(5, true);
	end
	extractfeaturesStage.addParams('target', target);

	normalizefeaturesStage = Stage(@normalizefeatures, ['normalized_train_features' matSuffix '.mat']);
	normalizefeaturesStage.addInputStages(extractfeaturesStage);

	buildfeaturematrixStage = Stage(@buildfeaturematrix, ['feature_matrix' matSuffix '.mat']);
	buildfeaturematrixStage.addInputStages(normalizefeaturesStage);
end