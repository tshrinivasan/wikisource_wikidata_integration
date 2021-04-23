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
        tag: wikitext ('[[Image: Wikidata.svg | 10px | link = d:' .. itemId .. '| View feature on Wikidata]]')
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

function indexTemplate(frame)
	--create a clean table of parameters with blank parameters removed
	local data = (require 'Module:Index_data').indexDataWithWikidata(frame)
	local args = data.args
	local item = data.item

	local page = mw.title.getCurrentTitle()
	local html = mw.html.create()

	if item then
        html: wikitext ('[[Category: Books with Wikidata id]] <indicator name = "wikidata"> [[File: Wikidata.svg | 20px | Wikidata element | link = d:' .. item.id .. ' ]] </indicator> ')
	end

    --Left part
    local left = html:tag('div')
    if args.summary or args.inscription then
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
    	if tonumber(args.image) == nil then
    		local imageTitle = mw.title.new(args.image, "Media")
    		if imageTitle ~= nil and imageTitle.exists then
    			imageContainer:wikitext('[[File:' .. args.image .. '|160px]]')
                -- TODO put a category here for books with a cover that is not from DJVU / PDF
    		else
    			imageContainer:wikitext(args.image)
    			-- TODO put a maintenance category here when the cover is missing
    		end
    	else
    		imageContainer:wikitext('[[File:' .. mw.title.getCurrentTitle().text .. '|page=' .. args.image .. '|160px]]')
    	end
    end
    --Metadata
    local metadataContainer = left:tag('div')
    if args.image then
    	metadataContainer:css('margin-left', '150px')
    end
    local metadataTable = metadataContainer:tag('table')

    if args.title then
	    if args.type == 'journal' then
    		addRow(metadataTable, 'Journal', withWikidataLink(args.title))
    	else
            addRow (metadataTable, 'Title', withWikidataLink (args.title, 'Books with Wikidata link'))
    	end
    else
        mw.addWarning ('You must enter the title field of the form')
    end
    addRow (metadataTable, 'Subtitle', args.sub_title)
    addRow (metadataTable, 'Volume', args.volume)
    addRow (metadataTable, 'Author', withWikidataLink (args.author))
    addRow (metadataTable, 'Translator', withWikidataLink (args.translator))
    addRow (metadataTable, 'Editor', withWikidataLink (args.scientific_editor))
    addRow (metadataTable, 'Illustrator', withWikidataLink (args.illustrator))
    addRow (metadataTable, 'School', withWikidataLink (args.school))
    addRow (metadataTable, 'Publishing house', withWikidataLink (args.editeur))
    addRow (metadataTable, 'Place of edition', withWikidataLink (args.location))
    addRow (metadataTable, 'Year & nbsp; of edition', args.year)
    addRow (metadataTable, 'Original & nbsp; publication', args.publication)

	if args.BNF_ARK then
		local arkLink = '[http://gallica.bnf.fr/ark:/12148/' .. args.BNF_ARK .. 'National Library of France][[Category:Facsimilés issus de Gallica]]<br/>'
		if args.bibliotheque then
			args.bibliotheque = arkLink .. args.bibliotheque
		else
			args.bibliotheque = arkLink
		end
	end
	addRow(metadataTable, 'Library', args.library)
	if args.source == 'djvu' or args.source == 'pdf' then
		addRow(metadataTable, 'Facsimiles', '[[:File:' .. mw.title.getCurrentTitle().text .. '|' .. args.source .. ']]')

		--add an indicator linking to the usages
		local query = 'SELECT ?item ?itemLabel ?pages ?page WHERE {\n  ?item wdt:P996 <http://commons.wikimedia.org/wiki/Special:FilePath/' .. mw.uri.encode(mw.title.getCurrentTitle().text, 'PATH') .. '> .\n  OPTIONAL { ?page schema:about ?item ; schema:isPartOf <https://fr.wikisource.org/> . }\n  OPTIONAL { ?item wdt:P304 ?pages . }\n  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en".\n}}'
		html:wikitext('<indicator name="index-scan-wikidata">[[File:Wikidata Query Service Favicon.svg|20px|éléments Wikidata|link=https://query.wikidata.org/embed.html#' .. mw.uri.encode(query, 'PATH') .. ']]</indicator>')
	else
		addRow(metadataTable, 'Facsimiles', args.source)
	end
	if args.avancement == 'T' then
		addRow(metadataTable, 'Avancement', '[[Category:Livres terminés]][[:Category:Livres terminés|Terminé]]')
	elseif args.avancement == 'V' then
		addRow(metadataTable, 'Avancement', '[[category:Livres à valider]][[:category:Livres à valider|À valider]]')
	elseif args.avancement == 'C' then
		addRow(metadataTable, 'Avancement', '[[category:Livres à corriger]][[:category:Livres à corriger|À corriger]]')
	elseif args.avancement == 'MS' then
		addRow(metadataTable, 'Avancement', '[[category:Livres à découper]][[:category:Livres à découper|Texte prêt à être découpé]]')
	elseif args.avancement == 'OCR' then
		addRow(metadataTable, 'Avancement', '[[category:Livres sans couche texte]][[:category:Livres sans couche texte|Ajouter une couche texte d’OCR]]')
	elseif args.avancement == 'X' then
		addRow(metadataTable, 'Avancement', '[[category:Extraits et compilations]][[:category:Extraits et compilations|Source incomplète: extrait ou compilation]]')
	elseif args.avancement == 'D' then
		addRow(metadataTable, 'Avancement', '[[category:Doublons]][[:category:Doublons|Index en double]]')
	elseif args.avancement == 'L' then
		addRow(metadataTable, 'Avancement', '[[category:Livres à réparer]]<span style="color: #FF0000; ">[[:category:Livres à réparer|Fichier source défectueux]]</span>')
	else
		addRow(metadataTable, 'Avancement', '[[Category:Livres d’avancement inconnu]][[:category:Livres d’avancement inconnu|Avancement inconnu]]')
	end
	addRow(metadataTable, 'Série', args.tomes)

	if args.pages then
		left:tag('div'):css('clear', 'both')
		left:tag('h3'):wikitext('Pages')
		left:tag('div'):attr('id', 'pagelist'):css({
			background = '#F0F0F0',
			['padding-left'] = '0.5em',
			['text-align'] = 'justify'
		}):newline():wikitext(args.pages):newline()
	else
		mw.addWarning('Vous devez rentrer la pagination du fac-similé (champ Pages)')
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
		html:wikitext('[[Catégorie:Index - Livres]]')
	elseif args.type == 'journal' then
		html:wikitext('[[Catégorie:Index - Périodiques]]')
	elseif args.type == 'collection' then
		html:wikitext('[[Catégorie:Index - Recueils]]')
	elseif args.type == 'dictionary' then
		html:wikitext('[[Catégorie:Index - Dictionnaires]]')
	elseif args.type == 'phdthesis' then
		html:wikitext('[[Catégorie:Index - Thèses]]')
	end
	html:wikitext('[[Catégorie:Index]]')

	if args.source ~= 'djvu' then
		html:wikitext('[[Category:Livre non djvu]]')
	end
	if not args.sommaire then
		html:wikitext('[[Catégorie:Sommaire manquant]]')
	end

	return tostring(html)
end

local p = {}

function p.indexTemplate( frame )
    return indexTemplate( frame )
end

return p
