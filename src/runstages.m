function result = runstages(varargin)
% RUNSTAGES  Run one or more stages, and their input stages recursively if
%    necessary.
%
%    R = RUNSTAGES(S1, S2, ...) runs the stages S1, S2 and all their input
%    stages recursively. Return results in the R structure where each field has
%    the name of the stage which produced the output.
	if nargin == 0
		result = [];
		return;
	end
	for i = 1:nargin
		stage = varargin{i};
		result.(stage.Name) = runstage(stage);
	end
	for i = 1:nargin
		stage = varargin{i};
		stage.clearMemory();
	end
	if nargin == 1
		result = result.(stage.Name);
	end
end

function nextData = runstage(stage)
	% Run a stage. If inputs stages need to be executed, this function is
	% recursively called.
	global CONTINUE_ON_WARNING

	% Just return if data is in in-memory cache.
	if stage.OutputAvailable
		nextData = stage.getOutput(false);
		return;
	end

	% Check if, according run policy, the stage needs to run
	if ~needrun(stage)
		fprintf('* Loading existing data for stage ''%s'' from file ''%s''...\n', stage.Name, stage.OutputFile);
		nextData = stage.getOutput(true);
		return;
	end

	% Recursive call for input stages
	if ~stage.allInputsAvailable()
		for inputStage = stage.InputStages
			runstage(inputStage);
		end
	end

	fprintf('*** STAGE %s ***\n', stage.Name);
	lastwarn(''); % Clear last warning

	tic; % timer
	nextData = stage.run(); % RUN THE STAGE
	elapsedTime = seconds(toc);
	elapsedTime.Format = 'hh:mm:ss.SSS';
	fprintf('* Stage %s completed in %s.\n', stage.Name, elapsedTime);

	% Check for warnings
	[warnmsg, warnid] = lastwarn();
	if ~isempty(warnmsg)
		fprintf('* Stage execution raised a warning:\n\t%s -> %s\n', warnid, warnmsg);
		if ~CONTINUE_ON_WARNING && ~askquestion('* Continue anyway?', 'y')
			error('IS:runstages:stageExecutionFailed', 'Error: Execution failed for stage ''%s''.', stage.Name);
		end
	end

	fprintf('* Results for stage ''%s'' saved in ''%s''.\n', stage.Name, stage.OutputFile);

	% Clear stage in-memory cache if requested
	if stage.ClearMemoryAfterExecution
		for inputStage = stage.InputStages
			inputStage.clearMemory();
		end
	end

	fprintf('*** END STAGE %s ***\n', stage.Name);
end

function result = needrun(stage, varargin)
	% Check if, according run policy, the stage needs to run. Ask questions
	% to user if needed.
	global DEFAULT_RUNPOLICY

	p = inputParser;
	p.addRequired('stage', @(x) isa(x, 'Stage'));
	p.addOptional('noRunBelow', false, @(x) isscalar(x) && islogical(x));
	p.parse(stage, varargin{:});
	stage = p.Results.stage;
	noRunBelow = p.Results.noRunBelow;

	if stage.RunPolicy == RunPolicy.DEFAULT
		runPolicy = DEFAULT_RUNPOLICY;
	else
		runPolicy = stage.RunPolicy;
	end

	switch runPolicy
	case RunPolicy.ALWAYS
		result = true;
	case {RunPolicy.OLD, RunPolicy.DEFAULT}
		result = stage.isOutdated();
	case RunPolicy.NEVER
		if ~exist(stage.OutputFile, 'file')
			error('IS:runstages:outputFileNotExist', 'Error: Can not load data for stage ''%s'': output file does not exists.', stage.Name);
		end
		if stage.isOutdated()
			warning('IS:runstages:outdatedLoad', 'Will load saved results for stage ''%s'', but they appear outdated.', stage.Name);
		end
		result = false;
	case {RunPolicy.ALWAYSASK, RunPolicy.ASK}
		if stage.RunQuestionAnswer(1)
			result = stage.RunQuestionAnswer(2);
			return;
		end
		result = false;
		if ~exist(stage.OutputFile, 'file')
			result = true;
		elseif noRunBelow
			result = false;
		elseif stage.isOutdated()
			result = ~askquestion("* Results for stage '" + stage.Name + "' are old.\n\tLoad anyway?", 'n');
			stage.RunQuestionAnswer = [true result];
		elseif runPolicy == RunPolicy.ALWAYSASK
			result = ~askquestion("* Up-to-date results for stage + '" + stage.Name + "' are available.\n\tLoad them?", 'y');
			stage.RunQuestionAnswer = [true result];
		end
	otherwise
		error('IS:runstages:invalidRunPolicy', 'Error: Invalid run policy for stage ''%s''.', stage.Name);
	end


	if result
		return;
	end
	switch runPolicy
	case {RunPolicy.NEVER, RunPolicy.ALWAYSASK, RunPolicy.ASK}

		for inputStage = stage.InputStages
			if needrun(inputStage, true)
				error('IS:runstages:invalidRunPolicySequence', 'A Stage above in the pipeline needs to run, but stage ''%s'' must not.', stage.Name);
			end
		end
	end
end

function response = askquestion(prompt, defAnswer)
	% Ask a question to the user.
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
