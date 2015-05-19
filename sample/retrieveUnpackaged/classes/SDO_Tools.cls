/*
 * Modified & Cloned from APEX Class SDO_Tools
 * @author Sameer Singhvi
 * @version 1.0
 * @changeSet Redesigned wCategory & condensed code.
 */
public with sharing class SDO_Tools {
    
    public List<wCategory> category_list {get;set;}
    
    public SDO_Tools() {
        /* Initialize variables */
        category_list = new List<wCategory>();

        /* Grab all possible picklist values for SDO_Tool__c.Category__c and create a new wCategory */
        for(Schema.PicklistEntry cat : SDO_Tool__c.Category__c.getDescribe().getPicklistValues())
            category_list.add(new wCategory(cat.getValue()));
    }
    
    /* Represents a Category * it's tools for SideNavBar */
    public class wCategory {
        public String category_title {get;set;}
        public List<SDO_Tool__c> category_tools {get;set;}
         
        public wCategory(String title) {
            category_title = title;
            category_tools = [Select Id, Name, url__c, pop_new_window__c, height__c, width__c 
                              From SDO_Tool__c
                              Where category__c = :category_title 
                              Order by order__c asc];                                         

            /* Modify url__c for each SDO_Tool__c from relative to direct link */
            String s = (ApexPages.Currentpage() == null) ? 'https://na1.salesforce.com/apex/sdo_tools' : ApexPages.currentPage().getUrl();
            s = (s == null) ? 'https://na1.salesforce.com/apex/sdo_tools' : s.substring(0, s.indexOf('/'));

            for(SDO_Tool__c t : category_tools) {
                t.url__c = (t.url__c.contains('/apex/')) ? s + t.url__c : s + '/apex/' + t.url__c;
                t.url__c = (t.url__c.contains('?')) ? t.url__c + '&isdtp=vw' : t.url__c + '?isdtp=vw';
            }
        }
    }    
}