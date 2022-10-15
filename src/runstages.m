function nextData = runstages(stages)
	projectRoot = currentProject().RootFolder;
	dataDir = fullfile(projectRoot, 'data');

	% Read stage definition
	stageToRun = stages{end}{1};
	if isa(stageToRun, 'function_handle')
		stageToRun = func2str(stageToRun);
	end
	fprintf('*** STAGE %s ***\n', stageToRun);

	if size(stages{end}, 2) < 2 || size(stages{end}, 2) > 4
		error('Error. Invalid stage definition.');
	end

	outputFile = fullfile(dataDir, string(stages{end}{2}));
	if size(stages, 2) > 1
		inputFile = fullfile(dataDir, string(stages{end-1}{2}));
	else
		inputFile = fullfile(projectRoot, 'dataset.zip'); % preparedata
	end

	forceRun = "old";
	additionalParams = {};
	if size(stages{end}, 2) == 4 % third: forceRun; fourth: additionalParams
		forceRun = string(stages{end}{3});
		additionalParams = stages{end}{4};
	elseif size(stages{end}, 2) == 3 % third element may be forceRun or additionalParams
		if isstring(stages{end}{3}) || ischar(stages{end}{3}) || islogical(stages{end}{3})
			forceRun = string(stages{end}{3});
		else
			additionalParams = stages{end}{3};
		end
	end
	if ~iscell(additionalParams)
		additionalParams = {additionalParams};
	end

	% Check if stage should be run
	forceRun = lower(forceRun);
	needRun = true;
	switch forceRun
		case {"always", "true", "yes", "y"}
			needRun = true;
		case {"old", "o"} % run only if outputFile older than inputFile
			needRun = ~exist(outputFile, 'file') || ...
				(exist(inputFile, 'file') && ...
				dir(outputFile).datenum < dir(inputFile).datenum);
		case {"never", "false", "no", "n"}
			if ~exist(outputFile, 'file')
				error('Error. Can not load data: file does not exist.');
			end
			needRun = false;
		case {"alwaysask", "aa", "ask", "a"} % if always, ask even if outputFile is up-to-date
			always = forceRun == "alwaysask" || forceRun == "aa";
			needRun = false;
			if ~exist(outputFile, 'file')
				needRun = true;
			elseif exist(inputFile, 'file')
				if dir(outputFile).datenum < dir(inputFile).datenum;
					needRun = ~askquestion("Results for this stage are old.\n    Load anyway?", 'n');
				elseif always
					needRun = ~askquestion("Up-to-date results for this stage are available.\n    Load them?", 'y');
				end
			elseif always
				needRun = ~askquestion("Results for this stage are available, but it is unknown if they are up-to-date.\n    Load anyway?", 'n');
			end
		otherwise
			error('Error. Invalid value for forceRun: %s.', forceRun);
	end

	% Load cached results if possible
	if ~needRun
		fprintf('Loading existing data from ''%s''...\n', outputFile);
		nextData = load(outputFile);
		return;
	end

	% Recursive call to run previous stages
	prevData = inputFile; % preparedata has no prevData, but it needs path to dataset.zip
	if size(stages, 2) > 1
		prevData = runstages(stages(1:end-1));
	end

	% Run this stage
	stageFunc = str2func(stageToRun);
	nextData = stageFunc(prevData, additionalParams{:});

	% Save results
	if ~isempty(nextData)
		if ~exist(dataDir, 'dir')
			mkdir(dataDir);
		end
		save(outputFile, '-struct', 'nextData');
		fprintf('Results saved to ''%s''.\n', outputFile);
	end

	fprintf('*** END STAGE %s ***\n\n', stageToRun);
end

function response = askquestion(prompt, defAnswer)
	answer = 'X';
	while answer(1) ~= 'y' && answer(1) ~= 'n'
		if defAnswer == 'y'
			answer = input(prompt + " [Y/n] ", 's');
		else
			answer = input(prompt + " [y/N] ", 's');
		end
		if isempty(answer)
			answer = defAnswer;
		end
		answer = lower(answer);
	end
	response = answer(1) == 'y';
end
