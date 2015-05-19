public with sharing class changeLogs {

    public pageReference goNew(){
        return new PageReference('/' + SDO_Changelog__c.SobjectType.getDescribe().getKeyPrefix() + '/e?');
    }

    public SDO_Changelog__c getNewPost()
    {
        List<SDO_Changelog__c> npList = [select id, name, lastmodifieddate, createdDate, body__c from SDO_Changelog__c order by changelog_number__c desc limit 1];
        if(npList.size() > 0)
            return npList[0];
        else
            return new SDO_Changelog__c();
    }

    public List<SDO_Changelog__c> getAllPosts(){
        return [select id, name, lastmodifieddate, createdDate, body__c from SDO_Changelog__c order by changelog_number__c desc];
    }

    public static testMethod void testMe(){
        changeLogs cl = new changeLogs();
        cl.goNew();
        cl.getAllPosts();
        cl.getNewPost();
    }

}