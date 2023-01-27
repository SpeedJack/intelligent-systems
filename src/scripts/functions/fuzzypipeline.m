function [normalizefeaturesStage, extracttargetsStage] = fuzzypipeline
	% build the pipeline needed to train/tune/test fuzzy systems
	preparedataStage = Stage(@preparedata, 'dataset.mat');
	preparedataStage.addDatasetParam();

	fixdataStage = Stage(@fixdata, 'fixed_dataset.mat');
	fixdataStage.addInputStages(preparedataStage);
	fixdataStage.ClearMemoryAfterExecution = true;

	augmentdataStage = Stage(@augmentdata, 'augmented_dataset.mat');
	augmentdataStage.addInputStages(fixdataStage);
	augmentdataStage.ClearMemoryAfterExecution = true;

	extracttargetsStage = Stage(@extracttargets, 'targets.mat');
	extracttargetsStage.addInputStages(augmentdataStage);

	% Will use features selected for fuzzy systems
	sfsStage = Stage(@selectfeatures_fuzzy, 'selected_features_fuzzy.mat', RunPolicy.NEVER);

	extractfeaturesStage = Stage(@extractfeatures, 'features_fuzzy.mat');
	extractfeaturesStage.addInputStages(augmentdataStage, extracttargetsStage, sfsStage);

	normalizefeaturesStage = Stage(@normalizefeatures, 'normalized_features_fuzzy.mat');
	normalizefeaturesStage.addInputStages(extractfeaturesStage);
end
