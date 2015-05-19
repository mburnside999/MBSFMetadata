/**
 * @author Timba Software
 * @description
 *		started at 08/06/2012
 *		Comunication object between front-end / back-end
 **/
global with sharing class cam_DTO {
	
	/**
	 *@description
	 *	RequestItem Constants
	 **/
	public map<String,String> globalConstants {get;set;}
	public map<String,String> searchConstants {get;set;}
	
	
	//Current User Information
	public map<String,String> currentUser {get;set;}
	
	//options
	public map<String,String> globalOptions {get; set;}
	public map<String,String> searchOptions {get;set;}
	public map<String,String> singleItemViewOptions { get;set; }
	public map<String,STring> myFeedOptions {get; set;}
	public map<String,Object> sitesDefinition {get;set;}
	
	//Response wrapper
	public cam_DTO.response response {get;set;}
	
	 /**
	 * @description
	 *		Contructor
	 **/
	 public cam_DTO(){
	 	init();
	 }
	 
	 /**
	 * @description
	 *		Contructor
	 **/
	 public cam_DTO(Boolean getAllSites){
	 	this.sitesDefinition = (map<String,Object>) cam_CustomSettingModel.getAllSitesSetup();
	 	init();
	 }
	 
	 /**
	 * @description
	 *		Initialize all values for current object
	 **/
	 private void init(){ 
	 	
	 	//Defining global constants
	 	this.globalConstants = cam_Config.globalConstants;
	 	
	 	//Defining Search Constants
	 	this.searchConstants = cam_Config.searchConstants;
	 	
	 	//Defining myFeed options
	 	this.myFeedOptions = new map<String,String>();
	 	this.myFeedOptions.put('communityId',this.globalConstants.get('NULL_VAL'));
	 	this.myFeedOptions.put('topicApiName',this.globalConstants.get('NULL_VAL'));
	 	this.myFeedOptions.put('questionOffset',this.globalConstants.get('NULL_VAL'));
	 	this.myFeedOptions.put('caseOffset',this.globalConstants.get('NULL_VAL'));
	 	
	 	//Defining standard structure for global options
	 	this.globalOptions = new map<String,String>();
	 	this.globalOptions.put('requestType', this.globalConstants.get('requestType_SEARCH'));
	 	
	 	//Defining standard structure for searchOptions
	 	this.searchOptions = new map<String,String>();
	 	this.searchOptions.put('communityId',this.globalConstants.get('NULL_VAL'));
	 	this.searchOptions.put('topicName',this.globalConstants.get('NULL_VAL'));
	 	this.searchOptions.put('searchInput',this.globalConstants.get('NULL_VAL'));
	 	this.searchOptions.put('sortBy',this.globalConstants.get('NULL_VAL'));
	 	//Can be open/bestanswer/withfilter/myfeed/all(this "all" doesn't include private messages)
	 	this.searchOptions.put('scope',this.globalConstants.get('NULL_VAL'));
	 	
	 	//Defining standard structure for singleItemViewOptions
	 	this.singleItemViewOptions = new map<String,String>();
	 	//It can be a Case id or a Question id
	 	this.singleItemViewOptions.put('idToDisplay', this.globalConstants.get('NULL_VAL') );
	 	this.singleItemViewOptions.put('getPrivateToo', this.globalConstants.get('BOOLEAN_FALSE') );
	 	
	 	//Defining response wrapper
	 	this.response = new cam_DTO.response(new list<cam_DTO.responseElement>(),'','',0,false);
	 	
	 	//Init current user map
	 	cam_Model.getUserDetails(false, this, Userinfo.getUserId(),''); 
	 }
	 
	 /**
	  * @description
	  *		Validates the requestItem
	  * @param obj - a JSON.Stringify result of this object in the front end
	  * @return Integer '-1' = fails / '1' = ok
	  **/
	  @RemoteAction
	  global static Integer validateDTOAsync(String obj){
	  	return validateDTO(obj);
	  }
	  
	  /**
	  * @description
	  *		Validates the requestItem
	  * @param obj - a JSON.Stringify result of this object in the front end
	  * @return Integer '-1' = fails / '1' = ok
	  **/
	  global static Integer validateDTO(String obj){
	  	//Parse the json received to work with
	  	cam_DTO elm = null;
	  	try{
	  		Jsonparser parser = Json.createParser(obj);
	  		Type itemType = Type.forName('cam_DTO');
        	elm = (cam_DTO)parser.readValueAs(itemType);
	  	}catch(Exception e){
        	return 	-1;
        }
        
        /*Validating each scenario
	  	 *Starting from global options
	  	 */
	  	map<String,String> globalOpts = elm.globalOptions;  
	  	map<String,String> searchOpts = elm.searchOptions;
	  	map<String,String> singleItemViewOpts = elm.singleItemViewOptions;
	  	map<String,String> myFeedOpts = elm.myFeedOptions;
	  	
	  	if ( globalOpts.get('requestType') == null || globalOpts.get('requestType') == 'undefined' ) return -1; 
	  	if ( globalOpts.get('requestType') != (elm.globalConstants).get('requestType_SEARCH')
	  		 && globalOpts.get('requestType') != (elm.globalConstants).get('requestType_POST')
	  		 && globalOpts.get('requestType') != (elm.globalConstants).get('requestType_SINGLE_ITEM_VIEW') 
	  		 && globalOpts.get('requestType') != (elm.globalConstants).get('requestType_MY_FEED')) return -1;
	  	
	  	
	  	//Covering requestType as Search
	  	if ( globalOpts.get('requestType') == (elm.globalConstants).get('requestType_SEARCH') ){
	  		//Checking minimum requirements to perform a search
	  		//Community Id is a must
	  		if ( (searchOpts.get('communityId') == null || searchOpts.get('communityId') == '-1') ) return -1;
	  		
	  		if ( searchOpts.get('scope') == (elm.searchConstants).get('questions_GET_ALL_QUESTIONS') 
	  			|| searchOpts.get('scope') == (elm.searchConstants).get('questions_GET_WITHFILTER')
	  			|| searchOpts.get('scope') == (elm.searchConstants).get('questions_GET_MYFEED')
	  			|| searchOpts.get('scope') == (elm.searchConstants).get('questions_GET_ARTICLES')){
	  				
	  				if ( searchOpts.get('scope') != (elm.searchConstants).get('questions_GET_WITHFILTER')
	  						&& searchOpts.get('scope') != (elm.searchConstants).get('questions_GET_ARTICLES') ){
	  					//during search with filter by text input
	  					if ( searchOpts.get('sortBy') != (elm.searchConstants).get('sortBy_POPULARITY')
	  					&& searchOpts.get('sortBy') != (elm.searchConstants).get('sortBy_RECENT')
	  					&& searchOpts.get('sortBy') != (elm.searchConstants).get('sortBy_LAST_REPLY')){
	  						return -1;
	  					}
	  				}
	  			return 1;
	  		}else{
	  			return -1;
	  		}	  	
	  	}
	  	//Covering Single Item View request
	  	if ( globalOpts.get('requestType') == (elm.globalConstants).get('requestType_SINGLE_ITEM_VIEW') ){
	  		String value = singleItemViewOpts.get('idToDisplay');
	  		if ( value == null ) return -1;
	  		value = value.trim();
	  		if ( value.length() == 18 || value.length() == 15 ) return 1;
	  		else return -1;
	  	}
	  	
	  	//Covering My Feed Request
	  	if ( globalOpts.get('requestType') == (elm.globalConstants).get('requestType_MY_FEED') ){
	  		String c = (myFeedOpts.get('communityId')).trim();
	  		if ( c == null ) return -1;
	  	}
	  	
	  	return 1;
	  }
	  
	 //Inner class for response
	  public with sharing class response{
	  	public list<cam_DTO.responseElement> responseElements {get;set;}
	  	public String responseMsg {get;set;}
	  	public String status {get;set;}
	  	public Integer offset {get;set;}
	  	public Boolean hasMore {get;set;}
	  	
	  	/*
	  	 * @description
	  	 * 	Constructor
	  	 */ 
	  	public response(list<cam_DTO.responseElement> elements, String rMSG, String st, Integer offst, Boolean hM){
	  		this.responseElements = elements;
	 		this.responseMsg = rMSG;
	 		this.status = st;
	 		this.offset = offst;
	 		this.hasMore = hM;
	  	}
	  	
	  }
	  
	  //Inner class for responseElement
	  public with sharing class responseElement{
	  	public map<String,Object> element {get;set;}
	  	public map<String,list<Object>> elementChilds {get;set;}
	  	public object results {get;set;}
	  	public responseElement(){
	  		this.element = new map<String,Object>();
	  		this.elementChilds = new map<String,list<Object>>();
	  		this.results = null;
	  	}
	  }
}