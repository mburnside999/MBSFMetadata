/**
 * @author Timba Software
 * @description
 *		started at 10/25/2012
 *		Front Controller Config Page
 *	DELEGATES TO cam_CustomSettingsModel Class
 **/
 global with sharing class cam_ConfigController {
 	
 	@RemoteAction
 	global static Object getAllSitesSetup(){
 		return cam_CustomSettingModel.getAllSitesSetup();
 	}
 	
 	@RemoteAction
 	global static Object getCurrentSiteSetup(){
 		return cam_CustomSettingModel.getCurrentSiteSetup();
 	}
 	
 	@RemoteAction
 	global static Object postPutModerator( String moderatorInfoStr ){
 		return cam_CustomSettingModel.postPutModerator(moderatorInfoStr);
 	}
 	
 	@RemoteAction
 	global static Object deleteModerator( String moderatorInfoStr ){
 		return cam_CustomSettingModel.deleteModerator(moderatorInfoStr);
 	}
 	
 	@RemoteAction
 	global static Object postPutSite( String siteInfoStr ){
 		return cam_CustomSettingModel.postPutSite(siteInfoStr);
 	}
 	
 	@RemoteAction
 	global static Object deleteSite( String siteInfoStr ){
 		return cam_CustomSettingModel.deleteSite(siteInfoStr);
 	}
 	
 	@RemoteAction
 	global static Object postPutCommunity( String communityInfoStr ){
 		return cam_CustomSettingModel.postPutCommunity(communityInfoStr);
 	}
 	
 	@RemoteAction
 	global static Object deleteCommunity( String communityInfoStr ){
 		return cam_CustomSettingModel.deleteCommunity(communityInfoStr);
 	}
 	
 	@RemoteAction
 	global static Object postPutGlobalSetup( String globalInfoStr ){
 		return cam_CustomSettingModel.postPutGlobalSetup(globalInfoStr);
 	}
 	
 	@RemoteAction
 	global static Object postPutKnowledgeArticle( String knowledgeArticleInfoStr ){
 		return cam_CustomSettingModel.postPutKnowledgeArticle(knowledgeArticleInfoStr);
 	}
 	
 	@RemoteAction
 	global static Object deleteKnowledgeArticle( String knowledgeArticleInfoStr ){
 		return cam_CustomSettingModel.deleteKnowledgeArticle(knowledgeArticleInfoStr);
 	}
 	
 	@RemoteAction
 	global static Object getOrgUsers(){
 		return cam_CustomSettingModel.getOrgUsers();
 	}
 	
 	@RemoteAction
 	global static Object getOrgSites(){
 		return cam_CustomSettingModel.getOrgSites();
 	}
 	
 	@RemoteAction
 	global static Object getOrgStaticResources(){
 		return cam_CustomSettingModel.getOrgStaticResources();
 	}
 	
 	@RemoteAction
 	global static Object getOrgProfiles(){
 		return cam_CustomSettingModel.getOrgProfiles();
 	}
 	
 	@RemoteAction
 	global static Object getOrgCommunities(){
 		return cam_CustomSettingModel.getOrgCommunities();
 	}
 	
 	@RemoteAction
 	global static Object getKAStructure(){
 		return cam_CustomSettingModel.getKnowledgeTypesAndFields();
 	}
}