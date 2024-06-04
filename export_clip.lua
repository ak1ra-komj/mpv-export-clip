utils = require "mp.utils"

-- test available filename
function test_outfile()
    local basename = mp.get_property("filename"):gsub("%.([^%.]+)$", "")
    local screenshot_folder = mp.get_property("screenshot-directory") or ""

    function filename(idx)
        return utils.join_path(screenshot_folder, basename .. '-' .. string.format("%04d", idx) .. '.mp4')
    end

    -- multiply
    local inc = 1
    while utils.file_info(filename(inc)) do
        inc = inc * 2
    end

    -- narrowing
    local lower_bound = math.floor(inc / 2)
    while inc - lower_bound > 1 do
        local mid = math.floor((inc + lower_bound) / 2)
        local is_file = utils.file_info(filename(mid))
        if is_file then
            lower_bound = mid
        else
            inc = mid
        end
    end

    return filename(inc)
end

function set_ab_loop_a()
    local pos = mp.get_property_number("time-pos")
    mp.set_property_number("ab-loop-a", pos)
    mp.osd_message('set A-B loop A: ' .. tostring(pos))
end

function set_ab_loop_b()
    local pos = mp.get_property_number("time-pos")
    mp.set_property_number("ab-loop-b", pos)
    mp.osd_message('set A-B loop B: ' .. tostring(pos))
end

function seek_ab_loop_a()
    local pos = mp.get_property_number("ab-loop-a")
    if pos then
        mp.set_property_number("time-pos", pos)
    end
end

function seek_ab_loop_b()
    local pos = mp.get_property_number("ab-loop-b")
    if pos then
        mp.set_property_number("time-pos", pos)
    end
end

function export_loop_clip()
    local a = mp.get_property_number("ab-loop-a")
    local b = mp.get_property_number("ab-loop-b")
    local path = mp.get_property("path")
    -- Get the track list
    -- https://mpv.io/manual/master/#command-interface-track-list
    local tracks = mp.get_property_native("track-list")
    local sub_track = nil

    -- Find the active subtitle track
    for _, track in ipairs(tracks) do
        if track.type == "sub" and track.selected then
            sub_track = track
            break
        end
    end

    if a and b then
        local infile = {}
        local outfile = test_outfile()
        local scale_filter = "scale=iw*min(1\\,min(1280/iw\\,720/ih)):-2"
        local sub_filter = ""

        if sub_track then
            if sub_track.external then
                local ext = string.match(sub_track["external-filename"], "%.([^%.]+)$")
                local sub_file = mp.command_native({"expand-path", sub_track["external-filename"]})
                table.insert(infile, "-i")
                table.insert(infile, sub_file)

                if ext == "srt" then
                    sub_filter = "subtitles=" .. sub_file:gsub("\\", "\\\\")
                elseif ext == "ass" then
                    sub_filter = "ass=" .. sub_file:gsub("\\", "\\\\")
                end
            else
                local codec = sub_track.codec
                if codec == "subrip" then
                    sub_filter = "subtitles=" .. path:gsub("\\", "\\\\") .. ":si=" .. tostring(sub_track["ff-index"])
                elseif codec == "ass" then
                    sub_filter = "ass=" .. path:gsub("\\", "\\\\") .. ":si=" .. tostring(sub_track["ff-index"])
                end
            end
        end

        local filter_complex = "[0:v]" .. scale_filter
        if sub_filter ~= "" then
            filter_complex = filter_complex .. "," .. sub_filter
        end
        filter_complex = filter_complex .. "[out]"

        local cmd = {"run", "ffmpeg", "-nostdin", "-n", "-loglevel", "info", "-ss", tostring(a), "-i", path, "-t",
                     tostring(b - a), "-c:v", "libx264", "-b:v", "3000k", "-crf", "21", "-preset", "placebo",
                     "-pix_fmt", "yuva420p", "-map_metadata", "-1", "-filter_complex", filter_complex, "-map", "[out]",
                     outfile}

        -- intert external sub_file after -i path
        local infile_pos = 11
        for i = #infile, 1, -1 do
            table.insert(cmd, infile_pos, infile[i])
        end

        mp.command_native_async(cmd, function(success, result, error)
            if success then
                mp.msg.info("mp.command_native_async cmd -> " .. table.concat(cmd, " "))
                mp.msg.info("mp.command_native_async result -> " .. tostring(result))
                mp.msg.info("save clip " .. outfile)
                mp.osd_message("save clip " .. outfile)
            else
                mp.msg.info(error)
                mp.osd_message("export loop clip error: " .. error)
            end
        end)
    end
end

-- register_script_message
mp.register_script_message("set-ab-loop-a", set_ab_loop_a)
mp.register_script_message("set-ab-loop-b", set_ab_loop_b)
mp.register_script_message("seek-ab-loop-a", seek_ab_loop_a)
mp.register_script_message("seek-ab-loop-b", seek_ab_loop_b)
mp.register_script_message("export-loop-clip", export_loop_clip)
