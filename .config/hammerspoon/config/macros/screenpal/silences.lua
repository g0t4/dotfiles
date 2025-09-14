---@class Silence
---@field x_start number
---@field x_end number
local Silence = {}
Silence.__index = Silence

function Silence:x_width()
    return self.x_end - self.x_start
end

function Silence.new(what)
    what = what or {}
    return setmetatable(what, { __index = Silence })
end

function Silence:x_start_pad_percent(ratio)
    -- compute the padding start if silence is shrunk to ratio/1.0
    -- i.e. padding for 90% of silence would be 10%/2 => 5% of width on each side
    local padding = self:x_width() * ratio / 2
    return self.x_start + padding
end

---@alias DetectionResults { short_silences: Silence[], regular_silences: Silence[], tool: { type: string, x_start: number, x_end: number}}

---@class SilencesController
---@field regular Silence[]
---@field short Silence[]
---@field all Silence[]
---@field hack_detected DetectionResults -- for experimenting, redesign later
---@field _timeline TimelineController -- mostly for internal use
local SilencesController = {}

---@param detected DetectionResults
---@param timeline TimelineController
---@return SilencesController
function SilencesController:new(detected, timeline)
    ---@type Silence[]
    local regular_shallow_clone =
        vim.iter(detected.regular_silences)
        :map(Silence.new)
        :totable()

    ---@type Silence[]
    local short_shallow_clone =
        vim.iter(detected.short_silences)
        :filter(function(s)
            --   can always put in a new list if useful
            --   zoom2 => 3 pixels per frame
            --   zoom3 => 6 pixels per frame
            --   so lets skip 6 pixels is reasonable (2 frames in zoom2)
            --   I won't be using silences when zoom is off, nor likely in zoom1
            return s.x_end - s.x_start >= 6
        end)
        :map(Silence.new)
        :totable()

    table.sort(regular_shallow_clone, function(a, b)
        return a.x_start < b.x_start
    end)
    table.sort(short_shallow_clone, function(a, b)
        return a.x_start < b.x_start
    end)

    ---@type Silence[]
    local all = vim.list_extend(regular_shallow_clone, short_shallow_clone)
    table.sort(all, function(a, b)
        return a.x_start < b.x_start
    end)

    local obj = {
        regular = regular_shallow_clone,
        short = short_shallow_clone,
        all = all,
        _timeline = timeline,
        hack_detected = detected,
    }

    setmetatable(obj, { __index = self })
    return obj
end

---@return vim.iter<Silence> -- TODO type hint?
function SilencesController:get_silences_that_start_after_playhead()
    -- that START after the playhead
    local playhead_x = self._timeline._playhead_timeline_relative_x
    return vim.iter(self.all):filter(function(silence)
        return playhead_x < silence.x_start
    end)
end

function SilencesController:get_silences_that_end_before_playhead()
    -- that END before the playhead
    local playhead_x = self._timeline._playhead_timeline_relative_x
    return vim.iter(self.all):filter(function(silence)
        return silence.x_end < playhead_x
    end)
end

---@return Silence?
function SilencesController:get_next_silence()
    return self:get_silences_that_start_after_playhead():next()
end

---@return Silence?
function SilencesController:get_prev_silence()
    return self:get_silences_that_end_before_playhead():last()
end

---@return Silence?
function SilencesController:get_this_silence()
    local playhead_x = self._timeline._playhead_timeline_relative_x
    return vim.iter(self.all)
        :filter(function(silence)
            return silence.x_start <= playhead_x
                and playhead_x <= silence.x_end
        end)
        :next() -- first one is fine, should only ever be one anyways
end

-- TODO highlight canvas elements should probably move here

return SilencesController
