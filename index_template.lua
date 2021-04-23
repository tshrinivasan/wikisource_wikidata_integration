function withWikidataLink(wikitext, category)
	if wikitext == nil then
		return nil
	end
	new_wikitext = mw.ustring.gsub(wikitext, '%[%[([^|%]]*)%]%]', function(page)
		return addWikidataToLink(page, mw.ustring.gsub(page, '%.*/', '') , category)
	end)
	if new_wikitext ~= wikitext then
		return new_wikitext
	end
	return mw.ustring.gsub(wikitext, '%[%[([^|]*)|([^|%]]*)%]%]', function(page, link)
		return addWikidataToLink(page, link, category)
	end)
end

function addWikidataToLink(page, label, category)
    local title = mw.title.new( page )
    if title == nil then
    	return '[[' .. page .. '|' .. label .. ']]'
    end
    if title.isRedirect then
        title = title.redirectTarget
    end

    local tag = mw.html.create('span')
    local itemId = mw.wikibase.getEntityIdForTitle(title.fullText)
	tag:wikitext('[[' .. page .. '|' .. label .. ']]')
    if itemId ~= nil then
    	tag:wikitext(' [[Image:Wikidata.svg|10px|link=d:' .. itemId .. '|Wikipedia items ]]')
    	if category ~= nil then
    		tag:wikitext('[[Category:' .. category .. ']]')
    	end
    end
    return tostring(tag)
end

function addRow(metadataTable, key, value)
	if value then
		metadataTable:tag('tr')
			:tag('th')
				:attr('score', 'row')
				:css('vertical-align', 'top')
				:wikitext(key)
				:done()
			:tag('td'):wikitext(value)
	end
end

function splitFileNameInFileAndPage(title)
    local slashPosition = string.find(title.text, "/")
    if slashPosition == nil then
    	return title.text,nil
    else
    	return string.sub(title.text, 1, slashPosition - 1), string.sub(title.text, slashPosition + 1)
    end
end

function indexTemplate(frame)
	--create a clean table of parameters with blank parameters removed
	local data = (require 'Module:Index_data').indexDataWithWikidata(frame)
	local args = data.args
	local item = data.item
	
	local page = mw.title.getCurrentTitle()
	local html = mw.html.create()
	
	if item then
		html: wikitext ('[[Category: Books linked to Wikipedia]]] <indicator name = "wikidata"> [[File: Wikidata.svg | 20px | Wikipedia items | link = d:' .. item.id .. '] ] </indicator> ') 
        else
        html: wikitext ('[[Category: Books not connected to Wikipedia]]') 
	end

    --Left part
    local left = html:tag('div')
    if args.remarks or args.notes then
    	left:css('width', '53%')
    end
    left:css('float', 'left')
    --Image
    if args.image then
        local imageContainer = left:tag('div')
            :css({
                float = 'left',
                overflow = 'hidden',
                border = 'thin grey solid'
            })
        local imageTitle = nil
        if tonumber(args.image) ~= nil then
            -- this is a page number
            imageTitle = mw.title.getCurrentTitle():subPageTitle(args.image)
        else
            -- this is an other file
            imageTitle = mw.title.new(args.image, "Media")
            -- TODO put a category for books with a cover that is not from the DJVU / PDF 
        end
        if imageTitle == nil then
            imageContainer:wikitext(args.image)
            -- TODO put a maintenance category here when the cover is missing 
        else
            local imageName, imagePage = splitFileNameInFileAndPage(imageTitle)
            if imagePage ~= nil then
	            imageContainer:wikitext('[[File:' .. imageName .. '|page=' .. imagePage .. '|250px]]')
	        else
	            imageContainer:wikitext('[[File:' .. imageName .. '|250px]]')
	        end
        end
    end
    --Metadata
    local metadataContainer = left:tag('div')
    if args.image then
    	metadataContainer:css('margin-left', '150px')
    end
    local metadataTable = metadataContainer:tag('table')

    if args.title then
       if item then
    		addRow (metadataTable, 'name', withWikidataLink (args.title, 'Books linked to Wikipedia')) 
else 
     addRow(metadataTable, 'Name', '[[' .. args.title .. ']]')
    	end
    else
    	mw.addWarning ('Book name needs to be added')
    end

	addRow (metadataTable, 'subtitle', withWikidataLink (args.subtitle))

if args.volume then
     addRow (metadataTable, 'segment', '[[' .. args.volume .. ']]') 
else 
end

if args.edition then
	addRow (metadataTable, 'version', '[[' .. args.edition .. ']]') 
else 
end

if args.author then
if item then
    addRow(metadataTable, 'Author', withWikidataLink(args.author))
  else 
   addRow(metadataTable, 'Author', '{{Al|' .. args.author  .. '}}')
 end
 else
end

if args.translator then
if item then
	addRow(metadataTable, 'Translator', withWikidataLink(args.translator))
  else 
   addRow(metadataTable, 'Translator', '{{Al|' .. args.translator .. '}}')
 end
 else
end

if args.editor then
if item then
	addRow(metadataTable, 'Editor', withWikidataLink(args.editor))
 else
   addRow(metadataTable, 'Editor', '{{Al|' .. args.editor .. '}}')
end
  else 
 end

	addRow(metadataTable, 'Illustrator', withWikidataLink(args.illustrator))

if args.publisher then
if item then
	addRow(metadataTable, 'Publisher', withWikidataLink(args.publisher))
  else 
   addRow(metadataTable, 'Publisher', '[[Publisher:' .. args.publisher .. '|' .. args.publisher .. ']]')
 end
 else
end

	addRow(metadataTable, 'Address', withWikidataLink(args.address))

    if args.year then
	addRow(metadataTable, 'Year', '[[' .. args.year .. ']]' )
else 
end

	addRow(metadataTable, 'Printer', withWikidataLink(args.printer))
	if args.source == 'djvu' or args.source == 'pdf' then
		addRow(metadataTable, 'Source', '[[:File:' .. mw.title.getCurrentTitle().text .. '|' .. args.source .. ']]')

		--add an indicator linking to the usages
		local query = 'SELECT ?item ?itemLabel ?pages ?page WHERE {\n  ?item wdt:P996 <http://commons.wikimedia.org/wiki/Special:FilePath/' .. mw.uri.encode(mw.title.getCurrentTitle().text, 'PATH') .. '> .\n  OPTIONAL { ?page schema:about ?item ; schema:isPartOf <https://bn.wikisource.org/> . }\n  OPTIONAL { ?item wdt:P304 ?pages . }\n  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],bn".\n}}'
		html:wikitext('<indicator name="index-scan-wikidata">[[File:Wikidata Query Service Favicon.svg|20px|উইকিউপাত্ত আইটেম|link=https://query.wikidata.org/embed.html#' .. mw.uri.encode(query, 'PATH') .. ']]</indicator>')
	else
		addRow(metadataTable, 'Source', args.source)
	end
	if args.progress == 'T' then
        addRow (metadataTable, 'progress', '[[Category: Schedule validated]] [[: Category: Schedule validated. Work completed by validating all pages]]') 	elseif args.progress == 'V' then
        addRow (metadataTable, 'progress', '[[Category: Schedule print modified]] [[: Category: Schedule print modified. All page print modified but not validated]]') 	elseif args.progress == 'C' then
		addRow (metadataTable, 'Progress', '[[Category: Schedule print not modified]] [[: Category: Schedule print not modified | All page print not modified]]') 
	elseif args.progress == 'OCR' then
		addRow (metadataTable, 'progress',' [[Category: Schedule-OCR and print modification ready]] [[: Category: Schedule-OCR and print modification ready | OCR and print modification ready]] ')
	elseif args.progress == 'L' then
		addRow (metadataTable, 'progress',' [[Category: Schedule-file needs to be fixed]] <span style = "color: # FF0000;"> [[: Category: Schedule-file needs to be fixed. Source file before print modification Need to fix]]] </span> ') 
   elseif args.progress == 'X' then
		addRow (metadataTable, 'Progress', '[[Category: Schedule-file needs to be checked]] [[: Category: Schedule-file needs to be checked. Check everything before printing modification]]') 
	else
		addRow (metadataTable, 'Progress', '[[Category: Schedule - Unknown progress]] [[: Category: Schedule - Unknown progress | Unknown progress]]') 
	end
	addRow(metadataTable, 'Volumes', args.volumes)
	
	if args.pages then
		left:tag('div'):css('clear', 'both')
		left: tag ('h3'): wikitext ('book pages') 
		left:tag('div'):attr('id', 'pagelist'):css({
			background = '#F0F0F0',
			['padding-left'] = '0.5em',
			['text-align'] = 'justify'
		}):newline():wikitext(args.pages):newline()
	else
		mw.addWarning ('Create page list') 
	end

	if args.remarks or args.notes then
		local right = html:tag('div'):css({
			width = '44%;',
			['padding-left'] = '1em',
			float = 'right'
		})
		if args.remarks then
			right:tag('div'):attr('id', 'remarks'):wikitext(args.remarks)
		end
		if args.notes then
			right:tag('hr'):css({
				['margin-top'] = '1em',
				['margin-bottom'] = '1em'
			})
			right:tag('div'):attr('id', 'notes'):wikitext(args.notes)
		end
	end
	
	if args.type == 'book' then
		html: wikitext ('[[Category: Schedules - Books]]') 
	elseif args.type == 'journal' then
		html: wikitext ('[[Category: Schedules - journal]]') 
	 elseif args.type == 'collection' then
        html: wikitext ('[[Category: Schedules - Collections]]') 
	elseif args.type == 'dictionary' then
        html: wikitext ('[[Category: Schedules - Dictionary]]') 
	elseif args.type == 'phdthesis' then
        html: wikitext ('[[Category: Schedules - Thesis]]') 
	end
	html: wikitext ('[[Category: Schedule]]') 

	if args.source ~= 'djvu' then
		html: wikitext ('[[Category: Deja Vu schedule pages]]') 
	elseif args.source == 'pdf' then
		html: wikitext ('[[Category: PDF schedule page]]') 
	elseif args.source == 'ogg' then
		html: wikitext ('[[Category: OGG schedule page]]') 
	elseif args.source == 'webm' then
		html: wikitext ('[[Category: WebM schedule page]]') 
	end
	if not args.remarks then
		html: wikitext ('[[Category: Indexed schedule pages]]') 
	end

	return tostring(html)
end

local p = {}
 
function p.indexTemplate( frame )
    return indexTemplate( frame )
end
 
return p
