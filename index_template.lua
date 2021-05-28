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
    	tag:wikitext(' [[Image:Wikidata.svg|10px|link=d:' .. itemId .. '|View feature on Wikidata]]')
    	if category ~= nil then
    		tag:wikitext('[[category:' .. category .. ']]')
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
		html:wikitext('[[Category: Books with a Wikidata ID]]<indicator name="wikidata">[[File:Wikidata.svg|20px|element Wikidata|link=d:' .. item.id .. ']]</indicator>')
        else
        html:wikitext('[[Category: Books without a Wikidata ID]]')
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
        end
        if imageTitle == nil then
            imageContainer:wikitext(args.image)
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
    		addRow(metadataTable, 'Title', withWikidataLink(args.title))
		else 
    		addRow(metadataTable, 'Title', '[[' .. args.title .. ']]')
    	end
    else
    	mw.addWarning('You must enter the title field of the form')
    end

	addRow(metadataTable, 'Subtitle', withWikidataLink(args.subtitle))

    if args.volume then
        addRow(metadataTable, 'Volume', '[[' .. args.volume .. ']]' )
        html:wikitext('[[Category: Books with Volume]]')
    else 
        html:wikitext('[[Category: Books without Volume]]')
    end


    if args.edition then
        addRow(metadataTable, 'Edition', '[[' .. args.edition .. ']]')
        html:wikitext('[[Category: Books with Edition]]')
    else 
        html:wikitext('[[Category: Books without Edition]]')
    end

    if args.author then
    if item then
        addRow(metadataTable, 'Author', withWikidataLink(args.author))
        html:wikitext('[[Category: Books with Author]]')
    else 
    addRow(metadataTable, 'Author', '{{Al|' .. args.author  .. '}}')
    end
    else
        html:wikitext('[[Category: Books without Author]]')
    end


    if args.translator then
    if item then
        addRow(metadataTable, 'Translator', withWikidataLink(args.translator))
        html:wikitext('[[Category: Books with Translator]]')
    else 
    addRow(metadataTable, 'Translator', '{{Al|' .. args.translator .. '}}')
    end
    else
        html:wikitext('[[Category: Books without Translator]]')
    end


    if args.editor then
    if item then
        addRow(metadataTable, 'Editor', withWikidataLink(args.editor))
        html:wikitext('[[Category: Books with Editor]]')
    else
    addRow(metadataTable, 'Editor', '{{Al|' .. args.editor .. '}}')
    end
    else 
        html:wikitext('[[Category: Books without Editor]]')
    end
    
    if args.illustrator then
        addRow(metadataTable, 'Illustrator', withWikidataLink(args.illustrator))
        html:wikitext('[[Category: Books with Illustrator]]')
    else 
        html:wikitext('[[Category: Books without Illustrator]]')
    end

    if args.publisher then
    if item then
        addRow(metadataTable, 'Publisher', withWikidataLink(args.publisher))
        html:wikitext('[[Category: Books with Publisher]]')
    -- {{suppress categories|html:wikitext[[Category:No Publisher]]}} 
    --    {{#invoke:Suppress categories|main|html:wikitext[[Category:No Publisher]]}} 
    else 
        addRow(metadataTable, 'Publisher', withWikidataLink(args.publisher))
        html:wikitext('[[Category: Books with Publisher]]')
    end
    else
            html:wikitext('[[Category: Books with No Publisher]]')

    end


    if args.publishedin then
        addRow(metadataTable, 'Published In', withWikidataLink(args.publishedin))
        html:wikitext('[[Category: Books with Published in country]]')
    else 
        html:wikitext('[[Category: Books without Published in country]]')
    end

    if args.address then
        addRow(metadataTable, 'Address', withWikidataLink(args.address))
        html:wikitext('[[Category: Books with Address]]')
    else 
        html:wikitext('[[Category: Books without Address]]')
    end

    if args.year then
        addRow(metadataTable, 'Year', withWikidataLink(args.year))
        html:wikitext('[[Category: Books with Year]]')
    else 
        html:wikitext('[[Category: Books without Year]]')
    end


    if args.printer then
        addRow(metadataTable, 'Printer', withWikidataLink(args.printer))
        html:wikitext('[[Category: Books with Printer]]')
    else 
        html:wikitext('[[Category: Books without Printer]]')
    end


    if args.source == 'djvu' or args.source == 'pdf' then
		addRow(metadataTable, 'Source', '[[:File:' .. mw.title.getCurrentTitle().text .. '|' .. args.source .. ']]')

		--add an indicator linking to the usages
        local query = 'SELECT ?item ?itemLabel ?pages ?page WHERE {\n  ?item wdt:P996 <http://commons.wikimedia.org/wiki/Special:FilePath/' .. mw.uri.encode(mw.title.getCurrentTitle().text, 'PATH') .. '> .\n  OPTIONAL { ?page schema:about ?item ; schema:isPartOf <https://bn.wikisource.org/> . }\n  OPTIONAL { ?item wdt:P304 ?pages . }\n  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],bn".\n}}'

        html:wikitext('<indicator name="index-scan-wikidata">[[File:Wikidata Query Service Favicon.svg|20px|Wikidata items |link=https://query.wikidata.org/embed.html#' .. mw.uri.encode(query, 'PATH') .. ']]</indicator>')
	else
		addRow(metadataTable, 'Source', args.source)
	end
	if args.progress == 'T' then
		addRow(metadataTable, 'Progress', '[[Category:Completed Books]] [[:Category:Completed Books | Completed]]')
	elseif args.progress == 'V' then
		addRow(metadataTable, 'Progress', '[[category:Books to validate]] [[:Category:Books to validate | To validate]]')
	elseif args.progress == 'C' then
		addRow(metadataTable, 'Progress', '[[category:Books to correct]] [[:category:Books to correct | To correct]]')
	elseif args.progress == 'OCR' then
		addRow(metadataTable, 'Progress', '[[category:Books without a text layer]] [[:category:Books without a text layer | Add an OCR text layer]]')
	elseif args.progress == 'L' then
		addRow(metadataTable, 'Progress', '[[category:Books to repair]] <span style = "color: # FF0000;"> [[:category: Books to repair | Defective source file]]</span>')
   elseif args.progress == 'X' then
		addRow(metadataTable, 'Progress', '[[category:Extracts and compilations]] [[:category:Extracts and compilations | Incomplete source:extract or compilation]]')
	else
		addRow(metadataTable, 'Progress', '[[Category:Unknown progress books]] [[:category:Unknown progress books | Unknown progress]]')
	end
	addRow(metadataTable, 'Series', args.volumes)
	
	if args.pages then
		left:tag('div'):css('clear', 'both')
            left:tag('h3'):wikitext('Pages')
		left:tag('div'):attr('id', 'pagelist'):css({
			background = '#F0F0F0',
			['padding-left'] = '0.5em',
			['text-align'] = 'justify'
		}):newline():wikitext(args.pages):newline()
	else
		mw.addWarning('You must enter the pagination of the facsimile (Pages field) ')
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
		html:wikitext('[[Category: Index - Books]] ')
	elseif args.type == 'journal' then
		html:wikitext('[[Category: Index - Periodicals]] ')
	 elseif args.type == 'collection' then
		html:wikitext('[[Category: Index - Collections]] ')
	elseif args.type == 'dictionary' then
		html:wikitext('[[Category: Index - Dictionaries]] ')
	elseif args.type == 'phdthesis' then
		html:wikitext('[[Category: Index - Theses]] ')
	end
	html:wikitext('[[Category: Index]] ')

	if args.source ~= 'djvu' then
		html:wikitext('[[Category: Non djvu book]] ')
	elseif args.source == 'pdf' then
		html: wikitext ('[[Category: PDF book]]') 
	elseif args.source == 'ogg' then
		html: wikitext ('[[Category: OGG file]]') 
	elseif args.source == 'webm' then
		html: wikitext ('[[Category: webm file]]') 
	end
	if not args.remarks then
		html: wikitext ('[[Category: Indexed pages]]') 
	end

	return tostring(html)
end

local p = {}
 
function p.indexTemplate( frame )
    return indexTemplate( frame )
end
 
return p
