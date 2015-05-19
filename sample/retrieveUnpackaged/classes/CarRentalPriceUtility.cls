public class CarRentalPriceUtility {

    public static Double getContractedCarRentalPrice(Id crcid, String typeofcar) {
        Double crdr = 0.0;
        try {
            crdr = [select daily_rate__c from car_rental_options__c where type_of_car__c = :typeofcar and car_Rental_Contract__c = :crcid limit 1].daily_rate__c;
            System.debug('Car Rental daily rate= ' + crdr);
            return crdr;
        } catch (Exception e) {
            System.debug('Error encountered + ' + e.getMessage());
            return crdr;
        }
    }
}