--[[Récupère les données de la page d'index et enrichie les avec Wikidata]]--

local wikidataTypeToIndexType = {
	['Q3331189'] = 'book',
	['Q1238720'] = 'journal',
	['Q28869365'] = 'journal',
	['Q191067'] = 'journal',
	['Q23622'] = 'dictionary',
	['Q187685'] = 'phdthesis'
}
local indexToWikidata = {
	-- type et titre sont gérés spécialement
    ['sous_titre'] = 'P1680',
    ['volume'] = 'P478',
    ['auteur'] = 'P50',
    ['traducteur'] = 'P655',
    ['editeur_scientifique'] = 'P98',
    ['illustrateur'] = 'P110',
    ['editeur'] = 'P123',
    -- TODO ['School'] = 'PXXX',
    ['lieu'] = 'P291',
    ['annee'] = 'P577',
    ['epigraphe'] = 'P7150',
    -- TODO ['publication'] = 'PXX',
    -- TODO ['bibliotheque'] = 'PXX',
    -- TODO ['clef'] = 'PXX',
    -- TODO ['BNF_ARK'] = 'P4258', formatting problems
    -- TODO ['source'] = 'PXX',
    -- TODO ['image'] = 'PXX',
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
			mw.addWarning('L\'identifiant d\'entité Wikidata [[d:' .. args.wikidata_item .. '|' .. args.wikidata_item .. ']] mise dans le paramètre "entité Wikidata" de la page Livre: ne semble pas valide.') 
		end
	end
	if not item then
		return {
			['args'] = args,
			['item'] = nil
		}
	end

	-- type depuis Wikidata
	if not args.type then
		for _, statement in pairs(item:getBestStatements('P31')) do
			if statement.mainsnak.datavalue ~= nil then
				local typeId = statement.mainsnak.datavalue.value.id
				if wikidataTypeToIndexType[typeId] then
					args.type = wikidataTypeToIndexType[typeId] 
				end
			end
		end
	end
	
	-- titre depuis Wikidata
	if not args.titre then
		local value = item:formatStatements('P1476')['value'] or ''
		if value == '' then
			value = item:getLabel() or ''
		end
		if value ~= '' then
			local siteLink =  item:getSitelink()
			if siteLink then
				value = '[[' .. siteLink .. '|' .. value .. ']]'
			end
			args.titre = value .. '&nbsp;[[File:OOjs UI icon edit-ltr.svg|Voir et modifier les données sur Wikidata|10px|baseline|class=noviewer|link=d:' .. item.id .. '#P1476]]'
		end
	end
	
	
    -- auteur depuis Wikidata
	if not args.auteur then
		local value = item:formatStatements('P253075')['value'] or ''
		if value == '' then
			value = item:getLabel() or ''
		end
		if value ~= '' then
			local siteLink =  item:getSitelink()
			if siteLink then
				value = '[[' .. siteLink .. '|' .. value .. ']]'
			end
			args.auteur = value .. '&nbsp;[[File:OOjs UI icon edit-ltr.svg|Voir et modifier les données sur Wikidata|10px|baseline|class=noviewer|link=d:' .. item.id .. '#P253075]]'
		end
	end

	-- autres propriétés
	for arg, propertyId in pairs(indexToWikidata) do
		if not args[arg] then
			local value = item:formatStatements(propertyId)["value"] or ''
			if value ~= '' then
				args[arg] = value .. '&nbsp;[[File:OOjs UI icon edit-ltr.svg|Voir et modifier les données sur Wikidata|10px|baseline|class=noviewer|link=d:' .. item.id .. '#' .. propertyId .. ']]'
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
