function string.isLetter(c)
	if c == "_" then
		return true
	elseif c >= "A" and c <= "Z" then
		return true
	elseif c >= "a" and c <= "z" then
		return true
	end

	return false
end

function string.isLetterOrDigit(s)
	return string.isLetter(s) or tonumber(s)
end
