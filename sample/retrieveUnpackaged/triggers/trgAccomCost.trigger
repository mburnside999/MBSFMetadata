trigger trgAccomCost on Accomodation__c(before insert, before update) {
    for (Accomodation__c a: Trigger.New) {
        Id ac = [select accomodation_contract__c from Travel_Request__c where id = :a.Travel_Request__c].accomodation_contract__c;
        a.Accom_Cost__c = AccomPriceUtility.getContractedAccomPrice(ac, a.location__c);
    }
}