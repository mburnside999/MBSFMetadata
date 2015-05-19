/**
 * @author Timba Software
 * @description
 *		started at 10/18/2012
 *		Custom Settings Model Class
 **/
public with sharing class cam_CustomSettingModel {
	 
	 private static final String CRITICAL_ERROR = 'Critical error found in custom settings.';
	 private static Boolean getOnlyCurrentSite = false;
	 
/**
	 * @description
	 *		get All Sites Setup
	 * @return Object / Map<String,Object>
	 **/
	 public static Object getAllSitesSetup(){
		map<String,Object> ret = (map<String,Object>) getResponseStructure();
		
		map<String,cam_Setup__c> camGlobalSetupMap = cam_Setup__c.getAll();
		
		if ( (camGlobalSetupMap.values()).size() > 0 ){
				cam_Setup__c camGlobalSetup = (camGlobalSetupMap.values())[0];
				ret.put('CA_Data_Category__c', camGlobalSetup.CA_Data_Category__c );
				ret.put('richTextEditor__c', camGlobalSetup.richTextEditor__c);
				
				map<String,cam_Site__c> camSitesMap = null;
				list<cam_Site__c> camSites = new list<cam_Site__c>();
				list<map<String,Object>> listOfSites = new list<map<String,Object>>();
				
				if ( getOnlyCurrentSite && Site.getName() != null){
					 camSites = [Select Id, siteName__c, staticResourceName__c, cssPath__c, guestProfileId__c, sitePublicName__c, guestProfileName__c
										FROM cam_Site__c
										WHERE siteName__c = :Site.getName()];
				}else{
					 camSitesMap = cam_Site__c.getAll();
					 camSites = camSitesMap.values();
				}
				
				for ( cam_Site__c element : camSites ){
					 
					 map<String,Object> s = new map<String,Object>{
													 'Id'								=> element.Id,
													 'siteName__c'					 => element.siteName__c,
													 'staticResourceName__c'	=> element.staticResourceName__c,
													 'cssPath__c'					 => element.cssPath__c,
													 'guestProfileId__c'				=> element.guestProfileId__c,
													 'Communities'					 => GetCommunities(element.siteName__c),
													 'sitePublicName__c'				=> element.sitePublicName__c,
													 'guestProfileName__c'		=> element.guestProfileName__c
					 };
					 listOfSites.add(s);
				}
				ret.put('Sites',listOfSites);
				ret.put('KAStructure',getKnowledgeArticlesSetup());
				ret.put('Moderators',getModerators());
				ret.put('Msg','Success');
				ret.put('Status','Success');
				return ret;
		}
		ret.put('Msg','Found 0 Settings');
		ret.put('Status','Success');
		return ret;
	 }
	 
/**
	 * @description
	 *		get Communities of a given Site Name
	 * @param siteName @type String
	 * @return Object / Map<String,Object>
	 **/
	 private static Object getCommunities(String siteName){
		list<Object> ret = new list<Object>();
		list<cam_Community__c> communities = [ Select Id, staticResourceName__c, iconPath__c, publicName__c, communityId__c, 
																communityDCApiName__c, communityDCLabel__c, siteName__c, communityName__c
																FROM cam_Community__c
																WHERE siteName__c = :siteName
																AND isActive__c = true];
		if ( communities.size() > 0 ){
				
				for ( cam_Community__c element : communities ){
					 map<String,Object> c = new map<String,Object>{
						'Id'								=> element.Id,
						'staticResourceName__c'	=> element.staticResourceName__c,
						'iconPath__c'					 => element.iconPath__c,
						'publicName__c'					 => element.publicName__c,
						'communityId__c'				=> element.communityId__c,
						'communityDCApiName__c'		=> element.communityDCApiName__c,
						'communityDCLabel__c'		=> element.communityDCLabel__c,
						'siteName__c'					 => element.siteName__c,
						'communityName__c'				=> element.communityName__c
					 };
					 ret.add(c);
				}
		}else{
				return 'No active communities.';
		}
		return ret;
	 }
	 
	 /**
	 * @description
	 *		get Moderators Ids
	 * @return Object / Map<String,Object>
	 **/
	 private static Object getModerators(){
		list<Object> ret = new list<Object>();
		list<cam_Moderator__c> moderators = [ Select Name, Id, userId__c, userInfo__c from cam_Moderator__c l limit: cam_Model.MAX_SOQL_RESULTS];
		if ( moderators.size() > 0 ){
				for ( cam_Moderator__c element : moderators ){
					 map<String,Object> c = new map<String,Object>{
						'Name'								=> element.Name,
						'Id'								=> element.Id,
						'userId__c'					=> element.userId__c,
						'userInfo__c'					 => element.userInfo__c
					 };
					 ret.add(c);
				}
		}else{
				return 'No Moderators assigned.';
		}
		return ret;
	 }
	 
/**
	 * @description
	 *		get KnowledgeArticles List from custom settings
	 * @return Object / Map<String,Object>
	 **/
	 private static Object getKnowledgeArticlesSetup(){
		map<String,cam_Ka__c> camKASetupMap = cam_Ka__c.getAll();
		list<Object> listOfKA = new list<Object>();
		if ( (camKASetupMap.values()).size() > 0 ){
				
				for ( cam_Ka__c element : camKASetupMap.values() ){
					 map<String,Object> k = new map<String,Object>{
													 'Id'						=> element.Id,
													 'apiName__c'				 => element.apiName__c,
													 'layout__c'					 => element.layout__c													 
					 };
					 listOfKA.add(k);
				}
				return listOfKA;
		}else{
				return 'No KA values';
		}
	 }
	 
	 
/**
	 * @description
	 *		get Current Site Setup
	 * @return Object / Map<String,Object>
	 **/
	 public static Object getCurrentSiteSetup(){
		if (!test.isRunningTest()) getOnlyCurrentSite = true;
		Object ret = getAllSitesSetup();
		getOnlyCurrentSite = false;
		return ret;
	 }
	 
	 
	 /**
	 * @description
	 *		Creates / Update a Site
	 * @param siteInfoStr @type String (Json stringified object)
	 * @return Object / Map<String,Object>
	 **/
	 public static Object postPutModerator( String moderatorInfoStr ){
		map<String,Object> ret = (map<String,Object>) getResponseStructure();
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(moderatorInfoStr);
		cam_Moderator__c element = null;
		
		if ( opts.get('userId__c') != null ){
				try{ 
					//check create permissions, on both actions user needs this
						cam_SecurityHandler.canCreate( 
							new Schema.SObjectType[] {cam_Moderator__c.sObjectType});
					 if ( opts.get('Id') == null ){
						 element = new cam_Moderator__c( Name		= String.valueOf((Datetime.now()).getTime()),
																	 userId__c	 = String.valueOf(opts.get('userId__c')),
																	 userInfo__c	 = String.valueOf(opts.get('userInfo__c')) );
						insert element;
						ret.put('Id',element.Id);
					 }else{
						
					//check update permissions
						cam_SecurityHandler.canUpdate( 
							new Schema.SObjectType[] {cam_Moderator__c.sObjectType});
					
						element = [Select Name,Id,userId__c, userInfo__c from cam_Moderator__c where Id = :String.valueOf(opts.get('Id'))];
						element.userId__c	= String.valueOf(opts.get('userId__c'));
						element.userInfo__c = String.valueOf(opts.geT('userInfo__c'));
						upsert element;
					 }
					 ret.put('Status','Success');
				}catch(cam_SecurityHandler.SecurityException sEx){
					 ret.put('Msg','Internal error, received: '+sEx.getMessage() ); 
					 ret.put('Status', 'Failed' );
				}catch(Exception e){
					 ret.put('Status','Failed');
					 ret.put('Msg','Internal error, received: '+e.getMessage());
				}
		}else{
				ret.put('Status','Failed');
				ret.put('Msg','Received Invalid Options.');
				ret.put('Received',moderatorInfoStr);
		}
		return ret;
	 }
	 
	 /**
	 * @description
	 *		Creates / Update a Site
	 * @param siteInfoStr @type String (Json stringified object)
	 * @return Object / Map<String,Object>
	 **/
	 public static Object deleteModerator( String moderatorInfoStr ){
		map<String,Object> ret = (map<String,Object>) getResponseStructure();
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(moderatorInfoStr);
		cam_Moderator__c element = null;
		if ( opts.get('userId__c') != null ){
				try{
					 //check delete permissions
				cam_SecurityHandler.canDelete( 
					new Schema.SObjectType[] {cam_Moderator__c.sObjectType});
					element = [Select Id from cam_Moderator__c where userId__c = :String.valueOf(opts.get('userId__c'))];
					 delete element;
					 ret.put('Status','Success');
				}catch(cam_SecurityHandler.SecurityException sEx){
					 ret.put('Msg','Internal error, received: '+sEx.getMessage() ); 
					 ret.put('Status', 'Failed' );
				}catch(Exception e){
					 ret.put('Status','Failed');
					 ret.put('Msg','Internal error, received: '+e.getMessage());
				}
		}else{
				ret.put('Status','Failed');
				ret.put('Msg','Received Invalid Options.');
				ret.put('Received',moderatorInfoStr);
		}
		return ret;
	 }
	 
/**
	 * @description
	 *		Creates / Update a Site
	 * @param siteInfoStr @type String (Json stringified object)
	 * @return Object / Map<String,Object>
	 **/
	 public static Object postPutSite( String siteInfoStr ){
		map<String,Object> ret = (map<String,Object>) getResponseStructure();
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(siteInfoStr);
		cam_Site__c element = null;
		
		if ( opts.get('cssPath__c') != null && opts.get('guestProfileId__c') != null 
				&& opts.get('siteName__c') != null && opts.get('staticResourceName__c') != null 
				&& opts.get('sitePublicName__c') != null && opts.get('guestProfileName__c') != null){
					 try{
						
						//check create permissions
						cam_SecurityHandler.canCreate( 
								new Schema.SObjectType[] {cam_Site__c.sObjectType});

						if ( opts.get('Id') == null ){
								 element = new cam_Site__c(
													Name						= String.valueOf((Datetime.now()).getTime()),
													cssPath__c					= String.valueOf(opts.get('cssPath__c')),
													guestProfileId__c		= String.valueOf(opts.get('guestProfileId__c')),
													siteName__c					 = String.valueOf(opts.get('siteName__c')),
													staticResourceName__c	 = String.valueOf(opts.get('staticResourceName__c')),
													sitePublicName__c		= String.valueOf(opts.get('sitePublicName__c')),
													guestProfileName__c		= String.valueOf(opts.get('guestProfileName__c'))
												 );
								 insert element;								 
						}else{
							//check update permissions
							cam_SecurityHandler.canUpdate( 
								new Schema.SObjectType[] {cam_Site__c.sObjectType});
								
							element = [Select Id,cssPath__c,guestProfileId__c,siteName__c,staticResourceName__c,sitePublicName__c,guestProfileName__c from cam_Site__c where Id = :String.valueOf(opts.get('Id'))];
							element.cssPath__c = String.valueOf(opts.get('cssPath__c'));
							element.guestProfileId__c = String.valueOf(opts.get('guestProfileId__c'));
							element.staticResourceName__c = String.valueOf(opts.get('staticResourceName__c'));
							element.sitePublicName__c = String.valueOf(opts.get('sitePublicName__c'));
							element.guestProfileName__c = String.valueOf(opts.get('guestProfileName__c'));
							if ( element.siteName__c != String.valueOf(opts.get('siteName__c')) ){
								 //let's update all communities related to this site in case if changed
							list<cam_Community__c>comm = [Select Id,siteName__c from cam_Community__c where siteName__c = :element.siteName__c];
								 for ( cam_Community__c elm : comm ){
									elm.siteName__c = String.valueOf(opts.get('siteName__c')); 
								 }
								 if ( comm.size() > 0 ) upsert comm;
								}
								element.siteName__c = String.valueOf(opts.get('siteName__c'));
								upsert element;
						}
						ret.put('Id',element.Id);
						ret.put('Status','Success');
						
					 }catch(cam_SecurityHandler.SecurityException sEx){
						ret.put('Msg','Internal error, received: '+sEx.getMessage() ); 
						ret.put('Status', 'Failed' );
					 }catch(Exception e){
						ret.put('Status','Failed');
						ret.put('Msg','Internal error, received: '+e.getMessage());
					 }
		}else{
				ret.put('Status','Failed');
				ret.put('Msg','Received Invalid Options.');
				ret.put('Received',siteInfoStr);
		}
		return ret;
	 }
	 
/**
	 * @description
	 *		Delete a Site (and all related communities)
	 * @param siteInfoStr @type String (Json stringified object)
	 * @return Object / Map<String,Object>
	 **/
	 public static Object deleteSite( String siteInfoStr ){
		map<String,Object> ret = (map<String,Object>) getResponseStructure();
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(siteInfoStr);
		cam_Site__c element = null;
		if ( opts.get('Id') != null ){
				try{
					 //check delete permissions
					cam_SecurityHandler.canDelete( 
						new Schema.SObjectType[] {cam_Community__c.sObjectType});
					 
					 element = [Select Id,siteName__c from cam_Site__c where Id = :String.valueOf(opts.get('Id'))];
					 list<cam_Community__c> childs = [Select Id From cam_Community__c where siteName__c = :element.siteName__c];
					 if ( childs.size() > 0 ) delete childs;
					 delete element;
					 ret.put('Status','Success');
				}catch(cam_SecurityHandler.SecurityException sEx){
						ret.put('Msg','Internal error, received: '+sEx.getMessage() ); 
						ret.put('Status', 'Failed' );
				}catch(Exception e){
					 ret.put('Status','Failed');
					 ret.put('Msg','Internal error, received: '+e.getMessage());
				}
		}else{
				ret.put('Status','Failed');
				ret.put('Msg','Received Invalid Options.');
				ret.put('Received',siteInfoStr);
		}
		return ret;
	 }
	 
/**
	 * @description
	 *		Create /Update a Community
	 * @param communityInfoStr @type String (Json stringified object)
	 * @return Object / Map<String,Object>
	 **/
	 public static Object postPutCommunity( String communityInfoStr ){
		map<String,Object> ret = (map<String,Object>) getResponseStructure();
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(communityInfoStr);
		cam_Community__c comm = null;
		
		if ( opts.get('staticResourceName__c') != null && opts.get('iconPath__c') != null && opts.get('publicName__c') != null &&
					 opts.get('communityId__c') != null && opts.get('communityDCApiName__c') != null && opts.get('communityDCLabel__c') != null &&
					 opts.get('siteName__c') != null && opts.get('communityName__c') != null){
					 
					 try{
						 //check create permissions
						cam_SecurityHandler.canCreate( 
							new Schema.SObjectType[] {cam_Community__c.sObjectType});

						if ( opts.get('Id') == null ){
								comm = new cam_Community__c(
									Name					= String.valueOf((Datetime.now()).getTime()) ,
									staticResourceName__c	= String.valueOf(opts.get('staticResourceName__c')),
									iconPath__c				= String.valueOf(opts.get('iconPath__c')),
									publicName__c			= String.valueOf(opts.get('publicName__c')),
									communityId__c			= String.valueOf(opts.get('communityId__c')),
									communityDCApiName__c	= String.valueOf(opts.get('communityDCApiName__c')),
									communityDCLabel__c		= String.valueOf(opts.get('communityDCLabel__c')),
									siteName__c				= String.valueOf(opts.get('siteName__c')),
									communityName__c		= String.valueOf(opts.get('communityName__c'))
								);
								insert comm;
						}else{
							 //check updatepermissions
								cam_SecurityHandler.canUpdate( 
									new Schema.SObjectType[] {cam_Community__c.sObjectType});
									
								comm = [Select Id,staticResourceName__c,iconPath__c,communityId__c,communityDCApiName__c,communityDCLabel__c,
										siteName__c from cam_Community__c where Id = :String.valueOf(opts.get('Id'))];
								comm.staticResourceName__c	= String.valueOf(opts.get('staticResourceName__c'));
								comm.iconPath__c				 = String.valueOf(opts.get('iconPath__c'));
								comm.publicName__c				 = String.valueOf(opts.get('publicName__c'));
								comm.communityId__c			= String.valueOf(opts.get('communityId__c'));
								comm.communityDCApiName__c	= String.valueOf(opts.get('communityDCApiName__c'));
								comm.communityDCLabel__c	= String.valueOf(opts.get('communityDCLabel__c'));
								comm.siteName__c				 = String.valueOf(opts.get('siteName__c'));
								comm.communityName__c		= String.valueOf(opts.get('communityName__c'));
								upsert comm;
						}
						ret.put('Status','Success');
						ret.put('Id',comm.Id);
					 }catch(cam_SecurityHandler.SecurityException sEx){
						ret.put('Msg','Internal error, received: '+sEx.getMessage() ); 
						ret.put('Status', 'Failed' );
					 }catch(Exception e){
						ret.put('Status','Failed');
						ret.put('Msg','Internal error, received: '+e.getMessage());
					 }
		}else{
				ret.put('Status','Failed');
				ret.put('Msg','Received Invalid Options.');
				ret.put('Received',communityInfoStr);
		}
		return ret;
	 }
	 
/**
	 * @description
	 *		deletes a Community
	 * @param communityInfoStr @type String (Json stringified object)
	 * @return Object / Map<String,Object>
	 **/
	 public static Object deleteCommunity( String communityInfoStr ){
		map<String,Object> ret = (map<String,Object>) getResponseStructure();
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(communityInfoStr);
		cam_Community__c comm = null;
		
		if ( opts.get('Id') != null ){
				try{
					 //check delete permissions
					cam_SecurityHandler.canDelete( 
						new Schema.SObjectType[] {cam_Community__c.sObjectType});
					 
					 comm = [Select Id from cam_Community__c where Id = :String.valueOf(opts.get('Id'))];
					 delete comm;
					 ret.put('Status','Success');
				}catch(cam_SecurityHandler.SecurityException sEx){
						ret.put('Msg','Internal error, received: '+sEx.getMessage() ); 
						ret.put('Status', 'Failed' );
				}catch(Exception e){
					 ret.put('Status','Failed');
					 ret.put('Msg','Internal error, received: '+e.getMessage());
				}
		}else{
				ret.put('Status','Failed');
				ret.put('Msg','Received Invalid Options.');
				ret.put('Received',communityInfoStr);
		}
		return ret;
	 }
	 
	 /**
	 * @description
	 *		Updates / Creates Global Setup
	 * @param globalInfoStr @type String (Json stringified object)
	 * @return Object / Map<String,Object>
	 **/
	 public static Object postPutGlobalSetup( String globalInfoStr ){
		map<String,Object> ret = (map<String,Object>) getResponseStructure();
		map<String,cam_Setup__c> camGlobalSetupMap = cam_Setup__c.getAll();
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(globalInfoStr);
		cam_Setup__c elm = null;
		if ( opts.get('CA_Data_Category__c') != null && opts.get('richTextEditor__c') != null){
				
				try{
					//check create permissions
					cam_SecurityHandler.canCreate( 
						new Schema.SObjectType[] {cam_Setup__c.sObjectType});
					 
					 if ( camGlobalSetupMap.values().size() > 0 ){
						//check update permissions
						cam_SecurityHandler.canUpdate( 
							new Schema.SObjectType[] {cam_Setup__c.sObjectType});
							
						elm = (camGlobalSetupMap.values())[0];
						elm.CA_Data_Category__c = String.valueOf(opts.get('CA_Data_Category__c'));
						elm.richTextEditor__c	= Boolean.valueOf(opts.get('richTextEditor__c'));
						upsert elm;
					 }else{
						elm = new cam_Setup__c( Name					= String.valueOf((Datetime.now()).getTime()), 
														CA_Data_Category__c =		String.valueOf(opts.get('CA_Data_Category__c')),
														richTextEditor__c	 =	 Boolean.valueOf(opts.get('richTextEditor__c')));
						insert elm;
					 }
					 ret.put('Status','Success');
				}catch(cam_SecurityHandler.SecurityException sEx){
						ret.put('Msg','Internal error, received: '+sEx.getMessage() ); 
						ret.put('Status', 'Failed' );
				}catch(Exception e){
					 ret.put('Status','Failed');
					 ret.put('Msg','Internal error, received: '+e.getMessage());
				}
		}else{
				ret.put('Status','Failed');
				ret.put('Msg','Received Invalid Options.');
				ret.put('Received',globalInfoStr);
		}
		return ret;
	 }
	 
/**
	 * @description
	 *		Creates/Update a new KnowledgeArticle (custom setting)
	 * @param knowledgeArticleInfoStr @type String (Json stringified object)
	 * @return Object / Map<String,Object>
	 **/
	 public static Object postPutKnowledgeArticle( String knowledgeArticleInfoStr ){
		map<String,Object> ret = (map<String,Object>) getResponseStructure();
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(knowledgeArticleInfoStr);
		cam_Ka__c element = null;
		
		if ( opts.get('apiName__c') != null && opts.get('layout__c') != null ){
				String elementId = opts.get('Id') == null ? null : String.valueOf(opts.get('Id'));
				try{
					 //check create permissions
					cam_SecurityHandler.canCreate( 
						new Schema.SObjectType[] {cam_Ka__c.sObjectType});
					 //check create permissions
					cam_SecurityHandler.canUpdate( 
						new Schema.SObjectType[] {cam_Ka__c.sObjectType});
					 
					 list<cam_Ka__c> elements = null;
					 if ( elementId != null ){
						 elements = [Select Id,Name,apiName__c,layout__c,isActive__c from cam_Ka__c where Id = :elementId limit 1];
						 elements[0].apiName__c			= String.valueOf(opts.get('apiName__c'));
						 elements[0].layout__c		= String.valueOf(opts.get('layout__c'));					 
					 }else{
						element = new cam_Ka__c(Name	= String.valueOf((Datetime.now()).getTime()) ,
												apiName__c	= String.valueOf(opts.get('apiName__c')),
												layout__c	= String.valueOf(opts.get('layout__c'))
									);
					 }
					 if ( elementId == null ) insert element; else upsert elements[0];
					 //if here all ok
					 ret.put('Status','Success');
					 if ( element != null ) ret.put('Id', element.Id );
					 else ret.put('Id',elements[0].Id);
				}catch(cam_SecurityHandler.SecurityException sEx){
						ret.put('Msg','Internal error, received: '+sEx.getMessage() ); 
						ret.put('Status', 'Failed' );
				}catch(Exception e){
					 ret.put('Status','Failed');
					 ret.put('Msg','Internal error, received: '+e.getMessage());
				}
		}else{
				ret.put('Status','Failed');
				ret.put('Msg','Received Invalid Options.');
				ret.put('Received',knowledgeArticleInfoStr);
		}
		return ret;
	 }
	 
	 /**
	 * @description
	 *		Delete KnowledgeArticle (custom setting)
	 * @param knowledgeArticleInfoStr @type String (Json stringified object)
	 * @return Object / Map<String,Object>
	 **/
	 public static Object deleteKnowledgeArticle( String knowledgeArticleInfoStr ){
		map<String,Object> ret = (map<String,Object>) getResponseStructure();
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(knowledgeArticleInfoStr);
		try{
				//check delete permissions
				cam_SecurityHandler.canDelete( 
					new Schema.SObjectType[] {cam_Ka__c.sObjectType});
				
				list<cam_Ka__c> element = opts.get('Id') == null ? new list<cam_Ka__c>() : [Select Id from cam_Ka__c where Id = :String.valueOf(opts.get('Id'))];
				if ( element.size() > 0 ){
					 delete element[0];
					 //if here all ok
					 ret.put('Status','Success');
				}else{
					 ret.put('Status','Failed');
					 ret.put('Msg','Given Id does not exist');
				}
		}catch(cam_SecurityHandler.SecurityException sEx){
						ret.put('Msg','Internal error, received: '+sEx.getMessage() ); 
						ret.put('Status', 'Failed' );
		}catch(Exception e){
				ret.put('Status','Failed');
				ret.put('Msg','Internal error, received: '+e.getMessage());
		}
		return ret;
	 }
	 
	 
/**
	 * @description
	 *	Get All Specific KA elements with all fields api name included
	 * @return @type Object
	 **/
	 public static Object getKnowledgeTypesAndFields(){
		map<String,Object> ret = new map<String,Object>();
		
		AggregateResult[] kas = [Select ArticleType from KnowledgeArticleVersion where Language = 'en_US' and PublishStatus = 'Online'
																group by ArticleType limit 25000];

		Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		
		for ( AggregateResult elm : kas ){
				Schema.DescribeSObjectResult descRes;
				Map<String, Schema.SObjectField> fieldMap;
				descRes = schemaMap.get(String.valueOf(elm.get('ArticleType'))).getDescribe();
				fieldMap = descRes.fields.getMap();
				ret.put(String.valueOf(elm.get('ArticleType')),fieldMap.keySet());
		}
		return ret;
	 }
	 
	/**
	 * @description
	 *		Returns Org users information
	 * @return Object
	 **/
	 public static Boolean isRichTextEnabledOnSite(){
		Boolean isOn = false;
		cam_Setup__c currentSetting = [Select Id, richTextEditor__c
										FROM cam_Setup__c];
		if (currentSetting != null){
				isOn = currentSetting.richTextEditor__c;
		}
		return isOn;
	 }
	 
	 
/**
	 * @description
	 *		Returns Org users information
	 * @return Object
	 **/
	 public static Object getOrgUsers(){
		return [Select Id,Name,Username from User limit 1000];
	 }
	 
/**
	 * @description
	 *		Returns Org static resources information
	 * @return Object
	 **/
	 public static Object getOrgStaticResources(){
		return [Select Id,Name from StaticResource limit 1000];
	 }
	 
/**
	 * @description
	 *		Returns Org Profiles information
	 * @return Object
	 **/
	 public static Object getOrgProfiles(){
		return [Select Id,Name from Profile limit 1000];
	 }
	 
/**
	 * @description
	 *		Returns Org Sites Information
	 * @return Object
	 **/
	 public static Object getOrgSites(){
		return [Select Id,Name from Site limit 500];
	 }
	 
/**
	 * @description
	 *		Returns Org Sites Information
	 * @return Object
	 **/
	 public static Object getOrgCommunities(){
		return [Select Id,Name from Community limit 1000];
	 }

	 private static Object getResponseStructure(){
		return new map<String,Object>{
					 'Status'	=> '',
					 'Msg'		=> ''
		};
	 }
	 
	 private static Object reportCriticalError(){
		map<String,Object> ret = (map<String,String>) getResponseStructure();
		ret.put('Status','FAILURE');
		ret.put('Msg',CRITICAL_ERROR);
		return ret;
	 }


}