/**
 * @author Timba Software
 * @description
 *	started at 08/06/2012
 *	Class Responsable of all logic related to DML
 **/
public with sharing class cam_Model {
	
	public static final Integer MAX_OBJECTS = 10;
	public static final Integer MAX_OBJECTS_SINGLE = 500;
	public static final Integer MAX_SOQL_QUERY_SIZE = Limits.getLimitQueryRows()*90/100 ;
	public static final Integer MAX_SOSL_OBJECTS = 10;
	public static final Integer MAX_SOQL_RESULTS = Limits.getLimitQueryRows();
	
	 /**
	  * @description
	  *  Retrieve Open/BestAnswers without text filter of a given community (optional filter by Topic Name)
	  * @param source -- cam_DTO type
	  * @return cam_DTO object
	  **/
	public static cam_DTO get_All_Questions(cam_DTO source){
		String community = ENCODE((source.searchOptions).get('communityId'));
		String topicName = ENCODE((source.searchOptions).get('topicName'));
		
		String sortBy = (source.searchOptions).get('sortBy') == source.searchConstants.get('sortBy_POPULARITY')
						? ' ORDER BY VoteScore DESC' : (source.searchOptions).get('sortBy') == source.searchConstants.get('sortBy_RECENT') ? 
						' ORDER BY CreatedDate DESC' : ' ORDER BY LastReplyDate DESC';
		
		Integer offSet = source.response.offset < 1 ? 1 : source.response.offset;
		String limits = ' LIMIT '+(MAX_SOQL_RESULTS);
		
		String query =  ' select Id, BestReplyId, BestReplySelectedById, Community.Name, Title, NumSubscriptions, NumReplies, Body, createdDate, '+
						' createdById, UpVotes, VoteScore, LastReplyDate,CreatorFullPhotoUrl,CreatorName,CreatorSmallPhotoUrl,'+
						' (Select Id from Votes v where Type = \'up\' and CreatedById = \''+Userinfo.getUserId()+'\'),'+
						' (Select Id From Subscriptions where CreatedById = \''+Userinfo.getUserId()+'\' ), '+
						' (Select Id From QuestionReportAbuses where CreatedById = \''+Userinfo.getUserId()+'\' ) '+
						' FROM Question'; 
		query += topicName != '-1' ? ' WITH DATA CATEGORY '+cam_Proxy.CAM_ROOT_GROUP_NAME+' BELOW '+topicName+'__c' : ' WHERE CommunityId =\''+community+'\' ';
		query += sortBy+limits;
		list<Object> results = Database.query(query);
		if ( results.size() > (offSet+MAX_OBJECTS) ){
			 source.response.hasMore = true;
		}else{
			source.response.hasMore = false;
		}
		
		list<cam_DTO.responseElement> responseElements = new list<cam_DTO.responseElement>();
		map<String,cam_DTO.responseElement> bestReplyAssignment = new map<String,cam_DTO.responseElement>();
		
		Integer iterator = 1;
		for ( Object q : results ){
			//we move untill we reach the offset needed
			if ( iterator < offSet ){
				iterator++;
				continue;
			}
			//we break if we reached the maximum response objects
			if ( responseElements.size() == MAX_OBJECTS ) break;				
			
			Question auxQ = (Question) q;
			Datetime d = auxQ.CreatedDate;
			Integer likeIt = auxQ.Votes.size();
			Integer subscriptions = auxQ.Subscriptions.size();
			Integer reports = auxQ.QuestionReportAbuses.size();
			
			String qString = JSON.serialize(q);
			Map<String, Object> qObject = (Map<String, Object>) JSON.deserializeUntyped(qString);
			Long elap = Datetime.now().getTime() - d.getTime();
			qObject.put('CreatedDateElap',String.valueOf( elap ));
			qObject.put('CreatedDate',String.valueOf( d.getTime() ));
			qObject.put('likeIt', ( (likeIt > 0) ? 'true' : 'false' ) );
			qObject.put('following', ( (subscriptions > 0) ? 'true' : 'false' ) );
			qObject.put('flagged', ( (reports > 0) ? 'true' : 'false' ) );
			qObject.put('NumSubscriptions', ( (auxQ.NumSubscriptions > 0) ? (auxQ.NumSubscriptions -1 ) : 0 ) );
			qObject.put('Subscriptions',null);qObject.put('Votes',null);
			//Resolving if it's a customer agent
			ID authorId =  auxQ.CreatedById ;
			qObject.put('isAgent',((cam_Config.supportAgentsIds).contains(authorId)  ? 'true' : 'false'));
			
			Object obj = (Object) qObject;
			cam_DTO.responseElement r = new cam_DTO.responseElement();
			map<String,Object> aux = new map<String,Object>();
			aux.put('Question',obj);
			
			if ( qObject.get('BestReplyId') <> null ){
				bestReplyAssignment.put(String.valueOf(qObject.get('BestReplyId')),r);
			}
			r.element = aux;
			responseElements.add(r);
			iterator++;
		}
		//Best Reply
		list<SObject> replies = [SELECT Body,CreatedById,CreatedDate,DownVotes,Id,QuestionId,UpVotes,VoteTotal,CreatorFullPhotoUrl,CreatorName,CreatorSmallPhotoUrl FROM Reply WHERE Id IN :bestReplyAssignment.keySet()];
		
		for ( SObject reply : replies ){			
			Reply auxR = (Reply) reply;
			Datetime d = auxR.CreatedDate;
			cam_DTO.responseElement elm = bestReplyAssignment.get( String.valueOf(reply.get('Id')) );
			list<SObject> aux = new list<SObject>(); aux.add(reply);
			
			String rString = JSON.serialize(reply);
			Map<String, Object> rObject = (Map<String, Object>) JSON.deserializeUntyped(rString);
			//Resolving if it's a customer agent
			rObject.put('isAgent',((cam_Config.supportAgentsIds).contains( (ID)auxR.CreatedById )  ? 'true' : 'false'));
			Long elap = Datetime.now().getTime() - d.getTime();
			rObject.put('CreatedDateElap',String.valueOf( elap ));
			rObject.put('CreatedDate',String.valueOf(d.getTime()));
			list<Object> lContainer = new list<Object>(); lContainer.add(rObject);
			(elm.elementChilds).put('Replies',lContainer);
		}
		source.response.responseElements = responseElements;
		source.response.status = source.globalConstants.get('STATUS_OK');
		source.response.offset = responseElements.size()+offSet;
				
		return source;
	}

	/**
	  * @description
	  *  Tokenizes search string word0 word1 word2 and builds new string word0 OR word1 Or word2
	  * @param qString -- String type
	  * @return newQString String
	  **/
	private static String process_SearchString(String qString){
		String finalStr = '';
		String glue = ' OR ';
		for(String s0 : qString.split('\\s+')){
			finalStr += glue+s0;
		}
		finalStr = finalStr.replaceFirst(glue,'');
		return finalStr;
	}

	/**
	  * @description
	  *  Retrieve Questions filtered by search string
	  * @param source @type cam_DTO
	  * @return @type object/cam_DTO
	  **/
	public static cam_DTO get_Questions_With_Filter(cam_DTO source){
		try{
			String stringToSearch = (String.escapeSingleQuotes(((source.searchOptions).get('searchInput')))).trim();
			String communityId = (String.escapeSingleQuotes(((source.searchOptions).get('communityId')))).trim();
		
			String soslQuery = 'FIND \''+process_SearchString(stringToSearch)+'*\' IN ALL FIELDS RETURNING '+
				' Question ( Id, BestReplyId, BestReplySelectedById, Community.Name, Title, NumSubscriptions, NumReplies, Body, createdDate, createdById, UpVotes, VoteScore, LastReplyDate,CreatorFullPhotoUrl,CreatorName,CreatorSmallPhotoUrl WHERE CommunityId = \''+communityId+'\') limit '+MAX_SOSL_OBJECTS;
			
			list<list<SObject>> results = search.query(soslQuery);
		
			list<cam_DTO.responseElement> responseElements = new list<cam_DTO.responseElement>();
		
			for ( sObject q : results[0] ){
				cam_DTO.responseElement r = new cam_DTO.responseElement();
				map<String,SObject> aux = new map<String,SObject>();
				aux.put('Question',q);
				r.element = aux;
				r.elementChilds = null;
				responseElements.add(r);
			}
			//Getting knowledge Articles via sosl
			getKnowledgeArticles(source,responseElements,false);
			//Resolving following and likes
			resolveBulkFollowingAndLikeForResponseElements(responseElements);
			source.response.responseElements = responseElements;
			source.response.status = source.globalConstants.get('STATUS_OK');			
		}catch(SearchException e){
			source.response.status = source.globalConstants.get('STATUS_ERROR');
			source.response.responseMsg = cam_Config.errorMsg;//e.getMessage();
		}
		
		return source;
	}
	
	/**
	  * @description
	  *  rebuilds the list received as param by ref adding "like it" and "follow" for current user in Questions
	  * @param responseElements @type list<cam_DTO.responseElement>
	  **/
	private static void resolveBulkFollowingAndLikeForResponseElements(list<cam_DTO.responseElement> responseElements){
		//collect elements Ids
		String questionsIds = '';
		list<cam_DTO.responseElement> elements = new list<cam_DTO.responseElement>();
		for ( Integer i = 0; i < responseElements.size(); i++ ){
			cam_DTO.responseElement elm = responseElements[i];
			object obj = elm.element.get('Question');
			if ( obj == null ){
				//saving this ones (ka) as right now we are not doing anything with it
				elements.add(elm);
				continue;
			}
			Question q = (Question) obj;
			questionsIds += i>0 ? ',\''+q.Id+'\'' : '\''+q.Id+'\'';
		}
		//cleaning the list received by reference
		responseElements.clear();
		//check if we have ids
		if ( questionsIds != '' ){	  
			String query =  ' select Id, BestReplyId, BestReplySelectedById, Community.Name, Title, NumSubscriptions, '+
							' NumReplies, Body, createdDate, createdById, UpVotes, VoteScore, LastReplyDate,CreatorFullPhotoUrl,'+
							' CreatorName,CreatorSmallPhotoUrl,'+
							' (Select Id from Votes v where Type = \'up\' and CreatedById = \''+Userinfo.getUserId()+'\'), '+
							' (Select Id From Subscriptions where CreatedById = \''+Userinfo.getUserId()+'\' ), '+
							' (Select Id From QuestionReportAbuses where CreatedById = \''+Userinfo.getUserId()+'\' ) '+
							'FROM Question where Id IN ('+questionsIds+') ';
			list<Object> results = Database.query(query);
 
			for ( Object q : results ){
				Question auxQ = (Question) q;
				Datetime d = auxQ.CreatedDate;
				Integer likeIt = auxQ.Votes.size();
				Integer subscriptions = auxQ.Subscriptions.size();
				
				String qString = JSON.serialize(q);
				Map<String, Object> qObject = (Map<String, Object>) JSON.deserializeUntyped(qString);
				Long elap = Datetime.now().getTime() - d.getTime();
				qObject.put('CreatedDateElap',String.valueOf( elap ));
				qObject.put('CreatedDate',String.valueOf(d.getTime()));
				qObject.put('likeIt', ( (likeIt > 0) ? 'true' : 'false' ) );
				qObject.put('following', ( (subscriptions > 0) ? 'true' : 'false' ) );
				qObject.put('Subscriptions',null);qObject.put('Votes',null);
				qObject.put('NumSubscriptions',( (auxQ.NumSubscriptions > 0) ? (auxQ.NumSubscriptions -1 ) : 0 ) );
				qObject.put('flagged', ( (auxQ.QuestionReportAbuses.size() > 0) ? 'true' : 'false' ) );
				qObject.put('isAgent',((cam_Config.supportAgentsIds).contains(auxQ.CreatedById)  ? 'true' : 'false'));
				Object obj = (Object) qObject;
				cam_DTO.responseElement r = new cam_DTO.responseElement();
				map<String,Object> aux = new map<String,Object>();
				aux.put('Question',obj);
				r.element = aux;
				responseElements.add(r);
			}
		}
		if ( elements.size() > 0 ){
			resolveKnowledgeArticlesLikes(elements);
			responseElements.addAll(elements);
		}
		
	}
	
	/**
	  * @description
	  *  Retrieve Knowledge Articles
	  * @param source @type cam_DTO type
	  * @param responseElements @type list<cam_DTO.responseElement>
	  * @param soql @type Boolean (true=search soql, false=search sosl)
	  **/
	private static void getKnowledgeArticles(cam_DTO source, list<cam_DTO.responseElement> responseElements, Boolean soql){
		//Dealing with restrictions in unit testing about knowledgeArticles publishStatus
		String publishStatus = Test.isRunningTest() ? 'Draft' : 'Online';
		
		String stringToSearch = (soql == false) ? (String.escapeSingleQuotes(((source.searchOptions).get('searchInput')))).trim() : null ;
		String communityId = (String.escapeSingleQuotes(((source.searchOptions).get('communityId')))).trim();
		String topicName = (String.escapeSingleQuotes(((source.searchOptions).get('topicName')))).trim();
		String soslQuery = ''; String soqlQuery = '';
		Integer offSet = source.response.offSet;
		list<list<Object>> results = new list<list<Object>>();
		//Let's look in Knowledge Articles
		//First we need to relate the community Id with a community API name
		String communityRelationship = (cam_Proxy.communityRelationWithDataCategory).get(communityId);
		String community = '';
		
			//Let's check if is not about to search by topic name instead of community Id
			if ( topicName != null && topicName != '' && topicName != '-1' ){
				community = topicName;
			}else{
				community = communityRelationship;
			}
			if ( community != '' && soql == false){
				soslQuery = 'FIND \''+stringToSearch+'*\' IN ALL FIELDS RETURNING '+
						'KnowledgeArticleVersion (Id, KnowledgeArticleId, Title, CreatedDate, LastPublishedDate, Summary WHERE PublishStatus=\''+publishStatus+'\' AND language =\'en_US\' order by CreatedDate)  WITH DATA CATEGORY '+cam_Proxy.CAM_ROOT_GROUP_NAME+' BELOW '+community+'__c limit '+MAX_OBJECTS;
				results = search.query(soslQuery);
				for ( Object q : results[0] ){
					cam_DTO.responseElement r = new cam_DTO.responseElement();
					map<String,Object> aux = new map<String,Object>();
					aux.put('KnowledgeArticle',q);
					r.element = aux;
					r.elementChilds = null;
					responseElements.add(r);
				}		   
			}else if ( community != '' && soql == true ){
				if ( test.isRunningTest() ) soqlQuery = ' Select Id, KnowledgeArticleId, Title, CreatedDate, LastPublishedDate, Summary from KnowledgeArticleVersion WHERE PublishStatus=\''+publishStatus+'\' AND language =\'en_US\' limit 1 '; 
				else soqlQuery = ' Select Id, KnowledgeArticleId, Title, CreatedDate, LastPublishedDate, Summary from KnowledgeArticleVersion WHERE PublishStatus=\''+publishStatus+'\' AND language =\'en_US\' WITH DATA CATEGORY '+cam_Proxy.CAM_ROOT_GROUP_NAME+' BELOW '+community+'__c order by LastPublishedDate limit '+MAX_SOQL_RESULTS;
				list<Object> soqlResults = Database.query(soqlQuery);
				
				Integer iterator = 1;   
				for ( Integer i=0; i<soqlResults.size();i++ ){
					if ( iterator <= offSet ){
						iterator++;
						continue;
					}
					if ( responseElements.size() > MAX_OBJECTS ) break;
					Object q = soqlResults[i];
					cam_DTO.responseElement r = new cam_DTO.responseElement();
					map<String,Object> aux = new map<String,Object>();
					aux.put('KnowledgeArticle',q);
					r.element = aux;
					r.elementChilds = null;
					responseElements.add(r);
				}
				resolveKnowledgeArticlesLikes(responseElements);
				if ( soqlResults.size() > (offSet+MAX_OBJECTS) ){
						source.response.hasMore = true;
				}else{
						source.response.hasMore = false;
				}
				source.response.offSet = responseElements.size()+offSet;
			}
	}
	
	/**
	  * @description
	  *  Adds number of likes to knowledgeArticleVersion Objects
	  * @param responseElements @type list<cam_DTO.responseElement>
	  **/
	private static void resolveKnowledgeArticlesLikes(list<cam_DTO.responseElement> responseElements){
		map<String,object> articlesMap = new map<String,object>();
		map<String,String> kToKaMap = new map<String,String>();
		for ( cam_DTO.responseElement elm : responseElements ){
			map<String,Object> elmMap = elm.element;
			object obj = elmMap.get('KnowledgeArticle');
			Datetime d = ((KnowledgeArticleVersion) obj).CreatedDate;
			Datetime d2 = ((KnowledgeArticleVersion) obj).LastPublishedDate;
			
			String objString = JSON.serialize(obj);
			Map<String, Object> objMap = (Map<String, Object>) JSON.deserializeUntyped(objString);
			Long elap = Datetime.now().getTime() - d.getTime();
			objMap.put('CreatedDateElap',String.valueOf( elap ));
			objMap.put('CreatedDate',d.getTime());
			objMap.put('LastPublishedDate',d2 == null ? d.getTime() : d2.getTime());
			objMap.put('Likes','0');
			objMap.put('LikeIt','false');
			
			articlesMap.put( String.valueOf(objMap.get('Id')) , objMap );
			kToKaMap.put( String.valueOf(objMap.get('KnowledgeArticleId')), String.valueOf(objMap.get('Id')) );
		}
		KnowledgeArticle[] kAList = [Select k.Id, (SELECT Id FROM Votes where Type='5') from KnowledgeArticle k where Id IN :kToKaMap.keySet() limit :MAX_SOQL_QUERY_SIZE];
		KnowledgeArticle[] kAListCurrentUser = [Select k.Id, (SELECT Id FROM Votes where CreatedById = :userInfo.getUserId()) from KnowledgeArticle k where Id IN :kToKaMap.keySet() limit :MAX_SOQL_QUERY_SIZE];
		
		for ( Integer i=0; i<kAList.size(); i ++ ){
			KnowledgeArticle elm = KAList[i];
			Map<String,Object> kA = (Map<String,Object>) articlesMap.get( kToKaMap.get(elm.Id) );
			kA.put('Likes',String.valueOf(elm.Votes.size()));
			//Setting this as false here, it will be overriden in next loop if applies
			kA.put('LikeIt','false');
			(responseElements[i]).element = new map<String,Object>{'KnowledgeArticle'=>kA};
		}
		for ( Integer i=0; i<kAListCurrentUser.size(); i ++ ){
			KnowledgeArticle elm = KAListCurrentUser[i];
			Map<String,Object> kA = (Map<String,Object>) articlesMap.get( kToKaMap.get(elm.Id) );
			String userLikesIt = elm.Votes.size() > 0 ? 'true' : 'false';
			kA.put('LikeIt',userLikesIt);
			(responseElements[i]).element = new map<String,Object>{'KnowledgeArticle'=>kA};
		}		   
	}
	
	/**
	 * @description
	 *	Retrieve Articles filtered by community and topic if required
	 * @param source -- cam_DTO type
	 * @return cam_DTO object
	 **/
	public static cam_DTO get_Questions_Articles(cam_DTO source){
		list<cam_DTO.responseElement> responseElements = new list<cam_DTO.responseElement>();
		
		getKnowledgeArticles(source,responseElements,true);
		source.response.responseElements = responseElements;
		source.response.status = source.globalConstants.get('STATUS_OK');
		return source;
	}
	
	
	/**
	  * @description
	  *  Retrieve current user information
	  * @param fullInfo @type boolean
	  * @param source @type cam_DTO
	  * @param userId @type String
	  * @return cam_DTO object
	  **/
	  public static cam_DTO getUserDetails(Boolean fullInfo, cam_DTO source, String userId, String commId){
		map<String,String> userMap = new map<String,String>();
		//Workaround as it seems we can't query the user table
		User theUser = new User();
		if ( userInfo.getUserId() == userId ){
			theUser.ProfileId = Userinfo.getProfileId();
		}
		
		//checking if it's a guest user
		if ( theUser.ProfileId == cam_Proxy.guestUserProfileId ){
			userMap.put('Id', source.globalConstants.get('NULL_VAL') );
			userMap.put('Name',source.globalConstants.get('NULL_VAL'));
			userMap.put('Photo', source.globalConstants.get('NULL_VAL') );
			
			source.currentUser = userMap;
			return source;
		}
		
		//check permissions on Case Object
		
		if (Schema.sObjectType.Case.isCreateable()) {
			userMap.put('caseEnabled',(source.globalConstants).get('BOOLEAN_TRUE'));
		}else{
			userMap.put('caseEnabled',(source.globalConstants).get('BOOLEAN_FALSE'));}
		
		//Let's try to reach the picture for the current user
		list<Question> lQ = [Select CreatorName,CreatorSmallPhotoUrl from Question where CreatedById = :userId limit 1];
		list<Reply> lR = (lQ.size() == 0) ? [Select CreatorName,CreatorSmallPhotoUrl from Reply where CreatedById = :userId limit 1] : new list<Reply>();
		list<Case> lC = (lQ.size() == 0 && lR.size() == 0) ? [Select CreatorName,CreatorSmallPhotoUrl from Case where CreatedById = :userId limit 1] : new list<Case>();
		list<CaseComment> lCC = (lQ.size() == 0 && lR.size() == 0 && lC.size() == 0) ? [Select CreatorName,CreatorSmallPhotoUrl from CaseComment where CreatedById = :userId limit 1] : new list<CaseComment>();
		
		String photoUrl = lQ.size() > 0 ? lQ[0].CreatorSmallPhotoUrl : lR.size() > 0 ? lR[0].CreatorSmallPhotoUrl : lC.size() > 0 ? lC[0].CreatorSmallPhotoUrl : lCC.size() > 0 ? lCC[0].CreatorSmallPhotoUrl : null;
		String creatorName = lQ.size() > 0 ? lQ[0].CreatorName : lR.size() > 0 ? lR[0].CreatorName : lC.size() > 0 ? lC[0].CreatorName : lCC.size() > 0 ? lCC[0].CreatorName : null; 
		
		userMap.put('Photo',photoUrl);
		userMap.put('Id',userId);
		userMap.put('Name',creatorName);
		
		source.currentUser = userMap;
		
		if ( !fullInfo ) return source;
		
		map<String,String> m = cam_Model.resolveReputationDetails(userId, commId);
		userMap.putAll(m);
		
		return source;  
	  }


	  /*
	* @description
	*   returns User reputation details
	* @param userId @type Id
	* @param commId @type Id
	* @return cam_DTO
	*/
	  public static cam_DTO getReputationDetails(cam_DTO source, String userId, String commId){
		userId = (String.escapeSingleQuotes(userId).trim());
		commId = (String.escapeSingleQuotes(commId).trim());
		map<String,String> m = cam_Model.resolveReputationDetails(userId, commId);
		source.currentUser = m;
		return source;
	  }


	  /**
	  * @description
	  *  Build a map containing reputation details 
	  * @param source -- cam_DTO type
	  * @return cam_DTO object
	  **/
	  private static map<String,String> resolveReputationDetails(String userId, String commId){
		
		map<String,String> userMap = new map<String,String>();

		String sql =	' SELECT Id,BestAnswerReceivedCount,QuestionUpVotesReceivedCount, '+
						' QuestionsCount,QuestionSubscrReceivedCount,BestAnswerSelectedCount,'+
						' RepliesCount,UserId '+
						' FROM ChatterAnswersActivity where UserId = \''+ENCODE(userId)+'\'';
		list<SObject> results = Database.query(sql);
		ChatterAnswersActivity uActivity = results.size() > 0 ? (ChatterAnswersActivity) results[0] : null;
		
		Integer uValue = 0;
		if ( uActivity != null ){
			userMap.put('Questions',String.valueOf(uActivity.QuestionsCount));
			userMap.put('Answers',String.valueOf(uActivity.RepliesCount));
			userMap.put('BestAnswers',String.valueOf(uActivity.BestAnswerReceivedCount));
			uValue = (Integer.valueOf(uActivity.BestAnswerReceivedCount) * 25 );
			uValue = uValue + (Integer.valueOf(uActivity.QuestionUpVotesReceivedCount) * 5 );
			uValue = uValue + (Integer.valueOf(uActivity.BestAnswerSelectedCount) * 10 );

			/* logic to resolve user badge
				- BestAnswerReceivedCount => 25 points for each
				- QuestionUpVotesReceivedCount => 5 points for each
				- BestAnswerSelectedCount => 10 points for each
			*/
			list<ChatterAnswersReputationLevel> carl = new list<ChatterAnswersReputationLevel>();
			if (commId != '-1'){
				carl = [	SELECT CreatedById,CreatedDate,Id,IsDeleted,Name,SystemModstamp,Value 
							FROM ChatterAnswersReputationLevel
							WHERE CommunityId =:commId AND IsDeleted = false AND
							value <=:uValue
							order BY value desc 
							limit 1];
			}else{
				carl = [SELECT CommunityId  , value , Name, Id
						FROM ChatterAnswersReputationLevel WHERE   IsDeleted = false	and value <=: uValue
						and CommunityId in: cam_Config.siteCommunities  
						order by value desc ,CommunityId 
						limit 1];
			}
			if (carl.size() > 0 ){
				 userMap.put('LevelName',carl[0].Name);
				 userMap.put('LevelPoints',String.valueOf(uValue));
			}
		}
		return userMap;
	}
	
	/**
	* @description
	*	Retrieve Single Item View
	* @param source @type cam_DTO
	* @return cam_DTO @type object
	**/
	public static cam_DTO getSingleItemView( cam_DTO source ){
		String valueToSearch = (source.singleItemViewOptions).get('idToDisplay');
		if ( valueToSearch.length() != 15 && valueToSearch.length() != 18 ) return source;
		String valueToSearchPrefix = valueToSearch.subString(0,3);
		
		//lets check if its a private question, public question or Article
		
		if ( Schema.sObjectType.Question.getKeyPrefix() == valueToSearchPrefix ) return getSingleItemViewPublic(source);
		else if ( Schema.sObjectType.Case.getKeyPrefix() == valueToSearchPrefix ) return getSingleItemViewPrivate(source);
		else return getSingleItemViewArticle(source);
		
		return source;
	}
	
	/**
	* @description
	*	Retrieve Single Item View for an article
	* @param source -- cam_DTO type
	* @return cam_DTO object
	**/
	private static cam_DTO getSingleItemViewArticle(cam_DTO source){
		String valueToSearch = ENCODE((source.singleItemViewOptions).get('idToDisplay'));
		String valueToSearchPrefix = valueToSearch.subString(0,3);
		
		Map<String, SObjectField> objFields = null;
		String selectFrom = ' FROM ';
		
		Schema.DescribeSObjectResult fromQuery = resolveObjectNameAndFields(valueToSearch);
		
		if ( fromQuery == null ){
			source.response.status = source.globalConstants.get('STATUS_ERROR');
			source.response.responseMsg = 'Invalid Knowledge Article Id';
			return source;
		}
		
		objFields = fromQuery.fields.getMap();
		selectFrom += fromQuery.getLocalName();
		
		//Let's build the query
		String query = 'Select ';
		
		list<String> allFields = new list<String>(objFields.keySet());
		
		for ( Integer i=0; i<allFields.size(); i++ ){
			String val = allFields[i];
			Boolean isCustom = (val.length() > 4) && (( val.subString(val.length()-3) ) == '__c');
			//if ( val != 'Summary' && val != 'Title' && val != 'LastPublishedDate' && !isCustom && val != 'KnowledgeArticleId'  ) continue;
			query +=  query.length() > 7 ? ' ,' : '';
			query += val;
		}
		
		query += selectFrom+' WHERE Id =  \''+valueToSearch+'\'';
		
		list<Object> results = Database.query(query);
		Object resultsHardCoded = cam_Config.sortKnowledgeArticleFields(results,fromQuery.getLocalName());

		
		//Article Likes
		map<String,String> elm = (map<String,String>)resultsHardCoded;
		AggregateResult[] votes = [SELECT Count(Type) daVotes FROM Vote WHERE ParentId = :elm.get('KnowledgeArticleId') AND Type = '5'];
		elm.put('Likes',String.valueOf(votes[0].get('daVotes')));
		//Knowing if current user likes this article
		list<Vote> cUserVote = [Select Id FROM Vote WHERE ParentId = :elm.get('KnowledgeArticleId') and CreatedById = :userInfo.getUserId()];
		if ( cUserVote.size() > 0 ){
			elm.put('LikeIt','true');
		}else{
			elm.put('LikeIt','false');
		}
		
		//elapsed
		Long d = Long.valueOf(elm.get('LastPublishedDate'));
		Long elap = Datetime.now().getTime() - d;
		elm.put('CreatedDateElap',String.valueOf( elap ));
		
		
		list<cam_DTO.responseElement> responseElements = new list<cam_DTO.responseElement>();
		cam_DTO.responseElement r = new cam_DTO.responseElement();
		r.results = (object) resultsHardCoded;
		r.element = null;
		r.elementChilds = null;
		responseElements.add(r);
		source.response.responseElements = responseElements;
		source.response.status = source.globalConstants.get('STATUS_OK');
		return source;
	}
	
	/**
	* @description
	*	Resolve the Object Name based on an Object Id
	* @param elmId @type String
	* @return @type String
	**/
	private static Schema.DescribeSObjectResult resolveObjectNameAndFields(String elmId){
		// This will be set to the object description metadata if found
		Schema.DescribeSObjectResult object_desc = null;
		
		// Search every object in the getGlobalDescribe() map to check key prefixes
		for( Schema.SObjectType t : Schema.getGlobalDescribe().values() ){
			Schema.DescribeSObjectResult descs = t.getDescribe();
			// If the Id starts with this objects prefix, then we know the type
			if( descs.getKeyPrefix() != null && elmId.startsWith( descs.getKeyPrefix() )){
				object_desc = descs;
				break;
			}
		}
		return object_desc;
	}
	
	/**
	* @description
	*	Retrieve Single Item View (public)
	* @param source -- cam_DTO type
	* @return cam_DTO object
	**/
	private static cam_DTO getSingleItemViewPublic(cam_DTO source){
		String valueToSearch = ENCODE((source.singleItemViewOptions).get('idToDisplay'));
		boolean lookInPrivate = false;
		
		String soql =   ' select (Select DataCategoryName From DataCategorySelections), '+
						' Id, BestReplyId, BestReplySelectedById, Community.Name, Title,'+
						' NumSubscriptions, NumReplies, Body, createdDate, createdById,'+
						' UpVotes, VoteScore, LastReplyDate,CreatorFullPhotoUrl,CreatorName,'+
						' CreatorSmallPhotoUrl '+
						'FROM Question WHERE Id = \''+valueToSearch+'\'';
		list<Object> q = Database.query(soql);
		
		//Getting public replies
		soql =  ' SELECT Body,CreatedDate,Id,QuestionId,UpVotes,VoteTotal,createdById, CreatorFullPhotoUrl,'+
				' CreatorName,CreatorSmallPhotoUrl,'+
				' (Select Id from Votes v where Type = \'up\' and CreatedById = \''+Userinfo.getUserId()+'\'), '+
				' (Select Id From ReplyReportAbuses where CreatedById = \''+Userinfo.getUserId()+'\' ) '+
				' FROM Reply WHERE QuestionId = \''+valueToSearch+'\' order by CreatedDate ASC limit '+MAX_OBJECTS_SINGLE;
		list<Object> replies = Database.query(soql);
		
		//checking if applies to check for private messages
		Question aux = (Question) q[0];
		if ( aux.createdById == UserInfo.getUserId() ) lookInPrivate = true;
		
		list<Object> caseComments = new list<Object>();
		
		if ( lookInPrivate && ((source.singleItemViewOptions).get('getPrivateToo')) == ((source.globalConstants).get('BOOLEAN_TRUE')) ){
			
			//getting case to be able to search by case comments for private messages
			list<Case> c = [Select Id from Case Where QuestionId = :aux.Id];
			if ( c.size() > 0 ){
				//getting private messages
				soql = 'SELECT Id, CreatedDate, CommentBody, ParentId, CreatorFullPhotoUrl, CreatorName, CreatorSmallPhotoUrl from CaseComment WHERE ParentId =\''+c[0].Id+'\' order by CreatedDate ASC limit '+MAX_OBJECTS_SINGLE;
				caseComments = Database.query(soql);
			}
		}
		
		String qString = JSON.serialize(aux);
		Map<String, Object> qObject = (Map<String, Object>) JSON.deserializeUntyped(qString);
		
		//Getting extra information about the question (if current user is following and/or likes it and if is a customer agent)
		resolveSimpleFollowingAndLikesForQuestion(qObject);
		
		Datetime d = aux.CreatedDate;
		Long elap = Datetime.now().getTime() - d.getTime();
		qObject.put('CreatedDateElap',String.valueOf( elap ));
		qObject.put('CreatedDate',String.valueOf(d.getTime()));
		qObject.put('NumSubscriptions',( (aux.NumSubscriptions > 0) ? (aux.NumSubscriptions -1 ) : 0 ) );
		
		//Resolving if it's a customer agent
		qObject.put('isAgent',((cam_Config.supportAgentsIds).contains( (ID)aux.CreatedById )  ? 'true' : 'false'));
		//Getting Topic API Name
		qObject.put('topicApiName',(aux.DataCategorySelections).DataCategoryName);
		qObject.put('DataCategorySelections',null);
		list<cam_DTO.responseElement> responseElements = new list<cam_DTO.responseElement>();
		cam_DTO.responseElement response = new cam_DTO.responseElement();
		(response.element).put('Question',qObject);
		
		list<Object> allRepliesNoCases = new list<Object>();
		//Getting extra information about the reply (if current user is following and/or likes it)
		resolveBulkLikesAndIsAgentForReplies(replies,allRepliesNoCases);
		
		list<Object> container = new list<Object>();
		container.add( ((Object)allRepliesNoCases) );
		container.add( ((Object)caseComments) );
		
		(response.elementChilds).put('Replies',container);
		responseElements.add(response);
		
		source.response.responseElements = responseElements;
		source.response.status = source.globalConstants.get('STATUS_OK');
		
		return source;
	}
	
	/**
	* @description
	*	Retrieve Single Item View (private)
	* @param source -- cam_DTO type
	* @return cam_DTO object
	**/
	private static cam_DTO getSingleItemViewPrivate(cam_DTO source){
		String valueToSearch = ENCODE((source.singleItemViewOptions).get('idToDisplay'));
		
		String soql = 'select Id, Description, Subject, createdDate, createdById,CreatorFullPhotoUrl,CreatorName,CreatorSmallPhotoUrl FROM Case WHERE Id = \''+valueToSearch+'\'';
		list<SObject> cases = Database.query(soql);
		Case c = (Case) cases[0];
 
		Datetime d = c.CreatedDate;
		String qString = JSON.serialize(c);
		Map<String, Object> qObject = (Map<String, Object>) JSON.deserializeUntyped(qString);
		//Resolving if it's a customer agent
		qObject.put('isAgent',((cam_Config.supportAgentsIds).contains( (ID)c.CreatedById )  ? 'true' : 'false'));
		Long elap = Datetime.now().getTime() - d.getTime();
		qObject.put('CreatedDateElap',String.valueOf( elap ));
		qObject.put('CreatedDate', String.valueOf(d.getTime()));
		
		list<SObject> caseComments = new list<SObject>();
		
		//getting private messages
		soql = 'SELECT Id, CreatedDate, CommentBody, createdById,CreatorFullPhotoUrl,CreatorName,CreatorSmallPhotoUrl from CaseComment WHERE ParentId =\''+c.Id+'\' order by CreatedDate'; 
		caseComments = Database.query(soql);
		
		list<cam_DTO.responseElement> responseElements = new list<cam_DTO.responseElement>();
		cam_DTO.responseElement response = new cam_DTO.responseElement();
		(response.element).put('Question',qObject);//cases[0]);
		
		list<SObject> allReplies = new list<SObject>();
		allReplies.addAll(caseComments);
		
		(response.elementChilds).put('Replies',allReplies);
		responseElements.add(response);
		
		source.response.responseElements = responseElements;
		source.response.status = source.globalConstants.get('STATUS_OK');
		
		return source;
	  }
	  
	  /*
	* @description
	*   Creates a new Question (Public)
	* @param communityId @type String
	* @param title @type String
	* @param body @type String
	* @param topic @type String
	* @return map<String,String>
	*/
	  public static map<String,String> postPublicQuestion( String communityId, String title, String body, String topic ){
		map<String,String> ret = new map<String,String>();
		cam_DTO aux = new cam_DTO();
		Question q = null; QuestionDataCategorySelection qDS = null; QuestionSubscription qS = null;
		
		try{
			body = sanitizePostBody(body,true);
			//check create permissions
			cam_SecurityHandler.canCreate( 
					new Schema.SObjectType[] {Question.sObjectType,
												QuestionDataCategorySelection.sObjectType,
												QuestionSubscription.sObjectType});

			q = new Question( CommunityId = communityId , Title = title , Origin = 'Chatter Answers' , Body = body); insert q;
			qDS = new QuestionDataCategorySelection( DataCategoryGroupName = cam_Proxy.CAM_ROOT_GROUP_NAME_SIMPLE , DataCategoryName = topic , ParentId = q.Id ); insert qDS;
			qS = new QuestionSubscription( SubscriberId = Userinfo.getUserId() , QuestionId = q.Id ); insert qS;
			
			
		}catch(cam_SecurityHandler.SecurityException sEx){
			ret.put('responseMsg',sEx.getMessage() ); 
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		
		}catch(Exception e){
			ret.put('responseMsg',cam_Config.errorMsg );//;//e.getMessage()
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		}
		
		ret.put('responseMsg','');
		ret.put('status', (aux.globalConstants).get('STATUS_OK') );
		ret.put('QuestionId', q.Id);
		return ret;
	  }
	  
	  /*
	* @description
	*   Creates a new Question (Private)
	* @param communityId @type String
	* @param title @type String
	* @param body @type String
	* @return map<String,String>
	*/
	public static map<String,String> postPrivateQuestion( String communityId, String title, String body ){
		map<String,String> ret = new map<String,String>();
		cam_DTO aux = new cam_DTO();
		Case c = null;
		
		try{
			
			//check create permissions
			cam_SecurityHandler.canCreate( 
					new Schema.SObjectType[] {Case.sObjectType});
			
			body = sanitizePostBody(body,false);
			c = new Case(CommunityId = communityId,
						 Origin = 'Chatter Answers',
						 Subject = title,
						 Description = body);
			insert c;
		}catch(cam_SecurityHandler.SecurityException sEx){
			ret.put('responseMsg',sEx.getMessage() ); 
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		
		}catch(Exception e){
			ret.put('responseMsg',cam_Config.errorMsg);//e.getMessage() 
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		}
		
		ret.put('responseMsg','');
		ret.put('status', (aux.globalConstants).get('STATUS_OK') );
		ret.put('CaseId', c.Id);
		return ret;
	}

	
	/*
	* @description
	* Creates a new Reply/Answer (Public/Private)
	* @param parentId @type String
	* @param body @type String
	* @return map<String,String>
	*/
	public static map<String,String> postReply(String parent, String body){
		map<String,String> ret = new map<String,String>();
		//first check if the parent is a question or a case
		list<Question> lQ = [Select Id from Question where Id = :parent];
		list<Case> lC = lQ.size() < 1 ? [Select Id from Case where Id = :parent] : null;
		Reply r = null; CaseComment c = null;
		cam_DTO aux = new cam_DTO();
		
		try{

			if ( lQ.size() > 0 ){
			//check create permissions
			cam_SecurityHandler.canCreate( 
					new Schema.SObjectType[] {Reply.sObjectType});
				body = sanitizeReplyBody(body, true);
				r = new Reply ( QuestionId = parent, Body = body );
				insert r;
			}else if ( lC.size() > 0 ){
				//check create permissions
				cam_SecurityHandler.canCreate( 
					new Schema.SObjectType[] {CaseComment.sObjectType});	
				body = sanitizeReplyBody(body, false);
				c = new CaseComment( ParentId = parent , CommentBody =  body );
				insert c;
			}else{
				ret.put('responseMsg','Unknown' );
				ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
				return ret;
			}
		}catch(cam_SecurityHandler.SecurityException sEx){
			ret.put('responseMsg',sEx.getMessage() ); 
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		
		}catch(Exception e){
			ret.put('responseMsg',cam_Config.errorMsg);//e.getMessage()
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		}
		
		ret.put('responseMsg','');
		ret.put('status', (aux.globalConstants).get('STATUS_OK') );
		if ( r != null ) ret.put('ReplyId', r.Id);
		if ( c != null ) ret.put('CaseCommentId', c.Id);
		return ret;
	}
	
	/*
	* @description
	*   Follow/Unfollow a question
	* @param questionId @type String
	* @param follow @type boolean
	* @return map<String,String>
	*/
	public static map<String,String> follow(String questionId, Boolean follow){
		map<String,String> ret = new map<String,String>();
		cam_DTO aux = new cam_DTO();
		questionId = (String.escapeSingleQuotes(questionId).trim());
		
		list<QuestionSubscription> subscriptionList = [Select QuestionId,SubscriberId 
															from QuestionSubscription
															where SubscriberId = :Userinfo.getUserId()
															and QuestionId = :questionId limit 1 ];
		
		if ( follow == true ){
			//Check if we already are following this question
			if ( subscriptionList.size() > 0 ){
				ret.put('responseMsg','User is already following this question' );
				ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			}else{
				//check create permissions
				if ( cam_SecurityHandler.isCreateable(QuestionSubscription.sObjectType) ) {
					QuestionSubscription qS = new QuestionSubscription( SubscriberId = Userinfo.getUserId() , QuestionId = questionId );
					insert qS;
					ret.put('responseMsg','');
					ret.put('status', (aux.globalConstants).get('STATUS_OK') );
				}else{
					ret.put('responseMsg','Objects not accesible' );
					ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
				}
				
				return ret;
			}
		}else{
			//Lets try to delete the subscription (if exists)
			if ( subscriptionList.size() == 1 ){
				//check accessibility permissions
				if ( cam_SecurityHandler.isAccessible(Question.sObjectType)  &&
					cam_SecurityHandler.isDeletable(QuestionSubscription.sObjectType) ) {
				
					//Lets check if we are not trying to unfollow something that we are the owner
					Question q = [Select CreatedById from Question where Id = :((subscriptionList[0]).QuestionId)];
					if ( q.CreatedById == Userinfo.getUserId() ){
						ret.put('responseMsg','Can\'t unfollow a question that you own' );
						ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
						return ret;
					}
					delete subscriptionList;
					ret.put('responseMsg','');
					ret.put('status', (aux.globalConstants).get('STATUS_OK') );
					return ret;
				
				}else{
					ret.put('responseMsg','Objects not accesible' );
					ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
					return ret;
				}
			}else{
				ret.put('responseMsg','');
				ret.put('status', (aux.globalConstants).get('STATUS_OK') );
			}
		}
		return ret;
	  }
	  
	/*
	 * @description
	 *  Select/Unselect a best answer for a given question/answer
	 * @param questionId @type String
	 * @param answerId @type String
	 * @return map<String,String>
	 */
	public static map<String,String> bestAnswer(String questionId, String answerId){
		questionId = (String.escapeSingleQuotes(questionId).trim());
		answerId = (String.escapeSingleQuotes(answerId).trim());
		cam_DTO aux = new cam_DTO();
		map<String,String> ret = new map<String,String>();
		
		
		//Firstly, let's check the owner of the given question
		list<Question> questions = [Select Id from Question where CreatedById = :Userinfo.getUserId() and Id = :questionId limit 1];
		if ( questions.size() == 0 ){
			ret.put('responseMsg','Can\'t perform this action, possible cause: current user must be the owner of given question or given question id is invalid' );
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		}
		
		//Let's check if answer id equals "-1" which it means we have to take the bestAnswer for given question away
		
		if ( (aux.globalConstants).get('NULL_VAL') == answerId ){
			Answers.setBestReply(questionId,null);
			/*Question q = [Select BestReplyId, BestReplySelectedById from Question where Id = :questionId];
			q.BestReplyId = null;
			upsert q;*/
			ret.put('responseMsg','');
			ret.put('status', (aux.globalConstants).get('STATUS_OK') );
			return ret;
		}
		
		//Let's check if the answer belongs to the question
		list<Reply> replies = [Select Id from Reply where QuestionId = :questionId and Id = :answerId limit 1];
		if ( replies.size() == 0 ){
			ret.put('responseMsg','Given Answer is not part of given Question' );
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		}
		
		Answers.setBestReply(questionId,answerId);
		/*
		Question q = [Select BestReplyId, BestReplySelectedById from Question where Id = :questionId];
		q.BestReplyId = answerId; 
		upsert q;*/
		ret.put('responseMsg','');
		ret.put('status', (aux.globalConstants).get('STATUS_OK') );
		return ret;
	}
	
	/*
	 * @description
	 *  Add a like to a question or an answer
	 * @param questionId @type String
	 * @return map<String,String>
	 */
	public static map<String,String> voteLike(String elementId){
		map<String,String> ret = new map<String,String>();
		cam_DTO aux = new cam_DTO();
		elementId = (String.escapeSingleQuotes(elementId).trim());
		
		//check create permissions
		if ( !cam_SecurityHandler.isCreateable( 
				new Schema.SObjectType[] {Vote.sObjectType}) ) {
			ret.put('responseMsg',cam_SecurityHandler.formatReplace(cam_SecurityHandler.ERROR_OBJECT_NOT_ACCESSIBLE,  new List<String> {String.valueOf(Vote.sObjectType)}) );
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		}
		
		
		//Let's check if user already have a vote for the parentId
		list<Vote> voteList = [Select Id From Vote where ParentId = :elementId AND CreatedById = :Userinfo.getUserId() limit 1]; 
		if ( voteList.size() > 0 ){
			ret.put('responseMsg','User already voted this question/answer' );
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		}
		
		//Let's check if we are not trying to vote on something that we own
		list<Question> qL = [Select Id from Question where Id = :elementId and CreatedById = :Userinfo.getUserId() limit 1]; 
		list<Reply> rL = (qL.size() == 0) ? [Select Id from Reply where Id = :elementId and CreatedById = :UserInfo.getUserId() limit 1] : new list<Reply>();
		
		if ( qL.size() > 0 || rL.size() > 0 ){
			ret.put('responseMsg','Can\'t vote in your own question/answer' );
			ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
			return ret;
		}
		
		//Let's figure out if its a vote for a knowledge article / question / reply
		String elementPrefix = elementId.subString(0,2)+'#';
		boolean isKAV = Schema.sObjectType.KnowledgeArticleVersion.getKeyPrefix() == elementPrefix;
		
		Vote daVote = null;
		if ( isKAV ){
			KnowledgeArticleVersion kav = [Select Id, KnowledgeArticleId from KnowledgeArticleVersion where Id = :elementId];
			daVote = new Vote( ParentId = kav.KnowledgeArticleId, Type = '5' );
			list<Vote> lVote = [SELECT Id FROM Vote where ParentId = :kav.KnowledgeArticleId and CreatedById = :UserInfo.getUserId()];
			if ( lVote.size() == 0 ) insert daVote;
			
		}else{
			daVote = new Vote( ParentId = elementId, Type = 'Up' );
			insert daVote;
		}
		
		
		ret.put('responseMsg','');
		ret.put('status', (aux.globalConstants).get('STATUS_OK') );
		return ret;
	}
	
	/*
	 * @description
	 *  Add to a map that represents a Question object relevant information (if current user likes it and/or is following it)
	 * @param element @type map<String,Object>
	 * @return void
	 */
	private static void resolveSimpleFollowingAndLikesForQuestion(map<String,Object> element){	
		String elementId = String.valueOf(element.get('Id'));
		//Let's check if user have a vote for the parentId
		list<Vote> voteList = [Select Id From Vote where ParentId = :elementId AND CreatedById = :Userinfo.getUserId() AND Type = 'Up' limit 1];
		//Let's check if user is following the parentId
		list<QuestionSubscription> sList = [ Select Id from QuestionSubscription where SubscriberId = :Userinfo.getUserId() AND QuestionId = :elementId limit 1];
		//Let's check if user has a report  for the parentId
		list<QuestionReportAbuse> rList = [ Select Id from QuestionReportAbuse where CreatedById = :Userinfo.getUserId() AND QuestionId = :elementId limit 1];
		 
		element.put('likeIt', ( (voteList.size() > 0) ? 'true' : 'false' ) );
		element.put('following', ( (sList.size() > 0) ? 'true' : 'false' ) );
		element.put('flagged', ( (rList.size() > 0) ? 'true' : 'false' ) );
	}
	
	/*
	 * @description
	 *  Add to a map that represents a Reply object relevant information (if current user likes it )
	 * @param elements @type list<Object>
	 * @return void
	 */
	private static void resolveBulkLikesAndIsAgentForReplies(list<Object> elements, list<Object> saveInto){
		for ( Object elm : elements ){
			Reply repAux = (Reply) elm; 
			Datetime d = repAux.CreatedDate;
			String rString = JSON.serialize(elm);
			Map<String, Object> rObject = (Map<String, Object>) JSON.deserializeUntyped(rString);
			//check if user has a vote for this object
			String id = String.valueOf(rObject.get('Id'));
			String voted = repAux.votes.size() > 0 ? 'true' : 'false';
			rObject.put('likeIt', voted );
			Long elap = Datetime.now().getTime() - d.getTime();
			rObject.put('CreatedDateElap',String.valueOf( elap ));
			rObject.put('CreatedDate', String.valueOf(d.getTime()));
			//Resolving if it's a customer agent
			rObject.put('isAgent',((cam_Config.supportAgentsIds).contains( (ID)repAux.CreatedById )  ? 'true' : 'false'));
			//ReplyReportAbuses
			String reported = repAux.ReplyReportAbuses.size() > 0 ? 'true' : 'false';
			rObject.put('flagged', reported );
			
			saveInto.add(rObject);
		}
	}  
	
	/*
	 * @description
	 *  Handles the my Feed request
	 * @param source @type cam_DTO
	 * @return  @type cam_DTO
	 */
	 public static cam_DTO handleMyFeed(cam_DTO source){
		String community		= ENCODE((source.myFeedOptions).get('communityId'));
		String viewCommunity	= ENCODE((source.myFeedOptions).get('viewCommunityId'));
		String topicName = ENCODE((source.myFeedOptions).get('topicApiName'));
		String authorId =  ENCODE((source.myFeedOptions).get('authorId'));
		String questionOffset = ((source.myFeedOptions).get('questionOffset')) == '-1' ? '0' : ((source.myFeedOptions).get('questionOffset'));
		String caseOffset = ((source.myFeedOptions).get('caseOffset')) == '-1' ? '0' : ((source.myFeedOptions).get('caseOffset'));
		String listOfWhatUserIsFollowing = '';
				
		//Determine author Id
		String uId = Userinfo.getUserId();
		if (authorId != null && authorId != '') uId = authorId;
		
		//Getting what user is following
		list<QuestionSubscription> whatIFollow = [Select QuestionId, SubscriberId from QuestionSubscription where SubscriberId = :uId limit :MAX_SOQL_QUERY_SIZE];
		for ( Integer i=0; i<whatIFollow.size(); i++ ){
			QuestionSubscription elm = whatIFollow[i];
			listOfWhatUserIsFollowing += (i != 0) ? ',\''+elm.QuestionId+'\'' : '\''+elm.QuestionId+'\'';	   
		}

		//Getting Questions
		String query =  ' select Id, BestReplyId, BestReplySelectedById, Community.Name, Title, NumSubscriptions, NumReplies, '+
						' Body, createdDate, createdById, UpVotes, VoteScore, LastReplyDate,CreatorFullPhotoUrl,CreatorName,CreatorSmallPhotoUrl ,'+
						' (Select Id from Votes v where Type = \'up\' and CreatedById = \''+Userinfo.getUserId()+'\') , '+
						' (Select Id From Subscriptions where CreatedById = \''+Userinfo.getUserId()+'\' ),'+
						' (Select Id From QuestionReportAbuses where CreatedById = \''+Userinfo.getUserId()+'\' ) '+
						' FROM Question '; 
		query += listOfWhatUserIsFollowing != '' ? ' where Id IN ('+listOfWhatUserIsFollowing+') ' : 'where CreatedById = \''+uId+'\''; 
		//query += topicName != '-1' ? ' WITH DATA CATEGORY '+cam_Proxy.CAM_ROOT_GROUP_NAME+' BELOW '+topicName+'__c' : ' AND CommunityId =\''+community+'\' ';
		if (viewCommunity != '-1') 
			query += ' AND CommunityId =\''+viewCommunity+'\' ';
		query += ' order by CreatedDate DESC limit '+MAX_SOQL_RESULTS/2; 

		
		list<Object> questionResults = Database.query(query);
		//Getting Private Conversations
		list<Object> caseResults = new list<Object>();
		//if ( topicName == '-1' ){
			query = 'select Id, Description, Subject, createdDate, createdById,CreatorFullPhotoUrl,CreatorName,CreatorSmallPhotoUrl FROM Case WHERE createdById = \''+uId+'\' AND QuestionId = null';
			if (viewCommunity != '-1') 
				query += ' AND CommunityId =\''+viewCommunity+'\'';
			query += ' order by CreatedDate DESC limit '+MAX_SOQL_RESULTS/2; 
			caseResults = Database.query(query);
		//}
		
		Boolean reachedTop = false;
		list<Object> mergedElements = new list<Object>();
		Integer qIterator = 0;
		Integer cIterator = 0;
		
		while ( !reachedTop ){
			if ( mergedElements.size() == MAX_OBJECTS ){
				 reachedTop = true;
			}else{
				Question q = (Integer.valueOf(questionOffset)+qIterator) < questionResults.size() ? (Question) questionResults[Integer.valueOf(questionOffset)+qIterator] : null; 
				Case c = (Integer.valueOf(caseOffset)+cIterator) < caseResults.size() ? (Case) caseResults[Integer.valueOf(caseOffset)+cIterator] : null;
				
				
				if ( q == null && c == null ){
					 reachedTop = true;
				}else{
					Object tmpQ,tmpC;
					if ( q!= null ){
						/* to handle elapsed time from server side*/
						Datetime d = q.CreatedDate;
						String qString = JSON.serialize(q);
						Map<String, Object> cObject = (Map<String, Object>) JSON.deserializeUntyped(qString);
						Long elap = Datetime.now().getTime() - d.getTime();
						cObject.put('CreatedDateElap',String.valueOf( elap ));
						cObject.put('CreatedDate',String.valueOf( d.getTime() ));
						//ReplyReportAbuses
						cObject.put('flagged', q.QuestionReportAbuses.size() > 0 ? 'true' : 'false' );
						cObject.put('NumSubscriptions', ( (q.NumSubscriptions > 0) ? (q.NumSubscriptions -1 ) : 0 ) );
						tmpQ = (Object) cObject;
					}
					if (c!= null){
						/* to handle elapsed time from server side*/
						Datetime d = c.CreatedDate;
						String qString = JSON.serialize(c);
						Map<String, Object> cObject = (Map<String, Object>) JSON.deserializeUntyped(qString);
						Long elap = Datetime.now().getTime() - d.getTime();
						cObject.put('CreatedDateElap',String.valueOf( elap ));
						cObject.put('CreatedDate',String.valueOf( d.getTime() ));
						
						tmpC = (Object) cObject;
					
					}
					
					if ( q!= null && c!= null && (q.CreatedDate).getTime() >= (c.CreatedDate).getTime() ){
							mergedElements.add( tmpQ );
							qIterator++;
					}else if ( q!= null && c!= null && (q.CreatedDate).getTime() <= (c.CreatedDate).getTime() ){
							
							mergedElements.add( tmpC );
							cIterator++;
					}
					
					if ( q!= null && c==null ){
						mergedElements.add( tmpQ );
						qIterator++;
					}
					
					if ( c!= null && q==null ){
						mergedElements.add( tmpC );
						cIterator++;
					}
				}
			}
		}
		
		
		list<cam_DTO.responseElement> responseElements = new list<cam_DTO.responseElement>();
		cam_DTO.responseElement r = new cam_DTO.responseElement();
		r.results = (Object) mergedElements;
		r.element = null; r.elementChilds = null;
		responseElements.add(r);
		
		source.response.responseElements = responseElements;
		source.response.status = source.globalConstants.get('STATUS_OK');
		
		Integer questionFinalOffset = Integer.valueOf(questionOffset) + qIterator ;
		Integer caseFinalOffset =  Integer.valueOf(caseOffset)  + cIterator  ;

		//add offset
		(source.myFeedOptions).put( 'questionOffset' ,  String.valueOf(questionFinalOffset));
		(source.myFeedOptions).put( 'caseOffset' ,	  String.valueOf(caseFinalOffset ) );
		//pagination controls
		if ( questionFinalOffset  >= questionResults.size()  &&  caseFinalOffset  >= caseResults.size()) {
			(source.myFeedOptions).put( 'feedReachedTotal' , 'true' );
		}else{
			(source.myFeedOptions).put( 'feedReachedTotal' , 'false' );
		} 
		
		return source;
	 }


	/*
	 * @description
	 *  Add reportAbuse to a question or an answer
	 * @param questionId @type String
	 * @return map<String,String>
	 */
	public static map<String,String> reportAbuse(String elementId){
		map<String,String> ret = new map<String,String>();
		cam_DTO aux = new cam_DTO();
		elementId = (String.escapeSingleQuotes(elementId).trim());
		
		String elementPrefix = elementId.subString(0,3);

		
		if (Schema.sObjectType.Question.getKeyPrefix() == elementPrefix){

			list<QuestionReportAbuse> qReportList = [Select Id From QuestionReportAbuse where QuestionId = :elementId AND CreatedById = :Userinfo.getUserId() limit 1]; 
			if ( qReportList.size() > 0 ){
				ret.put('responseMsg','User already reported this question' );
				ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
				return ret;
			}else{

				//check create permissions
				if ( !cam_SecurityHandler.isCreateable( 
						new Schema.SObjectType[] {QuestionReportAbuse.sObjectType})  ) {
					ret.put('responseMsg',cam_SecurityHandler.formatReplace(cam_SecurityHandler.ERROR_OBJECT_NOT_ACCESSIBLE,  new List<String> {String.valueOf(QuestionReportAbuse.sObjectType)}));
					ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
					return ret;
				}

				//add  report for given question
				QuestionReportAbuse report = new QuestionReportAbuse( QuestionId = elementId, Reason = 'Inappropriate' );
				insert report;
			} 
		}
		
		if (Schema.sObjectType.Reply.getKeyPrefix() == elementPrefix){
			list<ReplyReportAbuse> rReportList = [Select Id From ReplyReportAbuse where ReplyId = :elementId AND CreatedById = :Userinfo.getUserId() limit 1]; 
			if ( rReportList.size() > 0 ){
				ret.put('responseMsg','User already reported this reply' );
				ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
				return ret;
			}else{
				
				//check create permissions
				if (   !cam_SecurityHandler.isCreateable( 
						new Schema.SObjectType[] {ReplyReportAbuse.sObjectType})  ) {
					ret.put('responseMsg',cam_SecurityHandler.formatReplace(cam_SecurityHandler.ERROR_OBJECT_NOT_ACCESSIBLE,  new List<String> {String.valueOf(ReplyReportAbuse.sObjectType)}));
					ret.put('status', (aux.globalConstants).get('STATUS_ERROR') );
					return ret;
				} 
				
				//add report for given reply
				ReplyReportAbuse  report = new ReplyReportAbuse( ReplyId = elementId, Reason = 'Inappropriate' );
				insert report;
			} 
		}
		ret.put('responseMsg','');
		ret.put('status', (aux.globalConstants).get('STATUS_OK') );
		return ret;
	}


	/* sanitize methods*/

	/*
	 * @description
	 *  Sanitizes body of reply : 
	 * @param element @type map<String,Object>
	 * @return void
	 */
	public static String sanitizePostBody(String origBody, Boolean isPublic){   
		
		String res = origBody.escapeHtml4();
		res = escapeNewLines(res);
		if (isPublic){  
			res = replaceUrlsByLink(res);
		}
		return res;
	}

	/*
	 * @description
	 *  Sanitizes body of reply : 
	 * @param element @type map<String,Object>
	 * @return void
	 */
	public static String sanitizeReplyBody(String origBody, Boolean isPublic){  
		String res = '';
		if (isPublic){	  
			res = origBody.escapeHtml4();
			res = escapeNewLines(res);
			res = replaceUrlsByLink(res);

		}else{

			res = origBody.escapeHtml4();
			res = escapeNewLines(res);
			/* for Rich Text Disable : replace plain urls by links*/
			if (!cam_CustomSettingModel.isRichTextEnabledOnSite()){
			//  res = replaceUrlsByLink(res);
			}
		}

		
		return res;
	}
	
	/*
	* @description
	* Replaces newlines by new line html tag 
	* @param origString @type String
	* @return  String
	*/
	public static String escapeNewLines(String origString){
	 
		String res = origString;
			//sanitize
		res = res.replaceAll('\n','<br/>');
		res = res.replaceAll('\r','<br/>');
		
		return res;
	}

	/*
	* @description
	* Replaces plain urls by links 
	* @param origString @type String
	* @return  String
	*/
	public static String replaceUrlsByLink(String origString){
	 
		List<String> s = origString.split(' ');
		String finalResult = '';

		String res = '';
		try {
			Pattern patt = Pattern.compile('(?i)\\b((?:https?://|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:\'\".,<>???“”‘’]))');
			for (String str : s){
				 
				Matcher matcher = patt.matcher(str);	
				if(matcher.find()){
					 
					if (matcher.group(1).startsWith('http://')|| matcher.group(1).startsWith('https://')){
						res = matcher.replaceAll('<a href=\'$1\'  target=\'_blank\'>$1</a>');
					}else{
						res = matcher.replaceAll('<a href=\'http://$1\'  target=\'_blank\'>$1</a>');
					}
				}else{
					res = str;
				} 
				finalResult = finalResult +' '+ res;
			}
		} catch (Exception e) {
			finalResult = origString;
		}
		 
		if (finalResult.length() >=  Schema.SObjectType.Question.fields.Body.getLength() ){
			finalResult = origString.replaceAll('<br>','\n').replaceAll('<br/>','\n');
		}

		
		return finalResult;
	}
	
	
	public static String ENCODE(String input) {
		return String.escapeSingleQuotes(input);
	}
	
}