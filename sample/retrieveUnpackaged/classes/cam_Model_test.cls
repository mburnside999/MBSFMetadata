/**
 * @author Timba Software
 * @description
 *      started at 08/13/2012
 *      cam_Model class coverage
 **/
@isTest(OnInstall=false)
private class cam_Model_test {
	@isTest(SeeAllData=true)
    static void initTest() {
        
        cam_TestEnvironment.initData();
        
        cam_DTO dto = new cam_DTO();
        
        (dto.globalOptions).put('requestType', (dto.globalConstants).get('requestType_SEARCH') );
        (dto.searchOptions).put('communityId', cam_TestEnvironment.vcommunity.Id );
        (dto.searchOptions).put('scope', (dto.searchConstants).get('questions_GET_ALL_QUESTIONS') );
        (dto.searchOptions).put('sortBy', (dto.searchConstants).get('sortBy_LAST_REPLY') );
        
        //====
        cam_DTO response = cam_Model.get_All_Questions(dto);
        
        system.assertNotEquals(0,(response.response.responseElements).size());
        system.assertEquals( dto.globalConstants.get('STATUS_OK') , response.response.status);
        
       	Community c = cam_TestEnvironment.vcommunity;
        system.assertNotEquals(null,c);
        
        //==== posting public question
        Map<String,String> responseMap = cam_Model.postPublicQuestion(c.Id, 'test[model]', 'test[model]', cam_TestEnvironment.topic);
        system.assertEquals( dto.globalConstants.get('STATUS_OK') , responseMap.get('status'));
        
        list<Question> lQuestion = [Select Id, Title from Question where Title = 'test[model]'];
        system.assertEquals(1,lQuestion.size());
        
        Id [] fixedSearchResults= new Id[2];
       	fixedSearchResults[0] = cam_TestEnvironment.knowledgeArt.Id;
       	fixedSearchResults[1] = lQuestion[0].Id;
        Test.setFixedSearchResults(fixedSearchResults);
        
        (dto.searchOptions).put('communityId', c.Id );
        (dto.searchOptions).put('searchInput', 'test' );
        //====
        //Searchs with filter
        response = cam_Model.get_Questions_With_Filter(dto);
        system.assertNotEquals(0,(response.response.responseElements).size());
        system.assertEquals( dto.globalConstants.get('STATUS_OK') , response.response.status);
        
        //====
        responseMap = cam_Model.postReply(lQuestion[0].Id, 'test[model-reply]');
        system.assertEquals( dto.globalConstants.get('STATUS_OK') , responseMap.get('status'));
        list<Reply> lReply = [Select Id,Body from Reply where QuestionId = :lQuestion[0].Id];
        system.assertEquals(true,lQuestion.size()>0);
        
        //====
        responseMap = cam_Model.voteLike(lQuestion[0].Id);
        system.assertNotEquals( dto.globalConstants.get('STATUS_OK') , responseMap.get('status'));
        system.assertEquals( true , responseMap.get('responseMsg') != '');
        
        //====
        responseMap = cam_Model.postPrivateQuestion(c.Id, 'test[model-privateQ]', 'test[model=privateQ]');
        system.assertEquals( dto.globalConstants.get('STATUS_OK') , responseMap.get('status'));
        
        //====
        responseMap = cam_Model.follow(lQuestion[0].Id, true);
        system.assertEquals( true , responseMap.get('responseMsg') != '');
        
        //====
        dto.singleItemViewOptions.put('idToDisplay',lQuestion[0].Id);
        response = cam_Model.getSingleItemView(dto);
        system.assertEquals( true , response.response.responseElements.size()>0);
        system.assertEquals( dto.globalConstants.get('STATUS_OK') , response.response.status);
        
        //====
        dto.singleItemViewOptions.put('idToDisplay',cam_TestEnvironment.knowledgeArt.Id);
        response = cam_Model.getSingleItemView(dto);
        system.assertEquals( true , response.response.responseElements.size()>0);
        system.assertEquals( dto.globalConstants.get('STATUS_OK') , response.response.status);
        
        //====
        response = cam_Model.getUserDetails(true, dto, Userinfo.getUserId(),c.Id);
        system.assertEquals( true, response.currentUser!= null );
        
        //==== best answer
        responseMap = cam_Model.bestAnswer(lQUestion[0].Id, lReply[0].Id);
        system.assertEquals( dto.globalConstants.get('STATUS_OK') , responseMap.get('status'));
        
        //==== get articles
        //response = cam_Model.get_Questions_Articles(dto);
        //system.assertEquals( true, response.response.responseElements.size()>0 );
        //system.assertEquals( dto.globalConstants.get('STATUS_OK'), response.response.status );
        
        //====
        dto.myFeedOptions.put('communityId',c.Id);
        dto.myFeedOptions.put('viewCommunityId',c.Id);
        dto.myFeedOptions.put('authorId',userInfo.getUserId());
        response = cam_Model.handleMyFeed(dto);
        system.assertEquals(dto.globalConstants.get('STATUS_OK'),response.response.status );
        system.assertEquals(true,response.response.responseElements.size()>0 );
        
        //====
        //Getting questions with bestanswer
        (dto.globalOptions).put('requestType', (dto.globalConstants).get('requestType_SEARCH') );
        (dto.searchOptions).put('communityId', c.Id );
        (dto.searchOptions).put('scope', (dto.searchConstants).get('questions_GET_ALL_QUESTIONS') );
        (dto.searchOptions).put('sortBy', (dto.searchConstants).get('sortBy_LAST_REPLY') );
        
        //====
        response = cam_Model.get_All_Questions(dto);
        
        system.assertEquals(true,(response.response.responseElements).size() > 0);
        system.assertEquals( dto.globalConstants.get('STATUS_OK') , response.response.status);
    }
}