function diaryon(name)
	global DIARIES_FOLDER
	projectRoot = currentProject().RootFolder;
	diaryDir = fullfile(projectRoot, DIARIES_FOLDER);
	if ~exist(diaryDir, 'dir')
		mkdir(diaryDir);
	end
	diaryFile = fullfile(diaryDir, [name '.txt']);
	if exist(diaryFile, 'file')
		rotatediary(name);
	end
	diary(diaryFile);
end

function rotatediary(name)
	global DIARIES_FOLDER
	projectRoot = currentProject().RootFolder;
	diaryDir = fullfile(projectRoot, DIARIES_FOLDER);
	maxIndex = -1;
	while exist(fullfile(diaryDir, [name '.' num2str(maxIndex + 1) '.txt']), 'file')
		maxIndex = maxIndex + 1;
	end
	for i = maxIndex:-1:0
		movefile(fullfile(diaryDir, [name '.' num2str(i) '.txt']), fullfile(diaryDir, [name '.' num2str(i + 1) '.txt']));
	end
	movefile(fullfile(diaryDir, [name '.txt']), fullfile(diaryDir, [name '.0.txt']));
end
