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
    	tag:wikitext(' [[Image:Wikidata.svg|10px|link=d:' .. itemId .. '|উইকিউপাত্ত আইটেম]]')
    	if category ~= nil then
    		tag:wikitext('[[বিষয়শ্রেণী:' .. category .. ']]')
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
		html:wikitext('[[বিষয়শ্রেণী:উইকিউপাত্তের সঙ্গে সংযোগযুক্ত বই]]<indicator name="wikidata">[[File:Wikidata.svg|20px|উইকিউপাত্ত আইটেম|link=d:' .. item.id .. ']]</indicator>')
        else
        html:wikitext('[[বিষয়শ্রেণী:উইকিউপাত্তের সঙ্গে সংযোগহীন বই]]')
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
    		addRow(metadataTable, 'নাম', withWikidataLink(args.title, 'উইকিউপাত্তের সঙ্গে সংযোগযুক্ত বই'))
else 
     addRow(metadataTable, 'নাম', '[[' .. args.title .. ']]')
    	end
    else
    	mw.addWarning('গ্রন্থের নাম যোগ করা প্রয়োজন')
    end

	addRow(metadataTable, 'উপশিরোনাম', withWikidataLink(args.subtitle))

if args.volume then
     addRow(metadataTable, 'খণ্ড', '{{#invoke:ConvertDigit|main|' .. args.volume .. '}}')
else 
end

if args.edition then
	addRow(metadataTable, 'সংস্করণ', '{{#invoke:ConvertDigit|main|' .. args.edition .. '}}')
else 
end

if args.author then
if item then
    addRow(metadataTable, 'লেখক', withWikidataLink(args.author))
  else 
   addRow(metadataTable, 'লেখক', '{{Al|' .. args.author  .. '}}')
 end
 else
end

if args.translator then
if item then
	addRow(metadataTable, 'অনুবাদক', withWikidataLink(args.translator))
  else 
   addRow(metadataTable, 'অনুবাদক', '{{Al|' .. args.translator .. '}}')
 end
 else
end

if args.editor then
if item then
	addRow(metadataTable, 'সম্পাদক', withWikidataLink(args.editor))
 else
   addRow(metadataTable, 'সম্পাদক', '{{Al|' .. args.editor .. '}}')
end
  else 
 end

	addRow(metadataTable, 'অঙ্কনশিল্পী', withWikidataLink(args.illustrator))

if args.publisher then
if item then
	addRow(metadataTable, 'প্রকাশক', withWikidataLink(args.publisher))
  else 
   addRow(metadataTable, 'প্রকাশক', '[[প্রকাশক:' .. args.publisher .. '|' .. args.publisher .. ']]')
 end
 else
end

	addRow(metadataTable, 'প্রকাশস্থান', withWikidataLink(args.address))

    if args.year then
	addRow(metadataTable, 'প্রকাশসাল', '{{#invoke:ConvertDigit|main|' .. args.year .. '}} খ্রিস্টাব্দ ({{#invoke:ConvertDigit|main|{{#expr: ' .. args.year .. ' - 593}}}} বঙ্গাব্দ)' )
else 
end

	addRow(metadataTable, 'মুদ্রক', withWikidataLink(args.printer))
	if args.source == 'djvu' or args.source == 'pdf' then
		addRow(metadataTable, 'উৎস', '[[:File:' .. mw.title.getCurrentTitle().text .. '|' .. args.source .. ']]')

		--add an indicator linking to the usages
		local query = 'SELECT ?item ?itemLabel ?pages ?page WHERE {\n  ?item wdt:P996 <http://commons.wikimedia.org/wiki/Special:FilePath/' .. mw.uri.encode(mw.title.getCurrentTitle().text, 'PATH') .. '> .\n  OPTIONAL { ?page schema:about ?item ; schema:isPartOf <https://bn.wikisource.org/> . }\n  OPTIONAL { ?item wdt:P304 ?pages . }\n  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],bn".\n}}'
		html:wikitext('<indicator name="index-scan-wikidata">[[File:Wikidata Query Service Favicon.svg|20px|উইকিউপাত্ত আইটেম|link=https://query.wikidata.org/embed.html#' .. mw.uri.encode(query, 'PATH') .. ']]</indicator>')
	else
		addRow(metadataTable, 'উৎস', args.source)
	end
	if args.progress == 'T' then
		addRow(metadataTable, 'প্রগতি', '[[বিষয়শ্রেণী:নির্ঘণ্ট বৈধকরণ করা হয়েছে]][[:বিষয়শ্রেণী:নির্ঘণ্ট বৈধকরণ করা হয়েছে|সকল পাতা বৈধকরণ করার দ্বারা কাজ সম্পূর্ণ করা হয়েছে]]')
	elseif args.progress == 'V' then
		addRow(metadataTable, 'প্রগতি', '[[বিষয়শ্রেণী:নির্ঘণ্ট মুদ্রণ সংশোধন করা হয়েছে]][[:বিষয়শ্রেণী:নির্ঘণ্ট মুদ্রণ সংশোধন করা হয়েছে|সকল পাতার মুদ্রণ সংশোধন করা হয়েছে কিন্তু বৈধকরণ করা হয়নি]]')
	elseif args.progress == 'C' then
		addRow(metadataTable, 'প্রগতি', '[[বিষয়শ্রেণী:নির্ঘণ্ট মুদ্রণ সংশোধন করা হয়নি]][[:বিষয়শ্রেণী:নির্ঘণ্ট মুদ্রণ সংশোধন করা হয়নি|সকল পাতার মুদ্রণ সংশোধন করা হয়নি]]')
	elseif args.progress == 'OCR' then
		addRow(metadataTable, 'প্রগতি', '[[বিষয়শ্রেণী:নির্ঘণ্ট-ওসিআর ও মুদ্রণ সংশোধনের জন্য প্রস্তুত]][[:বিষয়শ্রেণী:নির্ঘণ্ট-ওসিআর ও মুদ্রণ সংশোধনের জন্য প্রস্তুত|ওসিআর ও মুদ্রণ সংশোধনের জন্য প্রস্তুত]]')
	elseif args.progress == 'L' then
		addRow(metadataTable, 'প্রগতি', '[[বিষয়শ্রেণী:নির্ঘণ্ট-ফাইলকে ঠিক করা প্রয়োজন]]<span style="color: #FF0000; ">[[:বিষয়শ্রেণী:নির্ঘণ্ট-ফাইলকে ঠিক করা প্রয়োজন|মুদ্রণ সংশোধনের আগে উৎস ফাইলকে ঠিক করা প্রয়োজন]]</span>')
   elseif args.progress == 'X' then
		addRow(metadataTable, 'প্রগতি', '[[বিষয়শ্রেণী:নির্ঘণ্ট-ফাইলকে পরীক্ষা করা প্রয়োজন]][[:বিষয়শ্রেণী:নির্ঘণ্ট-ফাইলকে পরীক্ষা করা প্রয়োজন|মুদ্রণ সংশোধনের আগে সকল কিছু পরীক্ষা করে পাতার তালিকা তৈরি করুন]]')
	else
		addRow(metadataTable, 'প্রগতি', '[[বিষয়শ্রেণী:নির্ঘণ্ট - অজ্ঞাত অগ্রগতি]][[:বিষয়শ্রেণী:নির্ঘণ্ট - অজ্ঞাত অগ্রগতি|অজ্ঞাত অগ্রগতি]]')
	end
	addRow(metadataTable, 'খণ্ডসমূহ', args.volumes)
	
	if args.pages then
		left:tag('div'):css('clear', 'both')
		left:tag('h3'):wikitext('বইয়ের পাতাগুলি')
		left:tag('div'):attr('id', 'pagelist'):css({
			background = '#F0F0F0',
			['padding-left'] = '0.5em',
			['text-align'] = 'justify'
		}):newline():wikitext(args.pages):newline()
	else
		mw.addWarning('পাতার তালিকা তৈরি করুন')
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
		html:wikitext('[[বিষয়শ্রেণী:নির্ঘণ্ট - বই]]')
	elseif args.type == 'journal' then
		html:wikitext('[[বিষয়শ্রেণী:নির্ঘণ্ট - সাময়িকী‎]]')
	 elseif args.type == 'collection' then
		html:wikitext('[[বিষয়শ্রেণী:নির্ঘণ্ট - সংকলন‎]]')
	elseif args.type == 'dictionary' then
		html:wikitext('[[বিষয়শ্রেণী:নির্ঘণ্ট - অভিধান‎]]')
	elseif args.type == 'phdthesis' then
		html:wikitext('[[বিষয়শ্রেণী:নির্ঘণ্ট - থিসিস‎]]')
	end
	html:wikitext('[[বিষয়শ্রেণী:নির্ঘণ্ট]]')

	if args.source ~= 'djvu' then
		html:wikitext('[[বিষয়শ্রেণী:দেজাভু নির্ঘণ্ট পাতা]]')
	elseif args.source == 'pdf' then
		html:wikitext('[[বিষয়শ্রেণী:পিডিএফ নির্ঘণ্ট পাতা‎]]')
	elseif args.source == 'ogg' then
		html:wikitext('[[বিষয়শ্রেণী:ওজিজি নির্ঘণ্ট পাতা‎]]')
	elseif args.source == 'webm' then
		html:wikitext('[[বিষয়শ্রেণী:ওয়েবএম নির্ঘণ্ট পাতা‎]]')
	end
	if not args.remarks then
		html:wikitext('[[বিষয়শ্রেণী:সূচীপত্রবিহীন নির্ঘণ্ট পাতা]]')
	end

	return tostring(html)
end

local p = {}
 
function p.indexTemplate( frame )
    return indexTemplate( frame )
end
 
return p
