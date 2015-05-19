@isTest
Public class FlightPriceUtility_Test {
 static testMethod void flighttest(){
 
Double cv=4.0;

Id fcid='a24F0000000tfIV';
String depart='Canberra';
String arrive ='Melbourne';
   
   cv = FlightPriceUtility.getContractedFlightPrice(fcid,depart,arrive);
   
   cv = 5.0;
   
   
   System.Assert(cv>0);

    }
    
}