---@class SilencesController
---@field regular Silence[]
---@field short Silence[]
---@field all Silence[]
---@field _timeline TimelineController -- mostly for internal use
local SilencesController = {}

---@param results DetectionResults
---@param timeline TimelineController
---@return SilencesController
function SilencesController:new(results, timeline)
    ---@type Silence[]
    local regular = vim.tbl_deep_extend("force", {}, results.regular_silences)

    ---@type Silence[]
    local short = vim.tbl_deep_extend("force", {}, results.short_silences)
    table.sort(regular, function(a, b)
        return a.x_start < b.x_start
    end)
    table.sort(short, function(a, b)
        return a.x_start < b.x_start
    end)

    ---@type Silence[]
    local all = vim.tbl_extend("force", regular, short)
    table.sort(all, function(a, b)
        return a.x_start < b.x_start
    end)

    -- TODO filter out silences that are too short to care about?
    --   can always put them in a new list at some point if I want them
    --   zoom2 => 3 pixels per frame
    --   zoom3 => 6 pixels per frame
    --   so maybe filter out any silence < 6 pixels? that would cover both and get two frames worth minimum in zoom 2?

    local obj = {
        regular = regular,
        short = short,
        all = all,
        _timeline = timeline,
    }

    setmetatable(obj, { __index = self })
    return obj
end

---@return vim.iter<Silence> -- TODO type hint?
function SilencesController:get_silences_that_start_after_playhead()
    -- that START after the playhead
    local playhead_x = self._timeline._playhead_timeline_relative_x
    return vim.iter(self.all):filter(function(silence)
        return playhead_x <= silence.x_start
    end)
end

function SilencesController:get_silences_that_end_before_playhead()
    -- that END before the playhead
    local playhead_x = self._timeline._playhead_timeline_relative_x
    return vim.iter(self.all):filter(function(silence)
        return silence.x_end <= playhead_x
    end)
end

---@return Silence?
function SilencesController:get_next_silence()
    return self:get_silences_that_start_after_playhead():next()
end

---@return Silence?
function SilencesController:get_previous_silence()
    return self:get_silences_that_end_before_playhead():last()
end

-- TODO highlight canvas elements should probably move here

return SilencesController
