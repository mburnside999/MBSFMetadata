/**
 * @author Timba Software
 * @description
 *      started at 09/10/2012
 *      Constants and Harcoded methods for mobile app
 **/
public with sharing class cam_Config {
	
	public static Object siteSetup = null;
	public static Object getSiteSetup(){
		return siteSetup == null ? cam_CustomSettingModel.getCurrentSiteSetup() : siteSetup;
	}
	public static map<String,String> savedRelationCDC = null;
	public static list<String> profileIds = null;
	public static map<String,String> moderatorsList = null;
	
	
    /**
     * @description
     *  CHATTER ANSWERS MOBILE CONSTANTS
     **/
    public static final String CAM_ROOT_GROUP_NAME_SIMPLE = ((map<String,Object>)getSiteSetup()).get('Msg') == 'Success' ?
    															String.valueOf(((map<String,Object>)getSiteSetup()).get('CA_Data_Category__c')) : '';
    public static final String CAM_ROOT_GROUP_NAME = CAM_ROOT_GROUP_NAME_SIMPLE == '' ? '' : CAM_ROOT_GROUP_NAME_SIMPLE+'__c';
    
    public static final map<String,String> communityRelationWithDataCategory = getCommunityRelationWithDataCategory();
    
    private static map<String,String> getCommunityRelationWithDataCategory(){
    	if ( savedRelationCDC != null ) return savedRelationCDC;
    	map<String,String> ret = new map<String,String>();
    	
    	Map<String,Object> s = (map<String,Object>) getSiteSetup();
    	
    	list<map<String,Object>> listOfSites = (list<map<String,Object>>) s.get('Sites');
    	map<String,Object> currentSite = listOfSites.size() > 0 ? listOfSites[0] : null;
    	
    	if ( currentSite != null ){
    		
    		Object communitiesObj = currentSite.get('Communities');
    		if ( communitiesObj instanceof list<Object> ){
    			
    			for ( Object elmObj : ( (list<Object>) communitiesObj) ){
    				map<String,Object> elm = (map<String,Object>) elmObj;
    				ret.put( String.valueOf(elm.get('communityId__c')) , String.valueOf(elm.get('communityDCApiName__c')) );
    			}
    		}
    	}
    	savedRelationCDC = ret;
    	return ret;
    }
    
    private static list<String> getProfileIds(){
    	if ( profileIds != null ) return profileIds;
    	list<String> ret = null;
    	
    	Map<String,Object> s = (map<String,Object>) getSiteSetup();
    	
    	list<map<String,Object>> listOfSites = (list<map<String,Object>>) s.get('Sites');
    	map<String,Object> currentSite = listOfSites.size() > 0 ? listOfSites[0] : null;
    	if ( currentSite != null ){
    		ret = new list<String>();
    		ret.add( String.valueOf(currentSite.get('guestProfileId__c')) );
    		profileIds = ret;
    	}
    	return ret;
    }
    
    private static map<String,String> getSupportAgents(){
    	if ( moderatorsList != null ) return moderatorsList;
    	else moderatorsList = new map<String,String>();
    	Map<String,Object> s = (map<String,Object>) getSiteSetup();
    	Object moderatorsObj = s.get('Moderators');
    	
    	if ( moderatorsObj instanceof list<Object> ){
    		list<Object> mList = (list<Object>) moderatorsObj;
    		for ( Object obj : mList ){
    			map<String,Object> elm = (map<String,Object>) obj;
    			moderatorsList.put( String.valueOf(elm.get('userId__c')), String.valueOf(elm.get('userId__c')) );
    		}
    	}
    	return moderatorsList;
    }
    
    public static list<String> siteCommunities = getSiteCommunities(); 
			
	private static list<String> getSiteCommunities(){
		list<String> ret = new list<String>();
		map<String,Object> s = (map<String,Object>) getSiteSetup();
		list<map<String,Object>> sites = (list<map<String,Object>>) s.get('Sites');
		list<Object> comms = (list<Object>) sites[0].get('Communities');
		if ( comms.size() < 1 ) return ret;
		for ( Object elm : comms ){
			map<String,Object> obj = (map<String,Object>) elm;
			ret.add( String.valueOf(obj.get('communityId__c')) );
		}
		return ret;
	}
    
    /**
     * @description
     *  CHATTER ANSWERS MOBILE HARDCODED GUEST USER PROFILE ID (this will affect results of "getUserDetails" proxy method) 
     **/
    public static final String guestUserProfileId = getProfileIds() == null ? '' : profileIds[0];
    
    public static map<String,String> customerSupportAgents = getSupportAgents();
    public static set<String> supportAgentsIds = ( customerSupportAgents.keySet() );
    
    /**
     * @description
     *  CHATTER ANSWERS MOBILE HARDCODED INFO ABOUT KNOWLEDGE ARTICLES PRESENTATION 
     **/
    public static Object sortKnowledgeArticleFields(Object obj,String objType){
        map<String,String> m = null;
        list<Object> l = (list<Object>) obj;
        SObject o = (SObject) l[0]; Datetime d = (Datetime) o.get('LastPublishedDate');
        if ( !test.isRunningTest() ) m = new map<String,String>{ 'Id'=>String.valueOf(o.get('Id')), 'Title'=>String.valueOf(o.get('Title')),'Print'=>getKAPrint(o,objType),'KnowledgeArticleId'=>String.valueOf(o.get('KnowledgeArticleId')),'LastPublishedDate'=>String.valueOf(d.getTime())};
        else m = new map<String,String>{ 'Id'=>String.valueOf(o.get('Id')), 'Title'=>String.valueOf(o.get('Title')),'Print'=>'','KnowledgeArticleId'=>String.valueOf(o.get('KnowledgeArticleId')),'LastPublishedDate'=>'000000000'};
        return (object) m;
    }
    
    private static String getKAPrint(SObject o,String oType){
    	list<cam_Ka__c> camCS = [ Select layout__c from cam_Ka__c where apiName__c = :oType and isActive__c = true ];
    	if ( camCS.size() < 1 ) return '';
    	
    	String kaLayout = camCS[0].layout__c;
    	String[] layoutSplit = kaLayout != null ? kaLayout.split(',') : null;
    	
    	if ( layoutSplit == null || layoutSplit.size() < 1 ) return '';
    	
    	String ret = '';
    	for ( Integer i=0; i<layoutSplit.size(); i++ ){
    		if ( String.valueOf( o.get(layoutSplit[i]) ) == 'null' || String.valueOf( o.get(layoutSplit[i]) ) == null ) continue;
    		ret += String.valueOf( o.get(layoutSplit[i]) )+'<br/>';
    	}
    	return ret;
    }
    
    //Constants for Skeleton (DTO)
    //Defining global constants
    	
    public static map<String,String> globalConstants = new map<String,String>{
    		'requestType_SEARCH' 				=> 'search',
    		'requestType_SINGLE_ITEM_VIEW' 		=> 'siview',
    		'requestType_MY_FEED' 				=> 'myFeed',
    		'NULL_VAL' 							=> '-1',
    		'STATUS_OK'							=> 'Success',
    		'STATUS_ERROR' 						=> 'Error',
    		'BOOLEAN_TRUE' 						=> 'true',
    		'BOOLEAN_FALSE' 					=> 'false'    	
    	};
    	
	public static map<String,String> searchConstants = new map<String,String>{
	 		'sortBy_POPULARITY'									=> 'sortPop',
	 		'sortBy_RECENT'										=> 'sortRecent',
	 		'sortBy_LAST_REPLY'									=> 'lastReplyRecent',
	 		'questions_GET_ALL_QUESTIONS'						=> 'getAllQuestions',
	 		'questions_GET_WITHFILTER'							=> 'getFiltering',
	 		'questions_GET_MYFEED'								=> 'getMyFeed',
	 		'questions_GET_ARTICLES'							=> 'getArticles'
	 	};
	/**
     * @description
     *  CHATTER ANSWERS MOBILE HARDCODED  GENERIC ERROR NOTE
     **/
    public static final String errorMsg = 'Internal application error';	 	
}