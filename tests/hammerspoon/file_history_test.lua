-- Run from the checkout: lua tests/hammerspoon/file_history_test.lua
-- Verify that filenames/provenance are inert text in the metadata inspector.
package.loaded['config.logs'] = {launcher=function() return {} end}
local history = dofile('.config/hammerspoon/config/launcher/file_history.lua')
local entry = {
    path='/tmp/<script>alert("file")</script>&.pdf',
    normal_search='Hidden: missing', match_score=42, note='<unsafe note>',
    filesystem={status='missing', reason='<unsafe reason>'},
    sources={{source='File-open history', database='/tmp/<store>', opens=3,
              last_open=1000, usage_score=2, reason='Accepted open',
              recorded_by={{source='pip-rot', opens=3, last_open=1000}}}},
    warnings={'<unsafe warning>'},
}
local html = history.inspectorHTML(entry)
assert(not html:find('<script>', 1, true))
assert(html:find('&lt;script&gt;', 1, true))
assert(html:find('&amp;.pdf', 1, true))
assert(html:find('&lt;unsafe warning&gt;', 1, true))
assert(html:find('pip-rot: 3 opens', 1, true))
assert(html:find('Hidden: missing', 1, true))
assert(html:find('Read-only inspection', 1, true))
print('PASS: escaped filenames, provenance, warnings, and missing-path inspector')
