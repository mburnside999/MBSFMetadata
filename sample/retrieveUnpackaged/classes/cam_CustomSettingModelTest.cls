/**
 * @author Timba Software
 * @description
 *		started at 10/23/2012
 *		Unit Tests for cam_ConfigController class
 **/
@isTest
private class cam_CustomSettingModelTest {

	static User getStandardUser(){
		Profile  stdPRf = [select Id, Name from Profile where Name = 'Standard User'  limit 1];
		
		User aUser = new User(alias = 'isUnique' , email='standarduser@testorg.com',
		FirstName='thisIsUnique',  UserName= 'thisIsUnique@testorg.com', lastname='thisIsUnique',
		emailencodingkey='UTF-8', timezonesidkey='America/Los_Angeles',
		languagelocalekey='en_US', localesidkey='en_US', profileid = stdPRf.Id);
		insert aUser;
		
		return aUser;
	}

	static testMethod void text_postPutKnowledgeArticle(){

		map<String,Object> options = new map<String,Object>{
				'apiName__c' 	=> 'cam__test__kav',
				'layout__c'		=> 'Title,Summary,SomethingElse'
		};
		
		//check that standard user cannot add cam_Ka__c
		User aUser = getStandardUser();
		system.runAs(aUser){
			if (!cam_Ka__c.sObjectType.getDescribe().isCreateable()){
				Object response = cam_ConfigController.postPutKnowledgeArticle( Json.serialize(options) );
				map<String,Object> responseMap = (map<String,Object>) response; 
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_CREATEABLE.substring(0,10)));
			}
		}
		
		//Insert
		Object response = cam_ConfigController.postPutKnowledgeArticle( Json.serialize(options) );
		map<String,Object> responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
		
		//Editing
		cam_Ka__c testElement = [Select Id from cam_Ka__c where apiName__c = 'cam__test__kav'];
		options.put('Id',testElement.Id);
		
		//check that standard user cannot update cam_Ka__c
		system.runAs(aUser){
			if (!cam_Ka__c.sObjectType.getDescribe().isUpdateable()){
				response = cam_ConfigController.postPutKnowledgeArticle( Json.serialize(options) );
				responseMap = (map<String,Object>) response; 
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_UPDATEABLE.substring(0,10)));
			}
		}
		
		response = cam_ConfigController.postPutKnowledgeArticle( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
		
		//Trying to create a new one with duplicated name
		//Editing
		options.put('Id',null);
		response = cam_ConfigController.postPutKnowledgeArticle( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
		
		//Test Deletion
		options.put('Id',testElement.Id);
		
		//check that standard user cannot delete cam_Ka__c
		system.runAs(aUser){
			if (!cam_Ka__c.sObjectType.getDescribe().isDeletable()){
				response = cam_ConfigController.deleteKnowledgeArticle( Json.serialize(options) );
				responseMap = (map<String,Object>) response; 
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_DELETABLE.substring(0,10)));
			}
		}
		
		response = cam_ConfigController.deleteKnowledgeArticle( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
		//Try again with an already deleted object
		response = cam_ConfigController.deleteKnowledgeArticle( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
	}
	
	static testMethod void test_postPutGlobalSetup(){
		//create
		map<String,Object> options = new map<String,Object>{
				'CA_Data_Category__c'		=> 'test',
				'richTextEditor__c'			=> true
		};

		//check that standard user cannot add setup
		User aUser = getStandardUser();
		system.runAs(aUser){
			if (!cam_Site__c.sObjectType.getDescribe().isCreateable()){
				Object response = cam_ConfigController.postPutGlobalSetup( Json.serialize(options) );
				map<String,Object> responseMap = (map<String,Object>) response; 
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_CREATEABLE.substring(0,10)));
			}
		}
		Object response = cam_ConfigController.postPutGlobalSetup( Json.serialize(options) );
		map<String,Object> responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
		
		list<cam_Setup__c> elms = [Select Id from cam_Setup__c];
		//Edit
		response = cam_ConfigController.postPutGlobalSetup( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
		//Error
		options.put('CA_Data_Category__c',null);
		response = cam_ConfigController.postPutGlobalSetup( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
	}
	
	
	static testMethod void test_postPutSite(){
		//create
		map<String,Object> options = new map<String,Object>{
			'cssPath__c'			=> 'dummyCss',
			'guestProfileId__c'		=> '123456789012345678',
			'guestProfileName__c'	=> 'Dummy Profile',
			'siteName__c'			=> 'dummySite',
			'sitePublicName__c'		=> 'dummySitePublic',
			'staticResourceName__c'	=> 'dummyStaticResource'			
		};
		//check that standard user cannot add site
		User aUser = getStandardUser();
		system.runAs(aUser){
			if (!cam_Site__c.sObjectType.getDescribe().isCreateable()){
				Object response = cam_ConfigController.postPutSite( Json.serialize(options) );
				map<String,Object> responseMap = (map<String,Object>) response; 
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_CREATEABLE.substring(0,10)));
			}
		}

		Object response = cam_ConfigController.postPutSite( Json.serialize(options) );
		map<String,Object> responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
		String theId = String.valueOf(responseMap.get('Id'));
		//edit
		system.runAs(aUser){
			if (!cam_Site__c.sObjectType.getDescribe().isUpdateable()){
				options.put('Id',theId);
				options.put('siteName__c','dummyTwoSite');
				response = cam_ConfigController.postPutSite( Json.serialize(options) );
				responseMap = (map<String,Object>) response;
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_UPDATEABLE.substring(0,10)));
			}
		}
		options.put('Id',theId);
		options.put('siteName__c','dummyTwoSite');
		response = cam_ConfigController.postPutSite( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
		//error
		options.put('siteName__c',null);
		response = cam_ConfigController.postPutSite( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
		//delete
		options.put('Id',theId);
		system.runAs(aUser){ 
			if (!cam_Site__c.sObjectType.getDescribe().isDeletable()){
				response = cam_ConfigController.deleteSite( Json.serialize(options) );
				responseMap = (map<String,Object>) response;
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.debug('\n\n====='+msg);
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_DELETABLE.substring(0,10)));
			}
		} 


		response = cam_ConfigController.deleteSite( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
	}
	
	
	static testMethod void test_postPutModerator(){
		//Moderators
		map<String,Object> options = new map<String,Object>{
			'userId__c'			=> '123456789012345678',
			'userInfo__c'		=> 'user@user.com'
		};
		
		//check that standard user cannot add site
		User aUser = getStandardUser();
		system.runAs(aUser){
			if (!cam_Moderator__c.sObjectType.getDescribe().isCreateable()){
				Object response = cam_ConfigController.postPutModerator( Json.serialize(options) );
				map<String,Object> responseMap = (map<String,Object>) response; 
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_CREATEABLE.substring(0,10)));
			}
		}
 
		Object response = cam_ConfigController.postPutModerator( Json.serialize(options) );
		map<String,Object> responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
		String elmId = String.valueOf(responseMap.get('Id'));
		
		//error duplicated
		response = cam_ConfigController.postPutModerator( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
		
		//delete
		options.put('Id',elmId);
		system.runAs(aUser){
			if (!cam_Moderator__c.sObjectType.getDescribe().isDeletable()){
				//delete
				response = cam_ConfigController.deleteModerator( Json.serialize(options) );
				responseMap = (map<String,Object>) response;
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_DELETABLE.substring(0,10)));
			}
		}
		
		response = cam_ConfigController.deleteModerator( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
	}


	@isTest(SeeAllData=true)
	static void fifthTest(){
		cam_TestEnvironment.initData();
		system.assertNotEquals(null,cam_ConfigController.getAllSitesSetup());
		system.assertNotEquals(null,cam_ConfigController.getCurrentSiteSetup());
		system.assertNotEquals(null,cam_ConfigController.getOrgUsers());
	}
	
	static testMethod void test_postPutCommunity(){
		map<String,Object> options = new map<String,Object>{
			'staticResourceName__c' => 'cam_branding',
			'iconPath__c'			=> 'img/Sony_mp3.png',
			'publicName__c'			=> 'MP3 & Portable Devices Public',
			'communityId__c'		=> '09a30000000LB0pAAG',
			'communityDCApiName__c'	=> 'MP3_Portable_Devices',
			'communityDCLabel__c'	=> 'MP3 & Portable Devices',
			'siteName__c'			=> 'Sony_Demo_Site',
			'communityName__c'		=> 'Sony Demo Site'
		};

		//check that standard user cannot add community
		User aUser = getStandardUser();
		system.runAs(aUser){
			if (!cam_Community__c.sObjectType.getDescribe().isCreateable()){
				Object response = cam_ConfigController.postPutCommunity( Json.serialize(options) );
				map<String,Object> responseMap = (map<String,Object>) response; 
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_CREATEABLE.substring(0,10)));
			}
		}
		
		//delete community
		
		Object response = cam_ConfigController.postPutCommunity( Json.serialize(options) );
		map<String,Object> responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
		
		String elmId = String.valueOf(responseMap.get('Id'));
		options = new map<String,Object>{
			'Id' => elmId
		};
		system.runAs(aUser){
			if (!cam_Moderator__c.sObjectType.getDescribe().isDeletable()){
				//delete
				response = cam_ConfigController.deleteCommunity( Json.serialize(options) );
				responseMap = (map<String,Object>) response;
				String msg = String.valueOf(responseMap.get('Msg'));
				system.assertEquals('Failed',String.valueOf(responseMap.get('Status')));
				system.assert(msg.contains(cam_SecurityHandler.ERROR_OBJECT_NOT_DELETABLE.substring(0,10)));
			}
		}
		response = cam_ConfigController.deleteCommunity( Json.serialize(options) );
		responseMap = (map<String,Object>) response;
		system.assertEquals('Success',String.valueOf(responseMap.get('Status')));
	}
	
}