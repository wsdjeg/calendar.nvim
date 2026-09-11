-- test/example_spec.lua
-- Example test file demonstrating the test framework usage

local lu = require('luaunit')

TestConfig = {}

function TestConfig:test_default_config()
  local config = require('calendar.config')
  local cfg = config.get()
  lu.assertNotNil(cfg)
  lu.assertEquals(cfg.mark_icon, '*')
  lu.assertEquals(cfg.locale, 'en-US')
  lu.assertTrue(cfg.show_adjacent_days)
end

function TestConfig:test_custom_keymap()
  local config = require('calendar.config')
  local cfg = config.get()
  lu.assertEquals(cfg.keymap.next_month, 'L')
  lu.assertEquals(cfg.keymap.previous_month, 'H')
  lu.assertEquals(cfg.keymap.close, 'q')
end

TestModel = {}

function TestModel:test_month_info_january_2025()
  local model = require('calendar.model')
  local info = model.month_info(2025, 1)
  lu.assertEquals(info.days, 31)
  -- January 1, 2025 is a Wednesday (3 in %w format, 0=Sunday)
  lu.assertEquals(info.first_wday, 3)
end

function TestModel:test_month_info_february_2024_leap()
  local model = require('calendar.model')
  local info = model.month_info(2024, 2)
  -- 2024 is a leap year, February has 29 days
  lu.assertEquals(info.days, 29)
end

function TestModel:test_month_info_february_2025_nonleap()
  local model = require('calendar.model')
  local info = model.month_info(2025, 2)
  lu.assertEquals(info.days, 28)
end

function TestModel:test_build_month_grid()
  local model = require('calendar.model')
  local grid = model.build_month_grid(2025, 1)
  lu.assertNotNil(grid)
  lu.assertEquals(#grid, 6)
  lu.assertEquals(grid.days, 31)
end

TestFirstDayOfWeek = {}

function TestFirstDayOfWeek:tearDown()
  -- restore the default so other test classes are not affected
  require('calendar.config').setup({ first_day_of_week = 'monday' })
end

function TestFirstDayOfWeek:test_default_is_monday()
  local config = require('calendar.config')
  lu.assertEquals(config.get().first_day_of_week, 'monday')
end

function TestFirstDayOfWeek:test_invalid_value_errors()
  local config = require('calendar.config')
  lu.assertError(function()
    config.setup({ first_day_of_week = 'friday' })
  end)
  -- config keeps the previous valid value
  lu.assertEquals(config.get().first_day_of_week, 'monday')
end

function TestFirstDayOfWeek:test_monday_first_column()
  local model = require('calendar.model')
  require('calendar.config').setup({ first_day_of_week = 'monday' })
  -- %w: 0 = Sunday ... 6 = Saturday
  lu.assertEquals(model.first_day_column(0), 7)
  lu.assertEquals(model.first_day_column(1), 1)
  lu.assertEquals(model.first_day_column(6), 6)
end

function TestFirstDayOfWeek:test_sunday_first_column()
  local model = require('calendar.model')
  require('calendar.config').setup({ first_day_of_week = 'sunday' })
  lu.assertEquals(model.first_day_column(0), 1)
  lu.assertEquals(model.first_day_column(1), 2)
  lu.assertEquals(model.first_day_column(6), 7)
end

function TestFirstDayOfWeek:test_monday_first_grid_june_2025()
  local model = require('calendar.model')
  require('calendar.config').setup({ first_day_of_week = 'monday' })
  -- June 1, 2025 is a Sunday, the last column of a Monday-first week
  local grid = model.build_month_grid(2025, 6)
  lu.assertEquals(grid[1][7], '  1')
  lu.assertEquals(grid[1][6], ' 31')
end

function TestFirstDayOfWeek:test_sunday_first_grid_june_2025()
  local model = require('calendar.model')
  require('calendar.config').setup({ first_day_of_week = 'sunday' })
  -- June 1, 2025 is a Sunday, the first column of a Sunday-first week
  local grid = model.build_month_grid(2025, 6)
  lu.assertEquals(grid[1][1], '  1')
  lu.assertEquals(grid[1][2], '  2')
end

function TestFirstDayOfWeek:test_sunday_first_grid_january_2025()
  local model = require('calendar.model')
  require('calendar.config').setup({ first_day_of_week = 'sunday' })
  -- January 1, 2025 is a Wednesday, so Sunday/Tuesday columns
  -- hold adjacent days of December 2024
  local grid = model.build_month_grid(2025, 1)
  lu.assertEquals(grid[1][1], ' 29')
  lu.assertEquals(grid[1][2], ' 30')
  lu.assertEquals(grid[1][3], ' 31')
  lu.assertEquals(grid[1][4], '  1')
end

TestExtensions = {}

function TestExtensions:test_mark_and_has_marks()
  local ext = require('calendar.extensions')
  ext.mark(2025, 1, 15)
  lu.assertTrue(ext.has_marks(2025, 1, 15))
  lu.assertNil(ext.has_marks(2025, 1, 16))
end

function TestExtensions:test_register()
  local ext = require('calendar.extensions')
  local mock_ext = {
    get = function()
      return {}
    end,
    actions = {},
  }
  ext.register('mock', mock_ext)
  -- Should not error
  lu.assertTrue(true)
end

TestSetup = {}

function TestSetup:test_setup_returns_no_error()
  local calendar = require('calendar')
  -- setup was already called in minimal_init.lua, call again with new opts
  calendar.setup({ mark_icon = '#' })
  local config = require('calendar.config')
  lu.assertEquals(config.get().mark_icon, '#')
end

return TestConfig

