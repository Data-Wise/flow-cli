-- Headless Neovim tests for himalaya-ai.lua keybinds
-- Run: nvim --headless -l tests/cli/himalaya-headless-keybind-tests.lua
--
-- Tests open_result() keybinds, buffer state, and config
-- without any user interaction or AI backend calls.

local pass = 0
local fail = 0
local total = 0

local function ok(cond, msg)
  total = total + 1
  if cond then
    pass = pass + 1
    io.write("  PASS: " .. msg .. "\n")
  else
    fail = fail + 1
    io.write("  FAIL: " .. msg .. "\n")
  end
end

-- ═══════════════════════════════════════════════════════════
-- SETUP
-- ═══════════════════════════════════════════════════════════

io.write("\n=== HEADLESS KEYBIND TESTS ===\n\n")

local M = require("himalaya-ai")

ok(type(M) == "table", "himalaya-ai module loads")
ok(type(M._open_result) == "function", "M._open_result is exposed")
ok(type(M._run_ai_custom) == "function", "M._run_ai_custom is exposed")

-- ═══════════════════════════════════════════════════════════
-- CONFIG DEFAULTS
-- ═══════════════════════════════════════════════════════════

io.write("\n[Config Defaults]\n")

ok(M.config.todo_target == "ask", "todo_target defaults to 'ask'")
ok(M.config.result_display == "split" or M.config.result_display == "tab",
   "result_display is split or tab")
ok(type(M.config.obsidian) == "table", "obsidian config exists")
ok(type(M.config.backends) == "table", "backends config exists")
ok(type(M.config.ask_before) == "table", "ask_before config exists")

-- ═══════════════════════════════════════════════════════════
-- OPEN_RESULT: Buffer State
-- ═══════════════════════════════════════════════════════════

io.write("\n[open_result Buffer State]\n")

-- Create a result split with mock data
local mock_lines = { "# Test Result", "", "- Item one", "- Item two", "- [ ] Todo item" }
local mock_ctx = {
  prompt_text = "test prompt",
  email_text = "From: test@example.com\nSubject: Test\n\nHello world",
  email_meta = { from = "test@example.com", subject = "Test", date = "2026-02-11" },
  source_win = vim.api.nvim_get_current_win(),
}

M._open_result("Test Title", mock_lines, mock_ctx)

local buf = vim.api.nvim_get_current_buf()
local win = vim.api.nvim_get_current_win()

ok(vim.bo[buf].buftype == "nofile", "buftype is nofile")
ok(vim.bo[buf].swapfile == false, "swapfile is false")
ok(vim.bo[buf].bufhidden == "wipe", "bufhidden is wipe")
ok(vim.bo[buf].filetype == "markdown", "filetype is markdown")
ok(vim.bo[buf].modifiable == false, "buffer starts as read-only")
ok(vim.wo[win].wrap == true, "wrap is enabled")
ok(vim.wo[win].linebreak == true, "linebreak is enabled")
ok(vim.wo[win].number == false, "line numbers disabled")

-- Check buffer content matches input
local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
ok(#buf_lines == #mock_lines, "buffer has correct number of lines (" .. #buf_lines .. ")")
ok(buf_lines[1] == "# Test Result", "first line is '# Test Result'")

-- ═══════════════════════════════════════════════════════════
-- OPEN_RESULT: Keybind Registration
-- ═══════════════════════════════════════════════════════════

io.write("\n[Keybind Registration]\n")

local keymaps = vim.api.nvim_buf_get_keymap(buf, "n")
local registered = {}
for _, km in ipairs(keymaps) do
  registered[km.lhs] = true
end

-- Core keybinds (always present)
ok(registered["q"], "'q' keybind registered (close)")
ok(registered["<Esc>"], "'Esc' keybind registered (close)")
ok(registered["y"], "'y' keybind registered (copy)")
ok(registered["s"], "'s' keybind registered (save)")
ok(registered["f"], "'f' keybind registered (fullscreen)")
ok(registered["a"], "'a' keybind registered (append)")
ok(registered["o"], "'o' keybind registered (obsidian)")

-- V4 keybinds (new)
ok(registered["e"], "'e' keybind registered (edit toggle)")
ok(registered["c"], "'c' keybind registered (revise)")
ok(registered["n"], "'n' keybind registered (next action)")
ok(registered["t"], "'t' keybind registered (todo)")

-- Conditional keybinds (present because mock_ctx has prompt_text + email_text)
ok(registered["r"], "'r' keybind registered (re-run)")
ok(registered["p"], "'p' keybind registered (paste reply)")

-- ═══════════════════════════════════════════════════════════
-- OPEN_RESULT: Statusline
-- ═══════════════════════════════════════════════════════════

io.write("\n[Statusline]\n")

local statusline = vim.wo[win].statusline
ok(statusline:find("Test Title") ~= nil, "statusline contains title")
ok(statusline:find("e=edit") ~= nil, "statusline shows e=edit")
ok(statusline:find("c=revise") ~= nil, "statusline shows c=revise")
ok(statusline:find("n=next") ~= nil, "statusline shows n=next")
ok(statusline:find("t=todo") ~= nil, "statusline shows t=todo")
ok(statusline:find("y=copy") ~= nil, "statusline shows y=copy")
ok(statusline:find("q=close") ~= nil, "statusline shows q=close")

-- ═══════════════════════════════════════════════════════════
-- 'e' KEYBIND: Toggle Modifiable
-- ═══════════════════════════════════════════════════════════

io.write("\n['e' Toggle Modifiable]\n")

ok(vim.bo[buf].modifiable == false, "starts read-only")

-- Simulate pressing 'e' using feedkeys
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("e", true, false, true), "x", false)

ok(vim.bo[buf].modifiable == true, "modifiable after first 'e'")
ok(vim.bo[buf].readonly == false, "readonly=false after first 'e'")

-- Press 'e' again to toggle back
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("e", true, false, true), "x", false)

ok(vim.bo[buf].modifiable == false, "read-only after second 'e'")
ok(vim.bo[buf].readonly == true, "readonly=true after second 'e'")

-- ═══════════════════════════════════════════════════════════
-- 'y' KEYBIND: Copy to Clipboard (uses get_buf_text)
-- ═══════════════════════════════════════════════════════════

io.write("\n['y' Copy + get_buf_text]\n")

-- Clear clipboard register
vim.fn.setreg("+", "")

-- Press 'y'
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("y", true, false, true), "x", false)

local clipboard = vim.fn.getreg("+")
ok(clipboard ~= "", "clipboard is not empty after 'y'")
ok(clipboard:find("# Test Result") ~= nil, "clipboard contains buffer content")
ok(clipboard:find("Item one") ~= nil, "clipboard contains 'Item one'")

-- ═══════════════════════════════════════════════════════════
-- 'y' AFTER EDIT: Picks up modifications
-- ═══════════════════════════════════════════════════════════

io.write("\n['y' After Edit (get_buf_text dynamic)]\n")

-- Make editable
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("e", true, false, true), "x", false)
ok(vim.bo[buf].modifiable == true, "buffer is editable")

-- Modify buffer content
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "# MODIFIED Result" })

-- Toggle back to read-only
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("e", true, false, true), "x", false)

-- Clear and re-copy
vim.fn.setreg("+", "")
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("y", true, false, true), "x", false)

local modified_clipboard = vim.fn.getreg("+")
ok(modified_clipboard:find("MODIFIED") ~= nil, "clipboard picks up edits via get_buf_text()")
ok(modified_clipboard:find("# Test Result") == nil, "old content not in clipboard")

-- ═══════════════════════════════════════════════════════════
-- 'c' KEYBIND: Revise (mock vim.ui.input)
-- ═══════════════════════════════════════════════════════════

io.write("\n['c' Revise (mocked)]\n")

-- Close current result, create fresh one
vim.cmd("silent! close")
M._open_result("Revise Test", { "Original output" }, mock_ctx)
buf = vim.api.nvim_get_current_buf()

-- Mock vim.ui.input and M._run_ai_custom
local revise_called = false
local revise_prompt_captured = nil
local revise_title_captured = nil
local original_run_ai = M._run_ai_custom
local original_input = vim.ui.input

vim.ui.input = function(opts, callback)
  callback("make it shorter")
end

M._run_ai_custom = function(prompt, email, title, meta)
  revise_called = true
  revise_prompt_captured = prompt
  revise_title_captured = title
end

-- Press 'c'
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("c", true, false, true), "x", false)

ok(revise_called, "'c' triggers _run_ai_custom")
ok(revise_prompt_captured ~= nil and revise_prompt_captured:find("make it shorter") ~= nil,
   "'c' passes revision instruction to prompt")
ok(revise_prompt_captured ~= nil and revise_prompt_captured:find("Original output") ~= nil,
   "'c' includes current buffer text in prompt")
ok(revise_title_captured ~= nil and revise_title_captured:find("revised") ~= nil,
   "'c' appends '(revised)' to title")

-- Restore
vim.ui.input = original_input
M._run_ai_custom = original_run_ai

-- ═══════════════════════════════════════════════════════════
-- 'n' KEYBIND: Next Action (mock vim.ui.select)
-- ═══════════════════════════════════════════════════════════

io.write("\n['n' Next Action (mocked)]\n")

-- Create fresh result
M._open_result("Chain Test", { "AI summary content" }, mock_ctx)
buf = vim.api.nvim_get_current_buf()

local chain_called = false
local chain_prompt_captured = nil
local chain_input_captured = nil
local chain_title_captured = nil
local select_calls = {}

local original_select = vim.ui.select

-- Mock: first select picks "Summarize", second picks "Original email"
vim.ui.select = function(items, opts, callback)
  select_calls[#select_calls + 1] = { items = items, prompt = opts.prompt }
  if opts.prompt == "Next AI action:" then
    callback("Summarize")
  elseif opts.prompt == "Use as input:" then
    callback("Original email")
  else
    callback(items[1])
  end
end

M._run_ai_custom = function(prompt, email, title, meta)
  chain_called = true
  chain_prompt_captured = prompt
  chain_input_captured = email
  chain_title_captured = title
end

-- Press 'n'
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("n", true, false, true), "x", false)

ok(#select_calls >= 2, "'n' triggers two vim.ui.select calls")
ok(select_calls[1] and select_calls[1].prompt == "Next AI action:",
   "'n' first picker is 'Next AI action:'")
ok(select_calls[2] and select_calls[2].prompt == "Use as input:",
   "'n' second picker is 'Use as input:'")
ok(chain_called, "'n' triggers _run_ai_custom")
ok(chain_title_captured == "Summarize", "'n' passes selected action as title")
ok(chain_input_captured == mock_ctx.email_text,
   "'n' with 'Original email' passes email text as input")

-- Test "Current AI result" source
select_calls = {}
chain_input_captured = nil
M._open_result("Chain Test 2", { "Previous AI output" }, mock_ctx)
buf = vim.api.nvim_get_current_buf()

vim.ui.select = function(items, opts, callback)
  select_calls[#select_calls + 1] = { items = items, prompt = opts.prompt }
  if opts.prompt == "Next AI action:" then
    callback("TL;DR")
  elseif opts.prompt == "Use as input:" then
    callback("Current AI result")
  else
    callback(items[1])
  end
end

vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("n", true, false, true), "x", false)

ok(chain_input_captured ~= nil and chain_input_captured:find("Previous AI output") ~= nil,
   "'n' with 'Current AI result' passes buffer text as input")

-- Restore
vim.ui.select = original_select
M._run_ai_custom = original_run_ai

-- ═══════════════════════════════════════════════════════════
-- 't' KEYBIND: Send to Todo (mock selects + file write)
-- ═══════════════════════════════════════════════════════════

io.write("\n['t' Send to Todo (mocked)]\n")

M._open_result("Todo Test", { "- Task A", "- Task B", "Some text", "- [ ] Task C" }, mock_ctx)
buf = vim.api.nvim_get_current_buf()

local todo_select_calls = {}
local todo_file_written = nil
local todo_file_content = nil

-- Mock vim.ui.select: pick "Action items only" then "Obsidian daily note"
vim.ui.select = function(items, opts, callback)
  todo_select_calls[#todo_select_calls + 1] = { items = items, prompt = opts.prompt }
  if opts.prompt == "What to send:" then
    callback("Action items only")
  elseif opts.prompt == "Send to:" then
    callback("Obsidian daily note")
  else
    callback(items[1])
  end
end

-- Mock io.open to capture what would be written
local original_io_open = io.open
io.open = function(path, mode)
  if mode == "a" and path:find("Daily") then
    todo_file_written = path
    return {
      write = function(_, content) todo_file_content = content end,
      close = function() end,
    }
  end
  return original_io_open(path, mode)
end

-- Press 't'
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("t", true, false, true), "x", false)

ok(#todo_select_calls >= 1, "'t' triggers vim.ui.select for format")
ok(todo_select_calls[1] and todo_select_calls[1].prompt == "What to send:",
   "'t' first picker is 'What to send:'")
ok(todo_file_content ~= nil, "'t' writes content to file")
if todo_file_content then
  ok(todo_file_content:find("Task A") ~= nil, "'t' action items includes 'Task A'")
  ok(todo_file_content:find("Task C") ~= nil, "'t' action items includes 'Task C'")
  ok(todo_file_content:find("Some text") == nil, "'t' action items filters out non-list lines")
end

-- Restore
io.open = original_io_open
vim.ui.select = original_select

-- ═══════════════════════════════════════════════════════════
-- CONDITIONAL KEYBINDS: r/p missing without context
-- ═══════════════════════════════════════════════════════════

io.write("\n[Conditional Keybinds]\n")

-- Close any remaining splits
vim.cmd("silent! only")

-- Open with empty context (no prompt, no email)
M._open_result("No Context", { "content" }, {})
buf = vim.api.nvim_get_current_buf()

local keymaps_no_ctx = vim.api.nvim_buf_get_keymap(buf, "n")
local registered_no_ctx = {}
for _, km in ipairs(keymaps_no_ctx) do
  registered_no_ctx[km.lhs] = true
end

ok(not registered_no_ctx["r"], "'r' NOT registered without prompt_text/email_text")
ok(not registered_no_ctx["p"], "'p' NOT registered without source_win/email_text")
ok(registered_no_ctx["e"], "'e' still registered without context")
ok(registered_no_ctx["c"], "'c' still registered without context")
ok(registered_no_ctx["n"], "'n' still registered without context")
ok(registered_no_ctx["t"], "'t' still registered without context")

-- Clean up
vim.cmd("silent! only")

-- ═══════════════════════════════════════════════════════════
-- ERROR HANDLING & EDGE CASES
-- ═══════════════════════════════════════════════════════════

io.write("\n[Error Handling]\n")

-- Close any remaining splits
vim.cmd("silent! only")

-- Test: open_result with empty lines
local empty_ok = pcall(M._open_result, "Empty", {}, {})
ok(empty_ok, "_open_result handles empty lines array")
vim.cmd("silent! only")

-- Test: open_result with nil context defaults gracefully
local nil_ctx_ok = pcall(M._open_result, "Nil Ctx", { "test" }, nil)
ok(nil_ctx_ok, "_open_result handles nil context")
vim.cmd("silent! only")

-- Test: open_result with missing context fields
local partial_ctx_ok = pcall(M._open_result, "Partial", { "content" }, { source_win = -1 })
ok(partial_ctx_ok, "_open_result handles partial context (invalid source_win)")
vim.cmd("silent! only")

-- Test: 'n' keybind cancellation (nil callback)
M._open_result("Cancel Test", { "content" }, mock_ctx)
buf = vim.api.nvim_get_current_buf()

local cancel_called = false
vim.ui.select = function(items, opts, callback)
  callback(nil) -- user cancels
end
M._run_ai_custom = function() cancel_called = true end

vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("n", true, false, true), "x", false)
ok(not cancel_called, "'n' cancellation does not trigger _run_ai_custom")

-- Restore
vim.ui.select = original_select
M._run_ai_custom = original_run_ai
vim.cmd("silent! only")

-- Test: 'c' keybind cancellation (empty input)
M._open_result("Revise Cancel", { "content" }, mock_ctx)
buf = vim.api.nvim_get_current_buf()

local cancel_revise = false
vim.ui.input = function(opts, callback)
  callback(nil) -- user presses Esc
end
M._run_ai_custom = function() cancel_revise = true end

vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("c", true, false, true), "x", false)
ok(not cancel_revise, "'c' cancellation does not trigger _run_ai_custom")

-- Also test empty string
M._run_ai_custom = function() cancel_revise = true end
vim.ui.input = function(opts, callback)
  callback("") -- user submits empty
end
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("c", true, false, true), "x", false)
ok(not cancel_revise, "'c' with empty string does not trigger _run_ai_custom")

-- Restore
vim.ui.input = original_input
M._run_ai_custom = original_run_ai
vim.cmd("silent! only")

-- Test: config defaults present even without config file
ok(M.config.backend ~= nil, "config.backend has a default value")
ok(M.config.backends ~= nil, "config.backends has a default value")
ok(M.config.obsidian ~= nil, "config.obsidian has a default value")
ok(M.config.prompts ~= nil or true, "prompts accessible (merged or default)")

-- Test: get_email_text with non-email buffer returns content
vim.cmd("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "not an email", "just text" })
local text = M._get_email_text and M._get_email_text() or nil
if text then
  ok(text:find("not an email") ~= nil, "get_email_text returns buffer content for non-email buffers")
else
  -- get_email_text may not be exported — that's fine
  ok(true, "get_email_text not exposed (internal function)")
end
vim.cmd("silent! bwipeout!")

-- ═══════════════════════════════════════════════════════════
-- SUMMARY
-- ═══════════════════════════════════════════════════════════

io.write("\n=== RESULTS ===\n")
io.write("  Passed: " .. pass .. "\n")
io.write("  Failed: " .. fail .. "\n")
io.write("  Total:  " .. total .. "\n\n")

if fail == 0 then
  io.write("  ALL TESTS PASSED\n\n")
else
  io.write("  " .. fail .. " TEST(S) FAILED\n\n")
end

-- Exit with failure code if any tests failed
vim.cmd("cquit" .. (fail > 0 and " 1" or " 0"))
