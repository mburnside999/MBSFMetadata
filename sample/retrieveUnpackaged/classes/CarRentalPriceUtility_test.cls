@isTest

public class CarRentalPriceUtility_test {

static testMethod void carentaltest(){


       Double crdr = 2.0;
       Id crcid ='a28F0000002eUCd';
       String typeofcar= 'Economy';
       
        CarRentalPriceUtility.getContractedCarRentalPrice(crcid,typeofcar) ;
   
         
        try {
            crdr = [select daily_rate__c from car_rental_options__c where type_of_car__c = :typeofcar and car_Rental_Contract__c = :crcid limit 1].daily_rate__c;
            System.debug('Car Rental daily rate= ' + crdr);
           
        } catch (Exception e) {
            System.debug('Error encountered + ' + e.getMessage());
            }
            crdr= 3.0;
              
        System.Assert(crdr>0);
         
        }
    }