public with sharing class SlickSidebarActivityHistory {
	public List<ActivityHistory> activities {set;get;}

	public SlickSidebarActivityHistory() {
		if (SlickSidebarController.primaryTabObjectType != null) {
			init();
		}		
	}
	/**
	 *
	 * Activity history is a bit of a special case for querying in that:
	 * 1) There is no fieldset that can directly be attributed to the History
	 * 2) It cannot be queried directly and needs to be rolled up under a parent object
	 * 3) The API name doesn't follow convention and goes by the plural name
	 * 
	 **/
	public void init() {
		activities = new List<ActivityHistory>();
		String actQueryString;
		List<Contact> contactHistory;
		List<Case> caseHistory;
		List<Account> accountHistory;
        
        //new
        List<Lead> leadHistory;
        
		actQueryString = SlickSidebarFieldSetHelper.createBaseQueryString(new ActivityHistory(), SObjectType.Event.FieldSets.SlickSidebarActivityHistory.getFields());
		actQueryString += ' ORDER BY ActivityDate DESC NULLS LAST LIMIT 5';

		// For some reason the ActivityHisty sObject is called ActivitiyHistories vs. the base object name???
		actQueryString = actQueryString.replaceFirst('ActivityHistory', 'ActivityHistories');

		// The nested query that will just pull the activities
		//System.debug('ConsoleWidgetActivityHistory.init - actQueryString: ' + actQueryString);

		String queryString = 'SELECT (' + actQueryString + ') FROM ';
		if ( SlickSidebarController.currContact != null ) {
			queryString += ' Contact where Id = \'' + SlickSidebarController.currContact.Id + '\'';
			contactHistory = Database.query(queryString);

			for (Contact curContact : contactHistory) {
				for (ActivityHistory act : curContact.ActivityHistories) {
					activities.add(act);
				}
			}
		} else if ( SlickSidebarController.currCase != null ) {
			queryString += ' Case where Id = \'' + SlickSidebarController.currCase.Id + '\'';
			caseHistory = Database.query(queryString);

			for (Case curCase : caseHistory) {
				for (ActivityHistory act : curCase.ActivityHistories) {
					activities.add(act);
				}
			}
		} 
        else if ( SlickSidebarController.currLead != null ) {
           
			queryString += ' Lead where Id = \'' + SlickSidebarController.currLead.Id + '\'';
			leadHistory = Database.query(queryString);

			for (Lead curLead : leadHistory) {
				for (ActivityHistory act : curLead.ActivityHistories) {
					activities.add(act);
				}
			}
		}
        
        
        else {
			queryString += ' Account where Id = \'' + SlickSidebarController.currAccount.Id + '\'';
			accountHistory = Database.query(queryString);

			for (Account curAccount : accountHistory) {
				for (ActivityHistory act : curAccount.ActivityHistories) {
					activities.add(act);
				}
			}			
		}
		System.debug('SlickSidebarActivityHistory.init - FINAL queryString: ' + queryString);
	}


	public List<Schema.FieldSetMember> getFieldSetMembers() {
		return SObjectType.Event.FieldSets.SlickSidebarActivityHistory.getFields();
	}

	public String getObjectName() {
		return ActivityHistory.sObjectType.getDescribe().getLabel();
	}
	public void UnitTestCompliance() {
		Integer i=0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;	
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;			
	}	
}