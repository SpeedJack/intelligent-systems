% This class represents a stage.
% property Stage.Function will contain a function handle to the function that
% must be executed to run the stage.
% OutputFile will contain the path to the file where cached results must be
% saved. Stage.Output, instead, is an in-memory cache for the output (to avoid
% to continuosly load from file).
% InputStages contains the input stages for the stage. Their output will be
% loaded before running the stage and passed as input to the function
% Stage.Function.
% AdditionalParams is used for additional parameters passed to the stage
% through the Stage.addParams() method.
classdef Stage < handle
	properties (Access = private)
		Function(1,1) function_handle = @NOP
		AdditionalParams(1,:) cell = {}
	end
	properties (Access = public)
		InputStages(1,:) Stage
		Output(1,1) struct = struct()
		OutputFile {mustBeTextScalar} = ''
		RunPolicy(1,1) RunPolicy = RunPolicy.DEFAULT
		RunQuestionAnswer(1,2) logical = [false false]
		ClearMemoryAfterExecution(1,1) logical = false
	end
	properties (Dependent)
		Name
		OutputAvailable
	end

	methods
		function obj = Stage(stageFunction, outputFile, runPolicy, varargin)
			global DATA_FOLDER
			projectRoot = currentProject().RootFolder;
			dataDir = fullfile(projectRoot, DATA_FOLDER);
			if nargin > 0
				if isa(stageFunction, 'function_handle')
					obj.Function = stageFunction;
				else
					obj.Function = str2func(stageFunction);
				end
			end
			if nargin > 1
				obj.OutputFile = fullfile(dataDir, outputFile);
			else
				obj.OutputFile = fullfile(dataDir, func2str(obj.Function) + ".mat");
			end
			if nargin > 2
				obj.RunPolicy = runPolicy;
			end
			if nargin > 3
				obj.AdditionalParams = varargin;
			end
		end

		function addParams(obj, varargin)
			obj.AdditionalParams = [obj.AdditionalParams varargin];
		end

		function addDatasetParam(obj)
			% convenience method to add the path to dataset.zip for
			% the first stage (preparedata)
			projectRoot = currentProject().RootFolder;
			obj.AdditionalParams = [obj.AdditionalParams {fullfile(projectRoot, 'dataset.zip')}];
		end

		function name = get.Name(obj)
			% the name of the stage is the name of the function
			name = func2str(obj.Function);
		end

		function available = get.OutputAvailable(obj)
			available = ~isempty(fieldnames(obj.Output));
		end

		function available = allInputsAvailable(obj)
			% check if output is available for all input stages

			for stage = obj.InputStages
				if ~stage.OutputAvailable

					available = false;
					return;
				end
			end
			available = true;
		end

		function outdated = isOutdated(obj)
			% recursively check if output is outdated (ie. if stage
			% must be re-executed when using RunPolicy.OLD)
			if ~obj.OutputAvailable && ~exist(obj.OutputFile, 'file')
				outdated = true;
				return;
			end
			for stage = obj.InputStages
				if ~exist(stage.OutputFile, 'file') || ...
						dir(stage.OutputFile).datenum > dir(obj.OutputFile).datenum
					outdated = true;
					return;
				end
				if stage.isOutdated()
					outdated = true;
					return;
				end
			end
			outdated = false;
		end

		function output = loadOutput(obj)
			% Load output from file, into in-memory cache
			if ~obj.OutputAvailable
				obj.Output = load(obj.OutputFile);

			end
			output = obj.Output;
		end

		function addInputStages(obj, varargin)
			for stageCell = varargin
				obj.InputStages(end+1) = stageCell{1};
			end
		end

		function inputData = getInputData(obj)
			% Build input arguments for the stage using the outputs
			% of the input stages
			if ~obj.allInputsAvailable
				error('IS:Stage:missingInput', 'Error: Missing input for stage ''%s''.', obj.Name);
			end
			if isempty(obj.InputStages)
				% no input stages
				inputData = [];
				return;
			end
			if numel(obj.InputStages) == 1
				stage = obj.InputStages(1);
				inputData = stage.getOutput();
				return;
			end

			% multiple input stages, need to build a structure
			inputData = struct();
			for stage = obj.InputStages
				if ~isfield(inputData, stage.Name)
					inputData.(stage.Name) = {};
				end
				% build a cell array in case of name clashing
				% (multiple input stages with same name)
				inputData.(stage.Name){end+1} = stage.getOutput();
			end
			for f = fieldnames(inputData)'
				f = f{1};
				% if there is only one element in a cell array,
				% get it out of the cell array
				if numel(inputData.(f)) == 1
					inputData.(f) = inputData.(f){1};
				end
			end
		end

		function output = run(obj)
			% run the stage
			inputData = obj.getInputData();
			if isempty(inputData)
				outputData = obj.Function(obj.AdditionalParams{:});
			else
				outputData = obj.Function(inputData, obj.AdditionalParams{:});
			end

			% save output to in-memory cache
			if isstruct(outputData)
				output = outputData;
			else
				output.(obj.Name) = outputData;
			end
			obj.Output = output;

			% save output to file
			folder = fileparts(obj.OutputFile);
			if ~exist(folder, 'dir')
				mkdir(folder);
			end

			save(obj.OutputFile, '-struct', 'output');

			output = obj.getOutput();
		end

		function output = getOutput(obj, varargin)
			% return (and load if necessary) output of the stage
			p = inputParser;
			p.addOptional('load', true, @(x) isscalar(x) && islogical(x));
			p.parse(varargin{:});
			if ~obj.OutputAvailable
				if ~p.Results.load
					error('IS:Stage:missingOutputMem', 'Error: No output available in memory for stage ''%s''.', obj.Name);
				end
				if ~exist(obj.OutputFile, 'file')
					error('IS:Stage:missingOutputDisk', 'Error: No output available on disk for stage ''%s''.', obj.Name);
				end
				obj.loadOutput();
			end

			fields = fieldnames(obj.Output);
			if numel(fields) == 1 && strcmp(fields{1}, obj.Name)
				output = obj.Output.(obj.Name);
			else
				output = obj.Output;
			end
		end

		function clearMemory(obj)
			% clear in memory cache, recursively on input stages
			obj.Output = struct();
			for stage = obj.InputStages
				stage.clearMemory();
			end
		end
	end
end

function NOP(varargin)
	% does nothing

end
