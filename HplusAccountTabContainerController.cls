public class HplusAccountTabContainerController {
    @AuraEnabled
	public static String getHplusNumber(Id accountId) {
        system.debug('??accountId'+accountId);
		if (accountId != null) {
            if (Hallmarkplus__c.SObjectType.getDescribe().isAccessible() && Schema.SObjectType.Hallmarkplus__c.fields.uuid__c.isAccessible()) {
                
                //Start:Naeem:Care-2147
                Account consumerAccount = [SELECT Id, CID__c, uuid__c FROM Account WHERE Id =:accountId LIMIT 1];
                
                if(consumerAccount != null && consumerAccount.uuid__c != null && consumerAccount.uuid__c != ''){
                    List<Hallmarkplus__c> Hallmarkplus = [SELECT uuid__c  FROM Hallmarkplus__c WHERE uuid__c = :consumerAccount.uuid__c LIMIT 1];
                    //End:Naeem:Care-2147
                    if (!Hallmarkplus.isEmpty()) {
                        return Hallmarkplus[0].uuid__c ;
                    }                    
                }

                CEMS_Connector_v2.KhDemoResponseProvider demoProvider =
                    CEMS_Connector_v2.getKhDemoResponseProvider();
                CEMS_CustomerData_Wrapper demoResponse = demoProvider == null
                    ? null
                    : demoProvider.findCustomer(consumerAccount.CID__c, null, null);
                if (demoResponse != null && demoResponse.Result != null
                    && demoResponse.Result.consumers != null
                    && !demoResponse.Result.consumers.isEmpty()
                    && demoResponse.Result.consumers[0].hPlusMembership != null
                    && !demoResponse.Result.consumers[0].hPlusMembership.isEmpty()) {
                    return demoResponse.Result.consumers[0].hPlusMembership[0].uuid;
                }
                
			}
		}

		return '';
	}
@AuraEnabled
public static HPlusInfoWrapper getHplusNumberinfo(Id accountId) {
    if (accountId != null) {
        if (Hallmarkplus__c.SObjectType.getDescribe().isAccessible() && 
            Schema.SObjectType.Hallmarkplus__c.fields.Akamai_Login__c.isAccessible() &&
             Schema.SObjectType.Hallmarkplus__c.fields.Current_Start_Date__c.isAccessible() &&
            Schema.SObjectType.Hallmarkplus__c.fields.Original_Start_Date__c.isAccessible() &&
            Schema.SObjectType.Hallmarkplus__c.fields.Current_End_Date__c.isAccessible() &&
            Schema.SObjectType.Hallmarkplus__c.fields.Status__c.isAccessible()) {
                
                //Start:Naeem:Care-2147
                Account consumerAccount = [SELECT Id, CID__c, uuid__c FROM Account WHERE Id =:accountId LIMIT 1];
                
                if(consumerAccount != null && consumerAccount.uuid__c != null && consumerAccount.uuid__c != ''){
				//Raghav - 2257 Free_Trial_Used__c field updated in the below SOQL
				//Raghav - 1507 Account_ID__c, Membership_Source__c,uuid__c fields updated in the below SOQL
                    List<Hallmarkplus__c> hpc = [SELECT Akamai_Login__c,Type__c,Auto_Renewel_On__c, Current_Start_Date__c, Original_Start_Date__c, 
                                                 Current_End_Date__c, Status__c,Crown_Rewards_Tier__c, Source__c, Linked_Login_Status__c,
                                                 Crown_Rewards_Number__c,Free_Trial_Used__c, Account_ID__c,Membership_Source__c,uuid__c 
                                                 FROM Hallmarkplus__c 
                                                 WHERE uuid__c = :consumerAccount.uuid__c 
                                                 LIMIT 1];
                    //End:Naeem:Care-2147
                    if (!hpc.isEmpty()) {
                        Hallmarkplus__c record = hpc[0];
                        //Raghav - 1507 start
                        CEMS_Connector_v2.KhDemoResponseProvider demoProvider =
                            CEMS_Connector_v2.getKhDemoResponseProvider();
                        String demoMembershipSource = demoProvider == null
                            ? null
                            : demoProvider.findMembershipSource(record.uuid__c);
                        if (String.isNotBlank(demoMembershipSource)) {
                            record.Membership_Source__c = demoMembershipSource;
                        } else {
                            List<Care_MPP_Connector.SubscriptionWrapper> subscriptionWrapperList =
                                getSubscriptions(record.uuid__c);
                            if (!subscriptionWrapperList.isEmpty()
                                && String.isNotBlank(subscriptionWrapperList[0].contractInfo.title)) {
                                record.Membership_Source__c = translateContractInfoTitle(
                                    subscriptionWrapperList[0].contractInfo.title
                                );
                                system.debug('membership source= '+record.Membership_Source__c);
                            }
                        }
                        //Raghav - 1507 end
                        HPlusInfoWrapper wrapper = new HPlusInfoWrapper(record.Akamai_Login__c,
                                                                        record.Type__c, 
                                                                        record.Auto_Renewel_On__c, 
                                                                        record.Current_Start_Date__c,
                                                                        record.Original_Start_Date__c, 
                                                                        record.Current_End_Date__c, 
                                                                        record.Status__c,record.Crown_Rewards_Tier__c,record.Source__c,
                                                                        record.Linked_Login_Status__c,
                                                                        record.Crown_Rewards_Number__c,																		
                                                                        record.Membership_Source__c,
                                                                        record.Free_Trial_Used__c
                                                                       );
                        system.debug('@@@Returning HPlusInfoWrapper: ' + wrapper);
                        return wrapper;
                        
                    }   
                }

                CEMS_Connector_v2.KhDemoResponseProvider demoProvider =
                    CEMS_Connector_v2.getKhDemoResponseProvider();
                HPlusInfoWrapper demoWrapper = demoProvider == null
                    ? null
                    : demoProvider.findMembershipInfo(consumerAccount.CID__c);
                if (demoWrapper != null) {
                    return demoWrapper;
                }
            }
        
    }
    // If no records found or other conditions not met, return an empty wrapper
    HPlusInfoWrapper emptyWrapper = new HPlusInfoWrapper(null, null, null, null, null, null, null, null, null, null, null,null,null);
        system.debug('@@Returning empty HPlusInfoWrapper: ' + emptyWrapper);
        return emptyWrapper;
}

  //Raghav - 1507 start
  public static List<Care_MPP_Connector.SubscriptionWrapper> getSubscriptions(String uuId) {
    try {
        Care_MPP_Connector connection = Care_MPP_Connector.getInstance();
        Care_MPP_Connector.MPPSessionResponse sessionResp = connection.getMPPSessionId(uuId,'POST');
        String sessionId = sessionResp.mppTokenAttributes.sessionId;
        String accountReferenceId = sessionResp.mppTokenAttributes.accountRef;
        return connection.fetchSubscriptions(sessionId,accountReferenceId);
    } catch (Care_MPP_Connector.MPP_ConnectionException e) {
        // Log the error
        Universal_Error_Logger.auraGenerateErrorLog('Hallmark+ memberships failed to retrieved.', 'HplusAccountTabContainerController', e.getMessage());

        // Throw a user-friendly exception
        throw new AuraHandledException('Failed to fetch subscriptions: ' + e.getMessage());
    } catch (Exception e) {
        // Handle unexpected errors
        Universal_Error_Logger.auraGenerateErrorLog('Hallmark+ memberships failed to retrieved.', 'HplusAccountTabContainerController', e.getMessage());
        throw new AuraHandledException('An unexpected error occurred. Please contact support.');
    }
}

public static String translateContractInfoTitle(String contractInfoTitle) {
    // Load all metadata records into a map
    Map<String, String> translationMap = new Map<String, String>();

    for (Contract_Info_Translation__mdt meta : [
        SELECT Contract_Info_Title__c, Translated_Title__c FROM Contract_Info_Translation__mdt
    ]) {
        translationMap.put(meta.Contract_Info_Title__c, meta.Translated_Title__c);
    }

    // Return translated title if found, else return original
    return translationMap.containsKey(contractInfoTitle)
        ? translationMap.get(contractInfoTitle)
        : contractInfoTitle;
}
    
}
