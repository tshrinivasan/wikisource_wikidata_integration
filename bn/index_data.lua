--[[Retrieves the data from the index page and enriches it with Wikidata]]--

local wikidataTypeToIndexType = {
	['Q3331189'] = 'book',
	['Q1238720'] = 'journal',
	['Q28869365'] = 'journal',
	['Q191067'] = 'journal',
	['Q23622'] = 'dictionary',
	['Q187685'] = 'phdthesis'
}
local indexToWikidata = {
	-- type and title are specially managed
    ['subtitle'] =  'P1680',
    ['volume'] = 'P478',
    ['edition'] = 'P393',   
    ['author'] = 'P50',
    ['translator'] = 'P655',
    ['editor'] = 'P98',
    ['illustrator'] = 'P110',
    ['publisher'] = 'P123',
    ['printer'] = 'P872',
    ['address'] = 'P291',
--    ['year'] = 'P577',
}

function indexDataWithWikidata(frame)
	--create a clean table of parameters with blank parameters removed
	local args = {}
	for k,v in pairs(frame.args) do
		if v ~= '' then
			args[k] = v
		end
	end
	
	local item = nil
	if args.wikidata_item then
		item = mw.wikibase.getEntity(args.wikidata_item)
		if item == nil then
			mw.addWarning('L\'identifiant d\'Wikidata entity [[d:' .. args.wikidata_item .. '|' .. args.wikidata_item .. ']] put in the "Wikidata entity" parameter of the Book page: does not seem valid.') 
		end
	end
	if not item then
		return {
			['args'] = args,
			['item'] = nil
		}
	end

	-- type from Wikidata
	if not args.type then
		for _, statement in pairs(item:getBestStatements('P31')) do
			if statement.mainsnak.datavalue ~= nil then
				local typeId = statement.mainsnak.datavalue.value
				if wikidataTypeToIndexType[typeId] then
					args.type = wikidataTypeToIndexType[typeId] 
				end
			end
		end
	end
	
	-- image depuis Wikidata
	if not args.image then
		for _, statement in pairs(item:getBestStatements('P18')) do
			if statement.mainsnak.datavalue.value ~= nil then
				args.image = statement.mainsnak.datavalue.value
			end
		end
	end
	
	-- title depuis Wikidata
	if not args.title then
		local value = item:formatStatements('P1476')['value']
		if value == '' then
			value = item:getLabel() or ''
		end
		if value ~= '' then
			local siteLink =  item:getSitelink()
			if siteLink then
				value = '[[' .. siteLink .. '|' .. value .. ']]'
			end
			args.title = value .. '&nbsp;[[File:OOjs UI icon edit-ltr.svg|????????????????????????????????? ??????????????? ??? ???????????????????????? ????????????|10px|baseline|class=noviewer|link=d:' .. item.id .. '#P1476]]'
		end
	end

    -- year property
    if not args.year then
		for _, statement in pairs(item:getBestStatements('P577')) do
			if statement.mainsnak.datavalue ~= nil then
				local current_year = statement.mainsnak.datavalue.value.time
                args['year'] = mw.ustring.sub(current_year, 2, 5)
			end
		end
    end

	-- author properties
	for arg, propertyId in pairs(indexToWikidata) do
		if not args[arg] then
			local value = item:formatStatements(propertyId)["value"]
			if value ~= '' then
				args[arg] = value 
			end
		end
	end
	

	return {
		['args'] = args,
		['item'] = item
	}
end

local p = {}
 
function p.indexDataWithWikidata(frame)
    return indexDataWithWikidata(frame)
end
 
return p
