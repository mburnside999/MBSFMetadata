/**
 * @author Timba Software
 * @description
 *		started at 08/13/2012
 *		cam_Proxy class coverage
 **/
@isTest(OnInstall=false)
private class cam_Proxy_test {
	
	@isTest(SeeAllData=true)
    static void initTest() {
        cam_TestEnvironment.initData();
        
        cam_DTO element = cam_Proxy.requestSkeleton();
        system.assertNotEquals(null,element);
        element.sitesDefinition = null;
        
        cam_DTO response = cam_Proxy.action( Json.serialize(element) );
        system.assertEquals( response.globalConstants.get('STATUS_ERROR') , response.response.status );
        
        element.searchOptions.put('communityId',cam_TestEnvironment.vcommunity.Id);
	 	element.searchOptions.put('topicName',element.globalConstants.get('NULL_VAL'));
	 	element.searchOptions.put('searchInput',element.globalConstants.get('NULL_VAL'));
	 	element.searchOptions.put('sortBy',element.searchConstants.get('sortBy_RECENT'));
	 	element.searchOptions.put('scope',element.searchConstants.get('questions_GET_ALL_QUESTIONS'));
	 	
	 	response = cam_Proxy.action( Json.serialize(element) );
        system.assertEquals( response.globalConstants.get('STATUS_OK') , response.response.status );
        
        Community c = cam_TestEnvironment.vcommunity;
        system.assertNotEquals(null,c);
        
        //Inserting a private question
        map<String,String> options = new map<String,String>();
		options.put('communityId',cam_TestEnvironment.vcommunity.Id);
		options.put('title','Testing Title 000XXX');
		options.put('body','Body for this mobile app');
		options.put('topic',cam_TestEnvironment.topic);
		options.put('isPublic','false');
		
        map<String,String> ret = cam_Proxy.postQuestion( Json.serialize(options) );
        
        list<Case> testC = [Select Id from Case where Subject = 'Testing Title 000XXX'];
        system.assertEquals(1,testC.size());
        
        //Now insert private question failure
        options.put('communityId',null);
        ret = cam_Proxy.postQuestion( Json.serialize(options) );
        system.assertEquals( true, ret.get('status') != '' );
        
        //Inserting a question
        options = new map<String,String>();
		options.put('communityId',cam_TestEnvironment.vcommunity.Id);
		options.put('title','Testing Title 000XXX');
		options.put('body','Body for this mobile app');
		options.put('topic',cam_TestEnvironment.topic);
		options.put('isPublic','true');
		
        ret = cam_Proxy.postQuestion( Json.serialize(options) );
        
        list<Question> testQ = [Select Id from Question where title = 'Testing Title 000XXX'];
        system.assertEquals(1,testQ.size());
        
        //Do the same but with wrong information
        options.put('communityId',null);
        ret = cam_Proxy.postQuestion( Json.serialize(options) );
        system.assertEquals( (element.globalConstants).get('STATUS_ERROR'), ret.get('status') );
        
        //Do the same but with wrong information in isPublic attribute
        options.put('communityId',cam_TestEnvironment.vcommunity.Id);
        options.put('isPublic',null);
        ret = cam_Proxy.postQuestion( Json.serialize(options) );
        system.assertEquals( (element.globalConstants).get('STATUS_ERROR'), ret.get('status') );
        
        //Inserting a reply
        options = new map<String,String>();
        options.put('parentId',testQ[0].Id);
        options.put('body','Reply Test');
        
        ret = cam_Proxy.postReply( Json.serialize(options) );
        
        list<Reply> testR = [Select Id from Reply where questionId = :testQ[0].Id];
        system.assertEquals(1,testR.size());
        
        //Do the same but with wrong information
        options.put('parentId',null);
        ret = cam_Proxy.postReply( Json.serialize(options) );
        system.assertEquals( (element.globalConstants).get('STATUS_ERROR'), ret.get('status') );
        
        //Follow wrong values
        options = new map<String,String>();
        options.put('questionId',null);
        options.put('follow',null); 
        ret = cam_Proxy.follow( Json.serialize(options) );
        system.assertEquals( (element.globalConstants).get('STATUS_ERROR'), ret.get('status') );
        
        options.put('questionId',testQ[0].Id);
        options.put('follow','true');
        ret = cam_Proxy.follow( Json.serialize(options) );
        system.assertEquals( (element.globalConstants).get('STATUS_ERROR'), ret.get('status') );
        system.assertEquals( 'User is already following this question', ret.get('responseMsg') );
        
        //VoteLike error
        options = new map<String,String>{
    		'elementId' => testR[0].Id
    	};
    	
    	ret = cam_Proxy.voteLike( Json.serialize(options) );
    	system.assertEquals( false, ret.get('responseMsg') == '' );
        
        //VoteLike with wrong format
        options.put('elementId',null);
        ret = cam_Proxy.voteLike( Json.serialize(options) );
        system.assertEquals( (element.globalConstants).get('STATUS_ERROR'), ret.get('status') );
        
        //BestAnswer
        options = new map<String,String>{
    		'questionId' => testQ[0].Id,
    		'answerId' => testR[0].Id
    	};
    	
    	ret = cam_Proxy.bestAnswer( Json.serialize(options) );
    	system.assertEquals( (element.globalConstants).get('STATUS_OK'), ret.get('status') );
    	
    	//BestAnswer wrong format
    	options.put('questionId',NULL);
    	ret = cam_Proxy.bestAnswer( Json.serialize(options) );
    	system.assertEquals( (element.globalConstants).get('STATUS_ERROR'), ret.get('status') );
    	
    	//Who am I method
    	map<String,Object> retO = (map<String,Object>) cam_Proxy.whoAmI();
    	system.assertEquals( Userinfo.getUserId(), String.valueOf(retO.get('Id')) );
    	
    	//getUserDetails
    	map<String,String> optionsUser = new map<String,String>();
        optionsUser.put('communityId','');
        optionsUser.put('uId',String.valueOf(Userinfo.getUserId()));
    	ret = cam_Proxy.getUserDetails( Json.serialize(optionsUser) );
    	system.assertEquals( Userinfo.getUserId(), ret.get('Id') );
    	
    	//singleItemView
    	element.globalOptions.put('requestType',element.globalConstants.get('requestType_SINGLE_ITEM_VIEW'));
    	element.singleItemViewOptions.put('idToDisplay',testQ[0].Id);
	 	response = cam_Proxy.action( Json.serialize(element) );
        system.assertEquals( response.globalConstants.get('STATUS_OK') , response.response.status );
        
        //MyFeed
        element.globalOptions.put('requestType',element.globalConstants.get('requestType_MY_FEED') );
        element.myFeedOptions.put('communityId',cam_TestEnvironment.vcommunity.Id);
        element.myFeedOptions.put('authorId',Userinfo.getUserId());
        element.myFeedOptions.put('topicApiName','-1');
        element.myFeedOptions.put('viewCommunityId',cam_TestEnvironment.vcommunity.Id);
    	
    	response = cam_Proxy.action( Json.serialize(element) );
    	system.assertEquals( response.globalConstants.get('STATUS_OK') , response.response.status );
    }
    
    @isTest(SeeAllData=true)
    static void secondTest(){
    	//User Reputation
    	cam_TestEnvironment.initData();
    	map<String,String> optionsUser = new map<String,String>();
        optionsUser.put('communityId',cam_TestEnvironment.vcommunity.Id);
        optionsUser.put('uId',String.valueOf(Userinfo.getUserId()));
    	map<String,String> ret = cam_Proxy.getUserReputation( Json.serialize(optionsUser) );
    	//It will come as null cuz in test environment current user has no chatter Activity
    	system.assertEquals( null, ret.get('currentUser') );
    }
    
    @isTest(SeeAllData=true)
    static void thirdTest(){
    	cam_TestEnvironment.initData();
    	//custom settings unit tests are in another test class
    	system.assertNotEquals(null,cam_Proxy.getsiteName());
    	system.assertNotEquals(null,cam_Proxy.getCamRootGroupName());
    	system.assertNotEquals(null,cam_Proxy.getcssPath());
    	system.assertNotEquals(null,cam_Proxy.getstaticResource());
    	system.assertNotEquals(null,cam_Proxy.getCommunities());
    }
    
    @isTest(SeeAllData=true)
    static void configTest(){
    	cam_TestEnvironment.initData();
    	Object a = cam_Config.CAM_ROOT_GROUP_NAME;
    	a = cam_Config.CAM_ROOT_GROUP_NAME_SIMPLE;
    	a = cam_Config.communityRelationWithDataCategory;
    	a = cam_Config.customerSupportAgents;
    	a = cam_Config.guestUserProfileId;    	
    	
    	system.assertEquals( true, cam_Config.CAM_ROOT_GROUP_NAME != null );
    	system.assertEquals( true, cam_Config.CAM_ROOT_GROUP_NAME_SIMPLE != null );
    	system.assertEquals( true, cam_Config.communityRelationWithDataCategory.size()>0  );
    	system.assertEquals( true, cam_Config.customerSupportAgents.size()>0 );
    	system.assertEquals( true, cam_Config.guestUserProfileId != null );
    }
}