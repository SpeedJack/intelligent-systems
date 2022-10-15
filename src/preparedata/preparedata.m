function dataset = preparedata(inputFile)
	projectRoot = currentProject().RootFolder;

	[~, inputFileName, inputFileExt] = fileparts(inputFile);
	if ~exist(inputFile, 'file')
		error('Error. %s not found. Please place it in %s.', strcat(inputFileName, inputFileExt), projectRoot);
	end

	tempDir = tempname;
	mkdir(tempDir);

	fprintf('Extracting %s...\n', strcat(inputFileName, inputFileExt));
	unzip(inputFile, tempDir);

	activities = {'sit', 'walk', 'run'};
	datasetFilePatterns = fullfile(tempDir, '**', strcat('s*_', activities, '_timeseries.csv'));
	datasetFiles = [dir(datasetFilePatterns{1}); dir(datasetFilePatterns{2}); dir(datasetFilePatterns{3})];
	datasetFiles = datasetFiles(~[datasetFiles.isdir]);
	if length(datasetFiles) == 0
		rmdir(tempDir, 's');
		error('Error. Dataset files not found.');
	end

	% Load data, sort by time, convert to time table
	maxsubject = 0;
	for i = 1:length(datasetFiles)
		filename = fullfile(datasetFiles(i).folder, datasetFiles(i).name);
		tokens = regexp(filename, "s([1-9][0-9]*)_(" + strjoin(activities, '|') + ")_timeseries.csv$", 'tokens');
		subject = str2num(string(tokens{1}(1)));
		activity = string(tokens{1}(2));
		fprintf("Loading data for subject %d, activity '%s'...\n", subject, activity);

		if subject < 1
			rmdir(tempDir, 's');
			warning('Warning. Invalid subject number: %d. Skipping...', subject);
			continue;
		end
		maxsubject = max(subject, maxsubject);

		targetsFilename = fullfile(datasetFiles(i).folder, sprintf('s%d_%s_targets.csv', subject, activity));
		if exist(targetsFilename, 'file') == 0
			rmdir(tempDir, 's');
			warning('Warning. Could not find targets file %s. Skipping...', targetsFilename);
			continue;
		end

		timeseries = table2timetable(sortrows(readtable(filename), 'time'));
		targets = table2timetable(sortrows(readtable(targetsFilename), 'time'));

		if ~isequal(timeseries.time, targets.time)
			rmdir(tempDir, 's');
			warning('Warning. Timeseries and targets files do not have the same timestamps. Skipping...');
			continue;
		end

		merged.("s"+ string(subject)).(activity) = [timeseries, targets];
	end

	rmdir(tempDir, 's');

	% Remove holes in the list of subjects; check that each subject has all activities
	index = 0;
	for i = 1:maxsubject
		if isfield(merged, "s" + string(i))
			index = index + 1;

			dataset.("s" + string(index)) = merged.("s" + string(i));

			if i ~= index
				fprintf('Renamed subject: %d --> %d.\n', i, index);
			end

			dataset.("s" + string(index)).hasActivity = isfield(dataset.("s" + string(index)), activities);
			if ~all(dataset.("s" + string(index)).hasActivity)
				warning('Warning. Subject %d does not have all activities.', index);
			end
		end
	end
	dataset.subjectCount = index;
	dataset.activities = activities;
end
