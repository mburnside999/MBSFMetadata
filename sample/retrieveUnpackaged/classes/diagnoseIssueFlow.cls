public class diagnoseIssueFlow {
    
    public Flow.Interview.Diagnose_Issue_Flow_2 theInterview {get;set;}
    public string caseID {set;}
    public string caseNumber {set;}
    public string searchString {set;}
    public string firstDim {set;}
    public string secondDim {set;}
    public string thirdDim {set;}
    
    public String finishLocationId{get;set;}
    
    public PageReference getfinishLocation() {
        if(theInterview !=null){
            finishLocationId=theInterview.CaseId;
        }
        return new PageReference('/'+finishLocationId);
    }
    
    public String getcaseID(){
        if(theInterview !=null){
            return theInterview.CaseId;
        }
        else{ 
            return '';
        }
    }
    
    public String getcaseNumber(){
        if(theInterview !=null){
            return theInterview.CaseNumber;
        }
        else{ 
            return '';
        }
    }
    
    public string getsearchString(){
        if(theInterview !=null){
            return theInterview.KnowledgeSubject;
        }
        else{ 
            return '';
        }
    }
    
    public string getfirstDim(){
        if(theInterview ==null){
            return '';           
        }
        else{ 
            return theInterview.KnowledgeCategoryOne;
        }
    } 
    
    public string getsecondDim(){
        if(theInterview !=null){
            return theInterview.KnowledgeCategoryTwo;
        }
        else{ 
            return '';
        }
    }
    
    public string getthirdDim(){
        if(theInterview !=null){
            return theInterview.KnowledgeCategoryThree;
        }
        else{ 
            return '';
        }
    }
    
    public diagnoseIssueFlow(ApexPages.StandardController controller) {

    }

}