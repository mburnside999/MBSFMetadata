public class FlightPriceUtility {

public static Double getContractedFlightPrice(Id fcid,String depart,  String arrive)  
{
 
Double cv=0.0;
    
    try {
cv = [select contract_value__c from contract_pair__c where arrive__c=:arrive and depart__C=:depart and  flight_contract__c=:fcid limit 1].contract_value__c  ;  
System.debug('Contract price= '+cv);
return cv;
    } catch (Exception e){
        System.debug('Error encountered + '+e.getMessage());
   return cv;     
    
    }
    
}
     
}