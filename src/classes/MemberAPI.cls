global with sharing class MemberAPI implements FieloCMS.DataInterface, FieloCMS.ControlInterface, FieloCMS.ViewInterface{
	
    global ApexPages.Component getComponent(FieloCMS__Component__c component){                        
        FieloCMS__Component__c c = [SELECT Name, FieloCMS__Fieldset__c, FieloCMS__Title__c, FieloCMS__CSSClasses__c FROM FieloCMS__Component__c WHERE Id =: component.Id];
        if(c.Name == 'Login'){
        //if(c.ComponentReference__c == 'Login'){
            return new Component.apex.outputtext(value = 'test2');
            Component.apex.panelgroup png = new Component.apex.panelgroup();
            //Component.SiteLoginFielo2 login = new Component.SiteLoginFielo2(config = c);
            //png.childcomponents.add(login);
            Component.Tag tag = new Component.Tag();
            return tag;
            //return login;
            return png;
        }else if(c.Name == 'RegisterStep2'){
        //}else if(c.ComponentReference__c == 'RegisterStep2'){            
            return new Component.apex.outputtext(value = 'test');
            //Component.RegisterStep3 register = new Component.RegisterStep3();
            //Component.RegisterStep2 register = new Component.RegisterStep2(config = c, showPassword = true);                
            //return register;
        }
        
        return null;
    }
    
	global Map<Id, Object> getBulkData(List<FieloCMS__Component__c> components){        
        Map<Id,Object> newMapData = new Map<Id,Object>();
        //Prepare all the queries
        for(FieloCMS__Component__c c : components){            
            if(c.FieloCMS__Limit__c == null)
                c.FieloCMS__Limit__c = 5;
            
            /*if(c.Name == 'MemberAccount'){    
            //if(c.ComponentReference__c == 'MemberAccount'){
                FieloAlpha__Member__c loggedMember = MemberService.getCurrentMember(new Set<String>{'OrganizationAccount__c','RecordType.DeveloperName'});
                if(loggedMember.RecordType.DeveloperName != 'OrganizationAccount' && loggedMember.FieloAlpha__OrganizationAccount__c != null){
                	newMapData.put(c.Id, new MembersSelector(new Set<String>(OrganizationUtil.getFieldSet(c.FieloCMS__FieldSet__c))).selectById(new Set<Id>{loggedMember.FieloAlpha__OrganizationAccount__c})[0]);
                }
            }else if(c.Name == 'MemberSelection'){
            //}else if(c.ComponentReference__c == 'MemberSelection'){
            	FieloAlpha__Program__c program = ProgramService.getCurrentProgram();
	      		newMapData.put(c.Id, new MembersSelector(new Set<String>(OrganizationUtil.getFieldSet(c.FieloCMS__FieldSet__c))).selectRelatedMembers(UserInfo.getUserId(), program.Id));
            }else if(c.Name == 'OrganizationMembers'){
            //}else if(c.ComponentReference__c == 'OrganizationMembers'){
	      		FieloAlpha__Member__c loggedMember = MemberService.getCurrentMember(new Set<String>{'RecordType.DeveloperName'});
	      		if(loggedMember.RecordType.DeveloperName == 'OrganizationAccount'){
	      			newMapData.put(c.Id, new MembersSelector(new Set<String>(OrganizationUtil.getFieldSet(c.FieloCMS__FieldSet__c))).selectByOrganizationAccount(loggedMember.Id));
	      		}
            }else if(c.Name == 'Register'){*/
            //}if(c.ComponentLibrary__r.Name == 'Register'){
                newMapData.put(c.Id, new FieloAlpha__Member__c());
            /*} else if(c.Name == 'MemberDetail' || c.Name == 'Account'){
            //}else if(c.ComponentLibrary__r.Name == 'MemberDetail' || c.ComponentLibrary__r.Name == 'Account'){
                newMapData.put(c.Id, MemberService.getCurrentMember(new Set<String>{'Name', 'FirstName__c', 'LastName__c', 'Email__c', 'Points__c'}));
            } */              
        }
        return newMapData;
    }

    global List<sObject> getData(FieloCMS__Component__c component2, Integer pageNumber, String orderBy, String filters){
        return null;
    }
    
    global FieloCMS.RemoteActionResult remoteComponentAction(FieloCMS__Component__c component2, sObject record, String json){
        
        Savepoint sp;

        FieloCMS.RemoteActionResult result = new FieloCMS.RemoteActionResult();
        List<FieloCMS.RemoteActionResult.RemoteActionMessage> successMessages = new List<FieloCMS.RemoteActionResult.RemoteActionMessage>();

        try{                    
            sp = Database.setSavepoint();

            FieloCMS__Component__c component = [SELECT AccountCRMMode__c, Account__c, Program__c, AccountOwner__c FROM FieloCMS__Component__c WHERE Id =: component2.Id];

            FieloAlpha__Member__c member = (FieloAlpha__Member__c)record;
            String registerType;
            if(UserInfo.getUserType() == 'Guest'){
                registerType = component.AccountCRMMode__c;
                if(registerType == 'Defined Account'){
                    member.FieloAlpha__Account__c = component.Account__c;
                }               
            }else{
                FieloAlpha__Member__c loggedMember = MemberService.getCurrentMember(new Set<String>{'RecordType.DeveloperName','OrganizationAccount__c'});
                if(loggedMember.RecordType.DeveloperName == 'OrganizationAccount'){
                    registerType = 'Organization';
                    member.FieloAlpha__OrganizationAccount__c = loggedMember.Id;
                    RecordType contributorRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'OrganizationContributor'];
                    member.RecordTypeId = contributorRT.Id;
                }
            }
            member.FieloAlpha__Program__c = component.Program__c;
            FieloAlpha.MemberService.register(member, registerType, component.AccountOwner__c);
            successMessages.add(new FieloCMS.RemoteActionResult.RemoteActionMessage( ApexPages.Severity.Info, Label.SucessRegistrationStep1 ));                                  
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