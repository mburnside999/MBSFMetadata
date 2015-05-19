trigger trgFlightCost on Flight__c(before insert, before update) {
    for (Flight__c f: Trigger.New) {
        Id fc = [select flight_contract__c from Travel_Request__c where id = :f.Travel_Request__c].flight_contract__c;
        f.contracted_value__c = FlightPriceUtility.getContractedFlightPrice(fc, f.flight_from__c, f.flight_to__c);
        f.Flight_Contract__c = fc;
    }
}