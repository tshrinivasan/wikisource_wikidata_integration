-- [[Get the data from the index page and enrich it with Wikidata]] --

local wikidataTypeToIndexType = {
    ['Q3331189'] = 'book',
    ['Q1238720'] = 'journal',
    ['Q28869365'] = 'journal',
    ['Q191067'] = 'journal',
    ['Q23622'] = 'dictionary',
    ['Q187685'] = 'phdthesis'
}
local indexToWikidata = {
-- type and title are managed specially
    ['subtitle'] = 'P1680',
    ['volume'] = 'P478',
    ['author'] = 'P50',
    ['translator'] = 'P655',
    ['scientific_editor'] = 'P98',
    ['illustrator'] = 'P110',
    ['editor'] = 'P123',
    -- TODO ['School'] = 'PXXX',
    ['location'] = 'P291',
    ['year'] = 'P577',
    ['epigraph'] = 'P7150',
    -- TODO ['publication'] = 'PXX',
    -- TODO ['library'] = 'PXX',
    -- TODO ['key'] = 'PXX',
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
            mw.addWarning('The Wikidata entity identifier [[d:' .. args.wikidata_item .. '|' .. args.wikidata_item .. ']] put in the "Wikidata entity" parameter of the page Book: does not appear to be valid. ')
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
                local typeId = statement.mainsnak.datavalue.value.id
                if wikidataTypeToIndexType[typeId] then
                    args.type = wikidataTypeToIndexType[typeId]
                end
            end
        end
    end

-- title from Wikidata
    if not args.title then
        local value = item:formatStatements('P1476')['value'] or ''
        if value == '' then
            value = item:getLabel() or ''
        end
        if value ~= '' then
            local siteLink = item:getSitelink ()
            if siteLink then
                value = '[[' .. siteLink .. '|' .. value .. ']]'
            end
            args.title = value .. '& nbsp; [[File: OOjs UI icon edit-ltr.svg | View and edit data on Wikidata | 10px | baseline | class = noviewer | link = d:' .. item.id .. '# P1476]]'
        end
    end


    -- author from Wikidata
    if not args.author then
        local value = item:formatStatements('P253075')['value'] or ''
        if value == '' then
            value = item:getLabel() or ''
        end
        if value ~= '' then
            local siteLink = item:getSitelink()
            if siteLink then
                value = '[[' .. siteLink .. '|' .. value .. ']]'
            end
            args.author = value .. '& nbsp; [[File: OOjs UI icon edit-ltr.svg | View and edit data on Wikidata | 10px | baseline | class = noviewer | link = d:' .. item.id .. '# P253075]]'
        end
    end

-- other properties
    for arg, propertyId in pairs(indexToWikidata) do
        if not args[arg] then
            local value = item:formatStatements(propertyId)["value"] or ''
            if value ~= '' then
                args[arg] = value .. '& nbsp; [[File: OOjs UI icon edit-ltr.svg | View and edit data on Wikidata | 10px | baseline | class = noviewer | link = d:' .. item.id .. '#' .. propertyId .. ']]'
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
