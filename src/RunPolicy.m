classdef RunPolicy
	enumeration
		DEFAULT, ALWAYS, OLD, NEVER, ASK, ALWAYSASK
	end
end

% ALWAYS: Always execute the stage, even if up-to-date cached results are
% available.
% NEVER: Never execute the stage. Throws an error if cached results are not
% available.
% OLD: Execute the stage if cached results are not available or if they are
% outdated or if the results of any of the stages before in the pipeline are
% not available or outdated (recursive check on the pipeline). Cached results
% of stage S are outdated when any of the results produced by at least one of
% the input stages of the stage S is more recent (by filesystem modification
% timestamp) than the cached results of stage S.
% ASK: Like OLD, but ask the user before executing the stage.
% ALWAYSASK: Like ALWAYS, but ask the user before executing the stage.
% DEFAULT: used to represent the default run policy. It's value is determined
% by global variable DEFAULT_RUNPOLICY.
