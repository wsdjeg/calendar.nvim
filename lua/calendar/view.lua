local M = {}

-- do not create new calendar buffer

local buf = -1
local win = -1

local highlight_today_id = -1

local calendar = {}

local model = require('calendar.model')

local ns = vim.api.nvim_create_namespace('calendar.nvim')
local ext = require('calendar.extensions')

---@param str string
---@param width number
---@param align? 'left'|'center'|'right' default: 'left'
---@param fillchar? string default: ' '）
---@return string
local function align_str(str, width, align, fillchar)
  align = align or 'left'
  fillchar = fillchar or ' '

  local str_width = vim.fn.strdisplaywidth(str)

  if str_width >= width then
    return str
  end

  local padding = width - str_width

  if align == 'left' then
    return str .. string.rep(fillchar, padding)
  elseif align == 'right' then
    return string.rep(fillchar, padding) .. str
  elseif align == 'center' then
    local left_pad = math.floor(padding / 2)
    local right_pad = padding - left_pad
    return string.rep(fillchar, left_pad)
      .. str
      .. string.rep(fillchar, right_pad)
  end

  return str
end

local function center(str, width)
  return align_str(str, width, 'center', ' ')
end

local function right(str, width)
  return align_str(str, width, 'right', ' ')
end

local function render_lines(year, month, grid)
  local conf = require('calendar.config').get()
  local locale = conf.locale
  local locales = conf.locales
  local lines = {}
  local CALENDAR_WIDTH, WEEKDAY_WIDTH = 33, 3

  -- check if locale exists
  if not locales[locale] then
    locales = require('calendar.locales')
    locale = 'en-US'
  end

  local months = locales[locale].months
  local year_month = locales[locale].year_month(year, month, months)
  table.insert(lines, center(year_month, CALENDAR_WIDTH))

  table.insert(lines, '                                 ')

  -- weekdays are stored Monday-first, rotate them when the
  -- calendar should start on Sunday
  local weekdays = vim.list_extend({}, locales[locale].weekdays)
  if conf.first_day_of_week == 'sunday' then
    table.insert(weekdays, 1, table.remove(weekdays))
  end
  local pad_weekdays = {}
  for _, weekday in ipairs(weekdays) do
    table.insert(pad_weekdays, right(weekday, WEEKDAY_WIDTH))
  end
  local pad_weekdays_str = table.concat(pad_weekdays, ' ')
  table.insert(lines, center(pad_weekdays_str, CALENDAR_WIDTH))

  table.insert(lines, '                                 ')

  for _, week in ipairs(grid) do
    table.insert(lines, '   ' .. table.concat(week, ' ') .. '   ')
    table.insert(lines, '                                 ')
  end

  return lines
end
local function highlight_today(year, month, grid)
  local today = os.date('*t')
  if today.year ~= year or today.month ~= month then
    return
  end

  local is_current_month = false

  for row, week in ipairs(grid) do
    for col, val in ipairs(week) do
      if is_current_month and tonumber(val) == 1 then
        is_current_month = false
      elseif not is_current_month and tonumber(val) == 1 then
        is_current_month = true
      end
      if is_current_month and tonumber(val) == today.day then
        local line = (row - 1) * 2 + 4
        local col_start, col_end
        if today.day < 10 then
          col_start = (col - 1) * 4 + 4
          col_end = col_start + 3
        else
          col_start = (col - 1) * 4 + 3
          col_end = col_start + 4
        end
        vim.api.nvim_buf_set_extmark(buf, ns, line, col_start, {
          hl_group = require('calendar.config').get().highlights.today,
          end_col = col_end,
        })
        break
      end
    end
  end
end

local marks = {}
local function set_mark(year, month, grid)
  for _, id in ipairs(marks) do
    pcall(vim.api.nvim_buf_del_extmark, buf, ns, id)
  end
  marks = {}
  local t = os.date('*t')
  local conf = require('calendar.config').get()
  local is_current_month = false
  for row, week in ipairs(grid) do
    for col, val in ipairs(week) do
      if is_current_month and tonumber(val) == 1 then
        is_current_month = false
      elseif not is_current_month and tonumber(val) == 1 then
        is_current_month = true
      end
      if is_current_month and ext.has_marks(year, month, tonumber(val)) then
        local line = (row - 1) * 2 + 4
        local col_start, col_end
        if tonumber(val) < 10 then
          col_start = (col - 1) * 4 + 4
        else
          col_start = (col - 1) * 4 + 3
        end
        local virt_text_hl = { conf.highlights.mark }
        if t.year == year and t.month == month and t.day == tonumber(val) then
          table.insert(virt_text_hl, conf.highlights.today)
        end
        if tonumber(val) == calendar.day then
          table.insert(virt_text_hl, conf.highlights.current)
        end
        local id = vim.api.nvim_buf_set_extmark(buf, ns, line, col_start, {
          virt_text = {
            {
              conf.mark_icon,
              virt_text_hl,
            },
          },
          virt_text_pos = 'overlay',
        })
        table.insert(marks, id)
      end
    end
  end
end

local adjacent_days_ids = {}
local function highlight_adjacent_days()
  for _, id in ipairs(adjacent_days_ids) do
    pcall(vim.api.nvim_buf_del_extmark, buf, ns, id)
  end
  adjacent_days_ids = {}
  local is_current_month = false
  for row, week in ipairs(calendar.grid) do
    for col, val in ipairs(week) do
      if is_current_month and tonumber(val) == 1 then
        is_current_month = false
      elseif not is_current_month and tonumber(val) == 1 then
        is_current_month = true
      end
      if not is_current_month then
        local line = (row - 1) * 2 + 4
        local col_start, col_end
        if tonumber(val) < 10 then
          col_start = (col - 1) * 4 + 4
          col_end = col_start + 3
        else
          col_start = (col - 1) * 4 + 3
          col_end = col_start + 4
        end
        local id = vim.api.nvim_buf_set_extmark(buf, ns, line, col_start, {
          hl_group = require('calendar.config').get().highlights.adjacent_days,
          end_col = col_end,
        })
        table.insert(adjacent_days_ids, id)
      end
    end
  end
end

function M.open(year, month, day)
  calendar.year = year
  calendar.month = month
  calendar.day = day or 1
  local conf = require('calendar.config').get()
  calendar.grid = model.build_month_grid(year, month)
  calendar.days = calendar.grid.days
  local lines = render_lines(year, month, calendar.grid)
  if not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = 'nofile'
    vim.api.nvim_buf_set_keymap(buf, 'n', conf.keymap.previous_month, '', {
      callback = M.previous_month,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', conf.keymap.next_month, '', {
      callback = M.next_month,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', conf.keymap.next_day, '', {
      callback = M.next_day,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', conf.keymap.previous_day, '', {
      callback = M.previous_day,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', conf.keymap.next_week, '', {
      callback = M.next_week,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', conf.keymap.previous_week, '', {
      callback = M.previous_week,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', conf.keymap.today, '', {
      callback = M.today,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', conf.keymap.close, '', {
      callback = M.close,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<LeftMouse>', '', {
      callback = function()
        local pos = vim.fn.getmousepos()
        if pos.winid == win then
          vim.api.nvim_win_set_cursor(win, { pos.line, pos.column - 1 })
          local line = vim.fn.line('.')
          if line >= 4 then
            local mouse_day = tonumber(vim.fn.expand('<cword>'))
            if mouse_day then
              if line == 5 and mouse_day > 7 then
                -- is previous month
                M.previous_month()
              elseif line > 12 and mouse_day < 15 then
                -- is next month
                M.next_month()
              end
              calendar.day = mouse_day
              M.highlight_day(mouse_day)
            end
          end
        else
          vim.api.nvim_set_current_win(pos.winid)
          if pos.line > 0 then
            vim.api.nvim_win_set_cursor(
              pos.winid,
              { pos.line, pos.column - 1 }
            )
          end
        end
      end,
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Enter>', '', {
      callback = function()
        require('calendar.extensions').on_action(
          calendar.year,
          calendar.month,
          calendar.day
        )
      end,
    })
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  if not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      row = 3,
      col = 5,
      width = 34,
      height = #lines,
      style = 'minimal',
      border = 'rounded',
    })
    local winhighlight =
      'NormalFloat:Normal,FloatBorder:WinSeparator,Search:None,CurSearch:None'
    vim.api.nvim_set_option_value('winhighlight', winhighlight, { win = win })
    vim.api.nvim_set_option_value('sidescrolloff', 0, { win = win })
    vim.api.nvim_set_option_value('scrolloff', 0, { win = win })
  end

  highlight_today(year, month, calendar.grid)

  ext.on_change(year, month)
  M.highlight_day(calendar.day)

  return buf, win
end

function M.previous_month()
  if calendar.month == 1 then
    calendar.month = 12
    calendar.year = calendar.year - 1
  else
    calendar.month = calendar.month - 1
  end
  M.open(calendar.year, calendar.month)
end
function M.next_month()
  if calendar.month == 12 then
    calendar.month = 1
    calendar.year = calendar.year + 1
  else
    calendar.month = calendar.month + 1
  end
  M.open(calendar.year, calendar.month)
end

function M.next_day()
  if calendar.day < calendar.days then
    calendar.day = calendar.day + 1
  else
    calendar.day = 1
    M.next_month()
  end
  M.highlight_day(calendar.day)
end

function M.previous_day()
  if calendar.day > 1 then
    calendar.day = calendar.day - 1
    M.highlight_day(calendar.day)
  else
    M.previous_month()
    calendar.day = calendar.days
    M.highlight_day(calendar.day)
  end
end

function M.next_week()
  if calendar.day + 7 > calendar.days then
    local day = calendar.day + 7 - calendar.days
    M.next_month()
    calendar.day = day
  else
    calendar.day = calendar.day + 7
  end
  M.highlight_day(calendar.day)
end

function M.today()
  local t = os.date('*t')
  calendar.year = t.year
  calendar.month = t.month
  calendar.day = t.day
  M.open(t.year, t.month, t.day)
end

function M.previous_week()
  if calendar.day <= 7 then
    local day = 7 - calendar.day
    M.previous_month()
    calendar.day = calendar.days - day
  else
    calendar.day = calendar.day - 7
  end
  M.highlight_day(calendar.day)
end

function M.highlight_day(day)
  local is_current_month = false
  for row, week in ipairs(calendar.grid) do
    for col, val in ipairs(week) do
      if is_current_month and tonumber(val) == 1 then
        is_current_month = false
      elseif not is_current_month and tonumber(val) == 1 then
        is_current_month = true
      end
      if is_current_month and tonumber(val) == day then
        local line = (row - 1) * 2 + 4
        local col_start, col_end
        if day < 10 then
          col_start = (col - 1) * 4 + 4
          col_end = col_start + 3
        else
          col_start = (col - 1) * 4 + 3
          col_end = col_start + 4
        end
        pcall(vim.api.nvim_buf_del_extmark, buf, ns, highlight_today_id)
        highlight_today_id =
          vim.api.nvim_buf_set_extmark(buf, ns, line, col_start, {
            hl_group = require('calendar.config').get().highlights.current,
            end_col = col_end,
          })
      end
    end
  end
  set_mark(calendar.year, calendar.month, calendar.grid)
  if require('calendar.config').get().show_adjacent_days then
    highlight_adjacent_days()
  end
end

function M.close()
  vim.api.nvim_win_close(win, true)
end

return M
