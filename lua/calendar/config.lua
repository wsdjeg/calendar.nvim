local default_config = {
  keymap = {
    next_month = 'L',
    previous_month = 'H',
    next_day = 'l',
    previous_day = 'h',
    next_week = 'j',
    previous_week = 'k',
    today = 't',
    close = 'q',
  },
  mark_icon = '•',
  show_adjacent_days = true,
  -- the first column of the week: 'monday' or 'sunday'
  first_day_of_week = 'monday',
  highlights = {
    current = 'Visual',
    today = 'Todo',
    mark = 'Todo',
    adjacent_days = 'Comment',
  },
  locale = 'en-US',
  locales = require('calendar.locales'),
}

local valid_first_day_of_week = { 'monday', 'sunday' }

return {
  get = function()
    return default_config
  end,
  setup = function(opt)
    opt = opt or {}
    if
      opt.first_day_of_week ~= nil
      and not vim.tbl_contains(valid_first_day_of_week, opt.first_day_of_week)
    then
      error(
        string.format(
          'calendar.nvim: invalid first_day_of_week %s, expected "monday" or "sunday"',
          vim.inspect(opt.first_day_of_week)
        )
      )
    end
    default_config = vim.tbl_deep_extend('force', default_config, opt)
  end,
}
