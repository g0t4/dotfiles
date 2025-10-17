local TimelineController = require('config.macros.screenpal.timeline')

describe('timeline - zoom 2 @ 3 pixels/frame', function()
    local timeline = {}
    function timeline:pixels_per_frame()
        return 3
    end

    local known_frame_x = 30

    it('intended_x == known_x', function()
        local left, right = TimelineController.calculate_frame_bounds(timeline, known_frame_x, known_frame_x)
        assert.are.equals(27, left)
        assert.are.equals(30, right)
        -- FYI could go either way, left is before or right is after, when intended is known frame
    end)

    it('intended_x < known_x', function()
        it('between frames - 1 pixel left', function()
            local intended_x = 29 -- known_frame_x - 1
            local left, right = TimelineController.calculate_frame_bounds(timeline, intended_x, known_frame_x)
            assert.are.equals(27, left)
            assert.are.equals(known_frame_x, right)
        end)
        it('over 1 PPF left, between frames', function()
            local intended_x = 26 -- known_frame_x - PPF - 1
            local left, right = TimelineController.calculate_frame_bounds(timeline, intended_x, known_frame_x)
            assert.are.equals(24, left)
            assert.are.equals(27, right)
        end)
    end)

    it('known_x < intended_x', function()
        it('between frames - 1 pixel right', function()
            local intended_x = 31 -- known_frame_x + 1
            local left, right = TimelineController.calculate_frame_bounds(timeline, intended_x, known_frame_x)
            assert.are.equals(known_frame_x, left)
            assert.are.equals(33, right)
        end)
        it('over 1 PPF right, between frames', function()
            local intended_x = 34 -- known_frame_x + PPF + 1
            local left, right = TimelineController.calculate_frame_bounds(timeline, intended_x, known_frame_x)
            assert.are.equals(33, left)
            assert.are.equals(36, right)
        end)
    end)

    it('intended_x is on a frame, right then is intended_x', function()
        local intended_x = 27
        -- TODO where do I want this?
        local known_frame_x = 30

        local left, right = TimelineController.calculate_frame_bounds(timeline, intended_x, known_frame_x)
        assert.are.equals(24, left)
        assert.are.equals(27, right)
        -- TODO should I adjust to return nil value for second frame? or first or? to signal its on a frame boundary?
    end)
end)
