local defaults = {
  '#1e1e2e', '#f38ba8', '#a6e3a1', '#f9e2af',
  '#89b4fa', '#cba6f7', '#94e2d5', '#bac2de',
  '#585b70', '#f38ba8', '#a6e3a1', '#f9e2af',
  '#89b4fa', '#cba6f7', '#94e2d5', '#cdd6f4',
}

local c = {}
local cache_file = vim.fn.stdpath('cache') .. '/simp_colors'

local function read_cache()
  local f = io.open(cache_file, 'r')
  if not f then return false end
  for line in f:lines() do
    local idx, hex = line:match('(%d+)=(#?%x+)')
    if idx then c[tonumber(idx)] = hex end
  end
  f:close()
  for i = 0, 15 do if not c[i] then return false end end
  return true
end

local function write_cache()
  local f, err = io.open(cache_file, 'w')
  if not f then return end
  for i = 0, 15 do
    if c[i] then f:write(i .. '=' .. c[i] .. '\n') end
  end
  f:close()
end

local function fill_defaults()
  for i = 0, 15 do
    c[i] = c[i] or defaults[i + 1]
  end
end

local query_script_path = vim.fn.stdpath('config') .. '/colors/query_simp_colors.py'

local function ensure_query_script()
  local f = io.open(query_script_path, 'w')
  if not f then return end
  f:write([[
import termios, tty, os, select, re, sys, signal
signal.signal(signal.SIGTTOU, signal.SIG_IGN)
signal.signal(signal.SIGTTIN, signal.SIG_IGN)
try:
    fd = os.open('/dev/tty', os.O_RDWR)
except OSError:
    sys.exit(1)
attrs = termios.tcgetattr(fd)
tty.setraw(fd)
qs = b''.join(f'\x1b]4;{i};?\x07'.encode() for i in range(16))
os.write(fd, qs)
resp = b''
r,_,_ = select.select([fd],[],[],0.5)
if r:
    while True:
        r2,_,_ = select.select([fd],[],[],0.15)
        if not r2: break
        b = os.read(fd, 4096)
        if not b: break
        resp += b
termios.tcsetattr(fd, termios.TCSADRAIN, attrs)
os.close(fd)
colors = {}
for m in re.finditer(r'\x1b\]4;(\d+);rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)', resp.decode(errors='replace')):
    i = int(m.group(1))
    r = int(m.group(2), 16) // 257
    g = int(m.group(3), 16) // 257
    b = int(m.group(4), 16) // 257
    sys.stdout.write(f'{i}=#{r:02x}{g:02x}{b:02x}\n')
if len(colors) < 16:
    sys.exit(1)
]])
  f:close()
end

local function query_from_within()
  local cmd = ('python3 "%s" > "%s" 2>/dev/null'):format(query_script_path, cache_file)
  vim.cmd('silent !' .. cmd)
  local rf = io.open(cache_file, 'r')
  if rf then
    for line in rf:lines() do
      local idx, hex = line:match('(%d+)=(#?%x+)')
      if idx then c[tonumber(idx)] = hex end
    end
    rf:close()
  end
end

ensure_query_script()

if not read_cache() then
  query_from_within()
  fill_defaults()
end

local bg    = c[0]
local fg    = c[7]
local gray  = c[8]
local red   = c[1]
local green = c[2]
local yellow = c[3]
local blue  = c[4]
local purple = c[5]
local cyan  = c[6]
local brfg  = c[15]

local hl = vim.api.nvim_set_hl

local function h(group, opts)
  hl(0, group, opts)
end

-- Editor UI
h('Normal',       { fg = fg, bg = bg })
h('NormalFloat',  { fg = fg, bg = bg })
h('NormalSB',     { fg = fg, bg = bg })
h('Cursor',       { reverse = true })
h('CursorIM',     { reverse = true })
h('TermCursor',   { reverse = true })
h('Visual',       { bg = gray })
h('VisualNOS',    { bg = gray })
h('Search',       { fg = bg, bg = yellow })
h('IncSearch',    { fg = bg, bg = yellow, bold = true })
h('CurSearch',    { link = 'IncSearch' })
h('MatchParen',   { bold = true, underline = true })
h('Substitute',   { fg = bg, bg = green })

-- Syntax
h('Comment',      { fg = gray, italic = true })
h('Constant',     { fg = purple })
h('String',       { fg = green })
h('Character',    { fg = green })
h('Number',       { fg = purple })
h('Float',        { fg = purple })
h('Boolean',      { fg = purple, bold = true })
h('Identifier',   { fg = fg })
h('Function',     { fg = blue })
h('Statement',    { fg = purple })
h('Conditional',  { fg = purple })
h('Repeat',       { fg = purple })
h('Label',        { fg = fg })
h('Operator',     { fg = fg })
h('Keyword',      { fg = purple })
h('Exception',    { fg = purple })
h('PreProc',      { fg = cyan })
h('Include',      { fg = cyan })
h('Define',       { fg = cyan })
h('Macro',        { fg = cyan })
h('PreCondit',    { fg = cyan })
h('Type',         { fg = yellow })
h('StorageClass', { fg = yellow })
h('Structure',    { fg = yellow })
h('Typedef',      { fg = yellow })
h('Special',      { fg = purple })
h('SpecialChar',  { fg = purple })
h('Tag',          { fg = red })
h('Delimiter',    { fg = fg })
h('SpecialComment', { fg = gray, italic = true })
h('Debug',        { fg = red })
h('Underlined',   { underline = true })
h('Ignore',       { fg = bg })
h('Error',        { fg = red, bold = true })
h('Todo',         { fg = yellow, bold = true })

-- Treesitter groups that differ from linked defaults
h('@variable',          { fg = fg })
h('@variable.builtin',  { fg = cyan })
h('@parameter',         { fg = fg })
h('@parameter.reference', { fg = fg })
h('@property',          { fg = cyan })
h('@field',             { fg = fg })
h('@constructor',       { fg = yellow })
h('@operator',          { fg = fg })
h('@punctuation.delimiter', { fg = fg })
h('@punctuation.bracket',   { fg = fg })
h('@punctuation.special',   { fg = purple })
h('@keyword.function',      { fg = purple })
h('@keyword.return',        { fg = purple })
h('@keyword.operator',      { fg = fg })
h('@string.regex',          { fg = cyan })
h('@string.escape',         { fg = cyan })
h('@character.special',     { fg = cyan })
h('@number.float',          { fg = purple })
h('@function.builtin',      { fg = blue })
h('@function.macro',        { fg = cyan })
h('@method',                { fg = blue })
h('@method.call',           { fg = blue })
h('@type.builtin',          { fg = yellow })
h('@type.definition',       { fg = yellow })
h('@constant.builtin',      { fg = purple })
h('@constant.macro',        { fg = cyan })
h('@attribute',             { fg = cyan })
h('@attribute.builtin',     { fg = cyan })
h('@tag',                   { fg = red })
h('@tag.attribute',         { fg = cyan })
h('@tag.delimiter',         { fg = gray })
h('@text.strong',           { bold = true })
h('@text.emphasis',         { italic = true })
h('@text.underline',        { underline = true })
h('@text.strike',           { strikethrough = true })
h('@text.title',            { fg = blue, bold = true })
h('@text.literal',          { fg = green })
h('@text.quote',            { fg = gray, italic = true })
h('@text.reference',        { fg = yellow })
h('@text.environment',      { fg = cyan })
h('@text.environment.name', { fg = yellow })
h('@text.note',             { fg = bg, bg = blue, bold = true })
h('@text.warning',          { fg = bg, bg = yellow, bold = true })
h('@text.danger',           { fg = bg, bg = red, bold = true })
h('@diff.plus',             { fg = green })
h('@diff.minus',            { fg = red })
h('@diff.delta',            { fg = yellow })

-- Diagnostic
h('DiagnosticError',        { fg = red })
h('DiagnosticWarn',         { fg = yellow })
h('DiagnosticInfo',         { fg = blue })
h('DiagnosticHint',         { fg = cyan })
h('DiagnosticOk',           { fg = green })
h('DiagnosticUnderlineError', { undercurl = true, sp = red })
h('DiagnosticUnderlineWarn',  { undercurl = true, sp = yellow })
h('DiagnosticUnderlineInfo',  { undercurl = true, sp = blue })
h('DiagnosticUnderlineHint',  { undercurl = true, sp = cyan })
h('DiagnosticUnderlineOk',    { undercurl = true, sp = green })
h('DiagnosticVirtualTextError', { fg = red })
h('DiagnosticVirtualTextWarn',  { fg = yellow })
h('DiagnosticVirtualTextInfo',  { fg = blue })
h('DiagnosticVirtualTextHint',  { fg = cyan })
h('DiagnosticFloatingError',    { fg = red })
h('DiagnosticFloatingWarn',     { fg = yellow })
h('DiagnosticFloatingInfo',     { fg = blue })
h('DiagnosticFloatingHint',     { fg = cyan })
h('DiagnosticSignError',        { fg = red })
h('DiagnosticSignWarn',         { fg = yellow })
h('DiagnosticSignInfo',         { fg = blue })
h('DiagnosticSignHint',         { fg = cyan })

-- LSP
h('LspReferenceText',  { bg = gray })
h('LspReferenceRead',  { bg = gray })
h('LspReferenceWrite', { bg = gray })
h('LspInlayHint',      { fg = gray })

-- UI
h('LineNr',           { fg = gray })
h('CursorLineNr',     { fg = brfg, bold = true })
h('CursorLine',       { bg = bg })
h('CursorColumn',     { bg = bg })
h('ColorColumn',      { bg = gray })
h('SignColumn',       { bg = bg })
h('FoldColumn',       { bg = bg })
h('Folded',           { fg = gray })
h('VertSplit',        { fg = gray })
h('WinSeparator',     { fg = gray })
h('StatusLine',       { fg = brfg, bg = gray })
h('StatusLineNC',     { fg = gray, bg = bg })
h('TabLine',          { fg = gray, bg = bg })
h('TabLineSel',       { fg = brfg, bg = bg, bold = true })
h('TabLineFill',      { bg = bg })
h('Title',            { fg = blue, bold = true })
h('Question',         { fg = blue })
h('MoreMsg',          { fg = green })
h('WarningMsg',       { fg = yellow })
h('ErrorMsg',         { fg = red, bold = true })
h('ModeMsg',          { bold = true })
h('NonText',          { fg = gray })
h('SpecialKey',       { fg = gray })
h('Whitespace',       { fg = gray })
h('Conceal',          { fg = gray })
h('EndOfBuffer',      { fg = gray })
h('WinBar',           { fg = fg })
h('WinBarNC',         { fg = gray })

-- Pmenu (completions)
h('Pmenu',            { fg = fg, bg = gray })
h('PmenuSel',         { fg = bg, bg = blue, bold = true })
h('PmenuKind',        { fg = purple, bg = gray })
h('PmenuKindSel',     { fg = bg, bg = purple })
h('PmenuExtra',       { fg = gray, bg = gray })
h('PmenuExtraSel',    { fg = bg, bg = blue })
h('PmenuSbar',        { bg = gray })
h('PmenuThumb',       { bg = brfg })

-- Float / Popup
h('FloatBorder',      { fg = gray })
h('FloatTitle',       { fg = blue, bold = true })

-- Diff
h('DiffAdd',          { fg = green })
h('DiffChange',       { fg = yellow })
h('DiffDelete',       { fg = red })
h('DiffText',         { fg = blue })
h('diffAdded',        { link = 'DiffAdd' })
h('diffRemoved',      { link = 'DiffDelete' })

-- GitSigns
h('GitSignsAdd',      { fg = green })
h('GitSignsChange',   { fg = yellow })
h('GitSignsDelete',   { fg = red })
h('GitSignsAddLn',    { fg = green })
h('GitSignsChangeLn', { fg = yellow })
h('GitSignsDeleteLn', { fg = red })
h('GitSignsAddNr',    { fg = green })
h('GitSignsChangeNr', { fg = yellow })
h('GitSignsDeleteNr', { fg = red })

-- Mini statusline
h('MiniStatuslineModeNormal',   { fg = bg, bg = blue, bold = true })
h('MiniStatuslineModeInsert',   { fg = bg, bg = green, bold = true })
h('MiniStatuslineModeVisual',   { fg = bg, bg = purple, bold = true })
h('MiniStatuslineModeReplace',  { fg = bg, bg = red, bold = true })
h('MiniStatuslineModeCommand',   { fg = bg, bg = yellow, bold = true })
h('MiniStatuslineFilename',     { fg = fg, bg = gray })
h('MiniStatuslineDevinfo',      { fg = fg, bg = gray })
h('MiniStatuslineFileinfo',     { fg = fg, bg = gray })
h('MiniStatuslineInactive',     { fg = gray, bg = bg })

-- WhichKey
h('WhichKey',          { fg = cyan, bold = true })
h('WhichKeyGroup',     { fg = purple })
h('WhichKeyDesc',      { fg = fg })
h('WhichKeySeparator', { fg = gray })
h('WhichKeyFloat',     { bg = bg })
h('WhichKeyBorder',    { fg = gray })

-- Telescope
h('TelescopeNormal',       { fg = fg, bg = bg })
h('TelescopeBorder',       { fg = gray, bg = bg })
h('TelescopePromptNormal', { fg = fg, bg = bg })
h('TelescopePromptBorder', { fg = blue, bg = bg })
h('TelescopePromptTitle',  { fg = bg, bg = blue, bold = true })
h('TelescopeResultsTitle', { fg = bg, bg = green, bold = true })
h('TelescopePreviewTitle', { fg = bg, bg = cyan, bold = true })
h('TelescopeSelection',    { fg = blue, bold = true })
h('TelescopeMatching',     { fg = yellow })
h('TelescopePromptPrefix', { fg = blue })
h('TelescopeResultsDiffAdd',    { fg = green })
h('TelescopeResultsDiffChange', { fg = yellow })
h('TelescopeResultsDiffDelete', { fg = red })

-- TodoComments
h('TodoFgFg',         { fg = fg })
h('TodoBgFg',         { fg = fg })
h('TodoSignTodo',     { fg = blue })
h('TodoSignFix',      { fg = purple })
h('TodoSignHack',     { fg = yellow })
h('TodoSignPerf',     { fg = cyan })
h('TodoSignWarn',     { fg = yellow })
h('TodoSignNote',     { fg = blue })
h('TodoSignTest',     { fg = green })

vim.api.nvim_create_user_command('SimpRefresh', function()
  os.remove(cache_file)
  vim.cmd('colorscheme simp')
  vim.cmd([[
    highlight Normal guibg=NONE ctermbg=NONE
    highlight NormalNC guibg=NONE ctermbg=NONE
    highlight SignColumn guibg=NONE ctermbg=NONE
    highlight LineNr guibg=NONE ctermbg=NONE
    highlight CursorLineNr guibg=NONE ctermbg=NONE
    highlight FoldColumn guibg=NONE ctermbg=NONE
    highlight EndOfBuffer guibg=NONE ctermbg=NONE
  ]])
end, { desc = 'Re-query terminal colors and re-apply (may flash screen)' })

vim.api.nvim_create_user_command('SimpDebug', function()
  print('Active colors:')
  for i = 0, 15 do
    print(string.format('  c[%d] = %s', i, c[i] or 'nil'))
  end
  print('')
  print('To query from your terminal (reliable):')
  print(string.format('  python3 %s > %s', query_script_path, cache_file))
  print('')
  print('To query from within Neovim (:! approach):')
  print(string.format('  :!python3 %s > %s', query_script_path, cache_file))
end, { desc = 'Show active colors and query instructions' })
