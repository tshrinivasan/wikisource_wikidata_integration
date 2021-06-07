from loguru import logger

import pywikibot
import pywikibot as pw
import pywikibot.pagegenerators
from pprint import pprint
import sys

import os
if not os.path.exists('logs'):
    os.makedirs('logs')

logger.add("logs/bot_log_{time}.log",rotation="500 MB",backtrace=True, diagnose=True)
#logger.add(sys.stdout, colorize=True, format="<green>{time}</green> <level>{message}</level>",backtrace=True, diagnose=True)

config = open("config.ini","r").readlines()
logger.info("Opening the config.ini file")

no_of_sites = len(config)
logger.info(f"Found {no_of_sites} sites")

#sys.exit()


@logger.catch
def get_all_pages_in_category(lang,site,category):
    try:
        wikisite = pywikibot.Site(lang,site)
        all_pages_in_category = pywikibot.pagegenerators.CategorizedPageGenerator(
            pywikibot.Category(wikisite,category), recurse=True)
        return(list(all_pages_in_category))
    except:
        return None

@logger.catch
def get_mainpage_from_indexpage(lang,site,indexpage):
    try:
        page = pywikibot.Page(pywikibot.Site(lang, site), indexpage)

        if page:
            text = page.get()
            all_text_list = text.split("\n")
            for item in all_text_list:
                if item.startswith('|Title'):
                    title = item.split("=")[1].replace('[[','').replace(']]','')
            if title:
                return title
            else:
                return None
        else:
            return None
    except:
        return None

@logger.catch
def get_wikidata_item_of_page(lang,site,page):
    try:
        page = pw.Page(pw.Site(lang, site), page)
        page_properties = page.properties()
        if "wikibase_item" in page_properties:
            wikidata_item = page_properties['wikibase_item']
        else:
            wikidata_item = None
            return(wikidata_item)
    except:
        return None
    
@logger.catch
def add_wikidata_to_indexpage_form(lang,site,indexpage, wikidata_item):

    try:
        page = pw.Page(pw.Site(lang, site), indexpage)
        text = page.get()

        counter = 0
        all_text_list = text.split("\n")

        for item in all_text_list:
            if item.startswith('|wikidata_item'):
                new_string = item.split("=")[0] + "=" +  wikidata_item
                all_text_list[counter] = new_string
                counter = counter + 1

        new_content = "\n".join(all_text_list)

        page.text=new_content
        page.save("changed wikidata_item - from the bot")
        return "success"
    except:
        return None

@logger.catch 
def set_indexpage_property_on_wikidata(qid,lang,wikisite,index_page):
    try:
        site = pw.Site("wikidata", "wikidata")
        repo = site.data_repository()
        item = pw.ItemPage(repo, qid) 
        claims = item.get(u'claims') 
        index_page = "https://" + lang + "."+ wikisite + ".org/wiki/" + index_page

        if u'P1957' in claims[u'claims']: #indexpagfe
            pw.output(u'Error: Already have a Index page ID!')
            return "exists"
        else:
            stringclaim = pw.Claim(repo, u'P1957') #Else, add the value
            #        target = pywikibot.ItemPage(repo, u"Q12451275") #Using another wikidata page (Cambridge (Q350))
            stringclaim.setTarget(index_page)
            item.addClaim(stringclaim, summary=u'Adding Index page')
            return "added"
    except:
        return None

        

@logger.catch
def main():
    counter = 1
    for item in config:
        logger.info(f"Processing item {counter} of {no_of_sites}")
        logger.info(item)
    
        lang = item.split("//")[1].split(".")[0]
        site = item.split("//")[1].split(".")[1]
        category = item.split("/wiki/")[1].strip()
    
        logger.info(f"Getting all the pages in the category {category}") 
        all_pages =   get_all_pages_in_category(lang,site,category)
        if all_pages:
            count_of_all_pages = len(all_pages)  
            logger.info(f"Success_1: Found  {count_of_all_pages}  pages in the category")

            
            for page in all_pages:
                logger.info(f"Getting main page for the index page {page}")
                mainpage = get_mainpage_from_indexpage(lang,site,page)
                if mainpage:
                    logger.info(f"Success_2: Got the mainpage {mainpage} for indexpage {page}")
                    qid_of_page = get_wikidata_item_of_page(lang,site,mainpage)
                    if qid_of_page:
                        logger.info(f"Success_3: Wikidata id of the page {mainpage} is {qid_of_page}")
                        logger.info(f"Adding {qid_of_page} to {page}")
                        add_qid = add_wikidata_to_indexpage_form(lang,site,page,qid_of_page)
                        if add_qid:
                            logger.info(f"Success_4: added {qid_of_page} to {page}")
                            logger.info(f"Adding index page property {page} to {qid_of_page}")
                            add_index_to_qid = set_indexpage_property_on_wikidata(qid_of_page,lang,site,page)
                            if add_index_to_qid == "exists":
                                logger.info(f"Fail 5.1: Some entry already exists for index property for {qid_of_page}")
                            elif add_index_to_qid == "added" :
                                logger.info(f"Success_5: Added index page property {page} to {qid_of_page}")
                            else:
                                logger.info(f"Fail_5.2: Got error on adding index page property {page} to {qid_of_page}")
                        else:
                            logger.info(f"Fail_4: Got error on adding {qid_of_page} to {page}")
                    else:
                        logger.info(f"Fail_3: Got error on getting wikidata id of the page {mainpage}")
                else:
                    logger.info(f"Fail_2: Got error on getting mainpage from the index page {page}")
        else:
            logger.info(f"Fail_1: Got error on getting all pages in the category {category}")

if __name__ == "__main__":
    main()
    
