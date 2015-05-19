/**
 * @author Timba Software
 * @description
 *		started at 08/24/2012
 *		static methods to be used by each unit test class
 **/
public with sharing class cam_TestEnvironment {
	
	public static Community vcommunity {get;set;}
	public static String topic{get;set;}
	public static cam_kav__kav knowledgeArt {get;set;}
	public static cam_Setup__c camSetup {get;set;}
	public static cam_Ka__c camKAone {get;set;}
	public static cam_Site__c camSite {get;set;}
	public static cam_Community__c camCommunityone {get;set;}
	public static cam_Community__c camCommunitytwo {get;set;}
	public static cam_Moderator__c camModeratorone {get;set;}
	
	public static void initData(){
		map<String,cam_Setup__c> gMap = cam_Setup__c.getAll(); delete gMap.values();
		map<String,cam_Ka__c> kMap = cam_Ka__c.getAll(); delete kMap.values();
		map<String,cam_Site__c> sMap = cam_Site__c.getAll(); delete sMap.values();
		map<String,cam_Community__c> cMap = cam_Community__c.getAll(); delete cMap.values();
		map<String,cam_Moderator__c> mMap = cam_Moderator__c.getAll(); delete mMap.values();
		
		Question q; QuestionDataCategorySelection qDC; Profile profileToUse;
		
		try{
			//As our app needs this three items in order to run test methods, we will add a more "user friendly" exception if we can't reach this objects
			q = [Select Id, CommunityId from Question where Origin = 'Chatter Answers' limit 1];
			qDC = [Select DataCategoryName,DataCategoryGroupName from QuestionDataCategorySelection where ParentId = :q.Id];
			profileToUse = [Select Id,Name from Profile where Id != :Userinfo.getProfileId() limit 1];
		}
		catch(Exception e){
			throw new ChatterAnswersMobileTestException('Chatter Answers Mobile Test Methods: In order to run the App test methods you must have Chatter Answers properly set up and at least one Question in the Database');
		}
		vcommunity = [Select Id,Name from Community where Id = :q.CommunityId];
		topic = qDC.DataCategoryName;
		
		if ( knowledgeArt == null ){
			cam_kav__kav kArt = new cam_kav__kav(Title = 'test[article]', Language = 'en_US', Summary = 'test[article]' , UrlName = 'testArticle');
			insert kArt;
			knowledgeArt = [Select Title,Id,Language,Summary,UrlName,LastPublishedDate,KnowledgeArticleId from cam_kav__kav where Id = :kArt.Id];
		}
		
		if ( cammoderatorone == null ){
			camModeratorone = new cam_Moderator__c( 
												Name		= String.valueOf( (Datetime.now()).getTime() ),
												userId__c 	= Userinfo.getUserId(),
												userInfo__c	= Userinfo.getUserName() );
			insert camModeratorone;
		}
		
		if ( camSetup == null ){
			camSetup = new cam_Setup__c(
									Name 				= String.valueOf( (Datetime.now()).getTime() ) ,
									CA_Data_Category__c = qDC.DataCategoryGroupName,
									richTextEditor__c	= false
								);
			insert camSetup;
		}
		
		
		if ( camKAone == null ){
			camKAone = new cam_Ka__c(
									Name 		= String.valueOf( (Datetime.now()).getTime() ) ,
									apiName__c 	= 'FAQ__kav',
									layout__c	= 'Title,Summary',
									isActive__c = true
							);
			insert camKAone;
		}
		
		if ( camSite == null  ){
			camSite = new cam_Site__c(
									Name 					= String.valueOf( (Datetime.now()).getTime() ) ,
									siteName__c				= 'Some_Site',
									staticResourceName__c 	= 'cam_javascripts',
									cssPath__c				= 'css/root.css',
									guestProfileId__c		= profileToUse.Id,
									guestProfileName__c		= profileToUse.Name,
									sitePublicName__c		= 'Some Site Public'
							);
			insert camSite;
		}
		
		
		if ( camCommunityone == null ){
			camCommunityone = new cam_Community__c(
												Name 					= String.valueOf( (Datetime.now()).getTime() ) ,
												staticResourceName__c 	= 'cam_branding',
												iconPath__c				= 'img/Sony_mp3.png',
												publicName__c			= 'dummy name',
												communityId__c			= q.CommunityId,
												communityDCApiName__c	= qDC.DataCategoryName,
												communityDCLabel__c		= qDC.DataCategoryName,
												isActive__c				= true,
												siteName__c				= 'Some_Site',
												communityName__c		= 'Test Community'
											);
			insert camCommunityone;
		}
	}
	
	public class ChatterAnswersMobileTestException extends Exception{
		
	}
}