utils = require "mp.utils"

-- test available filename
function slow_start()
  local basename = mp.get_property("filename"):gsub("%.([^%.]+)$", "")
  local screenshot_folder = mp.get_property("screenshot-directory") or ""

  function filename(idx)
    return utils.join_path(
      screenshot_folder,
      basename .. '-' .. string.format("%04d",idx) .. '.mp4'
    )
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

function export_loop_clip()
  local a = mp.get_property_number("ab-loop-a")
  local b = mp.get_property_number("ab-loop-b")
  local path = mp.get_property("path")
  if a and b then
    local outfile = slow_start()
    local cmd = {
      'ffmpeg',
      '-hide_banner',
      '-ss', tostring(a),
      '-i', path,
      '-t', tostring(b-a),
      '-c:v', 'libx264',
      '-crf', '22',
      '-pix_fmt', 'yuv420p',
      '-filter_complex', 'scale=iw*min(1\\,min(1280/iw\\,720/ih)):-2',
      '-an', '-sn',
      '-map_metadata', '-1',
      -- '-map', '0',
      '-v', 'error',
      outfile
    }
    local args = { args = cmd }
    local result = utils.subprocess(args)
    if result["status"] == 0 then
      mp.msg.info('save clip ' .. outfile)
      mp.osd_message('save clip ' .. outfile)
    else
      mp.msg.info(result["error_string"] .. result["status"])
      mp.osd_message("export loop clip error")
    end
  end
end
mp.register_script_message("export-loop-clip", export_loop_clip)

function set_ab_loop_a()
  local pos = mp.get_property_number("time-pos")
  local a = mp.get_property_number("ab-loop-a")
  mp.set_property_number("ab-loop-a", pos)
  mp.osd_message('set A-B loop A: ' .. tostring(pos))
end
mp.register_script_message("set-ab-loop-a", set_ab_loop_a)

function set_ab_loop_b()
  local pos = mp.get_property_number("time-pos")
  mp.set_property_number("ab-loop-b", pos)
  mp.osd_message('set A-B loop B: ' .. tostring(pos))
end
mp.register_script_message("set-ab-loop-b", set_ab_loop_b)

function seek_ab_loop_a()
  local pos = mp.get_property_number("ab-loop-a")
  if pos then
    mp.set_property_number("time-pos", pos)
  end
end
mp.register_script_message("seek-ab-loop-a", seek_ab_loop_a)

function seek_ab_loop_b()
  local pos = mp.get_property_number("ab-loop-b")
  if pos then
    mp.set_property_number("time-pos", pos)
  end
end
mp.register_script_message("seek-ab-loop-b", seek_ab_loop_b)
