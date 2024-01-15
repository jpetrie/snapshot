local snapshot = {
  options = {
    session_dir = vim.fn.expand(vim.fn.stdpath("state") .. "/session/"),
    allow_paths = {},
    hooks = {
      -- Each function accepts the path to the session being saved.
      pre_save = function(_) end,
      post_save = function(_) end,
      pre_load = function(_) end,
      post_load = function(_) end,
    }
  }
}

local directory_seperator_pattern = "[\\/:]"

local function is_path_under(path, parent)
  local path_parts = vim.fn.split(vim.fn.fnamemodify(path, ":p"), directory_seperator_pattern)
  local parent_parts = vim.fn.split(vim.fn.fnamemodify(parent, ":p"), directory_seperator_pattern)
  if #parent_parts > #path_parts then
    -- The path can't possibly be under the parent.
    return false
  end

  for index, part in ipairs(parent_parts) do
    if part ~= path_parts[index] then
      -- Each part of the parent must match the corresponding part of the path.
      return false
    end
  end

  return true
end

local function is_auto_allowed()
  if #vim.api.nvim_list_uis() == 0 then
    -- Do not perform automatic session management when headless.
    return false
  end

  local current_dir = vim.loop.cwd()
  for _, allowed in ipairs(snapshot.options.allow_paths) do
    allowed = vim.fn.fnamemodify(allowed, ":p")
    if is_path_under(current_dir, allowed) then
      return true
    end
  end

  return false
end

local function try_autoload_session()
  if is_auto_allowed() and vim.fn.argc() == 0 then
    -- Schedule the session load so it occurs during the main loop, which avoids any ordering issues that could
    -- occur due to other startup and VimEnter code not being complete yet.
    vim.schedule(function()
      snapshot.load()
    end)
  end
end

local function try_autosave_session()
  if is_auto_allowed() then
    snapshot.save()
  end
end

function snapshot.setup(options)
  snapshot.options = vim.tbl_deep_extend("keep", options, snapshot.options)

  vim.api.nvim_create_user_command("SnapSave", snapshot.save, {})
  vim.api.nvim_create_user_command("SnapLoad", snapshot.load, {})

  vim.api.nvim_create_autocmd("VimEnter", {callback = try_autoload_session})
  vim.api.nvim_create_autocmd("VimLeavePre", {callback = try_autosave_session})
end

function snapshot.session_file()
  local name = vim.loop.cwd()
  name = string.gsub(name, directory_seperator_pattern, "%%")

  return snapshot.options.session_dir .. name .. ".vim"
end

function snapshot.save()
  local path = snapshot.session_file()
  snapshot.options.hooks.pre_save(path)
  vim.fn.mkdir(snapshot.options.session_dir, "p")
  vim.cmd("mksession! " .. vim.fn.fnameescape(path))
  snapshot.options.hooks.post_save(path)
end

function snapshot.load()
  local path = snapshot.session_file()
  if vim.fn.filereadable(path) == 1 then
    snapshot.options.hooks.pre_load(path)
    vim.cmd("silent! source " .. vim.fn.fnameescape(path))
    snapshot.options.hooks.post_load(path)
  end
end

return snapshot
