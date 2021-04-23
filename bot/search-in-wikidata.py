#import pwb

'''
https://en.wikisource.org/wiki/Index:The_Kiss_and_Other_Stories_by_Anton_Tchekhoff,_1908.pdf

page info: https://en.wikisource.org/w/index.php?title=Index:The_Kiss_and_Other_Stories_by_Anton_Tchekhoff,_1908.pdf&action=info

Gives wikidata id as
https://www.wikidata.org/wiki/Special:EntityPage/Q89675998

But it has low details.

This has high details
https://www.wikidata.org/wiki/Q15839163


'''


import pywikibot
site = pywikibot.Site('en', 'wikisource.beta.wmflabs.org')  # any site will work, this is just an example
page = pywikibot.Page(site, 'Index:War_and_Peace.djvu')
print(page)
item = pywikibot.ItemPage.fromPage(page) 
print(item)

# [[wikidata:Q89675998]]


'''

site = pywikibot.Site('', 'wikisource')  # any site will work, this is just an example
page = pywikibot.Page(site, 'Index:The Kiss and Other Stories by Anton Tchekhoff, 1908.pdf')
item = pywikibot.ItemPage.fromPage(page) 
print(item)
'''
