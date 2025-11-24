local NoteContext = {}
-- TODO do I want to wrap notes as I load them and give them behavior?
--  if so I could easily create a Note type and have it delegate out to this type in its ctor

---Create a new NoteContext instance
---@param before string[]
---@param after string[]
---@param selection string
---@return NoteContext
function NoteContext:new(before, after, selection)
    local obj = {
        before = before or {},
        after = after or {},
        selection = selection or "",
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

---Add a line to the beginning of the before buffer
---@param line string
function NoteContext:add_before_line(line)
    table.insert(self.before, 1, line)
end

---Add a line to the end of the after buffer
---@param line string
function NoteContext:add_after_line(line)
    table.insert(self.after, line)
end

---Replace the current selection
---@param new_selection string
function NoteContext:set_selection(new_selection)
    self.selection = new_selection
end

return NoteContext
