/*
	myTaskListController - controller for myTaskList Visualforce page
		Provides a list of open tasks owned by the logged in user and methods to modify them
	Author: Mike Hineline
*/
global with sharing class myTaskListController {
	// Member variable to hold the list of Tasks and related info
	public List<TaskContainer> myTaskList {get; set;}

	// Member variables to hold task sorting onClick scripts
	public String orgHost {get; set;}
	public String taskSortDateASCScript {get; set;}
	public String taskSortDateDESCScript {get; set;}
	public String taskSortPriorityScript {get; set;}
    public String taskFilterAllOpenScript {get; set;}
    public String taskFilterOverdueScript {get; set;}
    public String taskFilterTodayScript {get; set;}
    public String taskFilterTodayPlusOverdueScript {get; set;}
    public String taskFilterTomorrowScript {get; set;}
    public String taskFilterNext7DaysScript {get; set;}
    public String taskFilterNext7DaysPlusOverdueScript {get; set;}
    public String taskFilterThisMonthScript {get; set;}

   	// pageFormat will store the type of page rendered and affect how URLs work
   	//	aloha [default] => aloha (standard) UI with standard hyperlinks
   	//	mobile = Salesforce1 browser => standard hyperlinks
   	//	console = sales/service cloud console => console javascript used to open hyperlinks
    public String pageFormat {get; set;}
    
    // Member variable for the Console javascript function to create a new task
    public String taskNewScript {get; private set;}
    
    // DEBUG USE: member variable for determining page isdtp parameter
    // public Map<String,String> pageParameters {get; private set;}

	/*
		Constructor to initialize the Task list including member variables and the list of Task sObjects
	*/
    public myTaskListController()
    {
    	/*
    		Initialize the page format to determine if this is the console, Salesforce1 mobile, or Aloha UI
    	*/
    	// DEBUG USE: determine page isdtp parameter
	    // pageParameters = ApexPages.currentPage().getParameters();

    	// Determine the page rendering location (default to aloha)
		String pageisdtp = ApexPages.currentPage().getParameters().get('isdtp');
		if (pageisdtp == 'nv' || pageisdtp == 'vw') {
			pageFormat = 'console';
		} else if (pageisdtp == 'p1') {
			pageFormat = 'mobile';	
		} else {
			pageFormat = 'aloha';
		}
	    // DEBUG USE: output isdtp parameter and pageFormat to Visualforce pageMessages
		// ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.info,pageisdtp + ' - ' + pageFormat);
		// ApexPages.addmessage(msg);

    	/*
    		Initialize the sort and filter onClick scripts
    	*/
    	// Get the current task sort order and filter from the page GET parameters
    	String getSortOrder = ApexPages.currentPage().getParameters().get('so');
    	if (getSortOrder == '' || getSortOrder == null) getSortOrder = 'priorityASC';
    	String getFilter = ApexPages.currentPage().getParameters().get('flt');
    	if (getFilter == '' || getFilter == null) getFilter = 'allopen';
		// Set the base URL for this page
		orgHost = myTaskListController.calculateOrgHost();
        String thisPage = orgHost + System.URL.getCurrentRequestUrl().getPath();
    	// Initialize the sort onClick scripts
    	taskSortDateASCScript = 'https://' + thisPage + '?so=dateASC&flt=' + getFilter + '&isdtp=' + pageisdtp;
    	taskSortDateDESCScript = 'https://' + thisPage + '?so=dateDESC&flt=' + getFilter + '&isdtp=' + pageisdtp;
    	taskSortPriorityScript = 'https://' + thisPage + '?so=priorityASC&flt=' + getFilter + '&isdtp=' + pageisdtp;
    	// Initialize the filter onClick scripts
        taskFilterAllOpenScript ='https://' + thisPage + '?flt=allopen&so=' + getSortOrder + '&isdtp=' + pageisdtp;
        taskFilterOverdueScript ='https://' + thisPage + '?flt=overdue&so=' + getSortOrder + '&isdtp=' + pageisdtp;
        taskFilterTodayScript ='https://' + thisPage + '?flt=today&so=' + getSortOrder + '&isdtp=' + pageisdtp;
        taskFilterTodayPlusOverdueScript ='https://' + thisPage + '?flt=todayplusoverdue&so=' + getSortOrder + '&isdtp=' + pageisdtp;
        taskFilterTomorrowScript ='https://' + thisPage + '?flt=tomorrow&so=' + getSortOrder + '&isdtp=' + pageisdtp;
        taskFilterNext7DaysScript ='https://' + thisPage + '?flt=next7days&so=' + getSortOrder + '&isdtp=' + pageisdtp;
        taskFilterNext7DaysPlusOverdueScript ='https://' + thisPage + '?flt=next7daysplusoverdue&so=' + getSortOrder + '&isdtp=' + pageisdtp;
        taskFilterThisMonthScript ='https://' + thisPage + '?flt=thismonth&so=' + getSortOrder + '&isdtp=' + pageisdtp;

    	// Default to ascending by activity date (i.e. due date) (to put closest due dates on top)
    	// 	and then ascending by priority (to put high on top)
    	String taskSortOrder;
    	if (getSortOrder == 'dateDESC') {
    		taskSortOrder = 't.ActivityDate DESC, t.Priority ASC';
    	} else if (getSortOrder == 'priorityASC') {
    		taskSortOrder = 't.Priority ASC, t.ActivityDate ASC';
    	} else {
    		taskSortOrder = 't.ActivityDate ASC, t.Priority ASC';
    	}
    	// Get the task filter from the page GET parameters
    	// Default to all open
    	String taskFilter;
    	if (getFilter == 'overdue') {
    		taskFilter = ' AND t.ActivityDate < TODAY';
    	} else if (getFilter == 'today') {
    		taskFilter = ' AND t.ActivityDate = TODAY';
    	} else if (getFilter == 'todayplusoverdue') {
    		taskFilter = ' AND t.ActivityDate <= TODAY';
    	} else if (getFilter == 'tomorrow') {
    		taskFilter = ' AND t.ActivityDate = TOMORROW';
    	} else if (getFilter == 'next7days') {
    		taskFilter = ' AND t.ActivityDate = NEXT_N_DAYS:7';
    	} else if (getFilter == 'next7daysplusoverdue') {
    		taskFilter = ' AND (t.ActivityDate < TODAY OR t.ActivityDate = NEXT_N_DAYS:7)';
    	} else if (getFilter == 'thismonth') {
    		taskFilter = ' AND t.ActivityDate = THIS_MONTH';
    	} else {
    		// default all open
    		taskFilter = '';
    	}
    	
		// JavaScript string to open new console primary tab with id=null, url='/00T/e', active=true, tabLabel='New Task' 
		taskNewScript = myTaskListController.formatURL(null,'New Task','new','Task',pageFormat);
    	
        // Create a activity wrapper sObject to contain the Task + Account info
    	myTaskList = new List<TaskContainer>();
    	
    	// Generate a list of all Tasks assigned to (via OwnerId) the logged in user
    	String myTaskQueryString = 'SELECT t.Id, t.OwnerId, t.ActivityDate, t.Subject, t.Priority, t.Status, t.Description, t.Type, t.CreatedDate, t.WhoId, t.Who.Name, t.WhatId, t.What.Name, t.AccountId, t.IsClosed';
        myTaskQueryString += ' FROM Task t';
		myTaskQueryString += ' WHERE t.IsClosed = false AND t.IsDeleted = false';
		myTaskQueryString += ' AND t.OwnerID = \'' + UserInfo.getUserId() + '\'';
		myTaskQueryString += taskFilter;
		myTaskQueryString += ' ORDER BY ' + taskSortOrder;
		List<Task> myTasks = Database.query(myTaskQueryString);
		
        // Fill member variable myTaskList with the user's events
        if (myTasks.size() > 0) {
        	for(Task t : myTasks) {
        		// Replace carriage returns in description with HTML line breaks
        		if (t.Description != null) {
					t.Description = t.Description.replace('\r','<br />');
        		}
        		myTaskList.add( new TaskContainer(t,this) );
        	}
        }
    }

	/*
		TaskContainer - class for storing Task sObject & related information
	*/
    public class TaskContainer {
    	// Getter/Setter for the contained Task sObject
        public Task taskSObject {get;set;}
        // Member variables for the Console javascript function to open, edit, and close the task
        public String taskOpenScript {get; private set;}
        public String taskEditScript {get; private set;}
        public String taskCloseScript {get; private set;}
        public String taskQuickCloseScript {get; private set;}
        // Member variable for the Console javascript function to open a related WhoId
        public String taskWhoOpenScript {get; private set;}
        // Member variable for the Console javascript function to open a related WhatId
        public String taskWhatOpenScript {get; private set;}
        // Member variable for the header CSS class addition of a card when the priority is high
        public String priorityPanelClass {get; private set;}
        // Member variable for the header CSS class addition of a card when the priority is high
        public String priorityIconClass {get; private set;}
        // Member variable for the CSS class addition to highlight the task due date
        public String dueDateStyle {get; private set;}

        // Empty constructor
        public TaskContainer() {
        }
        // Overloaded constructor to initialize the date when given an Task
        public TaskContainer(Task t, myTaskListController theController) {
            taskSObject = t;
            /*
				Define the appropriate javascript function to open the task in a console tab
			*/
			// Define the JavaScript functions to open and edit the task in a tab
            taskOpenScript = 'javascript:void(0);';
            taskEditScript = 'javascript:void(0);';
            taskCloseScript = 'javascript:void(0);';
            taskQuickCloseScript = 'javascript:void(0);';
            // Define the JavaScript function to open any related Task.WhoId tab
            taskWhoOpenScript = 'javascript:void(0);';
            // Define the JavaScript function to open any related Task.WhatId tab
            taskWhatOpenScript = 'javascript:void(0);';
            // Define the CSS class addition for the panel based on case priority; by default, no modification is made
            priorityPanelClass = '';
            // Define the CSS class addition based on case priority; by default, the priority icon is hidden
            priorityIconClass = 'hidden';
            // Define the CSS class addition based on due date; by default, no modification is made
            dueDateStyle = '';

			/*
				Initialize various UI features such as javascript calls and formatting options for this task
			*/
            String tabUrl = null;
            String tabLabel = null;
            String thisEntityName = 'Task';
            if (t != null) {
            	// JavaScript string to open task for viewing
            	taskOpenScript = myTaskListController.formatURL(t.Id,t.Subject,'view',thisEntityName,theController.pageFormat);
       	    	// JavaScript string to open task for editing
            	taskEditScript = myTaskListController.formatURL(t.Id,t.Subject,'edit',thisEntityName,theController.pageFormat);
				// JavaScript string to open task for closing/editing
            	taskCloseScript = myTaskListController.formatURL(t.Id,t.Subject,'close',thisEntityName,theController.pageFormat);
				// JavaScript string to open task for closing/editing
            	taskQuickCloseScript = myTaskListController.formatURL(t.Id,t.Subject,'close',thisEntityName,theController.pageFormat);
            }
            if (t.WhoId != null) {
            	// JavaScript string to open contact for viewing
            	taskWhoOpenScript = myTaskListController.formatURL(t.WhoId,t.Who.Name,'view',thisEntityName,theController.pageFormat);
            }
            if (t.WhatId != null) {
            	tabUrl = '\'/' + t.WhatId + '\'';
            	tabLabel = '\'' + t.What.Name + '\'';
            	// JavaScript string to open Related To record for viewing
            	taskWhatOpenScript = myTaskListController.formatURL(t.WhatId,t.What.Name,'view',thisEntityName,theController.pageFormat);
            }
            if (t.Priority.toLowerCase() == 'high') {
	            // If priority is high, apply Bootstrap CSS class for a red panel header
            	priorityPanelClass = ' panel-danger';
	            // If priority is high, do not apply the hidden class
            	priorityIconClass = '';
            }
            if (t.ActivityDate <= System.Date.today()) {
	            // If the ActivityDate is <= today, apply Bootstrap CSS class text class for red text
            	dueDateStyle = 'text-danger';
            }
        }
    }

	/*
		calculateOrgHost - return the Salesforce naX.salesforce.com host name
		Inputs: none
		Returns: String thisOrgHost
	*/
	static String calculateOrgHost() {
		// Split up the hostname using the period as a delimiter
		String thisOrgHost;
        List<String> urlParts = System.URL.getSalesforceBaseUrl().getHost().replace('-api','').split('\\.');
        if (urlParts.size() == 3) thisOrgHost = urlParts[0] + '.salesforce.com';
        else if (urlParts.size() == 5) thisOrgHost = urlParts[1] + '.salesforce.com';
        
        return thisOrgHost;
	}
	
	/*
		Remote method to create JavaScript string used by Visualforce onClick attributes
		to present an object across numerous UI's (aloha, console, & Salesforce1 mobile app)
		Inputs:
		- ID recordID - ID of the record to which to navigate (null if creating a new record)
		- String targetLabel - title of the console tab
		- String targetAction:
			- view - open the record for viewing
			- edit - open the record for editing
			- close - open the URL with delete rendering where available (console, aloha, NOT Salesforce1)
			- new - create a new record 
		- String entityName - name of the object type (e.g. Task)
		- String pageFormat - UI from which page is being viewed (console, mobile, aloha)
		Returns:
		- String with javascript function to navigate to the given targetURL formatted for the current UI
	*/
	@RemoteAction
	global static String formatURL(ID recordID, String targetLabel, String targetAction, String entityName, String pageFormat) {
		// String that will be returned by this function, defaulting to the void JavaScript function
		String returnURL = 'javascript:void(0);';
		// Escape the targetLabel
		String targetLabelSafe = targetLabel.escapeXml();
		
		// Set the default URL to be the recordID
        String thisURL = '/' + recordID;
        if (targetAction == 'close') {
        	// close/edit modifier
        	thisURL += '/e?close=1&cancelURL=%2F' + recordID;
        } else if (targetAction == 'edit') {
        	// edit modifier
        	thisURL += '/e';
        } else if (targetAction == 'new') {
        	// new URL (overwrites initialized default)
        	thisURL = '/00T/e';
        }

		// Form the appropriate javascript function based on the UI the user is using
		if (pageFormat == 'console') {
			// JavaScript string to open the targetURL in a new console primary tab with id=null, url=thisURL, active=true, tabLabel=targetLabelSafe, callback = N/A, name = N/A 
			returnURL = 'javascript:sforce.console.openPrimaryTab(null, \'' + thisURL + '\', true, \'' + targetLabelSafe + '\'); return false;';
		} else if (pageFormat == 'mobile') {
			if (targetAction == 'view') {
				// JavaScript string to open record for viewing in Salesforce1
				returnURL = 'javascript:sforce.one.navigateToSObject(\'' + recordID + '\');';
			} else if (targetAction == 'new') {
				// JavaScript string to create a new record for viewing in Salesforce1
				returnURL = 'javascript:sforce.one.createRecord(\'' + entityName + '\');';
			} else {
				// JavaScript string to open record for closing/editing in Salesforce1
				// NOTE: this does not set the status to completed as with the console or Aloha UI implementations
				returnURL = 'javascript:sforce.one.editRecord(\'' + recordID + '\');';
			}
		} else {
			// JavaScript string to open record using normal browser window.open commands (for the Aloha UI)
			returnURL = 'javascript:window.open(\'' + thisURL + '\',\'' + recordID + '\'); return false;';
		}

		return returnURL;
	}
	
	/*
		Remoting method to update a Task record
		Inputs:
		- ID recordID - ID of the record to update
		- String targetField - API name of the field to update (null if just getting the updated task from the DB)
		- String newValue - new value to store in targetField (null if just getting the updated task from the DB)
		Returns:
		- Task - the updated Task sObject
	*/
	@RemoteAction
	global static Task updateTask(ID recordID, String targetField, String newValue) {
		// Get the sObject from the input recordID
		Task thisTask = [SELECT t.Id, t.OwnerId, t.ActivityDate, t.Subject, t.Priority, t.Status, 
						t.Description, t.Type, t.CreatedDate, t.WhoId, t.Who.Name, t.WhatId, t.What.Name,
						t.AccountId, t.IsClosed, t.IsDeleted  
						FROM Task t
						WHERE t.Id = :recordID];
		
		// Determine if we should perform the DML update operation; by default, do not unless we get a valid targetField
		Boolean performDML = false;
		// Determine if the record needs to be requeried when finished; by default, it will not be
		Boolean reQueryRecord = false;
		
		// Update the appropriate targetField
		if (targetField == 'Status') {
			thisTask.Status = newValue;
			// Trigger the DML update
			performDML = true;
			// Trigger querying the sObject again to ensure calculated field IsClosed is up to date
			reQueryRecord = true;
		} else if (targetField == 'Priority') {
			thisTask.Priority = newValue;
			// Trigger the DML update
			performDML = true;
		} else if (targetField == null || targetField == '') {
			// Reiterate no DML update and no requery; just passing the object back
			performDML = false;
			reQueryRecord = false;
		} else {
			System.debug(LoggingLevel.ERROR, 'ERROR: Unknown targetField was passed');
			return null;
		}
		
		// Perform the DML update
		if (performDML) {
			try {
				update thisTask;	
			} catch (DmlException e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
				return null;
			}
		}

		// Get the sObject again to ensure calculated fields cush as IsClosed are up to date
		if (reQueryRecord) {
			thisTask = [SELECT t.Id, t.OwnerId, t.ActivityDate, t.Subject, t.Priority, t.Status, 
						t.Description, t.Type, t.CreatedDate, t.WhoId, t.Who.Name, t.WhatId, t.What.Name,
						t.AccountId, t.IsClosed, t.IsDeleted  
						FROM Task t
						WHERE t.Id = :recordID];
		}
		
		// Replace carriage returns in description with HTML line breaks
        if (thisTask.Description != null) {
			thisTask.Description = thisTask.Description.replace('\r','<br />');
        }
        
		// Return the Task sObject
		return thisTask;
		
	}
	
	/*
		emailTask - Remoting method to send a task to the logged in User via e-mail
		Inputs:
		- ID recordID - ID of the record to send
		Returns:
		- Boolean success - true if the mail send was successful / false if there is a sending exception
	*/
	@RemoteAction
	global static Boolean emailTask(ID recordID) {
		// Get the sObject from the input recordID
		Task thisTask = [SELECT t.Id, t.OwnerId, t.ActivityDate, t.Subject, t.Priority, t.Status, 
						t.Description, t.Type, t.CreatedDate, t.WhoId, t.Who.Name, t.WhatId, t.What.Name,
						t.AccountId, t.IsClosed, t.IsDeleted  
						FROM Task t
						WHERE t.Id = :recordID];
		
		// If the task was not found, return false
		if(thisTask == null) {
			return false;
		}

		// Get the base URL for object links
		String orgHost = myTaskListController.calculateOrgHost();
		String thisTaskBaseURL = 'https://' + orgHost + '/';

		/*
			Construct the e-mail reminder message
		*/
		// Send the message to the current user and set appropriate messaging defaults
		// use setTargetObjectId instead of setToAddressses to avoid SingleEmailMessage governer limit
		Messaging.SingleEmailMessage thisMail = new Messaging.SingleEmailMessage();
        thisMail.setTargetObjectId(UserInfo.getUserId());
        thisMail.setSaveAsActivity(false);
        thisMail.setUseSignature(false);
		// Set the e-mail subject
        String thisSubject = 'REMINDER: ' + thisTask.Subject;
        thisMail.setSubject(thisSubject);
        // Construct the e-mail HTML and Plain Text bodies
        String thisHTMLBody = 'Reminder for task: <a href="' + thisTaskBaseURL + thisTask.Id + '">' + thisTask.Subject + '</a><br /><br />';
        String thisPlainTextBody = 'Reminder for task: ' + thisTask.Subject + ' (' + thisTaskBaseURL + thisTask.Id + ')\n\n';
        if (thisTask.ActivityDate != null) {
        	thisHTMLBody += 'Due: ' + thisTask.ActivityDate.format() + '<br />';
        	thisPlainTextBody += 'Due: ' + thisTask.ActivityDate.format() + '\n';
        }
        if (thisTask.whatId != null) {
        	thisHTMLBody += 'RE: <a href="' + thisTaskBaseURL + thisTask.WhatId + '">' + thisTask.What.Name + '</a><br />';
        	thisPlainTextBody += 'RE: ' + thisTask.What.Name + ' (' + thisTaskBaseURL + thisTask.WhatId + ')\n';
        }
		if (thisTask.Status != null && thisTask.Status != '') {
        	thisHTMLBody += 'Status: ' + thisTask.Status + '<br />';
        	thisPlainTextBody += 'Status: ' + thisTask.Status + '\n';
		}
		if (thisTask.Type != null && thisTask.Type != '') {
        	thisHTMLBody += 'Type: ' + thisTask.Type + '<br />';
        	thisPlainTextBody += 'Type: ' + thisTask.Type + '\n';
		}
		if (thisTask.WhoId != null) {
        	thisHTMLBody += 'Who: <a href="' + thisTaskBaseURL + thisTask.WhoId + '">' + thisTask.Who.Name + '</a><br />';
        	thisPlainTextBody += 'Who: ' + thisTask.Who.Name + ' (' + thisTaskBaseURL + thisTask.WhoId + ')\n';
		}
		if (thisTask.Description != null && thisTask.Description != '') {
			String thisHTMLDescription = thisTask.Description.replace('\r','<br>');
        	thisHTMLBody += 'Description: <br />' + thisHTMLDescription + '<br />';
        	thisPlainTextBody += 'Description: \n' + thisTask.Description + '\n';
		}
        // Assemble the mail
        thisMail.setHtmlBody(thisHTMLBody);
        thisMail.setPlainTextBody(thisPlainTextBody);
        // Send the mail
        try {
        	Messaging.SendEmailresult[] mailResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { thisMail }); 
        } catch (System.EmailException e) {
        	System.Debug('The following error has occurred: ' + e.getMessage());
        	return false;
        }
		
		return true;
	}
	
}