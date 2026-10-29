-- test/extensions_spec.lua
-- 扩展标记的计算逻辑：标记必须每次重绘重算，不能跨月/跨数据版本残留。

local lu = require('luaunit')

local function fresh()
  package.loaded['calendar.extensions'] = nil
  return require('calendar.extensions')
end

local function due_ext(state)
  return {
    get = function(year, month)
      local out = {}
      for _, day in ipairs(state.days) do
        table.insert(out, { year = year, month = month, day = day })
      end
      return out
    end,
  }
end

TestExtensions = {}

function TestExtensions:test_marks_recomputed_on_change()
  local ext = fresh()
  local state = { days = { 3, 17 } }
  ext.register('due', due_ext(state))

  ext.on_change(2026, 5)
  lu.assertTrue(ext.has_marks(2026, 5, 3))
  lu.assertTrue(ext.has_marks(2026, 5, 17))
  lu.assertNil(ext.has_marks(2026, 5, 4))

  -- 数据源变了（任务改期/删除），重绘后旧标记必须消失
  state.days = { 17 }
  ext.on_change(2026, 5)
  lu.assertNil(ext.has_marks(2026, 5, 3))
  lu.assertTrue(ext.has_marks(2026, 5, 17))
end

function TestExtensions:test_marks_do_not_leak_across_months()
  local ext = fresh()
  ext.register('due', due_ext({ days = { 31 } }))

  ext.on_change(2026, 1)
  lu.assertTrue(ext.has_marks(2026, 1, 31))

  ext.on_change(2026, 2)
  lu.assertNil(ext.has_marks(2026, 1, 31))
end

function TestExtensions:test_clear()
  local ext = fresh()
  ext.register('due', due_ext({ days = { 9 } }))
  ext.on_change(2026, 5)
  lu.assertTrue(ext.has_marks(2026, 5, 9))
  ext.clear()
  lu.assertNil(ext.has_marks(2026, 5, 9))
end

function TestExtensions:test_actions_only_extension_is_ignored_by_on_change()
  local ext = fresh()
  ext.register('actions-only', { actions = {} })
  lu.assertNotNil(pcall(ext.on_change, 2026, 5))
end

function TestExtensions:test_extension_without_get_is_ignored()
  local ext = fresh()
  ext.register('no-get', {})
  lu.assertNotNil(pcall(ext.on_change, 2026, 5))
end

function TestExtensions:test_bad_marks_are_ignored()
  local ext = fresh()
  ext.register('bad', {
    get = function()
      return { 'junk', { year = 2026, month = 5, day = 7 } }
    end,
  })
  ext.on_change(2026, 5)
  lu.assertTrue(ext.has_marks(2026, 5, 7))
end
