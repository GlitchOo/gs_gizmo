local LocaleFile = LoadResourceFile(U.Cache.Resource, ('locales/%s.json'):format(Config.Locale or 'en'))
local Locales = json.decode(LocaleFile)

function _(str, ...)
	if Locales then
		if Locales[str] then
			return (Locales[str]):format(...)
		end
    end

	return str:format(...)
end

function _U(str, ...)
	return tostring(_(str, ...):gsub("^%l", string.upper))
end