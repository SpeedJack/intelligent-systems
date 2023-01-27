function diaryon(name)
% DIARYON  Start logging MATLAB output.
%    DIARYON FILENAME starts logging MATLAB output to the file FILENAME, inside
%    the DIARIES_FOLDER directory of the project.
	global DIARIES_FOLDER
	name = char(name);
	projectRoot = currentProject().RootFolder;
	diaryDir = fullfile(projectRoot, DIARIES_FOLDER);
	if ~exist(diaryDir, 'dir')
		mkdir(diaryDir);
	end
	diaryFile = fullfile(diaryDir, [name '.txt']);
	if exist(diaryFile, 'file')
		% If file already exists, rotate diary files.
		rotatediary(name);
	end
	% start logging
	diary(diaryFile);
end

function rotatediary(name)
	global DIARIES_FOLDER
	projectRoot = currentProject().RootFolder;
	diaryDir = fullfile(projectRoot, DIARIES_FOLDER);
	maxIndex = -1;
	% search for diary files with the same name but different index, get
	% the max index found
	while exist(fullfile(diaryDir, [name '.' num2str(maxIndex + 1) '.txt']), 'file')
		maxIndex = maxIndex + 1;
	end
	% move all diaries with the same name 1 index forward
	for i = maxIndex:-1:0
		movefile(fullfile(diaryDir, [name '.' num2str(i) '.txt']), fullfile(diaryDir, [name '.' num2str(i + 1) '.txt']));
	end
	movefile(fullfile(diaryDir, [name '.txt']), fullfile(diaryDir, [name '.0.txt']));
end
