function dataset = preparedata(inputFile, varargin)
% load dataset in a structure. Example field: dataset.s15.walk will contain a
% timetable with timeseries+targets for s15 during walk.
	p = inputParser;
	validFilePath = @(x) ischar(x) || (isscalar(x) && isstring(x));
	validPositiveIntArr = @(x) isnumeric(x) && all(x > 0) && all(x == round(x)) && (isvector(x) || isscalar(x) || isempty(x));
	p.addRequired('inputFile', validFilePath);
	p.addParameter('includedSubjects', [], validPositiveIntArr);
	p.parse(inputFile, varargin{:});

	inputFile = p.Results.inputFile;
	includedSubjects = p.Results.includedSubjects;

	projectRoot = currentProject().RootFolder;

	% search for dataset.zip
	[~, inputFileName, inputFileExt] = fileparts(inputFile);
	if ~exist(inputFile, 'file')
		error('IS:STAGE:preparedata:archiveNotFound', 'Error: %s not found. Please place it in %s.', strcat(inputFileName, inputFileExt), projectRoot);
	end

	% extract archive
	tempDir = tempname;
	mkdir(tempDir);

	fprintf('Extracting %s...\n', strcat(inputFileName, inputFileExt));
	unzip(inputFile, tempDir);

	% search timeseries and targets CSV files
	activities = {'sit', 'walk', 'run'};
	datasetFilePatterns = fullfile(tempDir, '**', strcat('s*_', activities, '_timeseries.csv'));
	datasetFiles = [dir(datasetFilePatterns{1}); dir(datasetFilePatterns{2}); dir(datasetFilePatterns{3})];
	datasetFiles = datasetFiles(~[datasetFiles.isdir]);
	if length(datasetFiles) == 0
		rmdir(tempDir, 's');
		error('IS:STAGE:preparedata:filesNotFound', 'Error: Dataset files not found.');
	end

	% Load data, sort by time, convert to time table
	maxsubject = 0;
	for i = 1:length(datasetFiles)
		filename = fullfile(datasetFiles(i).folder, datasetFiles(i).name);
		tokens = regexp(filename, "s([1-9][0-9]*)_(" + strjoin(activities, '|') + ")_timeseries.csv$", 'tokens');
		subject = str2num(string(tokens{1}(1)));
		if ~isempty(includedSubjects) && ~ismember(subject, includedSubjects)
			% used by testis.m to avoid load the entire dataset
			continue;
		end
		activity = string(tokens{1}(2));
		fprintf("Loading data for subject %d, activity '%s'...\n", subject, activity);

		if subject < 1
			rmdir(tempDir, 's');
			warning('IS:STAGE:preparedata:invalidSubject', 'Invalid subject number: %d. Skipping...', subject);
			continue;
		end
		maxsubject = max(subject, maxsubject);

		% targets file
		targetsFilename = fullfile(datasetFiles(i).folder, sprintf('s%d_%s_targets.csv', subject, activity));
		if exist(targetsFilename, 'file') == 0
			rmdir(tempDir, 's');
			warning('IS:STAGE:preparedata:targetsFileNotFound', 'Could not find targets file %s. Skipping...', targetsFilename);
			continue;
		end

		% build timetable
		timeseries = table2timetable(sortrows(readtable(filename), 'time'));
		targets = table2timetable(sortrows(readtable(targetsFilename), 'time'));

		% check for timeseries and targets mismatch
		if ~isequal(timeseries.time, targets.time)
			rmdir(tempDir, 's');
			warning('IS:STAGE:preparedata:timestampInconsistency', 'Timeseries and targets files do not have the same timestamps. Skipping...');
			continue;
		end

		% save in structure
		merged.("s"+ string(subject)).(activity) = [timeseries targets];
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

			% hasActivity will contain a logical vector indicating
			% if current subject has records for that activity
			dataset.("s" + string(index)).hasActivity = isfield(dataset.("s" + string(index)), activities);

			if ~all(dataset.("s" + string(index)).hasActivity)
				warning('IS:STAGE:preparedata:missingActivity', 'Subject %d does not have all activities.', index);
			end
		end
	end

	dataset.subjectCount = index;
	dataset.activities = activities;
end
