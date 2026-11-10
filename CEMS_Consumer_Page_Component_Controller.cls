//updated
/**
* Class used by the CEMS_GET_Component to connect to the CCDB database
* and retrieve, update or insert new records.
* Created by Matt Gerry ::: Hallmark ::: 4/29/2019.
*/



public without sharing class CEMS_Consumer_Page_Component_Controller {
    private static CEMS_CustomerData_Wrapper.AlternateId getPrimaryAlternateId(
        CEMS_CustomerData_Wrapper.Consumers consumer
    ) {
        if (consumer == null || consumer.alternateId == null || consumer.alternateId.isEmpty()) {
            return null;
        }

        CEMS_CustomerData_Wrapper.AlternateId firstAvailable;
        for (CEMS_CustomerData_Wrapper.AlternateId alternateId : consumer.alternateId) {
            if (alternateId == null) {
                continue;
            }
            if (firstAvailable == null) {
                firstAvailable = alternateId;
            }
            if ('HDXREF'.equalsIgnoreCase(alternateId.typ)) {
                return alternateId;
            }
        }
        return firstAvailable;
    }
    //Grabbing the Account record for the page the user is currently viewing and returning it
    //to the component.
    @AuraEnabled
    public static Account grabInternalConsumerRecord(Id personAcctId) {
        //If we have received an accountId successfully, continue
        System.debug('Person account id::: ' + personAcctId);
        if (personAcctId != null) {
            List<Account> pAcctFound = [
                SELECT
                Id,
                PersonEmail,
                FirstName,
                LastName,
                MiddleName,
                PersonHomePhone,
                //care-808
                //PersonMailingCity,
                Address_Line_1__c,
                Address_Line_2__c,
                Mailing_Country__c,
                Mailing_City__c,
                Mailing_State_Province__c,
                Mailing_Zip_Postal_Code__c,
                Crown_Rewards_Number__c,
                Market_via_Email__c,
                //care-134 Enable email Fields
                Email_Last_Provided__c, 
                Email_Consent_Provided__c,
                Last_Failed_Email_Attempt__c, 
                Failed_Email_Attempts__c, 
                //care-726
                Shared_Email__c,
                
                Email_Subsidiary_Opt_In__c,
                //Care-565 Enable Preferred Phone Opt Fields from CCDB
                Market_via_Preferred_Phone__c,
                Preferred_Phone_Consent_Provided_Date__c,
                //Care-564 Enable Preferred mail Opt Fields from CCDB
                Postal_Undeliverable__c,
                Postal_Consent_Provided_Date__c,
                Market_via_Postal_Mail__c,
                //End-Care-564 Enable Preferred mail Opt Fields from CCDB
                Postal_Opt_In__c,
                Third_Party_Mail_Opt_In__c,
                PersonBirthdate,
                Gender__c,
                Decesased__c,
                PersonMobilePhone,
                Market_via_Text__c,
                CID__c,
                CallGuid__c
                FROM Account
                WHERE Id = :personAcctId AND isPersonAccount = TRUE
                LIMIT 1
            ];
            //If we retrieved an account, return it, otherwise return null
            if (!pAcctFound.isEmpty()) {
                return pAcctFound[0];
            } else {
                //Returning null informs the component that we failed to retrieve a record and
                //should stop proceeding with any CRU operations.
                return null;
            }
        } else {
            return null;
        }
    }
    
    //This method will retrieve a consumer record from CCDB
    @AuraEnabled
    public static String retrieveConsumer(String acctId) {
        System.debug('Person acct id ::: ' + acctId);
        
        //Setting up our variables
        String responseMsg = '';
        CEMS_Connector_v2 cCon = new CEMS_Connector_v2('GET', null);
        CEMS_Consumer_Page_Component_Controller pageController = new CEMS_Consumer_Page_Component_Controller();
        Account personAccount = null;
        
        //If an accountId was successfully passed, query for the record
        if (acctId != null) {
            List<Account> acctList = [
                SELECT 
                Id,
                PersonEmail,
                FirstName,
                LastName,
                MiddleName,
                PersonHomePhone,
                //care-808
                Address_Line_1__c,
                Address_Line_2__c,
                Mailing_Country__c,
                //PersonMailingCity,
                Mailing_City__c,
                Mailing_State_Province__c,
                Mailing_Zip_Postal_Code__c,
                Crown_Rewards_Number__c,
                Market_via_Email__c,
                //care-134 Enable email Fields
                Email_Last_Provided__c,
                Email_Consent_Provided__c,
                Last_Failed_Email_Attempt__c, 
                Failed_Email_Attempts__c, 
                //care-726
                Shared_Email__c,
                Email_Subsidiary_Opt_In__c,
                //Care-565 Enable Preferred Phone Opt Fields from CCDB
                Market_via_Preferred_Phone__c,
                Preferred_Phone_Consent_Provided_Date__c,
                //Care-564 Enable Preferred mail Opt Fields from CCDB
                Postal_Undeliverable__c,
                Postal_Consent_Provided_Date__c,
                Market_via_Postal_Mail__c,
                //End-Care-564 Enable Preferred mail Opt Fields from CCDB
                Postal_Opt_In__c,
                Third_Party_Mail_Opt_In__c,
                PersonBirthdate,
                Gender__c,
                Decesased__c,
                PersonMobilePhone,
                Market_via_Text__c,
                CID__c,
                Text_Consent_Provided_Date__c,
                //care-2147
                UUID__c
                FROM Account
                WHERE Id = :acctId AND isPersonAccount = TRUE
                LIMIT 1
            ];
            //Birth_Month__pc,
            //Birth_Day__pc                
            
            
            //If we find a record, assign that record to the person account variable.
            if (!acctList.isEmpty()) {
                personAccount = acctList[0];
            } else {
                responseMsg = 'No consumer record was found. Please try reloading the page.'; return responseMsg;
            }
        } else {
            responseMsg = 'There was an error passing the record Id to the controller. Please reload the page and try again.';
            return responseMsg;
        }
        
        //If we assigned a record to our personAccount variable, continue
        if (personAccount != null) {
            //If the consumer has a CID attached to their record, continue
            if (personAccount.CID__c != null) {
                //Generate our CEMS GET request
                System.debug('@@personAccount.CID__c'+personAccount.CID__c);
                //Raghav - 2019 added new parameter hPlusMemberUUID value null
                CEMS_CustomerData_Wrapper customerWrapper = cCon.CEMS_Get(personAccount.CID__c, null, null, null, null, null, null,null, false);
                System.debug('@@customerWrapper='+customerWrapper);
                
                //If we received a response with an empty errors list continue
                if (customerWrapper != null && customerWrapper.Errors != null && customerWrapper.Errors.isEmpty() == true) {
                    //If we retrieved consumers, update those consumers in Salesforce
                    
                    if(customerWrapper != null && 
                       customerWrapper.Result != null && 
                       customerWrapper.Result.consumers != null && 
                       !customerWrapper.Result.consumers.isEmpty())
                        //changed to further checks on data coming from kh
                        //if (!customerWrapper.Result.consumers.isEmpty()) 
                    {
                        CEMS_CustomerData_Wrapper.Consumers consumer = customerWrapper.Result.consumers[0];
                        System.debug('This is the membership list :::' + consumer.memberships);
                        //start: care-675    
                        String updateResponse;
                        Boolean clearCRFieldValue = false;
                        //If we have memberships returned to us, update or add those memberships
                        if (consumer.memberships != null) {
                            if (!consumer.memberships.isEmpty()) {
                                List<CEMS_CustomerData_Wrapper.Memberships> memberships = consumer.memberships;
                                updateResponse = pageController.addSubscriptions(memberships, personAccount, false);
                            }
                            else{
                                //double check if the SF consumer also doesn't have any CR members
                                //Delete those caretools subscriptions records
                                List<Subscription__c> SFOnlySubList = [SELECT Id, Status__c, Consumer__c,Subscription__c.Consumer__r.CID__c, Subscription_Id__c FROM Subscription__c 
                                                                       WHERE Consumer__c = :personAccount.Id];
                                System.debug('SFOnlySubLis === '+SFOnlySubList);
                                if (!SFOnlySubList.isEmpty()){
                                    deleteConsumerSubs(SFOnlySubList,personAccount);  
                                    if(personAccount.Crown_Rewards_Number__c != '')
                                        clearCRFieldValue = true;
                                }
                                //Naeem: start care-817 Move membership
                                else{
                                    if (String.isNotBlank(personAccount.Crown_Rewards_Number__c)) 
                                        clearCRFieldValue = true;
                                }
                                //Naeem: end care-817 Move membership
                                
                            }
                            
                        }
                        system.debug('?????');
                        //Start-Add H+ membership data-VRaghava
                        if (consumer.hPlusMembership != null) {
                            if (!consumer.hPlusMembership.isEmpty()) {
                                List<CEMS_CustomerData_Wrapper.hPlusMembership> hPlusMemberships = consumer.hPlusMembership;
                                string shared =consumer.hPlusSharedIdentity;
                                string crnumber =' ';
                                system.debug('?????');
                                
                                if ( !consumer.memberships.isEmpty()&& ! String.isBlank(consumer.memberships[0].id)){ 
                                    system.debug('?????2');
                                    crnumber = consumer.memberships[0].id;
                                    system.debug('?????3');
                                }
                                system.debug('?????4');
                                CEMS_CustomerData_Wrapper.AlternateId primaryAlternateId =
                                    getPrimaryAlternateId(consumer);
                                if(primaryAlternateId != null && primaryAlternateId.hPlusMembership != null && primaryAlternateId.hPlusMembership.uuid != null) {
                                    //Start: Naeem-Care-2147
                                    updateResponse = pageController.addhPlusmemships(hPlusMemberships, String.valueOf(primaryAlternateId.hPlusMembership.uuid),
                                                                                     personAccount, false,shared,crnumber);
                                    //End: Naeem-Care-2147
                                    
                                }
                            }
                            else{
                                //double check if the SF consumer also doesn't have any CR members
                                //Delete those caretools subscriptions records
                                List<Hallmarkplus__c> SFOnlyhplusList = [SELECT Id FROM Hallmarkplus__c 
                                                                         WHERE Accountid__c  = :personAccount.Id];
                                if (!SFOnlyHplusList.isEmpty()) {
                                    
                                    
                                    // Delete the records from Salesforce
                                    try {
                                        delete SFOnlyHplusList;
                                    } catch (DmlException e) {
                                        
                                        System.debug('Failed to delete Hallmarkplus__c records: ' + e.getMessage());
                                    }
                                }
                                
                            }
                        }
                        //End-Add H+ membership data-VRaghava
                        
                        
                        //Determine our Salesforce record updates based on the returned CEMS consumer record and make those updates
                        System.debug('Desearlized JSON Result ::: ' + customerWrapper);
                        System.debug('Consumer Id we found is ::: ' + consumer.consumerId);
                        updateResponse = pageController.determineRecordUpdates(personAccount, customerWrapper, clearCRFieldValue);
                        system.debug('??updateResponse'+updateResponse);
                        //End: care-675    
                        return updateResponse;
                    }
                } else if (customerWrapper.Errors != null && customerWrapper.Errors[0].ErrorCode == '404') {
                    //If we were unable to match on the CID and received a 404 not found error code we know a merge must have occured
                    responseMsg = 'Merge';
                    return responseMsg;
                } else {
                    //If we did receive errors, continue
                    //If we receieved errors, log those errors in the CEMS_Update_Failures object.
                    if(customerWrapper.Errors != null){
                        for (CEMS_CustomerData_Wrapper.Errors err : customerWrapper.Errors) {
                            responseMsg += 'The error code is: ' + err.ErrorCode + ' - The error message returned was: ' + err.ErrorMessage + ' ';
                        }
                        pageController.logCEMSFailure(personAccount, responseMsg, 'GET');
                    }
                    return responseMsg;

                }
            } else {
                //If we don't have a consumer id, inform the agent
                responseMsg = 'The consumer record is missing a Consumer ID (CID). Please fill it out and then try saving again.';
                return responseMsg;
            }
        } else {
            //If we for some reason can't get the consumer record in the controller, inform the agent.
            responseMsg = 'No consumer found in our Salesforce database matches the Id passed. Please try reloading the page.';
            return responseMsg;
        }
        
        return responseMsg;
    }
    
    //Method is used to attempt to find suitable records to merge with the current Salesforce record with a record in CCDB in the event that Salesforce has a CID for the
    //consumer but no result is returned from CCDB.
    @AuraEnabled
    public static List<CEMS_ConsumerMerge> potentialMergeRecords(String acctId) {
        List<CEMS_ConsumerMerge> consumersForMerge = null;
        if (acctId != null) {           
            List<Account> acctsFound = [SELECT Id, PersonHomePhone, Mailing_Zip_Postal_Code__c, Crown_Rewards_Number__c, PersonMobilePhone, FirstName, LastName, PersonEmail    FROM Account WHERE isPersonAccount = TRUE AND Id = :acctId  LIMIT 1];
            
            //Crae-792-Start
            if (!acctsFound.isEmpty()) { 
                Account acctToPass = new Account();
                acctToPass = acctsFound[0];
                
                /*if (acctsFound[0].LastName != null && acctsFound[0].Mailing_Zip_Postal_Code__c != null) 
{                   
acctToPass.LastName = acctsFound[0].LastName;                   
acctToPass.Mailing_Zip_Postal_Code__c = acctsFound[0].Mailing_Zip_Postal_Code__c;
} 
else {                   
acctToPass = acctsFound[0];
}  */
                //End-Care-792
                system.debug('??acctToPass'+acctToPass);
                if(Test.isRunningTest()){
                    CEMS_ConsumerMerge CEMS_ConsumerMerge12 = new CEMS_ConsumerMerge();
                    CEMS_ConsumerMerge12.Id = '12312312';
                    CEMS_ConsumerMerge12.CID = '1212312312';
                    CEMS_ConsumerMerge12.firstName = 'asads';
                    CEMS_ConsumerMerge12.lastName = 'qwqwq';
                    CEMS_ConsumerMerge12.phone = null;
                    CEMS_ConsumerMerge12.mobilePhone = '1231231122';
                    CEMS_ConsumerMerge12.email = 'asdasdas@asdas.com';
                    CEMS_ConsumerMerge12.memberId = '1231111222';
                    CEMS_ConsumerMerge12.postalCode = '12311';
                    CEMS_ConsumerMerge12.source = 'salesforce';
                    List<CEMS_ConsumerMerge> consumersForMergeList  = new List<CEMS_ConsumerMerge>();
                    consumersForMergeList.add(CEMS_ConsumerMerge12);
                    consumersForMerge = consumersForMergeList;
                }else{            
                    consumersForMerge = CEMS_Find_Consumer.checkSalesforce(acctToPass, acctId); 
                }
                
                //               consumersForMerge = CEMS_Find_Consumer.checkSalesforce(acctToPass, acctId); 
                system.debug('??consumersForMerge'+consumersForMerge);
                return consumersForMerge;
            }
        }      
        return consumersForMerge;
    }
    
    //Method is utilized to actually perform the merging of two consumer records
    //13/12/2022 - Adeel - Updating Merge Functionality (CARE-245).
    @AuraEnabled
    public static String mergeRecords(String acctId, Account personAcct) {        if (acctId != null && personAcct != null) {
        try {                List<Account> acctsFound = new List<Account>();
             System.debug('This is the CID ::: ' + personAcct.CID__c + ' ::: This is the Id ::: ' + personAcct.Id);
             if (String.isNotBlank(personAcct.CID__c)) {                                     acctsFound = [SELECT Id, FirstName, LastName FROM Account WHERE CID__c = :personAcct.CID__c LIMIT 1];
                                                       } else if (String.isNotBlank(personAcct.Id)) {                    
                                                           acctsFound = [SELECT Id, FirstName, LastName FROM Account WHERE Id = :personAcct.Id LIMIT 1];
                                                       }
             
             System.debug('Account to merge with ::: ' + personAcct + ' ::: acct to merge ::: ' + acctsFound);
             if (acctsFound.isEmpty()) {
                 System.debug('No accounts found, creating a new account ::: ');
                 Database.DMLOptions dml = new Database.DMLOptions();                    
                 dml.DuplicateRuleHeader.AllowSave = true;
                 database.insert(personAcct, dml);
                 System.debug('This is the new account id ::: ' + personAcct.Id + ' ::: this is the old account id ::: ' + acctId);
                 database.merge(personAcct, acctId);                   
                 personAcct.CallGuid__c = personAcct.CallGuid__c;
                 update personAcct;
                 return personAcct.Id;
             } else {
                 database.merge(acctsFound[0], acctId);                                                                                                                                                                                                                                                                                                                                                                         
                 acctsFound[0].CallGuid__c = personAcct.CallGuid__c;                    
                 update acctsFound[0];
                 return acctsFound[0].Id;
             }
            } catch (Exception e) {                Universal_Error_Logger.auraGenerateErrorLog(                    'There was an error merging the consumer records',                    'CEMS_GET_Component',                    e.getMessage(),                    e.getStackTraceString(),                    acctId                );                return null;
                                  }
    } else {            return null;
           }
                                                                         }
    
    //This method is utilized to determine the updates that must be made to a record based on information retrieved from CEMS.
    //It compares the CEMS JSON response to the internal SF record and makes changes to any field that has a non-matching value.
    private String determineRecordUpdates(Account personAccount, CEMS_CustomerData_Wrapper cemsData, Boolean clearCRFieldValue) {
        Account pAcct = [
            SELECT
            Id,
            PersonEmail,
            FirstName,
            LastName,
            MiddleName,
            //care-808
            Address_Line_1__c,
            Address_Line_2__c,
            Mailing_Country__c,
            //PersonMailingCity,
            Mailing_City__c,
            Mailing_State_Province__c,
            Mailing_Zip_Postal_Code__c,
            Crown_Rewards_Number__c,
            Market_via_Email__c,
            //care-134 Enable email Fields
            Email_Last_Provided__c, 
            Email_Consent_Provided__c,
            Last_Failed_Email_Attempt__c, 
            Failed_Email_Attempts__c, 
            //care-726
            Shared_Email__c,
            
            Email_Subsidiary_Opt_In__c,
            //Care-565 Enable Preferred Phone Opt Fields from CCDB
            Market_via_Preferred_Phone__c,
            Preferred_Phone_Consent_Provided_Date__c,
            //Care-564 Enable Preferred mail Opt Fields from CCDB
            Postal_Undeliverable__c,
            Postal_Consent_Provided_Date__c,
            Market_via_Postal_Mail__c,
            //End-Care-564 Enable Preferred mail Opt Fields from CCDB
            ////Care-CARE-1356
            UUID__c,
            //CARE-1356
            //Care-2130
            Hallmarkplus__c,
            //End Care-2130
            Postal_Opt_In__c,
            Share_Postal_Address_with_Subs__c,
            Share_Postal_Address_with_3rd_Parties__c,
            PersonBirthdate,
            Gender__c,
            Decesased__c,
            PersonHomePhone,
            PersonMobilePhone,
            Market_via_Text__c,
            CID__c,
            Text_Consent_Provided_Date__c,
            Hallmark_Account_Id__c
            FROM Account
            WHERE isPersonAccount = TRUE AND Id = :personAccount.Id
            LIMIT 1
        ];
        //Birth_Month__pc,
        //Birth_Day__pc,
        
        System.debug('I at least called the updates method ::: ');
        System.debug('The zip code is ::: ' + pAcct.Mailing_Zip_Postal_Code__c);
        Boolean updateMade = false;
        Boolean CIDupdateMade = false;
        String updateResponse = 'No Update';
        String oldCID= pAcct.CID__c;
        String newCID= pAcct.CID__c;
        
        CEMS_CustomerData_Wrapper.Consumers consumer = cemsData.Result.consumers[0];
        
        //CID would only change in the event of a merge
        if (pAcct.CID__c != consumer.consumerId) {
            oldCID = pAcct.CID__c;
            newCID = consumer.consumerId;
            pAcct.CID__c = consumer.consumerId;
            
            updateMade = true;
            CIDupdateMade = true;
        }
        
        //Start: care-675
        if(clearCRFieldValue){            pAcct.Crown_Rewards_Number__c = null;            updateMade = true;
                             }
        //End: care-675    
        
        
        //Checking for updates to the consumers name
        if (consumer.name != null) {
            if (pAcct.FirstName != consumer.name.firstName) {
                pAcct.FirstName = consumer.name.firstName;
                updateMade = true;
            }
            
            if (pAcct.LastName != consumer.name.lastName) {
                pAcct.LastName = consumer.name.lastName;
                updateMade = true;
            }
            
            if (pAcct.MiddleName != consumer.name.middleInitial) {
                pAcct.MiddleName = consumer.name.middleInitial;
                updateMade = true;
            }
        }
        
        System.debug('This is the address object found ::: ' + consumer.address);
        //Checking for updates to the consumers address
        if (consumer.address != null) {
            //care-808
            //String cemsAddress = consumer.address.addressLine1 + ' ' + consumer.address.addressLine2;
            if (
                pAcct.Address_Line_1__c != consumer.address.addressLine1
                //&&
                // (consumer.address.country == 'USA' ||
                //consumer.address.country == 'CAN')
            ) {
                pAcct.Address_Line_1__c = consumer.address.addressLine1;
                updateMade = true;
            }
            if (
                pAcct.Address_Line_2__c != consumer.address.addressLine2 
                //&&
                // (consumer.address.country == 'USA' ||
                //consumer.address.country == 'CAN')
            ) {
                pAcct.Address_Line_2__c = consumer.address.addressLine2;
                updateMade = true;
            }
            
            if (consumer.address.country == 'USA' && pAcct.Mailing_Country__c != 'US') {                pAcct.Mailing_Country__c = 'US';                updateMade = true;
                                                                                                           }
            if (consumer.address.country == 'CAN' && pAcct.Mailing_Country__c != 'CA') {                pAcct.Mailing_Country__c = 'CA';                updateMade = true;
                                                                                                           }
            if (consumer.address.country == 'ZZ' && pAcct.Mailing_Country__c != 'ZZ') {                pAcct.Mailing_Country__c = 'ZZ';                updateMade = true;
                                                                                                           }
            
            
            if (
                consumer.address.zip != null &&
                consumer.address.zip != '' &&
                pAcct.Mailing_Zip_Postal_Code__c != consumer.address.zip 
                //&&
                //(consumer.address.country == 'USA' ||
                //consumer.address.country == 'CAN')
            ) {
                string zipCode = consumer.address.zip;
                if(zipCode.length() < 10){
                    pAcct.Mailing_Zip_Postal_Code__c = consumer.address.zip;
                    updateMade = true;    
                } 
            }
            
            if (
                pAcct.Mailing_State_Province__c != consumer.address.state 
                //&&
                //(consumer.address.country == 'USA' ||
                //consumer.address.country == 'CAN')
            ) {
                pAcct.Mailing_State_Province__c = consumer.address.state;
                updateMade = true;
            }
            
            //care-808
            /*
if (
pAcct.PersonMailingCity != consumer.address.city &&
(consumer.address.country == 'USA' ||
consumer.address.country == 'CAN')
) {
pAcct.PersonMailingCity = consumer.address.city;
updateMade = true;
}*/
            
            if (
                pAcct.Mailing_City__c != consumer.address.city 
                //&&
                //(consumer.address.country == 'USA' ||
                //consumer.address.country == 'CAN')
            ) {
                pAcct.Mailing_City__c = consumer.address.city;
                updateMade = true;
            }
            
            
            if (consumer.address.optIns != null) {
                Boolean khPostalOptIn = Boolean.valueOf(consumer.address.optIns.postalOptIn);
                Boolean khSubsidiaryMailOptIn = Boolean.valueOf(consumer.address.optIns.subsidiaryMailOptIn);
                Boolean khThirdPartyMailOptIn = Boolean.valueOf(consumer.address.optIns.thirdPartyMailOptIn);
                
                System.debug('This is the postal mail OptIn from CEMS ::: ' + Boolean.valueOf(consumer.address.optIns.postalOptIn));
                System.debug('This is the postal mail OptIn from SF ::: ' + pAcct.Postal_Opt_In__c);
                
                if (pAcct.Postal_Opt_In__c != khPostalOptIn) {                
                    pAcct.Postal_Opt_In__c = khPostalOptIn;                
                    System.debug('This is the postal OptIn in SF after update ::: ' + pAcct.Postal_Opt_In__c);                
                    updateMade = true;
                }
                
                //Care-564 Enable Preferred mail Opt Fields from CCDB
                if (pAcct.Market_via_Postal_Mail__c != khPostalOptIn) {                
                    pAcct.Market_via_Postal_Mail__c = khPostalOptIn;                
                    System.debug('??This is the market via postal mail in SF after update ::: ' + pAcct.Market_via_Postal_Mail__c);                                
                    updateMade = true;
                }
                
                if (pAcct.Postal_Consent_Provided_Date__c != consumer.address.optIns.postalOptCaptureDate) {                
                    pAcct.Postal_Consent_Provided_Date__c = consumer.address.optIns.postalOptCaptureDate;                
                    System.debug('??This is the PPostal Consent Date in SF after update ::: ' + pAcct.Postal_Consent_Provided_Date__c);                                
                    updateMade = true;
                }

                System.debug('This is the sub mail OptIn from SF ::: ' + pAcct.Share_Postal_Address_with_Subs__c);
                
                if (pAcct.Share_Postal_Address_with_Subs__c != khSubsidiaryMailOptIn) {
                    pAcct.Share_Postal_Address_with_Subs__c = khSubsidiaryMailOptIn;
                    System.debug('This is the sub mail OptIn in SF after update ::: ' + pAcct.Share_Postal_Address_with_Subs__c);
                    
                    updateMade = true;
                }
                
                System.debug(
                    'This is the third mail OptIn from CEMS::: ' + Boolean.valueOf(consumer.address.optIns.thirdPartyMailOptIn)
                );
                System.debug('This is the third mail OptIn from SF ::: ' + pAcct.Share_Postal_Address_with_3rd_Parties__c);
                
                if (pAcct.Share_Postal_Address_with_3rd_Parties__c != khThirdPartyMailOptIn) {
                    pAcct.Share_Postal_Address_with_3rd_Parties__c = khThirdPartyMailOptIn;
                    System.debug('This is the 3rd party mail OptIn in SF after update ::: ' + pAcct.Share_Postal_Address_with_3rd_Parties__c);
                    
                    updateMade = true;
                }
                System.debug('??This is the consent prov date from SF ::: ' + pAcct.Postal_Consent_Provided_Date__c);
                Boolean addrsavlbl;
                if(consumer.address.addrSts =='INACTIVE' )                
                    addrsavlbl =True;
                else
                    addrsavlbl =False;
                
                if (pAcct.Postal_Undeliverable__c != Boolean.valueOf(addrsavlbl)) {
                    pAcct.Postal_Undeliverable__c = Boolean.valueOf(addrsavlbl);
                    System.debug('??This is the Postal undeliverable in SF after update ::: ' + pAcct.Postal_Undeliverable__c);
                    updateMade = true;
                }
            }
            //End-Care-564 Enable Preferred mail Opt Fields from KH API
        }
        
        //Checking for any updates to the consumers phone numbers
        if(consumer.phone != null) {
            
            System.debug('This is the phone object found ::: ' + consumer.phone);
            if (pAcct.PersonHomePhone != null) {
                if (pAcct.PersonHomePhone.replaceAll('\\D', '') != String.valueOf(consumer.phone.homeNumber)) {
                    pAcct.PersonHomePhone = String.valueOf(consumer.phone.homeNumber);
                    updateMade = true;
                }
            } else {                pAcct.PersonHomePhone = String.valueOf(consumer.phone.homeNumber);                updateMade = true;
                   }
            
            if (pAcct.PersonMobilePhone != null && pAcct.PersonMobilePhone.replaceAll('\\D', '') != String.valueOf(consumer.phone.mobileNumber)) {
                pAcct.PersonMobilePhone = String.valueOf(consumer.phone.mobileNumber);
                updateMade = true;
            } else {                pAcct.PersonMobilePhone = String.valueOf(consumer.phone.mobileNumber);                updateMade = true;
                   }
            
            if (consumer.phone.optIns != null) {
                Boolean khPhoneOptIn = Boolean.valueOf(consumer.phone.optIns.phoneOptIn);
                Boolean khSmsOptIn = Boolean.valueOf(consumer.phone.optIns.smsOptIn);
                //Care-565 Enable Preferred Phone Opt Fields from CCDB
                System.debug('This is the phone OptIn from SF ::: ' + pAcct.Market_via_Preferred_Phone__c);
                
                if (pAcct.Market_via_Preferred_Phone__c != khPhoneOptIn) {
                    pAcct.Market_via_Preferred_Phone__c = khPhoneOptIn;
                    System.debug('This is the Phone OptIn in SF after update ::: ' + pAcct.Market_via_Preferred_Phone__c);
                    updateMade = true;
                }
                //Preferred_Phone_Consent_Provided_Date__c
                if (pAcct.Preferred_Phone_Consent_Provided_Date__c != consumer.phone.optIns.phoneOptCaptureDate) {
                    pAcct.Preferred_Phone_Consent_Provided_Date__c = consumer.phone.optIns.phoneOptCaptureDate;
                    updateMade = true;
                }                
                if (pAcct.Market_via_Text__c != khSmsOptIn) {
                    pAcct.Market_via_Text__c = khSmsOptIn;
                    System.debug('This is the SMS OptIn in SF after update ::: ' + pAcct.Market_via_Text__c);                
                    updateMade = true;
                }
            }
            if (!String.isBlank(consumer.phone.optIns.smsOptCaptureDate)) {
                String smsOptCaptureDate = String.valueOf(consumer.phone.optIns.smsOptCaptureDate).split(' ')[0];
                System.debug('smsOptCaptureDate ::: ' + smsOptCaptureDate );
                if ( pAcct.Text_Consent_Provided_Date__c  != smsOptCaptureDate) {
                    pAcct.Text_Consent_Provided_Date__c  = smsOptCaptureDate;
                    System.debug('This is the SMS OptIn in SF after update ::: ' + pAcct.Text_Consent_Provided_Date__c );
                    updateMade = true;
                }    
            }else{
                pAcct.Text_Consent_Provided_Date__c = '';                updateMade = true;
            }
            
            
        }//Ending if(consumer.phone != null) 
        
        
        if (consumer.hPlusMembership == null ||
            consumer.hPlusMembership.size() == 0
           ){
               pAcct.UUID__c = null;
               pAcct.Hallmarkplus__c = false;
               System.debug('??This is the uuid from SF ::: ' + pAcct.UUID__c);
               System.debug('??This is the Hallmark+ checkbox from SF ::: ' + pAcct.Hallmarkplus__c);
               updateMade = true;
           }
        //care-1914
        //
        //CARE-1356--uuid_c
        System.debug('This is the uuid from SF ::: ' + pAcct.UUID__c);
        CEMS_CustomerData_Wrapper.AlternateId primaryAlternateId =
            getPrimaryAlternateId(consumer);
        if(primaryAlternateId != null && primaryAlternateId.hPlusMembership != null && primaryAlternateId.hPlusMembership.uuid != null){
            if (consumer.hPlusMembership != null &&
                consumer.hPlusMembership.size() > 0 && pAcct.UUID__c != String.valueOf(primaryAlternateId.hPlusMembership.uuid)) 
            {
                //Naeem-Care-2147
                pAcct.UUID__c = String.valueOf(primaryAlternateId.hPlusMembership.uuid);
                System.debug('??This is the uuid from SF ::: ' + pAcct.UUID__c);
                updateMade = true;
            }
            
        }
        //CARE-1356--uuid_c
        
        System.debug('This is the email object found ::: ' + consumer.email);
        //Checking for an update to the consumers email address
        if (consumer.email != null) {
            if (pAcct.PersonEmail != consumer.email.address) {
                pAcct.PersonEmail = consumer.email.address;
                updateMade = true;
            }
            
            System.debug('This is the Email OptIn from CEMS ::: ' + Boolean.valueOf(consumer.email.optIns.optIn));
            System.debug('This is the Email OptIn from SF ::: ' + pAcct.Email_Subsidiary_Opt_In__c);
            
            if (pAcct.Market_via_Email__c != Boolean.valueOf(consumer.email.optIns.optIn)) {
                pAcct.Market_via_Email__c = Boolean.valueOf(consumer.email.optIns.optIn);
                System.debug('This is the Email OptIn in SF after update ::: ' + pAcct.Market_via_Email__c);
                
                updateMade = true;
            }
            
            System.debug('This is the Email Sub OptIn from CEMS ::: ' + Boolean.valueOf(consumer.email.optIns.subsidiaryOptIn));
            System.debug('This is the Email Sub OptIn from SF ::: ' + pAcct.Email_Subsidiary_Opt_In__c);
            
            if (pAcct.Email_Subsidiary_Opt_In__c != Boolean.valueOf(consumer.email.optIns.subsidiaryOptIn)) {
                pAcct.Email_Subsidiary_Opt_In__c = Boolean.valueOf(consumer.email.optIns.subsidiaryOptIn);
                System.debug('This is the Email Subs OptIn in SF after update ::: ' + pAcct.Email_Subsidiary_Opt_In__c);
                
                updateMade = true;
            }
            
            //care-134 Enable email Fields
            if (pAcct.Email_Last_Provided__c != consumer.email.lastCaptureDate) {
                pAcct.Email_Last_Provided__c = consumer.email.lastCaptureDate;
                updateMade = true;
            }
            if (pAcct.Email_Consent_Provided__c != consumer.email.lastCaptureDate) {
                pAcct.Email_Consent_Provided__c = consumer.email.lastCaptureDate;
                updateMade = true;
            }
            //Naeem: care-1443 
            Integer KH_hardBounceCount;
            if(consumer.email.hardBounceCount != null)
                KH_hardBounceCount = Integer.valueOf(consumer.email.hardBounceCount); 
            else
                KH_hardBounceCount = null; 
            
            if (pAcct.Failed_Email_Attempts__c != true &&
                ( KH_hardBounceCount != null && KH_hardBounceCount > 0)
               ) 
            {
                pAcct.Failed_Email_Attempts__c = true;                updateMade = true;            
            }
            
            if (pAcct.Failed_Email_Attempts__c != false &&
                (KH_hardBounceCount == 0 ||   KH_hardBounceCount == null)
               ) 
            {
                pAcct.Failed_Email_Attempts__c = false;                updateMade = true;            
            }
            
            //Start: care-726 enabled sharedEmail indicator            
            if(consumer.email != null && consumer.email.sharedEmail != null) 
            {
                if (pAcct.Shared_Email__c != true && consumer.email.sharedEmail == 'Y') 
                {
                    pAcct.Shared_Email__c = true;                					updateMade = true;            
                }
                if (pAcct.Shared_Email__c != false && consumer.email.sharedEmail == 'N') 
                {
                    pAcct.Shared_Email__c = false;                					updateMade = true;            
                }
            }else{
                if (pAcct.Shared_Email__c != false) 
                {
                    pAcct.Shared_Email__c = false;                                    updateMade = true;            
                }
            }
            //End: care-726 enabled sharedEmail indicator
            
            
            
            if (pAcct.Last_Failed_Email_Attempt__c != consumer.email.lastHardBounceDt) {
                pAcct.Last_Failed_Email_Attempt__c = consumer.email.lastHardBounceDt;
                updateMade = true;
            }       
        }//End of if (consumer.email != null
        else{
            // If KH email is null, clear SF email instead of using String.valueOf(consumer.email).
            if (pAcct.PersonEmail != null) {
                pAcct.PersonEmail = null;
                updateMade = true;
            }
            
            if (pAcct.Shared_Email__c != false) {
                pAcct.Shared_Email__c = false;
                updateMade = true;
            }
        }
        
        //pAcct.Last_Failed_Email_Attempt__c = 'tyest  112';
        
        
        
        //Checking for birthday updates
        // Birthday updates.
        if (!String.isBlank(consumer.dateOfBirth)) {
            if (consumer.dateOfBirth.length() == 8) {
                Date birthdayCEMSTransformer = Date.newInstance(
                    Integer.valueOf(consumer.dateOfBirth.substring(4, 8)),
                    Integer.valueOf(consumer.dateOfBirth.substring(0, 2)),
                    Integer.valueOf(consumer.dateOfBirth.substring(2, 4))
                );
                
                if (pAcct.PersonBirthdate != birthdayCEMSTransformer) {
                    pAcct.PersonBirthdate = birthdayCEMSTransformer;
                    updateMade = true;
                }
            }
        } else if (pAcct.PersonBirthdate != null) {
            pAcct.PersonBirthdate = null;
            updateMade = true;
        }
    
        //Care-566 Enable Decesased field
        if (pAcct.Decesased__c != null && consumer.deceased != null) {
            pAcct.Decesased__c = consumer.deceased;
            updateMade = true;
        }
        
        //Comparing the gender in CCDB to the gender in Salesforce. We need to transform some SF data to be able to accurately match
        String khGender;
        if (!String.isBlank(consumer.gender)) {
            if (consumer.gender.equalsIgnoreCase('M')) {
                khGender = 'Male';
            } else if (consumer.gender.equalsIgnoreCase('F')) {
                khGender = 'Female';
            }
        }
        
        if (!String.isBlank(khGender) && pAcct.Gender__c != khGender) {
            pAcct.Gender__c = khGender;
            updateMade = true;
        }
        
        //Raghav - Care-2290 setting Hallmark.com account Id in Care
        CEMS_CustomerData_Wrapper.AlternateId accountAlternateId =
            getPrimaryAlternateId(consumer);
        if (accountAlternateId != null && String.isNotBlank(accountAlternateId.val)) {
			pAcct.Hallmark_Account_Id__c = accountAlternateId.val;
            updateMade = true;
        }
        //If an update was made at any point, update the person account record.
        if (updateMade) {
            System.debug('Updating Record ::: ');
            //pAcct.isUpdatingRecord__c = true;
            Savepoint sp = Database.setSavepoint();
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            
            try {
                System.debug('This is the account we made ::: ' + pAcct);
                database.update(pAcct, dml);

                
                Boolean newCIDFoundOnAnotherLocalConsumer = false;
                if(CIDupdateMade){
                    //Create a consumer history record, for CID update
                    CareConsumerMergeUtility.addConsumerHistoryRecord(pAcct.Id, pAcct.Id, newCID, oldCID);
                    
                    //Check if the new CID already exists on some other consumer, if Yes, then merge that consumer with this one  
                    CareConsumerMergeUtility.checkConsumerCIDMerge(pAcct, oldCID, newCID); 
                }else{
                    //check if current CID is found on the other consumer, if yes, then lets merge that consumer.
                    List<Account> existingDupConsumerFound = [Select id, name, CID__c From Account Where CID__c = :newCID AND Id !=:pAcct.Id ];
                    
                    if (existingDupConsumerFound.size() > 0) { 
                        newCIDFoundOnAnotherLocalConsumer = true;
                        CareConsumerMergeUtility.checkConsumerCIDMerge(pAcct, oldCID, newCID); 
                        
                    }
                }
                
                
                
                
                // update pAcct;
            } catch (Exception e) {
                System.debug(
                    'An error has occured. It was ::: ' +
                    e.getMessage() +
                    ' ::: It occurred at the following location ::: ' +
                    e.getStackTraceString()
                );
                updateResponse = 'There was an error updating the record. The error was: ' + e.getMessage();                Database.rollback(sp);
                return updateResponse;
            }
            
            updateResponse = 'Update';
            return updateResponse;
        }
        
        System.debug('Returning update value of ::: ' + updateMade + ' And update response was ::: ' + updateResponse);
        
        return updateResponse;
    }
    
     //Method utilized to update or insert a consumer record in CCDB
    @AuraEnabled
    public static String updateOrInsertConsumer(String acctId, Boolean isInsert, Boolean logError, String changedFields) {
        String responseMsg = null;
        System.debug('updateOrInsertConsumer changedFields :::'+changedFields);
        if(changedFields == null)
            changedFields='';        
        //If the account Id was passed successfully, continue
        if(String.isNotBlank(acctId)) {
            List<Account> personAcct = [
                SELECT
                Id,
                PersonEmail,
                FirstName,
                LastName,
                MiddleName,
                //care-808
                Mailing_Country__c,
                Address_Line_1__c,
                Address_Line_2__c,
                Mailing_City__c,
                Mailing_State_Province__c,
                Mailing_Zip_Postal_Code__c,
                
                Crown_Rewards_Number__c,
                Market_via_Email__c,
                Failed_Email_Attempts__c,
                Email_Subsidiary_Opt_In__c,
                //Care-565 Enable Preferred Phone Opt Fields from CCDB
                Market_via_Preferred_Phone__c,
                Preferred_Phone_Consent_Provided_Date__c,
                //Care-564 Enable Preferred mail Opt Fields from CCDB
                Postal_Undeliverable__c,
                Postal_Consent_Provided_Date__c,
                Market_via_Postal_Mail__c,
                //End-Care-564 Enable Preferred mail Opt Fields from CCDB
                Postal_Opt_In__c,
                Share_Postal_Address_with_Subs__c,
                Share_Postal_Address_with_3rd_Parties__c,
                PersonBirthdate,
                Gender__c,
                Decesased__c,
                PersonHomePhone,
                PersonMobilePhone,
                Market_via_Text__c,
                CID__c,
                Text_Consent_Provided_Date__c
                FROM Account
                WHERE Id = :acctId AND isPersonAccount = TRUE
                LIMIT 1
            ];

            
            
            if (!personAcct.isEmpty()) {
                System.debug('This is the zip code ::: ' + personAcct[0].Mailing_Zip_Postal_Code__c);
                
                //If we're inserting or if we're updating and have a CID attached to the person account record, continue
                if (isInsert || (!isInsert && personAcct[0].CID__c != null)) {
                    //We're creating a new CEMSConsumerRecord to utilize for the body of the httprequest we send to CEMS
                    CEMS_Consumer_Record consumer = new CEMS_Consumer_Record();
                    
                    //Start setting up body of httprequest                    
                    if(isInsert == false && changedFields.contains('FirstName'))
                        consumer.FirstName = personAcct[0].FirstName;
                    else if (isInsert == true)
                        consumer.FirstName = personAcct[0].FirstName;
                    
                    //Have to transform middle name data to be what CCDB expects
                    if (String.isNotBlank(personAcct[0].MiddleName)) {
                        if(isInsert == false && changedFields.contains('MiddleName')) 
                            consumer.MiddleInitial = personAcct[0].MiddleName.substring(0, 1);
                        else if (isInsert == true)
                            consumer.MiddleInitial = personAcct[0].MiddleName.substring(0, 1);
                    }else if(personAcct[0].MiddleName == null && isInsert == false && changedFields.contains('MiddleName')){
                        //Raghav - care 2442 ability to clear middlename by care users
                        consumer.MiddleInitial = '';
                    }                    
                    
                    if(isInsert == false && changedFields.contains('LastName'))
                        consumer.LastName = personAcct[0].LastName;
                    else if (isInsert == true)
                        consumer.LastName = personAcct[0].LastName;
                    
                    //care-808
                    //postal changes
                    String addrsavlbl;
                    Boolean isBlank = True;
                    if( personAcct[0].Postal_Undeliverable__c == false )
                    {
                        addrsavlbl ='ACTIVE';
                    }
                    else{                        addrsavlbl ='INACTIVE';
                        }
                    if(changedFields.contains('Address_Line_1__c') ||
                       changedFields.contains('Address_Line_2__c') ||
                       changedFields.contains('Mailing_City__c') ||
                       changedFields.contains('Mailing_State_Province__c') ||
                       changedFields.contains('Mailing_Country__c') ||
                       changedFields.contains('Mailing_Zip_Postal_Code__c')||
                       //Postal
                       changedFields.contains('Market_via_Postal_Mail__c') ||
                       changedFields.contains('Postal_Undeliverable__c') 
                      ){
                          if (personAcct[0].Mailing_Country__c != null &&
                              personAcct[0].Address_Line_1__c != null &&
                              personAcct[0].Mailing_State_Province__c != null &&
                              personAcct[0].Mailing_City__c != null &&
                              personAcct[0].Mailing_Zip_Postal_Code__c != null
                              
                             ) {
                                 
                                 //We have to transform the country to match CCDB's required 3 character USA country code. Only USA is accepted at this time. No other countries.
                                 if (personAcct[0].Mailing_Country__c.equalsIgnoreCase('Canada') ||
                                     personAcct[0].Mailing_Country__c.equalsIgnoreCase('CA') ||
                                     personAcct[0].Mailing_Country__c.equalsIgnoreCase('CAN')
                                    ){
                                        consumer.Country = 'CAN';   
                                        consumer.State = personAcct[0].Mailing_State_Province__c;
                                        consumer.AddressLine1 = personAcct[0].Address_Line_1__c;
                                        consumer.AddressLine2 = personAcct[0].Address_Line_2__c;
                                        consumer.City = personAcct[0].Mailing_City__c;
                                        consumer.Zip = personAcct[0].Mailing_Zip_Postal_Code__c;
                                        consumer.PostalOptIn = personAcct[0].Market_via_Postal_Mail__c;
                                        consumer.AddressStatus = String.valueof(addrsavlbl);
                                        consumer.ValidateAddress =True;
                                        
                                    }else if (personAcct[0].Mailing_Country__c.equalsIgnoreCase('United States') ||
                                              personAcct[0].Mailing_Country__c.equalsIgnoreCase('US') || personAcct[0].Mailing_Country__c.equalsIgnoreCase('USA')) 
                                    {
                                        consumer.Country = 'USA';
                                        consumer.State = personAcct[0].Mailing_State_Province__c;
                                        consumer.AddressLine1 = personAcct[0].Address_Line_1__c;
                                        consumer.AddressLine2 = personAcct[0].Address_Line_2__c;
                                        consumer.City = personAcct[0].Mailing_City__c;
                                        consumer.Zip = personAcct[0].Mailing_Zip_Postal_Code__c;
                                        consumer.PostalOptIn = personAcct[0].Market_via_Postal_Mail__c;
                                        consumer.AddressStatus = String.valueof(addrsavlbl);
                                        consumer.ValidateAddress =True;
                                        
                                    }                        
                             }
                          
                          //Incase removal of all the fields, set everything null to KH (97717)
                          if(personAcct[0].Mailing_Country__c == null &&
                             personAcct[0].Address_Line_1__c == null &&
                             personAcct[0].Address_Line_2__c == null &&
                             personAcct[0].Mailing_State_Province__c == null &&
                             personAcct[0].Mailing_City__c == null &&
                             personAcct[0].Mailing_Zip_Postal_Code__c == null){ consumer.Country = '';
                                                                               consumer.State = '';
                                                                               consumer.AddressLine1 = '';
                                                                               consumer.AddressLine2 = '';
                                                                               consumer.City = '';
                                                                               consumer.Zip = '';
                                                                               consumer.AddressStatus = String.valueof(addrsavlbl);
                                                                              }
                          
                          
                      }
                    else 
                    {
                        consumer.AddressStatus = String.valueof(addrsavlbl);
                    }
                    
                    /*  Start COMMENTING AS PER CARE-661 if (personAcct[0].PersonMobilePhone != null) 
//We have to alter the format of the phone number in SF to match what CCDB expects to receive
if (personAcct[0].PersonMobilePhone != null) {
if(personAcct[0].PersonMobilePhone.length() >= 10){
if(isInsert == false && changedFields.contains('PersonMobilePhone'))
consumer.MobilePhone = personAcct[0].PersonMobilePhone.replaceAll('\\D', '');
else if (isInsert == true)
consumer.MobilePhone = personAcct[0].PersonMobilePhone.replaceAll('\\D', '');
}

}else{
if(isInsert == false && changedFields.contains('PersonMobilePhone')) consumer.MobilePhone = '';
}
End- */
                    
                    //Care-134 Enable the email fields
                    //when updating the email address, make sure the pass the current value of the 'Market via Email?', because updating the new value on the email 
                    //automatically opt-in the consumer to email unless the Salesforce user is updating the 'Email' and 'Market via Email?' fields together
                    if(isInsert == false && changedFields.contains('PersonEmail')){
                        if(!changedFields.contains('Market_via_Email__c')){
                            consumer.Email = personAcct[0].PersonEmail;
                            consumer.EmailOptIn = personAcct[0].Market_via_Email__c;
                        }
                        else
                            consumer.Email = personAcct[0].PersonEmail; 
                    }
                    else if (isInsert == true)
                        consumer.Email = personAcct[0].PersonEmail;
                    
                    //Care-134 Pass email along with emailOptin field value
                    if(isInsert == false && changedFields.contains('Market_via_Email__c') )
                    {
                        consumer.EmailOptIn = personAcct[0].Market_via_Email__c;                        consumer.Email = personAcct[0].PersonEmail;
                        system.debug('EmailOptIn::'+consumer.EmailOptIn);
                    }
                    else if (isInsert == true){
                        consumer.EmailOptIn = personAcct[0].Market_via_Email__c;
                        consumer.Email = personAcct[0].PersonEmail;
                        system.debug('EmailOptIn::'+consumer.EmailOptIn);
                    }

                    
                    
                    if(isInsert == false && changedFields.contains('Failed_Email_Attempts__c') && personAcct[0].Failed_Email_Attempts__c == false )
                    {
                        consumer.HardBounceCount = 0;                        consumer.Email = personAcct[0].PersonEmail;                        consumer.EmailOptIn = personAcct[0].Market_via_Email__c;
                        system.debug('consumer.HardBounceCount::'+consumer.HardBounceCount);
                    }
                    
                    //User should not insert the consumer record with this field
                    /*
else if (isInsert == true){
consumer.HardBounceCount = personAcct[0].Failed_Email_Attempts__c;
consumer.Email = personAcct[0].PersonEmail;
system.debug('consumer.HardBounceCount::'+consumer.HardBounceCount);
}*/
                    
                    
                    if(isInsert == false && changedFields.contains('Email_Subsidiary_Opt_In__c') ) consumer.EmailSubsOptIn = personAcct[0].Email_Subsidiary_Opt_In__c;
                    else if (isInsert == true)
                        consumer.EmailSubsOptIn = personAcct[0].Email_Subsidiary_Opt_In__c;
                    
                    //Care-565 Enable Preferred Phone Opt Fields from CCDB
                    if(isInsert == false && changedFields.contains('Market_via_Preferred_Phone__c') )
                    {
                        consumer.PhoneOptIn = personAcct[0].Market_via_Preferred_Phone__c;
                        if(personAcct[0].PersonHomePhone != null && personAcct[0].PersonHomePhone.length() >= 10)
                            consumer.HomePhone = personAcct[0].PersonHomePhone.replaceAll('\\D', '');
                        
                        system.debug('PhoneOptIn::'+consumer.PhoneOptIn);
                    }
                    else if (isInsert == true){
                        
                        if(personAcct[0].PersonHomePhone != null && personAcct[0].PersonHomePhone.length() >= 10)
                            consumer.HomePhone = personAcct[0].PersonHomePhone.replaceAll('\\D', '');
                        system.debug('PhoneOptIn::'+consumer.PhoneOptIn);
                    }
                    //We have to alter the format of the phone number in SF to match what CCDB expects to receive
                    //when updating the Preferred Phone, make sure the pass the current value of the 'Market via Preferred Phone?', because updating the new value on the email 
                    //automatically opt-in the consumer to Preferred Phone unless the Salesforce user is updating the 'Preferred Phone' and 'Market via Preferred Phone?' fields together
                    if (isInsert == false && changedFields.contains('PersonHomePhone') && personAcct[0].PersonHomePhone != null && personAcct[0].PersonHomePhone.length() >= 10) {
                        if(changedFields.contains('Market_via_Preferred_Phone__c')){
                            consumer.HomePhone = personAcct[0].PersonHomePhone.replaceAll('\\D', '');                            
                            consumer.PhoneOptIn = personAcct[0].Market_via_Preferred_Phone__c;
                        }
                        else
                            consumer.HomePhone = personAcct[0].PersonHomePhone.replaceAll('\\D', '');
                        
                    }else if (isInsert == true && personAcct[0].PersonHomePhone != null && personAcct[0].PersonHomePhone.length() >= 10)
                        consumer.HomePhone = personAcct[0].PersonHomePhone.replaceAll('\\D', '');  
                    
                    //STart-CARE-661
                    String mobilephn;
                    if (personAcct[0].PersonMobilePhone != null) {
                        if(personAcct[0].PersonMobilePhone.length() >= 10){
                            mobilephn = personAcct[0].PersonMobilePhone.replaceAll('\\D', '');
                        }
                    }
                    else{
                        mobilephn=null;
                    }
                    if(isInsert == false && changedFields.contains('PersonMobilePhone') )
                    {
                        if(!changedFields.contains('Market_via_Text__c'))
                        {
                            consumer.MobilePhone = mobilephn;
                            consumer.SmsOptIn = personAcct[0].Market_via_Text__c;
                        } 
                        else
                        {
                            consumer.MobilePhone = mobilephn;
                        }
                    }
                    else if (isInsert == true )
                    {
                        consumer.MobilePhone = mobilephn;
                    }
                    
                    if(isInsert == false && changedFields.contains('Market_via_Text__c') )
                    {
                        consumer.SmsOptIn = personAcct[0].Market_via_Text__c;                        consumer.MobilePhone = mobilephn;
                        system.debug('SmsOptIn::'+consumer.SmsOptIn);
                    }
                    else if (isInsert == true){
                        consumer.SmsOptIn = personAcct[0].Market_via_Text__c;
                        consumer.MobilePhone = mobilephn;
                        system.debug('SmsOptIn::'+consumer.SmsOptIn);
                    }
                    //End-CARE-661
                    if(isInsert == false && changedFields.contains('Share_Postal_Address_with_Subs__c')) consumer.SubsidiaryMailOptIn = personAcct[0].Share_Postal_Address_with_Subs__c;
                    else if (isInsert == true)
                        
                        consumer.SubsidiaryMailOptIn = personAcct[0].Share_Postal_Address_with_Subs__c;
                    
                    if(isInsert == false && changedFields.contains('Share_Postal_Address_with_3rd_Parties__c')) consumer.ThirdPartyMailOptIn = personAcct[0].Share_Postal_Address_with_3rd_Parties__c;
                    else if (isInsert == true)
                        consumer.ThirdPartyMailOptIn = personAcct[0].Share_Postal_Address_with_3rd_Parties__c;
                    
                    //We have to reformat the birthdate from SF to match what CCDB expects
                    if (personAcct[0].PersonBirthdate != null) {
                        String birthdayMonth = null;
                        String birthdayDay = null;
                        String birthYear = null;
                        
                        if (personAcct[0].PersonBirthdate.month() < 10) {
                            birthdayMonth = '0' + personAcct[0].PersonBirthdate.month();
                        } else {                            birthdayMonth = String.valueOf(personAcct[0].PersonBirthdate.month());
                               }
                        
                        if (personAcct[0].PersonBirthdate.day() < 10) {                            birthdayDay = '0' + personAcct[0].PersonBirthdate.day();
                                                                      } else {
                                                                          birthdayDay = String.valueOf(personAcct[0].PersonBirthdate.day());
                                                                      }
                        
                        birthYear = String.valueOf(personAcct[0].PersonBirthdate.year());
                        
                        if(isInsert == false && changedFields.contains('PersonBirthdate'))
                            consumer.DateOfBirth = birthdayMonth + '' + birthdayDay + '' + birthYear;
                        else if (isInsert == true)
                            consumer.DateOfBirth = birthdayMonth + '' + birthdayDay + '' + birthYear;
                    }else if(personAcct[0].PersonBirthdate == null && isInsert == false && changedFields.contains('PersonBirthdate')){
                                    //Raghav - care 2442 ability to clear birthdate by care users
                            consumer.DateOfBirth = '';
                    }
                    else
                    {
                        //CARE-561 - remove birth month and day field, and enable Birthday (date) field
                        /*
if(personAcct[0].Birth_Month__pc != null && personAcct[0].Birth_Day__pc != null){
if(isInsert == false && 
( changedFields.contains('Birth_Month__pc') == TRUE || changedFields.contains('Birth_Day__pc') == TRUE )
)
consumer.DateOfBirth = personAcct[0].Birth_Month__pc + '' + personAcct[0].Birth_Day__pc;
else if (isInsert == true )  consumer.DateOfBirth = personAcct[0].Birth_Month__pc + '' + personAcct[0].Birth_Day__pc;
}
else if( isInsert == false && 
( changedFields.contains('Birth_Month__pc') == TRUE || changedFields.contains('Birth_Day__pc') == TRUE )
)
{
consumer.DateOfBirth = '';
}
*/
                        
                        //We should not pass the blank value to the KH API's DateOfBirth field, else it would cause an error "Birthdate month is not valid"
                        //consumer.DateOfBirth = '';
                        //System.debug('consumer.DateOfBirth == '+ consumer.DateOfBirth);
                        
                    }
                    
                    //Care-566 Enable Decesased field 
                    if(personAcct[0].Decesased__c != null) {
                        if(isInsert == false && changedFields.contains('Decesased__c'))                            consumer.Deceased = personAcct[0].Decesased__c;
                        else if (isInsert == true)
                            consumer.Deceased = personAcct[0].Decesased__c;
                    }
                    //Have to reformat gender to be what CCDB expects
                    if (String.isNotBlank(personAcct[0].Gender__c)) {
                        if(isInsert == false && changedFields.contains('Gender__c'))                            consumer.Gender = personAcct[0].Gender__c.substring(0, 1);
                        else if (isInsert == true)
                            consumer.Gender = personAcct[0].Gender__c.substring(0, 1);
                    }
                    
                    
                    consumer.VendorId = 'SFDC';
                    
                    String operationType = null;
                    String reqBody = JSON.serialize(consumer);
                    
                    if(consumer.HardBounceCount == null)
                        reqBody = reqBody.remove('"HardBounceCount":null,');
                    
                    if(consumer.Deceased == null)
                        reqBody = reqBody.remove('"Deceased":null,');
                    
                    System.debug('reqBody: ' + reqBody);
                    
                    if (isInsert) {
                        operationType = 'POST';
                    } else {
                        operationType = 'PUT';
                    }
                    
                    //Setting up our variables to connect to CCDB via the CEMS API
                    CEMS_Connector_v2 cCon = new CEMS_Connector_v2(operationType, reqBody);
                    CEMS_Consumer_Page_Component_Controller pageController = new CEMS_Consumer_Page_Component_Controller();
                    CEMS_ConsumerDataPUT_Wrapper putResponse = null;
                    CEMS_ConsumerDataPOST_Wrapper postResponse = null;
                    
                    //If we're inserting a new record, continue
                    if (isInsert) {
                        //Generate a post request resposnes
                        postResponse = cCon.CEMS_Post();
                        
                        //If we have no errors, continue
                        Boolean hasPostErrors = postResponse == null || postResponse.Errors == null || !postResponse.Errors.isEmpty();
                        if (!hasPostErrors) {
                            if (logError && postResponse.Result != null) {
                                //Updating the Ids on insert
                                personAcct[0].CID__c = postResponse.Result.ConsumerId;
                                
                                String crownRewardsNumber = postResponse.Result.CrownRewardsNumber == null
                                    ? null
                                    : String.valueOf(postResponse.Result.CrownRewardsNumber);
                                
                                if (!String.isBlank(crownRewardsNumber) && crownRewardsNumber != '0') {
                                    personAcct[0].Crown_Rewards_Number__c = crownRewardsNumber;
                                }
                                
                                Database.DMLOptions dml = new Database.DMLOptions();
                                dml.DuplicateRuleHeader.AllowSave = true;
                                
                                Savepoint sp = Database.setSavepoint();
                                
                                try {
                                    database.update(personAcct[0], dml);
                                } catch (Exception e) {                                    responseMsg = 'There was an error updating the consumer. The error was: ' + e.getMessage(); Database.rollback(sp); return responseMsg;
                                                      }
                                
                                responseMsg = 'Insert';
                                return responseMsg;
                            } 
                        } else {
                            //If we did receive errors, continue
                            //If we receieved errors, log those errors in the CEMS_Update_Failures object.
                            for (CEMS_CustomerData_Wrapper.Errors err : postResponse.Errors) {
                                responseMsg += 'The error code is: ' + err.ErrorCode + ' - The error message returned was: ' + err.ErrorMessage + ' ';
                            }
                            
                            if (logError) {                                pageController.logCEMSFailure(personAcct[0], responseMsg, 'POST');
                                          }
                            return responseMsg;
                        }
                    } else {
                        //If we're updating a record, continue
                        //Generate the PUT request
                        putResponse = cCon.CEMS_Put(personAcct[0].CID__c);
                        
                        //If we have no errors, inform the component we successfully updated the record
                        Boolean hasPostErrors = putResponse == null || putResponse.Errors == null || !putResponse.Errors.isEmpty();
                        if (!hasPostErrors) {                                                                                      
                            responseMsg = 'Update';
                            
                            return responseMsg;
                        } else {
                            //If we did receive errors, continue
                            //If we receieved errors, log those errors in the CEMS_Update_Failures object.
                            for (CEMS_CustomerData_Wrapper.Errors err : putResponse.Errors) {
                                responseMsg += 'The error code is: ' + err.ErrorCode + ' - The error message returned was: ' + err.ErrorMessage + ' ';
                            }
                            
                            if (logError) {                                pageController.logCEMSFailure(personAcct[0], responseMsg, 'PUT');
                                          }
                            return responseMsg;
                        }
                    }
                } else {
                    //Inform the user that a CID must be present on the record to be able to update it in CCDB
                    responseMsg = 'You need to have be inserting a record or updating a record with a CID to be able to call this method';
                    return responseMsg;
                }
            } else {
                //Inform the user that a CID must be present on the record to be able to update it in CCDB
                responseMsg = 'Unable to find person account matching the data passed in';
                return responseMsg;
            }
        } else {
            //Inform the user that there was a problem retrieving the record to sync to CCDB
            responseMsg = 'The Id for the record you are viewing was not passed to the controller successfully. Try reloading the page.';
            return responseMsg;
        }
        return responseMsg;
    }

    //Start-Method to add or update hplusmemships-CARE-1302
    public String addhPlusmemships( List<CEMS_CustomerData_Wrapper.hPlusMembership> hPlusMemberships, String consumerUUID,
                                   Account consumerAcct, Boolean newSubCreated,string shared,string crnumber) {
                                       
                                       //Start: Naeem-Care-2147
                                       Integer iter = 0;
                                       String responseMsg = 'No Update';
                                       system.debug('consumerAcct.uuid__c === '+ consumerAcct.uuid__c);
                                       system.debug('consumerAcct.uuid__c hPlusMemberships === '+ hPlusMemberships);
                                       for(iter = 0; iter < hPlusMemberships.size(); iter++ ){
                                           if(consumerUUID == hPlusMemberships[iter].uuid){
                                               
                                               //delete any existing duplicate UUID records
                                               List<Hallmarkplus__c> hplusAddList = [SELECT Id FROM Hallmarkplus__c WHERE uuid__c = :hPlusMemberships[iter].uuid];
                                               if (!hplusAddList.isEmpty()) {
                                                   delete hplusAddList;
                                               }
                                               Account accountToUpdate1 = [SELECT Id,Hallmarkplus__c  FROM Account WHERE Id = :consumerAcct.Id];
                                               accountToUpdate1.uuid__c = hPlusMemberships[iter].uuid;
                                               
                                               Hallmarkplus__c hplusAdd = new Hallmarkplus__c();
                                               
                                               hplusAdd.Accountid__c  = accountToUpdate1.Id;
                                               hplusAdd.Linked_Login_Status__c = shared;
                                               hplusAdd.Crown_Rewards_Number__c = crnumber;
                                               hplusAdd.Crown_Rewards_Tier__c = crnumber;
                                               hplusAdd.uuid__c = hPlusMemberships[iter].uuid;
                                               hplusAdd.Status__c  = hPlusMemberships[iter].subscriptionStatus;
                                               //Start: Mahesh, Care-1765 H+: Post MVP story
                                               if((String.isNotBlank(hPlusMemberships[iter].entitlementStatus)) && (hPlusMemberships[iter].entitlementStatus == 'true' ))
                                                   accountToUpdate1.Hallmarkplus__c = True;
                                               else if((String.isNotBlank(hPlusMemberships[iter].entitlementStatus)) && (hPlusMemberships[iter].entitlementStatus == 'false' ))
                                                   accountToUpdate1.Hallmarkplus__c = False;
                                               else
                                                   accountToUpdate1.Hallmarkplus__c = False;
                                               
                                               //End: Mahesh, Care-1765 H+: Post MVP story
                                               
                                               //Start: Mahesh, Care-1716 H+: Post MVP story
                                               if((String.isNotBlank(hPlusMemberships[iter].entitlementStatus)) && (hPlusMemberships[iter].entitlementStatus == 'true' ))
                                                   hplusAdd.Status__c = 'Active';
                                               else if((String.isNotBlank(hPlusMemberships[iter].entitlementStatus)) && (hPlusMemberships[iter].entitlementStatus == 'false' ))
                                                   hplusAdd.Status__c = 'Expired';
                                               //End: Mahesh, Care-1716 H+: Post MVP story
                                               
                                               
                                               if((String.isNotBlank(hPlusMemberships[iter].autoRenewStatus)) && (hPlusMemberships[iter].autoRenewStatus == 'true' ))
                                                   hplusAdd.Auto_Renewel_On__c = 'Yes';
                                               else if((String.isNotBlank(hPlusMemberships[iter].autoRenewStatus)) && (hPlusMemberships[iter].autoRenewStatus == 'false' ))
                                                   hplusAdd.Auto_Renewel_On__c = 'No';
                                               
                                               hplusAdd.Type__c  = hPlusMemberships[iter].subscriptionLength; 
                                               
                                               if(String.isNotBlank(hPlusMemberships[iter].entitlementStartDate)){
                                                   //Naeem: Care-2146
                                                   //hplusAdd.Current_Start_Date__c = DateTime.parse(hPlusMemberships[iter].entitlementStartDate.replace(hPlusMemberships[iter].entitlementStartDate.substring(hPlusMemberships[iter].entitlementStartDate.lastIndexOf(':'), hPlusMemberships[iter].entitlementStartDate.lastIndexOf(' ')) + ' ', ' '));
                                                   hplusAdd.Current_Start_Date__c = stringToDateTime(hPlusMemberships[iter].entitlementStartDate);
                                               }
                                               
                                               if(String.isNotBlank(hPlusMemberships[iter].entitlementEndDate)){
                                                   //Naeem: Care-2146
                                                   //hplusAdd.Current_End_Date__c = DateTime.parse(hPlusMemberships[iter].entitlementEndDate.replace(hPlusMemberships[iter].entitlementEndDate.substring(hPlusMemberships[iter].entitlementEndDate.lastIndexOf(':'), hPlusMemberships[iter].entitlementEndDate.lastIndexOf(' ')) + ' ', ' '));                    
                                                   hplusAdd.Current_End_Date__c = stringToDateTime(hPlusMemberships[iter].entitlementEndDate);
                                               }
                                               
                                               if(String.isNotBlank(hPlusMemberships[iter].subscriptionStartDate)){
                                                   //Naeem: Care-2146
                                                   //hplusAdd.Original_Start_Date__c = DateTime.parse(hPlusMemberships[iter].subscriptionStartDate.replace(hPlusMemberships[iter].subscriptionStartDate.substring(hPlusMemberships[iter].subscriptionStartDate.lastIndexOf(':'), hPlusMemberships[iter].subscriptionStartDate.lastIndexOf(' ')) + ' ', ' '));                    
                                                   hplusAdd.Original_Start_Date__c = stringToDateTime(hPlusMemberships[iter].subscriptionStartDate);
                                               }
                                               if(String.isNotBlank(hPlusMemberships[iter].origSourceOfDataDesc)) {
                                                   String translatedMembershipSource =
                                                       translateOrigSourceOfDataDesc(
                                                           hPlusMemberships[iter].origSourceOfDataDesc
                                                       );
                                                   hplusAdd.Source__c = translatedMembershipSource;
                                                   hplusAdd.Membership_Source__c = translatedMembershipSource;
                                               }
                                                   //Raghav: care-2275 below flag added to check whether user availed free trial H+membership
                                               if(hPlusMemberships[iter].freeTrialFlag != null)
                                                   hplusAdd.Free_Trial_Used__c = hPlusMemberships[iter].freeTrialFlag;
     
                                               
                                               Savepoint sp = Database.setSavepoint();
                                               Database.DMLOptions dml = new Database.DMLOptions();
                                               dml.DuplicateRuleHeader.AllowSave = true;
                                               system.debug('??hplusAdd'+hplusAdd);
                                               system.debug('??accountToUpdate1'+accountToUpdate1);
                                               
                                               try {
                                                   if (hplusAdd != null)
                                                       database.upsert(hplusAdd);
                                                   database.update(accountToUpdate1, dml);
                                                   system.debug('??sucsess');
                                               } catch (Exception e) {   
                                                   system.debug('??nosucsess');responseMsg = 'There was an error inserting the hplusmemberships. The error was: ' + e.getMessage();            Database.rollback(sp);            Universal_Error_Logger.auraGenerateErrorLog('There was an error inserting the memberships/subscriptions','addSubscriptions',e.getMessage(), e.getStackTraceString(),consumerAcct.Id );
                                                   return responseMsg;
                                               }
                                               
                                               responseMsg = 'Update';
                                               break;
                                           }
                                       }
                                       
                                       
                                       return responseMsg;
                                       //End: Naeem-Care-2147
                                       
                                   }
    //End-Method to add or update hplusmemships-CARE-1302
    
    public static String translateOrigSourceOfDataDesc(String origSourceOfDataDesc) {
        String sourceDesc = '';
        if (origSourceOfDataDesc == 'HPLUS ON HMK.COM') {
            sourceDesc = 'Hallmark.com';
        } else if (origSourceOfDataDesc == 'HPLUS ON HMN.COM') {
            sourceDesc = 'Hallmarkplus.com or Hallmark+ App';
        } else if (origSourceOfDataDesc == 'HPLUS PRE LOAD') {
            sourceDesc = 'Hmnow.com or HMN App';
        } else if (origSourceOfDataDesc != null &&
                   origSourceOfDataDesc.equalsIgnoreCase('HPlusHMN - IOS')) {
            sourceDesc = 'H+ App Apple';
        } else if (origSourceOfDataDesc != null &&
                   origSourceOfDataDesc.equalsIgnoreCase('HPlusHMN - Android')) {
            sourceDesc = 'H+ App Android';
        } else if (origSourceOfDataDesc != null &&
                   origSourceOfDataDesc.equalsIgnoreCase('HPlusHMN - Other_App')) {
            sourceDesc = 'H+ App Other';
        } else if (origSourceOfDataDesc != null &&
                   origSourceOfDataDesc.equalsIgnoreCase('GoogleUCP')) {
            sourceDesc = 'Google Shop';
        } else if (origSourceOfDataDesc != null &&
                   origSourceOfDataDesc.equalsIgnoreCase('Meta Shop hallmarkornaments')) {
            sourceDesc = 'Instagram Shop Ornaments';
        } else if (origSourceOfDataDesc != null &&
                   origSourceOfDataDesc.equalsIgnoreCase('Meta Shop hallmarkstores')) {
            sourceDesc = 'Instagram Shop';
        } else if (origSourceOfDataDesc != null &&
                   origSourceOfDataDesc.equalsIgnoreCase('DoorDash')) {
            sourceDesc = 'DoorDash';
        } else if (origSourceOfDataDesc != null &&
                   origSourceOfDataDesc.equalsIgnoreCase('TikTok')) {
            sourceDesc = 'TikTok Shop';
        } else {
            sourceDesc = origSourceOfDataDesc; // Default assignment if none of the conditions match
        }
        
        return sourceDesc;
    }
    
    //Method to add or update subscriptions to from CEMS to the Subscriptions object
    //25/08/2022 - Adeel - Added new field in mapping (Charter) - (7787)
    //01/09/2022 - Adeel - Commenting out logic for charter as we are not deploying 7787
    public String addSubscriptions(List<CEMS_CustomerData_Wrapper.Memberships> membershipList, Account consumerAcct, Boolean newSubCreated) {
        String responseMsg = 'No Update';
        List<Subscription__c> SFOnlySubList;
        
        //Care-1235
        //List<Subscription__c> existingSubList;
        
        List<Subscription__c> newSubList = new List<Subscription__c>();
        Set<String> subIds = new Set<String>();
        
        //care-1235
        //Map<String, Subscription__c> existingSubMap = new Map<String, Subscription__c>();
               
        Account accountToUpdate = [SELECT Id, Crown_Rewards_Number__c FROM Account WHERE Id = :consumerAcct.Id];
        // mh - null out crown rewards. this makes it empty unless an active one is found.
        if (accountToUpdate.Crown_Rewards_Number__c != null) {
            accountToUpdate.Crown_Rewards_Number__c = null;
        }
        
        if (!membershipList.isEmpty()) {
            for (CEMS_CustomerData_Wrapper.Memberships membership : membershipList) {
                subIds.add(String.valueOf(membership.id));
            }
            
            if (!subIds.isEmpty()) {
                
                //Start: care-675    
                //Care-675 - Update Crown Rewards Membership Logic to Delete Crown Rewards Memberships from Consumer Records when MDM deletes the Crown Rewards Membership
                //Find consumer subscriptions which exists in caretools but doesn't exist in KH/MDM
                //Delete those caretools subscriptions records
                if(!newSubCreated){
                    SFOnlySubList = [SELECT Id, Status__c, Consumer__c, Subscription_Id__c,Consumer__r.CID__c FROM Subscription__c 
                                     WHERE Subscription_Id__c NOT IN :subIds 
                                     AND Consumer__c = :accountToUpdate.Id];
                    System.debug('SFOnlySubLis === '+SFOnlySubList);
                    if (!SFOnlySubList.isEmpty())                         deleteConsumerSubs(SFOnlySubList,accountToUpdate);
                }   
                //End: care-675    
                
                
                //Start: Care-1235
                /* 
existingSubList = [SELECT Id, Status__c, Consumer__c, Subscription_Id__c FROM Subscription__c WHERE Subscription_Id__c IN :subIds];

if (!existingSubList.isEmpty()) {                    
for (Subscription__c sub : existingSubList) {                        
existingSubMap.put(sub.Subscription_Id__c, sub);

}
}


// mh delete memberships pointing to the wrong consumer.

try {
List<Subscription__c> existingScriptsForOtherConsumers = [
SELECT id
FROM Subscription__c
WHERE Subscription_Id__c IN :existingSubMap.keySet() AND Consumer__c != :accountToUpdate.Id
];
if (existingScriptsForOtherConsumers.size() > 0) {
system.debug('found subscription for other consumers. deleting...');
delete existingScriptsForOtherConsumers;
}
} catch (exception e) {
system.debug('error deleting other subscriptions');
Universal_Error_Logger.auraGenerateErrorLog('There was an error deleting the memberships/subscriptions','addSubscriptions',e.getMessage(),                        e.getStackTraceString(),                        consumerAcct.Id                    );
}*/
                //END: Care-1235
                
                //Start: Care-1235
                if(newSubCreated == false){
                    
                    List<Subscription__c> existingSubListv2 = [SELECT Id, Status__c, Consumer__c, Subscription_Id__c 
                                                               FROM Subscription__c 
                                                               WHERE Subscription_Id__c IN :subIds  ];
                    System.debug('existingSubListv2 ==== '+existingSubListv2);
                    if (!existingSubListv2.isEmpty()) { 
                        delete existingSubListv2;
                        /*

List<Subscription__c> existingSubListv1 = [SELECT Id, Status__c, Consumer__c, Subscription_Id__c 
FROM Subscription__c 
WHERE Consumer__c = :accountToUpdate.Id  ];                        
System.debug('existingSubListv1 ==== '+existingSubListv1);
if (!existingSubListv1.isEmpty()) { 
delete existingSubListv1;
}*/   
                    }
                }
                //End: Care-1235
                
                // end mh code
                
                //Naeem: H+ Care-1400
                Boolean foundConsumerCR = false;
                
                for (CEMS_CustomerData_Wrapper.Memberships membership : membershipList) {
                    if (membership.membershipType != null && membership.membershipType != '') {
                        Subscription__c subAdd;
                        //Start: Care-1235
                        /*
Subscription__c subFound = existingSubMap.get(String.valueOf(membership.id));
if (subFound != null) {                           
subAdd = subFound;
} else {
subAdd = new Subscription__c();
subAdd.Consumer__c = accountToUpdate.Id;
}*/
                        //End: Care-1235
                        subAdd = new Subscription__c();
                        subAdd.Consumer__c = accountToUpdate.Id;
                        System.debug('membership.rank == '+membership.rank);
                        System.debug('membership.id == '+membership.id);
                        if(membership.rank != null && membership.rank != '' )                        
                            subAdd.Rank__c = Integer.valueOf(membership.rank);
                        
                        //Start: Naeem: H+ Care-1330
                        if(membership.hPlusMembership != null && membership.hPlusMembership.uuid != null )
                            subAdd.Linked_to_Hallmark__c = true;                            
                        //End: Naeem: H+ Care-1330
                        
                        //Start: Naeem: H+ Care-44
                        if (
                            membership.membershipType == 'Crown Rewards' &&
                            (membership.memberCurrentStatus == '1') &&
                            foundConsumerCR == false
                        ) {
                            accountToUpdate.Crown_Rewards_Number__c = membership.id;
                            //Naeem: H+ Care-1400
                            foundConsumerCR = true;
                        }
                        //End: Naeem: H+ Care-44
                        
                        if (membership.membershipType == 'Keepsake Ornaments Club') {
                            if (membership.KeepsakeOrnamentClub != null) {
                                subAdd.Membership_Start_Date__c = membership.KeepsakeOrnamentClub.MemberSince;
                                
                                String expDate = null;
                                
                                if (membership.KeepsakeOrnamentClub.DateExpires != null) {
                                    expDate =
                                        membership.KeepsakeOrnamentClub.DateExpires.substring(4) +
                                        '/' +
                                        membership.KeepsakeOrnamentClub.DateExpires.substring(0, 4);
                                }
                                //25/08/2022 - Adeel - Map New Field 
                                subAdd.Charter__c = membership.KeepsakeOrnamentClub.CharterMember == 'true' ? 'Yes' : 'No';
                                subAdd.Membership_Expiration_Date__c = expDate;
                            }
                        }
                        
                        subAdd.Subscription_Type__c = membership.membershipType;
                        System.debug('This is the ub Id ::: ' + membership.id);
                        subAdd.Subscription_Id__c = membership.id;
                        
                        //Start: Naeem H+Care-1690
                        if (membership.membershipType == 'Crown Rewards') 
                            subAdd.Status__c = membership.memberCurrentStatus;
                        if (membership.membershipType == 'Keepsake Ornaments Club') 
                            subAdd.Status_KOC__c  = membership.memberCurrentStatus;
                        
                        //End: Naeem H+Care-1690
                        
                        //11/10/2022 - Adeel - Instead of storing text, store it as a date so filters should work
                        //Need to parse the date string to remove the seconds as it will give error in SF
                        if(String.isNotBlank(membership.memberLastUpdate)){
                            //Naeem: Care-2146
                            //String stringToReplace = membership.memberLastUpdate.substring(membership.memberLastUpdate.lastIndexOf(':'), membership.memberLastUpdate.lastIndexOf(' ')) + ' ';
                            //String formattedModifiedDate = membership.memberLastUpdate.replace(stringToReplace, ' ');
                            //subAdd.Date_Modified__c = DateTime.parse(formattedModifiedDate);
                            subAdd.Date_Modified__c = stringToDateTime(membership.memberLastUpdate);
                        }
                        
                        newSubList.add(subAdd);
                    }
                }
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        
        try {
            if (!newSubList.isEmpty())
                database.upsert(newSubList);
            database.update(accountToUpdate, dml);
        } catch (Exception e) {            responseMsg = 'There was an error inserting the memberships/subscriptions. The error was: ' + e.getMessage();            Database.rollback(sp);            Universal_Error_Logger.auraGenerateErrorLog('There was an error inserting the memberships/subscriptions','addSubscriptions',e.getMessage(), e.getStackTraceString(),consumerAcct.Id );
                               return responseMsg;
                              }
        
        responseMsg = 'Update';
        return responseMsg;
    }
    
    //Used to log failures for update or insert calls to CEMS in our CEMS_Update_Failure__c object. Theses failures are then re-attempted by the CEMS_Error_Batch class every hour
    public void logCEMSFailure(Account personAcct, String errorMsg, String operationType) {
        if (
            errorMsg.contains('500') ||
            errorMsg.contains('504') ||
            errorMsg.contains('503') ||
            errorMsg.contains('502') ||
            errorMsg.contains('777')
        ) {
            CEMS_Update_Failure__c cemsFailure = new CEMS_Update_Failure__c();
            cemsFailure.Original_CCDB_Error_Response__c = errorMsg;
            cemsFailure.Consumer_Record__c = personAcct.Id;
            cemsFailure.Operation_Type__c = operationType;
            cemsFailure.Initial_Failure_Date__c = Date.today();
            insert cemsFailure;
        }
    }
    
    //Method to update case if consumer gets deleted from knowher
    @AuraEnabled
    public static string updateCase(String caseId){
        String returnStr = '';
        try{
            Case c = [SELECT Id FROM Case where Id =:caseId];
            c.ContactId = null;
            c.AccountId = null;
            update c;
            returnStr = 'SUCCESS';                
        }catch(Exception e){            returnStr = e.getMessage();
                           }
        return returnStr;
    }
    //Start: care-675    
    public static void deleteConsumerSubs(List<Subscription__c> SFOnlySubList, Account consumerAcct){
        System.debug('deleteConsumerSubs == SFOnlySubList '+SFOnlySubList);
        System.debug('deleteConsumerSubs == consumerAcct '+consumerAcct);
        Set<String> finalSubSet = new Set<String>();
        Set<String> CIDSet = new Set<String>();
        Set<String> subIDSet = new Set<String>();
        //care-817, adding the logic here for Consumer history tracking for whose membership records which are moved to difference CID
        for(Subscription__c SFOnlysub: SFOnlySubList ){
            // if the sub as requested to be moved to different CID
            CIDSet.add(SFOnlysub.Consumer__r.CID__c);
            subIDSet.add(SFOnlysub.Subscription_Id__c);
        }
        System.debug('deleteConsumerSubs == CIDSet '+CIDSet);
        System.debug('deleteConsumerSubs == subIDSet '+subIDSet);
        
        List<Field_History__c> FHList = new List<Field_History__c>([Select Id,Account__c, Tracked_Field_Label__c, Old_Value__c, New_Value__c From Field_History__c 
                                                                    Where Tracked_Field_Label__c LIKE '%to a different CID is processing%' 
                                                                    AND Old_Value__c IN :CIDSet
                                                                   ]);
        System.debug('deleteConsumerSubs == FHList '+FHList);
        
        List<Field_History__c> FHinsertList = new List<Field_History__c>();
        Map<String, Field_History__c> unihstry = new Map<String, Field_History__c>();
        for(Field_History__c FHRecord :FHList){
            String fldlbl =FHRecord.Tracked_Field_Label__c;            string memshipText = fldlbl.substring(20, fldlbl.indexOf(')') +1);            string memshipId = fldlbl.substring(fldlbl.indexOf('(')+1, fldlbl.indexOf(')'));
            System.debug('deleteConsumerSubs == memshipId '+memshipId);
            if(subIDSet.contains(memshipId)){
                Field_History__c history = new Field_History__c(                                        Tracked_Object__c = 'Account',User__c = UserInfo.getUserId(),Date__c = DateTime.now(),New_Value__c = FHRecord.New_Value__c,                    Old_Value__c = FHRecord.Old_Value__c,                    Tracked_Field_Label__c = 'The '+ memshipText + ' to a different CID was successfully moved.',                    Tracked_Field_API__c = 'The '+ memshipText +' to a different CID was successfully moved.'
                                                               );
                history.Account__c = FHRecord.Account__c;                FHinsertList.add(history);
            }
        }
        System.debug('??FHinsertList ==== '+FHinsertList);
        insert FHinsertList;
        try {            delete SFOnlySubList;
            } catch (exception e) {
                system.debug('error deleting the SF only Consumer subscriptions');
                Universal_Error_Logger.auraGenerateErrorLog('There was an error deleting the SF only Consumer memberships/subscriptions','addSubscriptions',e.getMessage(),e.getStackTraceString(),                consumerAcct.Id            );
            }
    }
    //End: care-675   
        
    //2046 - Raghav start
    //This method will retrieve a consumer record from CCDB
    @AuraEnabled
    public static String fetchConsumer(String acctId) {
        System.debug('Person acct id ::: ' + acctId);
        
        // Initialize response message and variables
        String responseMsg = '';
        CEMS_Connector_v2 cCon = new CEMS_Connector_v2('GET', null);
        CEMS_Consumer_Page_Component_Controller pageController = new CEMS_Consumer_Page_Component_Controller();
        Account personAccount = null;          // Validate the accountId and query for the consumer record
        if (String.isBlank(acctId)) {
            return 'There was an error passing the record Id to the controller. Please reload the page and try again.';
        }
        
        // Query for the consumer record in Salesforce
        List<Account> acctList = [
            SELECT 
            Id, PersonEmail, FirstName, LastName, MiddleName, PersonHomePhone, Mailing_Zip_Postal_Code__c,
            PersonMobilePhone, CID__c, CallGuid__c, Crown_Rewards_Number__c,UUID__c
            FROM Account
            WHERE Id = :acctId AND isPersonAccount = TRUE
            LIMIT 1
        ];
        
        if (acctList.isEmpty()) {
            return 'No consumer found in our Salesforce database matches the Id passed. Please try reloading the page.';
        }
        
        personAccount = acctList[0];        
        //If we assigned a record to our personAccount variable, continue
        if (personAccount != null) {
            //If the consumer has a CID attached to their record, continue
            if (personAccount.CID__c == null) {
                //Generate our CEMS GET request
                System.debug('@@personAccount.CID__c'+personAccount.CID__c);
                //Raghav - 2019 added new parameter hPlusMemberUUID value null
                CEMS_CustomerData_Wrapper customerWrapper = cCon.CEMS_Get(null, personAccount.PersonHomePhone, personAccount.PersonEmail, personAccount.FirstName, personAccount.LastName, personAccount.Mailing_Zip_Postal_Code__c, null,null, false);                

                if (customerWrapper == null) {
                    return 'No response received from KH API.';
                }
                
                Boolean hasErrors = customerWrapper.Errors != null && !customerWrapper.Errors.isEmpty();   
                
                //If we received a response with an empty errors list continue
                if (!hasErrors) {
                    System.debug('@@customerWrapper='+customerWrapper);
                    //If we retrieved consumers, update those consumers in Salesforce
                    if(customerWrapper != null && 
                       customerWrapper.Result != null && 
                       customerWrapper.Result.consumers != null && 
                       customerWrapper.Result.consumers.size() == 1)
                    {
                        CEMS_CustomerData_Wrapper.Consumers consumer = customerWrapper.Result.consumers[0];
                        List<CEMS_CustomerData_Wrapper.Memberships> memberships = consumer.memberships;
                        
                        System.debug('This is the membership list :::' + memberships);
                        String updateResponse;
                        Boolean clearCRFieldValue = false;
                        //If we have memberships returned to us, update or add those memberships
                        if (memberships != null && !memberships.isEmpty()) {
                            updateResponse = pageController.addSubscriptions(memberships, personAccount, false);
                        }
                        else{
                            //double check if the SF consumer also doesn't have any CR members
                            //Delete those caretools subscriptions records
                            List<Subscription__c> SFOnlySubList = [SELECT Id, Status__c, Consumer__c,Subscription__c.Consumer__r.CID__c, Subscription_Id__c FROM Subscription__c 
                                                                   WHERE Consumer__c = :personAccount.Id];
                            System.debug('SFOnlySubLis === '+SFOnlySubList);
                            if (!SFOnlySubList.isEmpty()){
                                deleteConsumerSubs(SFOnlySubList,personAccount);  
                                if (!String.isBlank(personAccount.Crown_Rewards_Number__c))
                                    clearCRFieldValue = true;
                            }
                            else{
                                if (!String.isBlank(personAccount.Crown_Rewards_Number__c)) 
                                    clearCRFieldValue = true;
                            }
                            
                        }
                        List<CEMS_CustomerData_Wrapper.hPlusMembership> hPlusMemberships = consumer.hPlusMembership;
                        
                        if (hPlusMemberships != null && !hPlusMemberships.isEmpty()) {
                            string shared = consumer.hPlusSharedIdentity;
                            string crnumber;
                            String hPlusUuid;
                            
                            if (memberships != null && !memberships.isEmpty() && memberships[0] != null && !String.isBlank(memberships[0].id)){ 
                                crnumber = memberships[0].id;
                            }
                            
                            CEMS_CustomerData_Wrapper.AlternateId primaryAlternateId =
                                getPrimaryAlternateId(consumer);
                            if (
                                primaryAlternateId != null &&
                                primaryAlternateId.hPlusMembership != null &&
                                primaryAlternateId.hPlusMembership.uuid != null
                            ) {
                                hPlusUuid = String.valueOf(primaryAlternateId.hPlusMembership.uuid);
                            }
                            if(crnumber != null && hPlusUuid != null){
                                //Start: Naeem-Care-2147
                                updateResponse = pageController.addhPlusmemships(hPlusMemberships, hPlusUuid, personAccount, false,shared,crnumber);
                                //End: Naeem-Care-2147 
                            }                            
                        }
                        else{
                            //double check if the SF consumer also doesn't have any CR members
                            //Delete those caretools subscriptions records
                            List<Hallmarkplus__c> SFOnlyhplusList = [SELECT Id FROM Hallmarkplus__c 
                                                                     WHERE Accountid__c  = :personAccount.Id];
                            if (!SFOnlyHplusList.isEmpty()) {
                                
                                
                                // Delete the records from Salesforce
                                try {
                                    delete SFOnlyHplusList;
                                } catch (DmlException e) {
                                    
                                    System.debug('Failed to delete Hallmarkplus__c records: ' + e.getMessage());
                                }
                            }
                            
                        }
                        
                        
                        //Determine our Salesforce record updates based on the returned CEMS consumer record and make those updates
                        System.debug('Desearlized JSON Result ::: ' + customerWrapper);
                        //  System.debug('Consumer Id we found is ::: ' + customerWrapper.Result.consumers[0].consumerId);
                        updateResponse = pageController.determineRecordUpdates(personAccount, customerWrapper, clearCRFieldValue);
                        system.debug('??updateResponse'+updateResponse);
                        return updateResponse;
                    } else if(customerWrapper != null && 
                              customerWrapper.Result != null && 
                              customerWrapper.Result.consumers != null && 
                              customerWrapper.Result.consumers.size() > 1){
                                  //If more than one consumer found in KH, inform the agent
                                  String cidValues = '';
                                  //If more than one consumer found in KH, inform the agent
                                  for(CEMS_CustomerData_Wrapper.Consumers consumerRec : customerWrapper.Result.consumers){
                                      if(cidValues != '') {
                                          cidValues += ',' + consumerRec.consumerId;
                                      } else {
                                          cidValues = consumerRec.consumerId;
                                      }
                                  }
                                  responseMsg = 'Multiple consumers found in the KH database that match the Salesforce consumer details. The corresponding CID values are:'+ cidValues;
                                  return responseMsg;
                              }
                } else if (customerWrapper.Errors[0].ErrorCode == '404') {
                    //If we were unable to match with the Salesforce consumer data and received a 404 not found error code then consumer can be created in KH
                    responseMsg = 'Create';
                    return responseMsg;
                } else {
                    //If we did receive errors, continue
                    //If we receieved errors, log those errors in the CEMS_Update_Failures object.
                    for (CEMS_CustomerData_Wrapper.Errors err : customerWrapper.Errors) {
                        responseMsg += 'The error code is: ' + err.ErrorCode + ' - The error message returned was: ' + err.ErrorMessage + ' ';
                    }
                    pageController.logCEMSFailure(personAccount, responseMsg, 'GET');
                    return responseMsg;
                }
            }
        }
        
        return responseMsg;
    }

    
    //Start: Naeem: care-2146
    public static DateTime stringToDateTime(String dateTimeString){
        
        // Split the string into parts
        List<String> dateTimeParts = dateTimeString.split(' ');
        String datePart = dateTimeParts[0];
        String timePart = dateTimeParts[1];
        String amPm = dateTimeParts[2];
        
        // Split and parse the date
        List<String> dateParts = datePart.split('/');
        Integer month = Integer.valueOf(dateParts[0]);
        Integer day = Integer.valueOf(dateParts[1]);
        Integer year = Integer.valueOf(dateParts[2]);
        
        // Split and parse the time
        List<String> timeParts = timePart.split(':');
        Integer hour = Integer.valueOf(timeParts[0]);
        Integer minute = Integer.valueOf(timeParts[1]);
        Integer second = Integer.valueOf(timeParts[2]);
        
        // Convert to 24-hour format
        if (amPm == 'PM' && hour != 12) {
            hour += 12;
        } else if (amPm == 'AM' && hour == 12) {
            hour = 0;
        }
        
        
        // Build the ISO 8601 string
        String formattedDateTime = 
            String.valueOf(year) + '-' +
            (month < 10 ? '0' : '') + String.valueOf(month) + '-' +
            (day < 10 ? '0' : '') + String.valueOf(day) + ' ' +
            (hour < 10 ? '0' : '') + String.valueOf(hour) + ':' +
            (minute < 10 ? '0' : '') + String.valueOf(minute) + ':' +
            (second < 10 ? '0' : '') + String.valueOf(second);
        
        // Convert to DateTime
        DateTime dt = DateTime.valueOf(formattedDateTime);
        
        System.debug('Parsed DateTime: ' + dt);
        return dt;
    }
     //End: Naeem: care-2146   


}
