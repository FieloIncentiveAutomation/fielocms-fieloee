public with sharing class TransactionAPI implements FieloCMS.DataInterface, FieloCMS.ControlInterface{
	
	public Map<Id, Object> getBulkData(List<FieloCMS__Component__c> components){                
        Map<Id,Object> newMapData = new Map<Id,Object>();
        //Prepare all the queries
        for(FieloCMS__Component__c c : components){            
            if(c.FieloCMS__Limit__c == null)
                c.FieloCMS__Limit__c = 5;

            if(c.Name == 'GetPoints'){
            //if(c.ComponentLibrary__r.Name == 'GetPoints'){
                newMapData.put(c.Id, new FieloAlpha__Transaction__c());
            }else if(c.Name == 'Transactions'){
            //}else if(c.ComponentLibrary__r.Name == 'Transactions'){
                Id memberId = MemberService.getCurrentMemberId();
                newMapData.put(c.Id, Database.query('SELECT ' + String.join(new List<String>(OrganizationUtil.getFieldSet(c.FieloCMS__FieldSet__c)), ',') + ' FROM FieloAlpha__Transaction__c WHERE FieloAlpha__Member__c =: memberId'));
            }                
        }
        return newMapData;
    }

    public List<sObject> getData(FieloCMS__Component__c component, Integer pageNumber, String orderBy, String filters){        
        if(component.FieloCMS__Limit__c == null)
            component.FieloCMS__Limit__c = 5;

        //Calculate the offset from the Page Number
        Integer offset = Integer.valueOf(component.FieloCMS__Limit__c * (pageNumber - 1));                
        Id memberId = MemberService.getCurrentMemberId();
        String query = 'SELECT ' + String.join(new List<String>(OrganizationUtil.getFieldSet(component.FieloCMS__FieldSet__c)), ',') + ' FROM FieloAlpha__Transaction__c WHERE FieloAlpha__Member__c =: memberId';
        query += ' LIMIT ' + String.valueOf(offset);
        query += ' OFFSET ' + String.valueOf(component.FieloCMS__Limit__c);
        return Database.query(query);
    }
    
    public FieloCMS.RemoteActionResult remoteComponentAction(FieloCMS__Component__c component, sObject record, String json){
        
        Savepoint sp;

        FieloCMS.RemoteActionResult result = new FieloCMS.RemoteActionResult();
        List<FieloCMS.RemoteActionResult.RemoteActionMessage> successMessages = new List<FieloCMS.RemoteActionResult.RemoteActionMessage>();

        try{                    
            sp = Database.setSavepoint();
            
            FieloAlpha__Transaction__c trans = (FieloAlpha__Transaction__c)record;
            trans.FieloAlpha__Type__c = (component.TransactionType__c != null && component.TransactionType__c != '') ? component.TransactionType__c : 'Code Insert';
            FieloAlpha.CodeUtil.sendCode(trans);
            successMessages.add(new FieloCMS.RemoteActionResult.RemoteActionMessage( ApexPages.Severity.Info, 'Success'));            
        }catch(DmlException e){            
            Database.rollback(sp);
            if(ApexPages.hasMessages()){
                result.redirectURL = '';
                for(ApexPages.Message m : ApexPages.getMessages()){
                    result.addMessage(new FieloCMS.RemoteActionResult.RemoteActionMessage(m));
                }
            }
            return result;
        }catch(Exception e){
            if(sp != null){
                Database.rollback(sp);
            }
            result.addMessage(new FieloCMS.RemoteActionResult.RemoteActionMessage(e));
            return result;
        }

        if(!successMessages.isEmpty()){            
            result.addMessages(successMessages);            
        }

        return result;
    }
}