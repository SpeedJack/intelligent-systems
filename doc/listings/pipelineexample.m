preparedataStage = Stage(@preparedata, 'dataset.mat');
preparedataStage.addDatasetParam();

augmentdataStage = Stage(@augmentdata, 'augmented_dataset.mat');
augmentdataStage.addInputStages(preparedataStage);

getfeaturesStage = Stage(@getfeatures, 'feature_list.mat');

extractfeaturesStage = Stage(@extractfeatures, 'features.mat');
extractfeaturesStage.addInputStages(augmentdataStage, getfeaturesStage);

extracttargetsStage = Stage(@extracttargets, 'targets.mat');
extracttargetsStage.addInputStages(augmentdataStage);

result = runstages(extractfeaturesStage, extracttargetsStage);
