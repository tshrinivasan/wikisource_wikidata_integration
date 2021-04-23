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
	
	mw.logObject( args )
	mw.logObject( item )
	
	
	local page = mw.title.getCurrentTitle()
	local html = mw.html.create()
	
	if item then
		html:wikitext('[[Category: Books with a Wikidata ID]]<indicator name="wikidata">[[File:Wikidata.svg|20px|élément Wikidata|link=d:' .. item.id .. ']]</indicator>')
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
            -- TODO mettre une catégorie pour les livres ayant une couverture qui ne provient pas du DJVU/PDF
        end
        if imageTitle == nil then
            imageContainer:wikitext(args.image)
            -- TODO mettre une catégorie de maintenance ici lorsque la couverture est manquante
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
			addRow (metadataTable, 'Name', withWikidataLink (args.title, 'Books linked to Wikipedia')) 		
		else 
    		addRow(metadataTable, 'Name', '[[' .. args.title .. ']]')
    	end
    else
		mw.addWarning ('Book name needs to be added') 
	end

	addRow(metadataTable, 'Subtitle', withWikidataLink(args.subtitle))

if args.author then
	mw.logObject(args)
if item then
    addRow(metadataTable, 'Author', withWikidataLink(args.author))
  else 
   addRow(metadataTable, 'Author', '{{Al|' .. args.author  .. '}}')
 end
 else
end


--	addRow(metadataTable, 'Sous-titre', args.sous_titre)
	addRow(metadataTable, 'Volume', args.volume)
	addRow(metadataTable, 'Publisher', args.publisher)
	addRow(metadataTable, 'author_orig', args.author)
--	addRow(metadataTable, 'Author', withWikidataLink(args.author))
	addRow(metadataTable, 'Year', withWikidataLink(args.year))
	addRow(metadataTable, 'Place of Publication', withWikidataLink(args.place_of_publication))
	addRow(metadataTable, 'VIAF identifier',withWikidataLink(args.viaf))
	addRow(metadataTable, 'Parts', withWikidataLink(args.parts))
--	addRow(metadataTable, 'Traducteur', withWikidataLink(args.traducteur))
--	addRow(metadataTable, 'Éditeur', withWikidataLink(args.editeur_scientifique))
--	addRow(metadataTable, 'Illustrateur', withWikidataLink(args.illustrateur))--
--  addRow(metadataTable, 'École', withWikidataLink(args.school))
--	addRow(metadataTable, 'Maison&nbsp;d’édition', withWikidataLink(args.editeur))
--	addRow(metadataTable, 'Lieu&nbsp;d’édition', withWikidataLink(args.lieu))
--	addRow(metadataTable, 'Année&nbsp;d’édition', args.annee)
--	addRow(metadataTable, 'Publication&nbsp;originale', args.publication)
	if args.BNF_ARK then
		local arkLink = '[http://gallica.bnf.fr/ark:/12148/' .. args.BNF_ARK .. ' National Library of France][[Category:Facsimilés issus de Gallica]]<br/>'
		if args.bibliotheque then
			args.bibliotheque = arkLink .. args.bibliotheque
		else
			args.bibliotheque = arkLink
		end
	end
	addRow(metadataTable, 'Bibliothèque', args.bibliotheque)
	if args.source == 'djvu' or args.source == 'pdf' then
		addRow(metadataTable, 'Fac-similés', '[[:File:' .. mw.title.getCurrentTitle().text .. '|' .. args.source .. ']]')

		--add an indicator linking to the usages
		local query = 'SELECT ?item ?itemLabel ?pages ?page WHERE {\n  ?item wdt:P996 <http://commons.wikimedia.org/wiki/Special:FilePath/' .. mw.uri.encode(mw.title.getCurrentTitle().text, 'PATH') .. '> .\n  OPTIONAL { ?page schema:about ?item ; schema:isPartOf <https://fr.wikisource.org/> . }\n  OPTIONAL { ?item wdt:P304 ?pages . }\n  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en".\n}}'
		html:wikitext('<indicator name="index-scan-wikidata">[[File:Wikidata Query Service Favicon.svg|20px|éléments Wikidata|link=https://query.wikidata.org/embed.html#' .. mw.uri.encode(query, 'PATH') .. ']]</indicator>')
	else
		addRow(metadataTable, 'Fac-similés', args.source)
	end
	if args.avancement == 'T' then
		addRow(metadataTable, 'Progress', '[[Category:Completed Books]] [[:Category:Completed Books | Completed]]')
	elseif args.avancement == 'V' then
		addRow(metadataTable, 'Progress', '[[category:Books to validate]] [[:Category:Books to validate | To validate]]')
	elseif args.avancement == 'C' then
		addRow(metadataTable, 'Progress', '[[category:Books to correct]] [[:category:Books to correct | To correct]]')
	elseif args.avancement == 'MS' then
		addRow(metadataTable, 'Progress', '[[category:Cutting books]] [[:category:Cutting books | Text ready to cut]]')
	elseif args.avancement == 'OCR' then
		addRow(metadataTable, 'Progress', '[[category:Books without a text layer]] [[:category:Books without a text layer | Add an OCR text layer]]')
	elseif args.avancement == 'X' then
		addRow(metadataTable, 'Progress', '[[category:Extracts and compilations]] [[:category:Extracts and compilations | Incomplete source:extract or compilation]]')
	elseif args.avancement == 'D' then
		addRow(metadataTable, 'Progress', '[[category:Duplicates]] [[:category:Duplicates | Duplicate index]]')
	elseif args.avancement == 'L' then
		addRow(metadataTable, 'Progress', '[[category:Books to repair]] <span style = "color: # FF0000;"> [[:category: Books to repair | Defective source file]]</span>')
	else
		addRow(metadataTable, 'Progress', '[[Category:Unknown progress books]] [[:category:Unknown progress books | Unknown progress]]')
	end
	addRow(metadataTable, 'Series', args.tomes)
	
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

	if args.sommaire or args.epigraphe then
		local right = html:tag('div'):css({
			width = '44%;',
			['padding-left'] = '1em',
			float = 'right'
		})
		if args.sommaire then
			right:tag('div'):attr('id', 'sommaire'):wikitext(args.sommaire)
		end
		if args.epigraphe then
			right:tag('hr'):css({
				['margin-top'] = '1em',
				['margin-bottom'] = '1em'
			})
			right:tag('div'):attr('id', 'epigraphe'):wikitext(args.epigraphe)
		end
	end
	
	if args.clef then
		html:wikitext('{{DEFAULTSORT:' .. args.clef .. '}}')
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
	end
	if not args.sommaire then
		html:wikitext('[[Category: Summary missing]] ')
	end

	return tostring(html)
end

local p = {}
 
function p.indexTemplate( frame )
    return indexTemplate( frame )
end
 
return p
