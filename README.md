# calendar.nvim

A lightweight and extensible pure-Lua monthly calendar plugin for Neovim,
featuring Vim-style navigation, customizable day highlights and marks,
and a simple extension system for integrating your own workflows.

[![Run Tests](https://github.com/wsdjeg/calendar.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/wsdjeg/calendar.nvim/actions/workflows/test.yml)
[![GitHub License](https://img.shields.io/github/license/wsdjeg/calendar.nvim)](LICENSE)
[![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/wsdjeg/calendar.nvim)](https://github.com/wsdjeg/calendar.nvim/issues)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/wsdjeg/calendar.nvim)](https://github.com/wsdjeg/calendar.nvim/commits/master/)
[![GitHub Release](https://img.shields.io/github/v/release/wsdjeg/calendar.nvim)](https://github.com/wsdjeg/calendar.nvim/releases)
[![luarocks](https://img.shields.io/luarocks/v/wsdjeg/calendar.nvim)](https://luarocks.org/modules/wsdjeg/calendar.nvim)

<img width="660" height="653" alt="image" src="https://github.com/user-attachments/assets/64ec7e8f-d5aa-4265-974a-9f56f0214527" />

<!-- vim-markdown-toc GFM -->

- [✨ Features](#-features)
- [📦 Installation](#-installation)
- [🔧 Configuration](#-configuration)
    - [locales](#locales)
- [🧩 Custom extensions](#-custom-extensions)
    - [register extension manually](#register-extension-manually)
    - [automatically extensions](#automatically-extensions)
- [🖼️ Screenshots](#-screenshots)
- [📣 Self-Promotion](#-self-promotion)
- [💬 Feedback](#-feedback)
- [🙏 Credits](#-credits)
- [📄 License](#-license)

<!-- vim-markdown-toc -->

## ✨ Features

- Monthly calendar view in Neovim
- Vim-style keyboard navigation
- Today highlighting and custom day highlights
- Marked days support
- Extensible architecture
- Configurable setup and keymaps
- Configurable first day of the week (`monday` or `sunday`)
- Pure Lua, lightweight, no dependencies

## 📦 Installation

```lua
return {
  'wsdjeg/calendar.nvim',
}
```

## 🔧 Configuration

```lua
require('calendar').setup({
  mark_icon = '•',
  -- locale currently affects UI language only.
  locale = 'en-US', -- en-US | de-DE | en-GB | es-ES | fr-FR | it-IT | ja-JP | ko-KR | zh-CN | zh-TW | ru-RU
  show_adjacent_days = true,
  -- the first day of the week column, 'monday' by default.
  first_day_of_week = 'monday', -- 'monday' | 'sunday'
  -- calendar.nvim support vim style keyboard navigation, hjkl.
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
  highlights = {
    current = 'Visual',
    today = 'Todo',
    mark = 'Todo',
    adjacent_days = 'Comment',
  },
  locales = {} -- See `## Locales`
})
```

### locales

`locales` config is extendable.

(e.g. Add `my-LC` locale based on `en-US`)
```lua
require('calendar').setup({
  locale = 'my-LC',
  locales = {
    ['my-LC'] = {
       -- stylua: ignore
       months = { 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' },
       weekdays = { 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' },
       year_month = function(year, month, months)
         return string.format('%s %d', months[month], year)
       end,
     },
  },
})
```

## 🧩 Custom extensions

calendar.nvim supports extensions which can be used to mark specific date.

### register extension manually

for example:

here is a simple extension to add [zettelkasten.nvim](https://github.com/wsdjeg/zettelkasten.nvim) support to calendar.nvim

```lua
local zk_ext = {}

function zk_ext.get(year, month)
  local notes = require('zettelkasten.browser').get_notes()
  local marks = {}
  for _, note in ipairs(notes) do
    local t = vim.split(note.id, '-')
    if tonumber(t[1]) == year and tonumber(t[2]) == month then
      table.insert(
        marks,
        {
          year = tonumber(t[1]),
          month = tonumber(t[2]),
          day = tonumber(t[3]),
        }
      )
    end
  end

  return marks
end

require('calendar.extensions').register('zettelkasten', zk_ext)
```

### automatically extensions

create `lua/calendar/extensions/zettelkasten.lua`

```lua
local extension = {}

function extension.get(year, month)
  local notes = require('zettelkasten.browser').get_notes()
  local marks = {}
  for _, note in ipairs(notes) do
    local t = vim.split(note.id, '-')
    if tonumber(t[1]) == year and tonumber(t[2]) == month then
      table.insert(marks, {
        year = tonumber(t[1]),
        month = tonumber(t[2]),
        day = tonumber(t[3]),
      })
    end
  end

  return marks
end

extension.actions = {
  create_daily_note = function(year, month, day) end,
  view_daily_notes = function(year, month, day) end,
}

return extension
```

## 🖼️ Screenshots

![calendar-intro](https://github.com/user-attachments/assets/cc774407-92f7-490b-b9b3-34d62886fbf8)

## 📣 Self-Promotion

Like this plugin? Star the repository on
GitHub.

Love this plugin? Follow [me](https://wsdjeg.net/) on
[GitHub](https://github.com/wsdjeg).

## 💬 Feedback

If you encounter any bugs or have suggestions, please file an issue in the [issue tracker](https://github.com/wsdjeg/calendar.nvim/issues)

## 🙏 Credits

- [calendar](https://github.com/itchyny/calendar.vim)

## 📄 License

Licensed under GPL-3.0.
