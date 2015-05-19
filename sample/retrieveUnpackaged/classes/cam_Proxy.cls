/**
 * @author Timba Software
 * @description
 *		started at 08/06/2012
 *		Front Controller of Chatter Answers Mobile
 **/
global with sharing class cam_Proxy { 
	
	/**
	 * @description
	 *	CHATTER ANSWERS MOBILE PRIMARY CONSTANT (DATA CATEGORY GROUP NAME RELATED)
	 **/
	public static final String CAM_ROOT_GROUP_NAME = cam_Config.CAM_ROOT_GROUP_NAME;
	public static final String CAM_ROOT_GROUP_NAME_SIMPLE = cam_Config.CAM_ROOT_GROUP_NAME_SIMPLE;
	
	public static final map<String,String> communityRelationWithDataCategory = cam_Config.communityRelationWithDataCategory;
	 
	/** 
	 * @description
	 *	CHATTER ANSWERS MOBILE HARDCODED GUEST USER PROFILE ID (this will affect results of "getUserDetails" proxy method) 
	 **/
	public static final String guestUserProfileId = cam_Config.guestUserProfileId;
	
	/**
	 * @description
	 *	Constants
	 **/
	 public static final String INVALID_DTO = 'DTO Object received: Validation failed.';
	 public static final String INVALID_OPTIONS = 'Options Object received: Validation failed.';
	 public static final String INVALID_SESSION = 'Your session has timed out.';
	
	/*
	 * @description
	 *	Exposed method to front-end
	 * @return cam_DTO
	 */
	@RemoteAction
	global static cam_DTO action(String obj){
		cam_DTO ret = resolveObject(obj); 
		//validate DTO
		if ( cam_DTO.validateDTO(obj) == -1 ){
			ret.response.status = ret.globalConstants.get('STATUS_ERROR');
			ret.response.responseMsg = INVALID_DTO;
			return ret;
		}
		
		//delegate to proper handler
		if ( (ret.globalOptions).get('requestType') == ret.globalConstants.get('requestType_SEARCH') ) 
			return handleSearch(ret);
		if ( (ret.globalOptions).get('requestType') == ret.globalConstants.get('requestType_SINGLE_ITEM_VIEW') ) 
			return handleSingleItemView(ret);
		if ( (ret.globalOptions).get('requestType') == ret.globalConstants.get('requestType_MY_FEED') ) 
			return handleMyFeed(ret);
		
		return ret;
	}
	
	@RemoteAction
	global static cam_DTO requestSkeleton(){
		return new cam_DTO(true);  
	}
	
	/*
	 * @description
	 * 	tries to convert string into cam_DTO object
	 * @return cam_DTO
	 * @throws Exception if cant convert item
	 */
	private static cam_DTO resolveObject(String obj){
		cam_DTO elm = null;
	  	Jsonparser parser = Json.createParser(obj);
	  	Type itemType = Type.forName('cam_DTO');
        elm = (cam_DTO)parser.readValueAs(itemType);
        return elm;
	}
	
	/*
	 * @description
	 *	Handles a search in chatter answers
	 * @return cam_DTO
	 */
	private static cam_DTO handleSearch(cam_DTO source){
		String searchScope = (source.searchOptions).get('scope');
		
		if ( searchScope == (source.searchConstants).get('questions_GET_ALL_QUESTIONS')){
	  		source = cam_Model.get_All_Questions(source);
	  	}else if ( searchScope == (source.searchConstants).get('questions_GET_WITHFILTER') ){
	  		source = cam_Model.get_Questions_With_Filter(source);
	  	}else if ( searchScope == (source.searchConstants).get('questions_GET_ARTICLES') ){
	  		source = cam_Model.get_Questions_Articles(source);
	  	}
	  	return source;
	}
	
	/*
	 * @description
	 *	Handles single item view
	 * @return cam_DTO
	 */
	 private static cam_DTO handleSingleItemView(cam_DTO source){
	 	cam_DTO result = null;
	 	String valueToSearch = (source.singleItemViewOptions).get('idToDisplay');
	 	String valueToSearchPrefix = valueToSearch.subString(0,3);
	 	if ( Schema.sObjectType.Case.getKeyPrefix() == valueToSearchPrefix ) {
	 		if (!cam_Proxy.validSession() && !Test.isRunningTest()){
	 			result = new cam_DTO();
	      		result.response.status = result.globalConstants.get('STATUS_ERROR');
            	result.response.responseMsg = INVALID_SESSION;//e.getMessage();
            	return result;
	 		}
	 	}
 		return cam_Model.getSingleItemView(source);
	 }
	 
	/*
	 * @description
	 * 	Handles the my Feed request
	 * @param source @type cam_DTO
	 * @return  @type cam_DTO
	 */
	 private static cam_DTO handleMyFeed(cam_DTO source){
		return cam_Model.handleMyFeed(source);		 
	 }
	
	/*
	 * @description
	 *	Retrieve User Full Details
	 * @return cam_DTO
	 */
	@RemoteAction
	global static map<String,String> getUserDetails(String options){
		cam_DTO container = new cam_DTO();
		//Deserializing options
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(options);
		if ( opts.get('communityId') != null && opts.get('uId') != null){	
			container = cam_Model.getUserDetails(true, container, String.valueOf(opts.get('uId')),String.valueOf(opts.get('communityId')));
		}
		return container.currentUser;
	}

	/*
	 * @description
	 *	Retrieve User Reputation Details
	 * @return cam_DTO
	 */
	@RemoteAction
	global static map<String,String> getUserReputation(String options){
		cam_DTO container = new cam_DTO();
		//Deserializing options
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(options);
		if ( opts.get('communityId') != null && opts.get('uId') != null){	
			container = cam_Model.getReputationDetails( container, String.valueOf(opts.get('uId')),String.valueOf(opts.get('communityId')));
		}
		return container.currentUser;
	}
	
	/*
	 * @description
	 *	Creates a new Question (Public Or Private)
	 * @param options @type JSON STRINGIFIED CONTENT
	 * 		@param communityId @type String
	 * 		@param title @type String
	 * 		@param body @type String
	 * 		@param topic @type String [Optional]
	 *		@param isPublic @type String
	 * @return map<String,String>
	 */
	@RemoteAction
	global static map<String,String> postQuestion(String options){
		
		// control valid session
		if (!cam_Proxy.validSession()){
 			cam_DTO aux = new cam_DTO();
      		map<String,String> ret = new map<String,String>();
      		ret.put('responseMsg', INVALID_SESSION);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
	  		return ret;
 		}
		
		//Deserializing options
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(options);
		if ( opts.get('isPublic') != null ){
			cam_DTO aux = new cam_DTO();
			String t = String.valueOf(opts.get('isPublic'));
			if ( t == (aux.globalConstants).get('BOOLEAN_FALSE') ) return postPrivateQuestion(options);
			else return postPublicQuestion(options);
		}else{
			cam_DTO aux = new cam_DTO();
      		map<String,String> ret = new map<String,String>();
      		ret.put('responseMsg', INVALID_OPTIONS);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
	  		return ret;
		}
	}
	
	/*
	 * @description
	 *	Creates a new Question (Public)
	 * @param options @type JSON STRINGIFIED CONTENT
	 * 		@param communityId @type String
	 * 		@param title @type String
	 * 		@param body @type String
	 * 		@param topic @type String
	 * @return map<String,String>
	 */
	private static map<String,String> postPublicQuestion( String options ){
		//Deserializing options
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(options);      	
      	//validating content
      	if ( opts.get('communityId') != null && opts.get('title') != null && opts.get('body') != null && opts.get('topic') != null  ){
      		return cam_Model.postPublicQuestion(String.valueOf(opts.get('communityId')),String.valueOf(opts.get('title')),String.valueOf(opts.get('body')),String.valueOf(opts.get('topic')));
      	}else{
      		cam_DTO aux = new cam_DTO();
      		map<String,String> ret = new map<String,String>();
      		ret.put('responseMsg', INVALID_OPTIONS);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
	  		return ret;
      	}
	}
	
	/*
	 * @description
	 *	Creates a new Question (Private)
	 * @param options @type JSON STRINGIFIED CONTENT
	 * 		@param communityId @type String
	 * 		@param title @type String
	 * 		@param body @type String
	 * @return map<String,String>
	 */
	private static map<String,String> postPrivateQuestion(String options){
		//Deserializing options
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(options);
		//validating content
		if ( opts.get('communityId') != null && opts.get('title') != null && opts.get('body') != null ){
			return cam_Model.postPrivateQuestion( String.valueOf(opts.get('communityId')), String.valueOf(opts.get('title')), String.valueOf(opts.get('body')) );
		}else{
			cam_DTO aux = new cam_DTO();
      		map<String,String> ret = new map<String,String>();
      		ret.put('responseMsg', INVALID_OPTIONS);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
	  		return ret;
		}
	}
	
	/*
	 * @description
	 *	Creates a new Reply/Answer (Public/Private)
     * @param options @type JSON STRINGIFIED CONTENT
     * 		@param parentId @type String
	 * 		@param body @type String
	 * @return map<String,String>
	 */
	@RemoteAction
	global static map<String,String> postReply (String options){
		
		// control valid session
		if (!cam_Proxy.validSession()){
 			cam_DTO aux = new cam_DTO();
      		map<String,String> ret = new map<String,String>();
      		ret.put('responseMsg', INVALID_SESSION);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
	  		return ret;
 		}
		
		
		//Deserializing options
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(options);
		//validating content
		if ( opts.get('parentId') != null && opts.get('body') != null ){
			return cam_Model.postReply(String.valueOf(opts.get('parentId')),String.valueOf(opts.get('body')));
		}else{
			cam_DTO aux = new cam_DTO();
      		map<String,String> ret = new map<String,String>();
      		ret.put('responseMsg', INVALID_OPTIONS);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
	  		return ret;
		}
	}
	
	/*
	 * @description
	 *	Follow/Unfollow a question
     * @param options @type JSON STRINGIFIED CONTENT
     * 		@param questionId @type String
	 * 		@param follow @type String
	 * @return map<String,String>
	 */
	@RemoteAction
	global static map<String,String> follow( String options ){
		map<String,String> ret = new map<String,String>();
		cam_DTO aux = new cam_DTO();
		
		// control valid session
		if (!cam_Proxy.validSession()){
      		ret.put('responseMsg', INVALID_SESSION);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
	  		return ret;
 		}		
		
		//Deserializing options
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(options);
		if ( opts.get('questionId') != null && opts.get('follow') != null){
			Boolean follow = (opts.get('follow')) == ((aux.globalConstants).get('BOOLEAN_TRUE')) ? true : false;
			return cam_Model.follow( String.valueOf(opts.get('questionId')), follow );
		}else{
			ret.put('responseMsg', INVALID_OPTIONS);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
		}
		return ret;
	}
	
	/*
	 * @description
	 *	Select/Unselect a best answer for a given question/answer
     * @param options @type JSON STRINGIFIED CONTENT
     * 		@param questionId @type String
	 * 		@param answerId @type String
	 * @return map<String,String>
	 */
	@RemoteAction
	global static map<String,String> bestAnswer(String options){
		map<String,String> ret = new map<String,String>();
		cam_DTO aux = new cam_DTO();

		// control valid session
		if (!cam_Proxy.validSession()){
      		ret.put('responseMsg', INVALID_SESSION);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
	  		return ret;
 		}
		
		//Deserializing options
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(options);
		
		if ( opts.get('questionId') != null && opts.get('answerId') != null ){
			return cam_Model.bestAnswer(String.valueOf(opts.get('questionId')),String.valueOf(opts.get('answerId')));
		}else{
			ret.put('responseMsg', INVALID_OPTIONS);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
		}
		
		return ret;
	}
	
	/*
	 * @description
	 *	Add a like to a question or an answer
     * @param options @type JSON STRINGIFIED CONTENT
     * 		@param questionId @type String
	 * @return map<String,String>
	 */
	@RemoteAction
	global static map<String,String> voteLike(String options){
		map<String,String> ret = new map<String,String>();
		cam_DTO aux = new cam_DTO();

		// control valid session
		if (!cam_Proxy.validSession()){
      		ret.put('responseMsg', INVALID_SESSION);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
	  		return ret;
 		}
		
		//Deserializing options
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(options);
		if ( opts.get('elementId') != null ){
			return cam_Model.voteLike(String.valueOf(opts.get('elementId')));
		}else{
			ret.put('responseMsg', INVALID_OPTIONS);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
		}
		return ret;
	}
	

	/*
	 * @description
	 *	Add a reportAbuse to a question or an answer
     * @param options @type JSON STRINGIFIED CONTENT
     * 		@param questionId @type String
	 * @return map<String,String>
	 */
	@RemoteAction
	global static map<String,String> reportAbuse(String options){
		map<String,String> ret = new map<String,String>();
		cam_DTO aux = new cam_DTO();

		// control valid session
		if (!cam_Proxy.validSession()){
      		ret.put('responseMsg', INVALID_SESSION);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
	  		return ret;
 		}
		
		//Deserializing options
		Map<String, Object> opts = (Map<String, Object>) JSON.deserializeUntyped(options);
		if ( opts.get('elementId') != null ){
			return cam_Model.reportAbuse(String.valueOf(opts.get('elementId')));
		}else{
			ret.put('responseMsg', INVALID_OPTIONS);
	  		ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
		}
		return ret;
	}
	
	public static Boolean validSession(){
		Boolean valid = true;
		if (UserInfo.getProfileId() == cam_Config.guestUserProfileId){
			valid = false;
		}
		return Test.isRunningTest() ? true : valid;
	}
	
	@RemoteAction
	global static Object whoAmI(){
		map<String,Object> ret = new map<String,Object>();
		ret.put('User',Userinfo.getUserName());
		ret.put('Id',Userinfo.getUserId());
		ret.put('SiteName',Site.getName());
		return ret;
	}
	
	public static String getsiteName(){
		map<String,Object> currentSiteGlobal = (map<String,Object>) cam_CustomSettingModel.getCurrentSiteSetup();
		list<map<String,Object>> sites = (list<map<String,Object>>) currentSiteGlobal.get('Sites');
		map<String,Object> currentSite = sites[0];
		return String.valueOf(currentSite.get('sitePublicName__c'));
	}
	
	public static String getCamRootGroupName(){
		map<String,Object> currentSiteGlobal = (map<String,Object>) cam_CustomSettingModel.getCurrentSiteSetup();
		return String.valueOf( currentSiteGlobal.get('CA_Data_Category__c') );
	}
	
	public static String getcssPath(){
		map<String,Object> currentSiteGlobal = (map<String,Object>) cam_CustomSettingModel.getCurrentSiteSetup();
		list<map<String,Object>> sites = (list<map<String,Object>>) currentSiteGlobal.get('Sites');
		map<String,Object> currentSite = sites[0];
		return String.valueOf(currentSite.get('cssPath__c'));
	}
	
	public static String getstaticResource(){
		map<String,Object> currentSiteGlobal = (map<String,Object>) cam_CustomSettingModel.getCurrentSiteSetup();
		list<map<String,Object>> sites = (list<map<String,Object>>) currentSiteGlobal.get('Sites');
		map<String,Object> currentSite = sites[0];
		return String.valueOf(currentSite.get('staticResourceName__c'));
	}
	
	public static list<map<String,Object>> getCommunities(){
		map<String,Object> currentSiteGlobal = (map<String,Object>) cam_CustomSettingModel.getCurrentSiteSetup();
		list<map<String,Object>> sites = (list<map<String,Object>>) currentSiteGlobal.get('Sites');
		list<map<String,Object>> ret = new list<map<String,Object>>();
		
		Object comms = (sites[0]).get('Communities');
		if ( comms instanceof String){
			//map<String,Object> msg = new map<String,Object>{ 'msg' => String.valueOf(comms) };
			//ret.add(msg);
			return null;
		}
		list<Object> commsList = (list<Object>) comms;
		for ( Object elm : commsList ){
			map<String,Object> elmMap = (map<String,Object>) elm;
			ret.add(elmMap);
		}
		return ret;
	}
	
	public class SecurityException extends Exception {}
	
}