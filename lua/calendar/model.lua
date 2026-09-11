local M = {}

function M.month_info(year, month)
  local first_day = os.time({ year = year, month = month, day = 1, hour = 0 })
  local last_day = os.time({ year = year, month = month + 1, day = 0 })

  return {
    first_wday = tonumber(os.date('%w', first_day)),
    days = tonumber(os.date('%d', last_day)),
  }
end

--- compute the column (1-based) of the first day of the month,
--- depending on the first_day_of_week config.
---@param first_wday number weekday of the 1st day, %w format: 0 = Sunday, ..., 6 = Saturday
---@return number column 1-7
function M.first_day_column(first_wday)
  local conf = require('calendar.config').get()
  if conf.first_day_of_week == 'sunday' then
    -- %w: Sunday is 0, so it lands on the first column
    return first_wday + 1
  end
  -- Monday-first grid: Sunday is the last column
  return first_wday == 0 and 7 or first_wday
end

function M.build_month_grid(year, month)
  local conf = require('calendar.config').get()
  local info = M.month_info(year, month)
  local grid = {}

  for i = 1, 6 do
    grid[i] = {}
    for c = 1, 7 do
      grid[i][c] = '   '
    end
  end

  local start_col = M.first_day_column(info.first_wday)
  local row, col = 1, start_col

  if conf.show_adjacent_days and start_col > 1 then
    local previous_month_info
    if month == 1 then
      previous_month_info = M.month_info(year - 1, 12)
    else
      previous_month_info = M.month_info(year, month - 1)
    end
    for i = 1, start_col - 1 do
      grid[1][i] =
        string.format('%3d', previous_month_info.days - start_col + i + 1)
    end
  end

  for day = 1, info.days do
    grid[row][col] = string.format('%3d', day)
    col = col + 1
    if col > 7 then
      col = 1
      row = row + 1
    end
  end

  if conf.show_adjacent_days then
    for i = 1, 42 - start_col + 1 - info.days do
      grid[row][col] = string.format('%3d', i)
      col = col + 1
      if col > 7 then
        col = 1
        row = row + 1
      end
    end
  end

  grid.days = info.days

  return grid
end

return M
