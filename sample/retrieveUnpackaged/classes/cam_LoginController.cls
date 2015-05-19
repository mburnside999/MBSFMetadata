public with sharing class cam_LoginController {
     public String username {get; set;}
     public String password {get; set;}

     public PageReference login() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        /*PageReference tmpL = Site.login(username, password, startUrl);
        if ( !test.isRunningTest() & tmpL != null){
        	PageReference pageRef = new PageReference(tmpL.getUrl().replace('%3F','%23'));
        	return pageRef;
        }*/
        return Site.login(username, password, startUrl);//tmpL;
     }  
     
    public cam_LoginController () {}
     
     public static testMethod void testSiteLoginController () {
        // Instantiate a new controller with all parameters in the page
        cam_LoginController controller = new cam_LoginController ();
        controller.username = 'test@salesforce.com';
        controller.password = '123456';
                     
        System.assertEquals(controller.login(),null);
     }
}