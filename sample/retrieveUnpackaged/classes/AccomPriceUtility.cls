public class AccomPriceUtility {
    public static Double getContractedAccomPrice(Id acid, String location) {
        Double lcc = 0.0;
        try {
            lcc = [select location_contract_cost__c from location_Costs__c where location__C = :location and Accomodation_Contract__c = :acid limit 1].location_contract_cost__c;
            System.debug('Accomodation location cost= ' + lcc);
            return lcc;
        } catch (Exception e) {
            System.debug('Error encountered + ' + e.getMessage());
            return lcc;
        }
    }
}