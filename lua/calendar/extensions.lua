local M = {}

local extensions = {
  auto = {},
  manual = {},
}

local marked_days = {}

local function get_calendar_exts()
  local exts = {}
  for _, name in
    ipairs(
      vim.api.nvim_get_runtime_file('lua/calendar/extensions/*.lua', true)
    )
  do
    name = vim.fn.fnamemodify(name, ':t:r')
    local ok, ext = pcall(require, 'calendar.extensions.' .. name)
    if ok then
      exts[name] = ext
    end
  end
  return exts
end

local function get_key(year, mouth, day)
  return string.format('%4d-%2d-%2d', year, mouth, day)
end

function M.has_marks(year, mouth, day)
  if
    type(year) == 'number'
    and type(mouth) == 'number'
    and type(day) == 'number'
  then
    return marked_days[get_key(year, mouth, day)]
  else
  end
end

function M.mark(year, mouth, day)
  marked_days[get_key(year, mouth, day)] = true
end

function M.register(name, ext)
  extensions.manual[name] = ext
end

function M.on_change(year, month)
  extensions.auto = get_calendar_exts()
  for _, ext in pairs(extensions.manual) do
    local marks = ext.get(year, month)
    for _, mark in ipairs(marks) do
      M.mark(mark.year, mark.month, mark.day)
    end
  end
  for _, ext in pairs(extensions.auto) do
    local marks = ext.get(year, month)
    for _, mark in ipairs(marks) do
      M.mark(mark.year, mark.month, mark.day)
    end
  end
end

function M.on_action(year, month, day)
  extensions.auto = get_calendar_exts()
  local actions = {}
  for extension, ext in pairs(extensions.manual) do
    for action, callback in pairs(ext.actions) do
      table.insert(actions, {
        name = extension .. '/' .. action,
        callback = callback,
        date = { year = year, month = month, day = day },
      })
    end
  end
  for extension, ext in pairs(extensions.auto) do
    for action, callback in pairs(ext.actions) do
      table.insert(actions, {
        name = extension .. '/' .. action,
        callback = callback,
        date = { year = year, month = month, day = day },
      })
    end
  end
  vim.ui.select(actions, {
    prompt = 'calendar actions',
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if choice then
      choice.callback(choice.date.year, choice.date.month, choice.date.day)
    end
  end)
end

return M
