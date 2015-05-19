/* Unit test to cover:
    - myTaskList Visualforce page
    - myTaskList Apex class (controller extension for Visualforce page)
*/
@isTest
private class myTaskList_test {

	/*
    	CreateTasks - utility method to create test Tasks and return them in a List
    	Inputs:
    		basename = beginnging of task.Subject string, to be concatenated with an incrementing integer
    		objectCount = number of test records to be created
    	Output:
    		List<Task> = list containing the records created
   	*/
    public static List<Task> CreateTasks(String basename, Integer objectCount) {
        // List to hold the Task sObjects
        List<Task> newTasks = new List<Task>();
        
        // Fill the list with test records with names initialized based on basename
        for(Integer i=0; i<objectCount; i++) {
            newTasks.add(new Task(Subject = basename + String.valueof(i)));
        }
        
        // Return the list of records created
        return newTasks;
    }

	/*
		myTaskListTestMethod - main test class for the My Task List package components
	*/
    static testMethod void myTaskListTestMethod() {
        // Create a test opportunity for the WhatId field
        Opportunity testOpportunity = new Opportunity(Name='Test Opportunity',CloseDate=Date.today()+365,StageName='Prospecting');
        insert testOpportunity;
        
        // Create a test contact for the WhoId field
        Contact testContact = new Contact(LastName='TestContact');
        insert testContact;

        // Initialize test data and add test data for required fields
        final Integer NUM_TEST_TASKS = 20;
        List<Task> testTasks = CreateTasks('TestTask_',NUM_TEST_TASKS);
        for(Task thisTask: testTasks) {
			thisTask.OwnerID = UserInfo.getUserId();
			thisTask.Status = 'In Progress';
			thisTask.WhatId = testOpportunity.Id;
			thisTask.WhoId = testContact.Id;
			thisTask.Priority = 'Normal';
        }
        insert testTasks;
        
        // Set Visualforce page
        PageReference page = new PageReference('myTaskList');
        Test.setCurrentPage(page); 
        
        /*
        	Test query and aloha formatting
        */
        // Set the controller
        myTaskListController controller = new myTaskListController();
        // Test that <NUM_TEST_TASKS> of TaskContainers were added to myTaskList
        System.assertEquals(controller.myTaskList.size(),NUM_TEST_TASKS); 
        // Test aloha link formatting
        System.assertEquals(controller.pageFormat,'aloha');
        System.assertEquals(controller.myTaskList[0].taskOpenScript.left(22),'javascript:window.open');

        /*
        	Test console formatting
        */
        ApexPages.CurrentPage().getparameters().put('isdtp', 'nv');
        // Set the controller
        controller = new myTaskListController();
        // Test console link formatting
        System.assertEquals(controller.pageFormat,'console');
        System.assertEquals(controller.myTaskList[0].taskOpenScript.left(40),'javascript:sforce.console.openPrimaryTab');

        /*
        	Test mobile formatting
        */
        ApexPages.CurrentPage().getparameters().put('isdtp', 'p1');
        // Set the controller
        controller = new myTaskListController();
        // Test Salesforce1 link formatting
        System.assertEquals(controller.pageFormat,'mobile');
        System.assertEquals(controller.myTaskList[0].taskOpenScript.left(39),'javascript:sforce.one.navigateToSObject');
        
        /*
        	Test the updateTask remote static action - modify Status to completed
        	Test data was all created with Status = 'In Progress' so updating Status to Completed
        		should result in IsClosed = true for the passed task
        */
        Task updatedTask = myTaskListController.updateTask(testTasks[0].Id,'Status','Completed');
        System.assertEquals(updatedTask.IsClosed,true);

        /*
        	Test the updateTask remote static action - modify Priority to high
        */
        Task updatedTask2 = myTaskListController.updateTask(testTasks[0].Id,'Priority','High');
        System.assertEquals(updatedTask2.Priority,'High');

        /*
        	Test the updateTask remote static action - query only
        	The test class should return the sObject and make no modifications to it
        */
		Task originalTask = [SELECT LastModifiedDate from Task where Id = :testTasks[1].Id];
        DateTime originalDate = originalTask.LastModifiedDate;
        Task updatedTask3 = myTaskListController.updateTask(testTasks[1].Id,null,null);
		originalTask = [SELECT LastModifiedDate from Task where Id = :testTasks[1].Id];
        DateTime newDate = originalTask.LastModifiedDate;
        // Validate record was returned
        System.assertEquals(updatedTask3.Id,testTasks[1].Id);
        // Validate record was not modified
        System.assertEquals(originalDate,newDate);

        /*
        	Test the sorting functionality
        	The tests force sort order and check the filter script and set the filter and test the sort script
        */
        Integer testSearch;
        // Set the sort order and then test the filter string to ensure the sort order is set correctly
        ApexPages.CurrentPage().getparameters().put('so', 'dateASC');
        controller = new myTaskListController();
        testSearch = controller.taskFilterAllOpenScript.indexOf('so=dateASC');
        System.assertNotEquals(-1, testSearch);

        // Set the sort order and then test the filter string to ensure the sort order is set correctly
        ApexPages.CurrentPage().getparameters().put('so', 'dateDESC');
        controller = new myTaskListController();
        testSearch = controller.taskFilterAllOpenScript.indexOf('so=dateDESC');
        System.assertNotEquals(-1, testSearch);

        // Set the sort order and then test the filter string to ensure the sort order is set correctly
        ApexPages.CurrentPage().getparameters().put('so', 'priorityASC');
        controller = new myTaskListController();
        testSearch = controller.taskFilterAllOpenScript.indexOf('so=priorityASC');
        System.assertNotEquals(-1, testSearch);
        
        // Set the filter and then test the sort order string to ensure the filter is set correctly
        ApexPages.CurrentPage().getparameters().put('flt', 'overdue');
        controller = new myTaskListController();
        testSearch = controller.taskSortDateASCScript.indexOf('flt=overdue');
        
        // Set the filter and then test the sort order string to ensure the filter is set correctly
        ApexPages.CurrentPage().getparameters().put('flt', 'today');
        controller = new myTaskListController();
        testSearch = controller.taskSortDateASCScript.indexOf('flt=today');
        
        // Set the filter and then test the sort order string to ensure the filter is set correctly
        ApexPages.CurrentPage().getparameters().put('flt', 'todayplusoverdue');
        controller = new myTaskListController();
        testSearch = controller.taskSortDateASCScript.indexOf('flt=todayplusoverdue');
        
        // Set the filter and then test the sort order string to ensure the filter is set correctly
        ApexPages.CurrentPage().getparameters().put('flt', 'tomorrow');
        controller = new myTaskListController();
        testSearch = controller.taskSortDateASCScript.indexOf('flt=tomorrow');
        
        // Set the filter and then test the sort order string to ensure the filter is set correctly
        ApexPages.CurrentPage().getparameters().put('flt', 'next7days');
        controller = new myTaskListController();
        testSearch = controller.taskSortDateASCScript.indexOf('flt=next7days');
        
        // Set the filter and then test the sort order string to ensure the filter is set correctly
        ApexPages.CurrentPage().getparameters().put('flt', 'next7daysplusoverdue');
        controller = new myTaskListController();
        testSearch = controller.taskSortDateASCScript.indexOf('flt=next7daysplusoverdue');
        
        // Set the filter and then test the sort order string to ensure the filter is set correctly
        ApexPages.CurrentPage().getparameters().put('flt', 'thismonth');
        controller = new myTaskListController();
        testSearch = controller.taskSortDateASCScript.indexOf('flt=thismonth');
        
        // Set the filter and then test the sort order string to ensure the filter is set correctly
        ApexPages.CurrentPage().getparameters().put('flt', 'allopen');
        controller = new myTaskListController();
        testSearch = controller.taskSortDateASCScript.indexOf('flt=allopen');
    }
    
	/*
		myTaskListEmailTestMethod - test class for My Task List package component
			that requires running as a test user
	*/
    static testMethod void myTaskListUserTestMethod() {
        // Set up test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='mikehineline@gmail.com',
				EmailEncodingKey='UTF-8', LastName='Test', LanguageLocaleKey='en_US',
				LocaleSidKey='en_US', ProfileId = p.Id,
        		TimeZoneSidKey='America/Chicago', UserName='standarduser@test.com');
        // Test emailTask
        System.runAs(u) {
	        // Create a test opportunity for the WhatId field
    	    Opportunity testOpportunity = new Opportunity(Name='Test Opportunity',CloseDate=Date.today()+365,StageName='Prospecting');
       		insert testOpportunity;
        
       		// Create a test contact for the WhoId field
        	Contact testContact = new Contact(LastName='TestContact');
        	insert testContact;

        	// Initialize test data and add test data for required fields
        	final Integer NUM_TEST_TASKS = 1;
        	List<Task> testTasks = CreateTasks('TestTask_',NUM_TEST_TASKS);
        	for(Task thisTask: testTasks) {
				thisTask.OwnerID = UserInfo.getUserId();
				thisTask.ActivityDate = Date.today();
				thisTask.Status = 'In Progress';
				thisTask.WhatId = testOpportunity.Id;
				thisTask.WhoId = testContact.Id;
				thisTask.Priority = 'Normal';
				thisTask.Type = 'Other';
				thisTask.Description = 'Test\nTest';
        	}
        	insert testTasks;

	        // Set Visualforce page
    	    PageReference page = new PageReference('myTaskList');
        	Test.setCurrentPage(page); 
        
        	// Set the controller
        	myTaskListController controller = new myTaskListController();
        
	        /*
    	    	Test the emailTask remote static action
        		The emailTask class should return true
        	*/
        	Boolean sendResult = myTaskListController.emailTask(testTasks[0].Id);
	        System.assertEquals(true,sendResult);
        }
    }
}