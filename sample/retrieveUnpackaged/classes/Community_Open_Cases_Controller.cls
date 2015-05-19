public with sharing class Community_Open_Cases_Controller {
    
    User loggedInUser = [Select Id, ContactId, Contact.AccountId From User Where Id =:UserInfo.getUserId()];
    public List<Case> openCases {get;set;}
    
    public Community_Open_Cases_Controller() {

        openCases = [Select Id, Subject, Status, ContactId 
                     From Case 
                     Where Status != 'Closed' AND ContactId= :loggedInUser.ContactId
                     Order by CreatedDate Desc Limit 5];       
    }
}