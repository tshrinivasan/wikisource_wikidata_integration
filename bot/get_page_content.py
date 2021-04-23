import pywikibot as pw
import sys


def get_mainpage_from_indexpage(lang,site,indexpage):
    page = pw.Page(pw.Site(lang, site), indexpage)
    text = page.get()


    all_text_list = text.split("\n")


    for item in all_text_list:
        if item.startswith('|Title'):
            
            title = item.split("=")[1].replace('[[','').replace(']]','')

            #print(title)
    return title



def get_wikidata_item_of_page(lang,site,page):
    page = pw.Page(pw.Site(lang, site), page)
#    print(page.properties())
    page_properties = page.properties()
    if "wikibase_item" in page_properties:
        wikidata_item = page_properties['wikibase_item']
    else:
        wikidata_item = None
    return(wikidata_item)
#    print(page.properties['wikidata_item'])
    




def add_wikidata_to_indexpage_form(lang,site,indexpage, wikidata_item):

    page = pw.Page(pw.Site(lang, site), indexpage)
    text = page.get()
    print(text)


    counter = 0
    all_text_list = text.split("\n")
    #print(len(all_text_list))

    for item in all_text_list:
        if item.startswith('|wikidata_item'):
    #        print(item)
    #        print(counter)
            new_string = item.split("=")[0] + "=" +  wikidata_item
            #index = all_text_list(item)
#            print(new_string)
            all_text_list[counter] = new_string
            counter = counter + 1
#            print(all_text_list)

    new_content = "\n".join(all_text_list)
#    print(new_content)

    page.text=new_content
    page.save("changed wikidata_item - from the bot")




def get_all_index_pages(lang,site):
    index_page_namespace = 252  #https://en.wikisource.org/wiki/Help:Namespaces
    # https://ta.wikisource.org/w/api.php?action=query&meta=siteinfo&siprop=namespaces

    site = pw.Site(lang,site)
    #for namespace in site.namespaces():
    all_index_pages = []
    #all_index_page_count = 0
#    for namespace in site.namespaces():
#        print(namespace)
#    sys.exit()
    indexes = open("index.list","w")
    for page in site.allpages(namespace = index_page_namespace):
        all_index_pages.append(page.title())
        indexes.write(page.title() + "\n")
        
    print(len(all_index_pages))
    indexes.close()
    

    

lang = "ta"
site = "wikisource"

get_all_index_pages(lang,site)

all_index = open("index.list","r").readlines()


for indexpage in all_index:
    try:
        page = get_mainpage_from_indexpage(lang,site,indexpage)
        results = open("results.csv","a")
        wikidata_item = get_wikidata_item_of_page(lang,site,page)
        if wikidata_item:
            print(page,wikidata_item)
            results.write(indexpage + "," + page + "," + wikidata_item + "\n")
        if not wikidata_item == None:
            print(page,"NONE")
            results.write(indexpage + "," + page + "," + "NONE"  + "\n")
        results.close()
    except:
        results = open("results.csv","a")
        results.write(indexpage + "," + page + "," + "ERROR on Getting data" + "\n")
        results.close()
#sys.exit()          

results.close()

'''
title = get_mainpage_from_indexpage('en','wikisource','Index:The_Kiss_and_Other_Stories_by_Anton_Tchekhoff,_1908.pdf')
print(title)


wikidata_item = get_wikidata_item_of_page('en','wikisource',title)

print(wikidata_item)

add_wikidata_to_indexpage_form('en','wikisource','Index:The_Kiss_and_Other_Stories_by_Anton_Tchekhoff,_1908.pdf',wikidata_item)

print("Done")






sys.exit()

'''
    
#    page = pw.Page(pw.Site('bn', 'wikisource'), 'নির্ঘণ্ট:গীতাঞ্জলি_-_রবীন্দ্রনাথ_ঠাকুর.djvu')  #wikidata_item=Q51614301


#page = pw.Page(pw.Site('en', 'wikisource'), 'Index:The_Kiss_and_Other_Stories_by_Anton_Tchekhoff,_1908.pdf')  #wikidata_item=Q51614301                                                 
#https://en.wikisource.org/wiki/Index:The_Kiss_and_Other_Stories_by_Anton_Tchekhoff,_1908.pdf
# test_id = Q161531

text = page.get()
print(text)
sys.exit()



counter = 0
all_text_list = text.split("\n")
print(len(all_text_list))

for item in all_text_list:
    if item.startswith('|wikidata_item'):
        print(item)
        print(counter)
        new_string = item.split("=")[0] + "=Q161531"
        #index = all_text_list(item)
        print(new_string)
        all_text_list[counter] = new_string
    counter = counter + 1
print(all_text_list)

new_content = "\n".join(all_text_list)
print(new_content)

page.text=new_content
page.save("changed wikidata_item - demo for krishna")
        
#নির্ঘণ্ট:গীতাঞ্জলি_-_রবীন্দ্রনাথ_ঠাকুর.djvu




'''
 from pywikibot.page import Page

 newPage=Page(site,pageTitle)
 newPage.text=pageContent
 newPage.save("summary")
'''
