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

---清空已计算的标记（每次重绘前自动调用，一般无需手动调用）
function M.clear()
  marked_days = {}
end

---收集扩展返回的标记
---@param ext table
---@param year number
---@param month number
local function collect(ext, year, month)
  if type(ext) ~= 'table' or type(ext.get) ~= 'function' then
    return
  end
  local marks = ext.get(year, month)
  if type(marks) ~= 'table' then
    return
  end
  for _, mark in ipairs(marks) do
    if type(mark) == 'table' then
      M.mark(mark.year, mark.month, mark.day)
    end
  end
end

function M.on_change(year, month)
  -- 标记必须每次重绘从当前数据重算：marked_days 是模块级缓存，
  -- 不重置的话，任务被删除/改期/切换项目后旧的标记会永久残留。
  M.clear()
  extensions.auto = get_calendar_exts()
  for _, ext in pairs(extensions.manual) do
    collect(ext, year, month)
  end
  for _, ext in pairs(extensions.auto) do
    collect(ext, year, month)
  end
end

function M.on_action(year, month, day)
  extensions.auto = get_calendar_exts()
  local actions = {}
  local function collect(extension, ext)
    if type(ext) ~= 'table' or type(ext.actions) ~= 'table' then
      return
    end
    for action, callback in pairs(ext.actions) do
      table.insert(actions, {
        name = extension .. '/' .. action,
        callback = callback,
        date = { year = year, month = month, day = day },
      })
    end
  end
  for extension, ext in pairs(extensions.manual) do
    collect(extension, ext)
  end
  for extension, ext in pairs(extensions.auto) do
    collect(extension, ext)
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
