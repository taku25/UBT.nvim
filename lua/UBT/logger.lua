--- UBT.nvim's central logger and event dispatcher.
-- This module acts as a facade, receiving events from the job runner
-- and dispatching them to all registered writer backends.
-- It decouples the job logic from the actual output mechanisms.
local M = {}

-- Load all available writers via the writer/init.lua facade.
local writers = require("UBT.writer")

--- Called once when the plugin is set up by the user.
function M.on_plugin_setup(config)
  for _, writer in ipairs(writers) do
    if writer.on_plugin_setup then
      writer.on_plugin_setup(config)
    end
  end
end

--- Dispatches the 'on_job_start' event to all writers.
-- Called once when a new job begins.
-- @param opts table: Job start options, e.g., { name = "Build" }
function M.on_job_start(opts)
  for _, writer in ipairs(writers) do
    if writer.on_job_start then
      writer.on_job_start(opts)
    end
  end
end

--- Dispatches the 'on_job_exit' event to all writers.
-- Called once when the job finishes.
-- @param code integer: The exit code of the job.
function M.on_job_exit(code)
  for _, writer in ipairs(writers) do
    if writer.on_job_exit then
      writer.on_job_exit(code)
    end
  end
end

--- Dispatches progress updates to all writers.
-- @param label string: The label of the progress task, e.g., "Compiling C++".
-- @param percentage integer: The progress percentage (0-100).
function M.on_progress_update(label, percentage)
  for _, writer in ipairs(writers) do
    if writer.on_progress_update then
      writer.on_progress_update(label, percentage)
    end
  end
end

--- Dispatches a standard log line to all writers.
-- @param message string: The log message.
-- @param level integer: The log level, e.g., vim.log.levels.INFO.
function M.write(message, level)
  -- Ensure a default log level if not provided.
  level = level or vim.log.levels.INFO

  for _, writer in ipairs(writers) do
    if writer.write then
      writer.write(message, level)
    end
  end
end

return M
