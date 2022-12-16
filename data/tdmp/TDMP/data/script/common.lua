function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end


function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end


function startsWith(str, start)
	return string.sub(str, 1, string.len(start)) == start
end

function splitString(str, delimiter)
	local result = {}
	for word in string.gmatch(str, '([^'..delimiter..']+)') do
		result[#result+1] = trim(word)
	end
	return result
end


function hasWord(str, word)
	local words = splitString(str, " ")
	for i=1,#words do
		if string.lower(words[i]) == string.lower(word) then
			return true
		end
	end
	return false
end

function smoothstep(edge0, edge1, x)
	x = math.clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return x * x * (3 - 2 * x)
end


function math.clamp(val, lower, upper)
    if lower > upper then lower, upper = upper, lower end -- swap if boundaries supplied the wrong way
    return math.max(lower, math.min(upper, val))
end


function progressBar(w, h, t)
	UiPush()
		UiAlign("left top")
		UiColor(0, 0, 0, 0.5)
		UiImageBox("ui/common/box-solid-10.png", w, h, 6, 6)
		if t > 0 then
			UiTranslate(2, 2)
			w = (w-4)*t
			if w < 12 then w = 12 end
			h = h-4
			UiColor(1,1,1,1)
			UiImageBox("ui/common/box-solid-6.png", w, h, 6, 6)
		end
	UiPop()
end


--Draw hint box with arrow to the left, pointing at cursor position
function drawHintArrow(str)
	UiPush()
		UiAlign("middle left")
		UiColor(1,1,1, 0.7)
		local w,h = UiImage("common/arrow-left.png")
		UiTranslate(w-1, 0)
		UiFont("bold.ttf", 22)
		 w,h = UiGetTextSize(str)
		UiImageBox("common/box-solid-6.png", w+40, h+12, 6, 6)
		UiPush()
			UiColor(0,0,0)
			UiTranslate(20, 0)
			UiText(str)
		UiPop()
	UiPop()
end

