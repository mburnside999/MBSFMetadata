global class MyCaseTemplateChooser implements Support.EmailTemplateSelector {
    // Empty constructor 
    global MyCaseTemplateChooser() {    }

    // The main interface method 
    global ID getDefaultEmailTemplateId(ID caseId) {
        // Select the case we're interested in, choosing any fields that are relevant to our decision
        Case c = [SELECT Subject, Description FROM Case WHERE Id=:caseId];

        EmailTemplate et;

        et = [SELECT id FROM EmailTemplate WHERE DeveloperName = 'CasewAnswer'];
        
        
        // Return the ID of the template selected
        return et.id;
    }
    
    /*
    // Empty constructor
    global SmartTemplateLoader() {
    }
    // The main interface method
    global ID getDefaultEmailTemplateId(ID caseId) {
        
        // Select the case we're interested in, choosing any fields that are relevant to our decision
        Case c = [SELECT Status, Asset.Name FROM Case WHERE Id=:caseId];

        Smart_Template_Loader_Conf__c conf = null;
        List<Smart_Template_Loader_Conf__c> confs = null;

        // get template from case status + case asset
        confs = [SELECT Template_Name__c FROM Smart_Template_Loader_Conf__c WHERE Case_Status__c = :c.status and Asset_Name__c LIKE :c.Asset.Name];
        
        if (!confs.isEmpty()) {
            conf = confs[0];
            System.debug('got template: ' + conf.Template_Name__c);
        }

        // get template from case status
        if (conf==null) {
            confs = [SELECT Template_Name__c FROM Smart_Template_Loader_Conf__c WHERE Case_Status__c = :c.status];
            if (!confs.isEmpty()) {
                conf = confs[0];
                System.debug('got template: ' + conf.Template_Name__c);
            }
        }
        
        // get template from case asset
        confs = [SELECT Template_Name__c FROM Smart_Template_Loader_Conf__c WHERE Asset_Name__c LIKE :c.Asset.Name];
        
        if (!confs.isEmpty()) {
            conf = confs[0];
            System.debug('got template: ' + conf.Template_Name__c);
        }

        // get default template
        if (conf==null) {
            confs = [SELECT Template_Name__c FROM Smart_Template_Loader_Conf__c WHERE Case_Status__c = '' AND Asset_Name__c = ''];
            if (!confs.isEmpty()) {
                conf = confs[0];
                System.debug('got template: ' + conf.Template_Name__c);
            }
        }

        if (conf==null) {
            System.debug('no template!');
            return null;
        }

        // get the template ID
        List<EmailTemplate> ets = [SELECT id FROM EmailTemplate WHERE DeveloperName = :conf.Template_Name__c];
        //Return the ID of the template selected
        if (!ets.isEmpty()) {
            EmailTemplate et = ets[0];
            System.debug('template: ' + conf.Template_Name__c + ' -- id: ' + et.id);
            return et.id;
        }
        System.debug('No template with the name: ' + conf.Template_Name__c);

        return null;
    }
    */
}