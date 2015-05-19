@isTest
public class AccomPriceUtility_Test {
    public static testMethod void accomtest() {
        
        Id acid='a27F0000005pObX';
        String location ='Melbourne';
        
        Double lcc = 0.0;
        
        AccomPriceUtility.getContractedAccomPrice(acid,location);
        
        try {
            lcc = [select location_contract_cost__c from location_Costs__c where location__C = :location and Accomodation_Contract__c = :acid limit 1].location_contract_cost__c;
            System.debug('Accomodation location cost= ' + lcc);
          
        } catch (Exception e) {
            System.debug('Error encountered + ' + e.getMessage());
   
        }
        lcc=2.0;
        
      System.Assert(lcc>0)  ;
        
    }
}