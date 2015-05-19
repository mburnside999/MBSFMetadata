trigger trgCarRentalCost on Car_Rental__c(before insert, before update) {
    for (Car_Rental__c a: Trigger.New) {
        Id crc = [select Car_Rental_Contract_del__c from Travel_Request__c where id = :a.Travel_Request__c].car_Rental_Contract_del__c;
        a.Contracted_Value__c = CarRentalPriceUtility.getContractedCarRentalPrice(crc, a.type_of_Car__c);
    }
}