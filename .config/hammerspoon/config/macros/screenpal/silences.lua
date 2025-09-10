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
    local short = vim.iter(results.short_silences)
        :filter(function(s)
            --   can always put in a new list if useful
            --   zoom2 => 3 pixels per frame
            --   zoom3 => 6 pixels per frame
            --   so lets skip 6 pixels is reasonable (2 frames in zoom2)
            --   I won't be using silences when zoom is off, nor likely in zoom1
            return s.x_end - s.x_start >= 6
        end)
        :totable()

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
