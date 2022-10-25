function result = runstages(varargin)
	if nargin == 0
		result = [];
		return;
	end
	for i = 1:nargin
		stage = varargin{i};
		result.(stage.Name) = runstage(stage);
		fields = fieldnames(result.(stage.Name));
		if numel(fields) == 1 && strcmp(fields{1}, stage.Name)
			result.(stage.Name) = result.(stage.Name).(stage.Name);
		end
	end
	if nargin == 1
		result = result.(stage.Name);
	end
end

function nextData = runstage(stage)
	if stage.OutputAvailable
		nextData = stage.Output;
		return;
	end

	fprintf('*** STAGE %s ***\n', stage.Name);

	switch stage.RunPolicy
	case RunPolicy.ALWAYS
		needRun = true;
	case RunPolicy.OLD
		needRun = stage.isOutdated();
	case RunPolicy.NEVER
		if ~exist(stage.OutputFile, 'file')
			error('Error. Can not load data for stage ''%s'': output file does not exists.', stage.Name);
		end
		if stage.isOutdated()
			warning('Warning. Will load saved results for stage ''%s'', but they appear outdated.', stage.Name);
		end
		needRun = false;
	case {RunPolicy.ALWAYSASK, RunPolicy.ASK}
		needRun = false;
		if ~exist(stage.OutputFile, 'file')
			needRun = true;
		elseif stage.isOutdated()
			needRun = ~askquestion("* Results for this stage are old.\n    Load anyway?", 'n');
		elseif stage.RunPolicy == RunPolicy.ALWAYSASK
			needRun = ~askquestion("* Up-to-date results for this stage are available.\n    Load them?", 'y');
		end
	end

	if needRun
		if ~stage.allInputsAvailable()
			fprintf('* Running input stages...\n');
			for inputStage = stage.InputStages
				runstage(inputStage);
			end
			fprintf('*** BACK TO STAGE %s ***\n', stage.Name);
		end

		nextData = stage.run();
		fprintf('* Results for stage ''%s'' saved in ''%s''.\n', stage.Name, stage.OutputFile);
	else
		fprintf('* Loading existing data for stage ''%s'' from file ''%s''...\n', stage.Name, stage.OutputFile);
		nextData = stage.loadOutput();
	end

	fprintf('*** END STAGE %s ***\n', stage.Name);
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
