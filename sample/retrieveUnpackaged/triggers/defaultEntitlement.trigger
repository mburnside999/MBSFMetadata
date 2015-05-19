trigger defaultEntitlement on Case (Before Insert, Before Update) {
    /*
    If the Entitlement Name is not set then, check to see if the Contact on the Case has an active Entitlement
    and select the first one.
    */
    List<Id> contactIds = new List<Id>();
    for (Case c : Trigger.new){
        if (c.EntitlementId == null && c.ContactId != null)
            contactIds.add(c.ContactId);
    }
    if(contactIds.isEmpty()==false){
        /*
        Added check for active entitlement
        Note:  you could add a search for active entitlements for the account on the case
        currently it is only checking for active entitlements explicitly associated
        with the contact on the case.
        */
        List <EntitlementContact> entlContacts = [Select e.EntitlementId, e.entitlement.primary__c, e.entitlement.name, e.ContactId From EntitlementContact e
                                                  Where e.ContactId in :contactIds And e.Entitlement.EndDate >= Today
                                                  And e.Entitlement.StartDate <= Today];
        if(entlContacts.isEmpty()==false){
            for(Case c : Trigger.new){
                if(c.EntitlementId == null && c.ContactId != null){
                    for(EntitlementContact ec:entlContacts){
                        if(ec.ContactId==c.ContactId && ec.entitlement.primary__c==true){
                            c.EntitlementId = ec.EntitlementId;
                            break;
                        }
                    } // end for
                }
            } // end for
        }
    } // end if(contactIds.isEmpty()==false)
}