/**
 * @author Timba Software
 * @description
 *		started at 08/09/2012
 *		cam_DTO class coverage
 **/
@isTest(OnInstall=false)
private class cam_DTO_test {
	@isTest(SeeAllData=true)
    static void initTest() {
        cam_TestEnvironment.initData();
        
        cam_DTO element = new cam_DTO();
        element = new cam_DTO();
        element.globalOptions.put('requestType', element.globalConstants.get('requestType_SEARCH'));
        
        element.searchOptions.put('communityId',cam_TestEnvironment.vcommunity.Id);
	 	element.searchOptions.put('topicName',element.globalConstants.get('NULL_VAL'));
	 	element.searchOptions.put('searchInput',element.globalConstants.get('NULL_VAL'));
	 	element.searchOptions.put('sortBy',element.searchConstants.get('sortBy_RECENT'));
	 	element.searchOptions.put('scope',element.searchConstants.get('questions_GET_ALL_QUESTIONS'));
	 	
	 	system.assertEquals(1, cam_DTO.validateDTOAsync( Json.serialize(element) ));
	 	
	 	element.searchOptions.put('scope','dummy');
	 	system.assertEquals(-1, cam_DTO.validateDTOAsync( Json.serialize(element) ));
	 	
	 	element.globalOptions.put('requestType', 'WRONG VALUE');
	 	system.assertEquals(-1, cam_DTO.validateDTOAsync( Json.serialize(element) ));
	 	
	 	element.globalOptions.put('requestType', element.globalConstants.get('requestType_SEARCH'));
	 	element.searchOptions.put('sortBy','WRONG VALUE');
	 	system.assertEquals(-1, cam_DTO.validateDTOAsync( Json.serialize(element) ));
	 	
	 	element.globalOptions.put('requestType', element.globalConstants.get('requestType_SINGLE_ITEM_VIEW'));
	 	element.singleItemViewOptions.put('idToDisplay','123456789012345');
		system.assertEquals(1, cam_DTO.validateDTOAsync( Json.serialize(element) ));
 
	 	element.singleItemViewOptions.put('idToDisplay','123');
		system.assertEquals(-1, cam_DTO.validateDTOAsync( Json.serialize(element) ));
	 	
	 	String dummyJson = '{requestType : \'siview\' , dummyField : \'dummyContent\'}';
	 	system.assertEquals(-1, cam_DTO.validateDTOAsync( Json.serialize(dummyJson) ));
    }
}