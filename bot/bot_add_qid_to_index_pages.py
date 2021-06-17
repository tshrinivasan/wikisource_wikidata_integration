from loguru import logger

import pywikibot
import pywikibot as pw
import pywikibot.pagegenerators
from pprint import pprint
import sys
import time


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
    logger.info(f"reading the indexpage {indexpage}")
    try:
        page = pywikibot.Page(pywikibot.Site(lang, site), indexpage)
#        logger.info(f"Found main page {page} for the indexpage {indexpage}")
    except:
        logger.info(f"Cant get mainpage for the indexpage {indexpage}")
        return None
    if page:
        text = page.get()

        if '|Title' in text:
            all_text_list = text.split("\n")
            for item in all_text_list:
                if item.startswith('|Title'):
                    print(item)
                    title = item.split("=")[1].replace('[[','').replace(']]','')
                    if len(title) > 1:
                        logger.info(f"Found title : {title}") 
                        return title
                    else:
                        logger.info("There is no value for Title")
                        return None

        else:
            logger.info(f"Cant get '|Title' on the page content for {page}")
            return None
    #except:
    #    return None

@logger.catch
def get_wikidata_item_of_page(lang,site,page):
    
    page = pw.Page(pw.Site(lang, site), page)
    page_properties = page.properties()
    print(page_properties)
    if "wikibase_item" in page_properties:
        wikidata_item = page_properties['wikibase_item']
        return(wikidata_item)
    else:
        wikidata_item = None
        return(wikidata_item)
    #except:
    #    return None
    
@logger.catch
def add_wikidata_to_indexpage_form(lang,site,indexpage, wikidata_item):
    
    page = pw.Page(pw.Site(lang, site), indexpage)
    text = page.get()
    counter = 0
    print(text)
#    sys.exit()

    if not "wikidata_item" in text:
        new_lineitem = "|wikidata_item=" + wikidata_item + "\n"
        new_content = new_lineitem + text.split("{{:MediaWiki:Proofreadpage_index_template")[1]
        new_content = "{{:MediaWiki:Proofreadpage_index_template" + "\n" + new_content

#        new_content = text.split("}}")[0]+ new_lineitem + "}}"
        print(new_content)

    if "wikidata_item" in text:
        all_text_list = text.split("\n")
        #print(all_text_list)
        for item in all_text_list:
            # print(item)
            if item.startswith('|wikidata_item'):
                
                existing_qid = item.split("=")[1]
                if existing_qid:
                    return existing_qid
                else:
                    new_string = item.split("=")[0] + "=" +  wikidata_item
                
                    all_text_list[counter] = new_string
            counter = counter + 1

            
        new_content = "\n".join(all_text_list)
        print(new_content)
#        sys.exit()
        page.text=new_content
        page.save("changed wikidata_item - from the bot")
        return "success"
#    except:
 #       return None

@logger.catch 
def set_indexpage_property_on_wikidata(qid,lang,wikisite,index_page):
    try:
        site = pw.Site("wikidata", "wikidata")
        repo = site.data_repository()
        item = pw.ItemPage(repo, qid) 
        claims = item.get(u'claims') 
        index_page = "https://" + lang + "."+ wikisite + ".org/wiki/" + index_page
        index_page = index_page.replace(" ","_")
        if u'P1957' in claims[u'claims']: #indexpagfe
            pw.output(u'Error: Already have a Index page ID!')
            return "exists"
        else:
            stringclaim = pw.Claim(repo, u'P1957') #Else, add the value
            #        target = pywikibot.ItemPage(repo, u"Q12451275") #Using another wikidata page (Cambridge (Q350))
            stringclaim.setTarget(index_page)
            item.addClaim(stringclaim, summary=u'Adding Index page - from the bot')
            return "added"
    except:
        return None

        

@logger.catch
def main():
    site_counter = 1
    for item in config:
        logger.info(f"Processing item {site_counter} of {no_of_sites}")
        logger.info(item)
    
        lang = item.split("//")[1].split(".")[0]
        site = item.split("//")[1].split(".")[1]
        category = item.split("/wiki/")[1].strip()
    
        logger.info(f"Getting all the pages in the category {category}") 
        all_pages =   get_all_pages_in_category(lang,site,category)
        if all_pages:
            count_of_all_pages = len(all_pages)  
            logger.info(f"Success_1: Found  {count_of_all_pages}  pages in the category")
                
            index_page_counter = 1
            for index_page_link in all_pages:
                logger.info("\n\n")
                
                logger.info("============")
                logger.info(f"Processing item {index_page_counter} of {count_of_all_pages}")
                time.sleep(500/1000)
                
                logger.info(f"Getting main page for the index page {index_page_link}")
                index_page_link_title = index_page_link.title()
                logger.info(f"index page URL = https://{lang}.{site}.org/wiki/{index_page_link_title}")
 #               page = "ਇੰਡੈਕਸ:ਕੌਡੀ ਬਾਡੀ ਦੀ ਗੁਲੇਲ - ਚਰਨ ਪੁਆਧੀ.pdf"
#                page = "ਇੰਡੈਕਸ:Sohni Mahiwal - Qadir Yar.pdf"
#                logger.info(dir(index_page_link))
                index_page = index_page_link.title()
                logger.info(index_page)
                mainpage = get_mainpage_from_indexpage(lang,site,index_page_link_title)
#                sys.exit()
                if mainpage:
                    mainpage_title = mainpage.title()
                    logger.info(f"Success_2: Got the mainpage {mainpage} for indexpage {index_page}")
                    logger.info(f"main page URL = https://{lang}.{site}.org/wiki/{mainpage_title}")
                    
                    qid_of_page = get_wikidata_item_of_page(lang,site,mainpage)
                    
                    if qid_of_page:
                        logger.info(f"Success_3: Wikidata id of the page {mainpage} is {qid_of_page}")
                        logger.info(f"wikidata URL = https://wikidata.org/wiki/{qid_of_page}")
                        
                        logger.info(f"Adding {qid_of_page} to {index_page}")
                        add_qid = add_wikidata_to_indexpage_form(lang,site,index_page,qid_of_page)
                        logger.info(add_qid)
                        if not add_qid =="success":
                            logger.info(f"Already a wikidata_item is available. The avaliable value is {add_qid}")
                        elif add_qid =="success":
                            logger.info(f"SUCCESS_4: added {qid_of_page} to {index_page}")
                            logger.info(f"Check https://{lang}.{site}.org/wiki/{index_page_link_title}")
                                        
                            logger.info(f"Adding index page property {index_page} to {qid_of_page}")
                            add_index_to_qid = set_indexpage_property_on_wikidata(qid_of_page,lang,site,index_page)
                            if add_index_to_qid == "exists":
                                logger.info(f"Fail 5.1: Some entry already exists for index property for {qid_of_page}")
                            elif add_index_to_qid == "added" :
                                logger.info(f"SUCCESS_5: Added index page property {index_page} to {qid_of_page}")
                                logger.info(f"Check https://www.wikidata.org/wiki/{qid_of_page}")
                        
                            else:
                                logger.info(f"Fail_5.2: Got error on adding index page property {index_page} to {qid_of_page}")
                
                        else:
                            logger.info(f"Fail_4: Got error on adding {qid_of_page} to {index_page}")
                    else:
                        logger.info(f"Fail_3: Got error on getting wikidata id of the page {mainpage}")
                else:
                    logger.info(f"Fail_2: Got error on getting mainpage from the index page {index_page}")
#                sys.exit()
                index_page_counter = index_page_counter + 1
#                if index_page_counter == 20:
#                    sys.exit()
        else:
            logger.info(f"Fail_1: Got error on getting all pages in the category {category}")
            
    site_counter = site_counter + 1
    
if __name__ == "__main__":
    main()
    
