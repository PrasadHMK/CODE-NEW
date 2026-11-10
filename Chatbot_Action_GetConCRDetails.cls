public with sharing class Chatbot_Action_GetConCRDetails {
    private static CEMS_CustomerData_Wrapper.AlternateId getPrimaryAlternateId(
        CEMS_CustomerData_Wrapper.Consumers consumer
    ) {
        if (consumer == null || consumer.alternateId == null) {
            return null;
        }
        for (CEMS_CustomerData_Wrapper.AlternateId alternateId : consumer.alternateId) {
            if (alternateId != null && 'HDXREF'.equalsIgnoreCase(alternateId.typ)) {
                return alternateId;
            }
        }
        return consumer.alternateId.isEmpty() ? null : consumer.alternateId[0];
    }
    
    public class Input {
        @InvocableVariable(label='Comsumer Email')
        public String email;
        
        @InvocableVariable(label='Consumer Phone')
        public String phone;
        
        @InvocableVariable(label='Get CR Details or CR Rewards')
        public String consumerCRDetailsOrRewards;
    }
    
    @InvocableMethod(
        label='Chatbot - Get CR Membership Details'
        description='Get CR Membership Details Email or Phone'
    )
    public static List<Output> getConCRDetails(List<Input> inputList) {
        
        System.debug('getConCRDetails ::: Checking inputList ::: ' + inputList);
        List<Output> outputList = new List<Output>();
        
        CEMS_Connector_v2 cCon = new CEMS_Connector_v2('GET', null);
        CEMS_CustomerData_Wrapper customerWrapper;
        if(Test.isRunningTest()){
            
            string resp =
                '{    "Errors": [],    "Result": {        "numberOfResults": 1,        "consumers": [            {                "consumerId": 163212591007,                "hPlusSharedIdentity": "Activated",                "alternateId": {                    "val": "2118817752",                    "typ": "HDXREF",                    "lastUpdatedFrom": "HPlusHmk",                    "hPlusMembership": {                        "uuid": "184d53bb-f05e-4039-8825-10f0889f01f5"                    }                },                "name": {                    "namePrefix": null,                    "firstName": "MAGGIE FNMA",                    "middleInitial": "",                    "lastName": "MAGGIE LNMA",                    "nameSuffix": null,                    "languageCode": null,                    "lastUpdatedFrom": "HPlusHmk",                    "sourceOfDataId": "88007",                    "sourceOfDataDesc": "Digital Profile",                    "sourceCapturedDt": null                },                "address": {                    "addressLine1": null,                    "addressLine2": "",                    "city": null,                    "state": null,                    "zip": "",                    "country": null,                    "prisonAddress": null,                    "addressType": null,                    "validationStatus": null,                    "validated": null,                    "validationMessage": null,                    "NCOAChgDt": null,                    "latitude": null,                    "longitude": null,                    "geocodingStatus": null,                    "geocodingStatusDesc": null,                    "lastUpdatedFrom": null,                    "consumerAddrSource": null,                    "sourceCapturedDt": null,                    "addrSts": null,                    "dfltInd": null,                    "mailabilityScore": null,                    "mailabilityScoreDesc": null,                    "deliverable": true,                    "optIns": {                        "postalOptIn": false,                        "postalOptCaptureDate": null,                        "subsidiaryMailOptIn": false,                        "thirdPartyMailOptIn": false,                        "lastUpdatedFrom": null,                        "DMAOptFlg": null                    }                },                "phone": {                    "homeNumber": 0,                    "mobileNumber": 0,                    "mobileCaptureDate": null,                    "lastUpdatedFrom": null,                    "sourceCapturedDt": null,                    "optIns": {                        "phoneOptIn": false,                        "phoneOptCaptureDate": null,                        "smsOptIn": false,                        "textOptIn": false,                        "smsOptCaptureDate": null,                        "lastUpdatedFrom": null,                        "sourceCapturedDt": null                    }                },                "email": {                    "address": "MAGGIEES789+DEV349@GMAIL.COM",                    "captureDate": "08/09/2024",                    "lastCaptureDate": "08/09/2024",                    "deliverable": true,                    "lastHardBounceDt": null,                    "hardBounceCount": "0",                    "sharedEmail": "Y",                    "espStatus": null,                    "sourceCapturedDt": null,                    "lastUpdatedFrom": "HDProfile",                    "optIns": {                        "optIn": true,                        "subsidiaryOptIn": true,                        "lastUpdatedFrom": "HDProfile",                        "sourceCapturedDt": null                    }                },                "dateOfBirth": "",                "gender": null,                "deceased": false,                "hallmarkSweepstakesOpt": true,                "lastUpdate": "8/09/2024 6:22:43 PM",                "memberships": [                    {                        "membershipType": "Crown Rewards",                        "id": 914247532033,                        "memberCurrentStatus": "1",                        "effStartDateCR": "2024-08-09T18:21:53Z",                        "memberCurrentStatusHD": "EARN AND ISSUE",                        "memberLastUpdate": "8/09/2024 6:22:43 PM",                        "hPlusMembership": {                            "uuid": "184d53bb-f05e-4039-8825-10f0889f01f5"                        },                        "rank": "1",                        "CrownRewardsLoyalty": {                            "currentTierNumber": 0,                            "MemberPointsAvailable": 0,                            "currentTier": null,                            "CardCount": 0                        },                        "KeepsakeOrnamentClub": {                            "CharterMember": false,                            "MemberSince": 0,                            "DateExpires": null                        }                    },                    {                        "membershipType": "Crown Rewards",                        "id": 914247609031,                        "memberCurrentStatus": "1",                        "effStartDateCR": "2024-08-09T22:48:06Z",                        "memberCurrentStatusHD": "EARN AND ISSUE",                        "memberLastUpdate": "8/09/2024 10:48:07 PM",                        "rank": "3",                        "CrownRewardsLoyalty": {                            "currentTierNumber": 0,                            "MemberPointsAvailable": 0,                            "currentTier": null,                            "CardCount": 0                        },                        "KeepsakeOrnamentClub": {                            "CharterMember": false,                            "MemberSince": 0,                            "DateExpires": null                        }                    }                ],                "hPlusMembership": [                    {                        "uuid": "184d53bb-f05e-4039-8825-10f0889f01f5",                        "accountId": "1970714",                        "accountReference": "0010AXRK0EUDPDJ622",                        "subscriptionStatus": "ACTIVE",                        "subscriptionLength": "ANNUAL",                        "entitlementStatus": "true",                        "entitlementStartDate": "8/09/2024 6:23:23 PM",                        "entitlementEndDate": "8/13/2024 2:28:23 AM",                        "subscriptionStartDate": "8/09/2024 6:23:23 PM",                        "subscriptionEndDate": "8/13/2024 2:28:23 AM",                        "freeTrialFlag": true,                        "freeTrialStatus": "INACTIVE",                        "freeTrialStartDate": "8/09/2024 6:23:23 PM",                        "freeTrialEndDate": "8/09/2024 6:28:23 PM",                        "origSourceOfDataId": "121001",                        "origSourceOfDataDesc": "HPLUS ON HMK.COM",                        "origSourceCapturedDt": "8/09/2024 6:22:42 PM",                        "autoRenewStatus": "true",                        "cancellationDate": "",                        "cancelReason": null                    }                ]            }        ]    }}';
            
            customerWrapper = CEMS_CustomerData_Wrapper.parseCustomerData(resp,'https://apiwaf-qa.hallmark.com/secure/hmk-care-knowher-exp-api-qa/api/v1/hmkretail/consumers?homePhone=5552226666&email=email=jondon@hotmail.biz');
            system.debug('customerWrapper'+customerWrapper);
            
        }else{        
            //Raghav - 2019 added new parameter hPlusMemberUUID value null    
            customerWrapper = cCon.CEMS_Get(null, inputList[0].phone, inputList[0].email, null, null, null, null, null,false);
        }
        
        System.debug('getConCRDetails @@customerWrapper='+customerWrapper);
        Output outputData = new Output();
        outputData.consumerFound = false;
        outputData.noEmailOnConsumer = false;
        outputData.EntitledToHallmarkPlus = false;
        
        //If we received a response with an empty errors list continue
        if (customerWrapper.Errors.isEmpty() && !customerWrapper.Result.consumers.isEmpty()) {
            CEMS_CustomerData_Wrapper.Consumers chatConsumer = new CEMS_CustomerData_Wrapper.Consumers();
            
            if(customerWrapper.Result.consumers.size() == 1){
                
                Integer TotalToPlatinum = 2500;
                Integer YTDPointBalance = 0;
                String consumerCRDetailsOrRewards = '';
                
                if(inputList[0].consumerCRDetailsOrRewards != null || inputList[0].consumerCRDetailsOrRewards != '' )
                    consumerCRDetailsOrRewards = inputList[0].consumerCRDetailsOrRewards;
                else
                    consumerCRDetailsOrRewards = 'CR Details';
                
                
                
                outputData.consumerFound = true;
                
                
                if(customerWrapper.Result.consumers[0].email != null){
                    if(customerWrapper.Result.consumers[0].email.address == null || customerWrapper.Result.consumers[0].email.address == '' ){
                        outputData.noEmailOnConsumer = true;                   
                    }
                }
                else
                    outputData.noEmailOnConsumer = true; 
                
                
                
                if(!customerWrapper.Result.consumers[0].memberships.isEmpty() 
                   && !String.isBlank(customerWrapper.Result.consumers[0].memberships[0].id)){
                       
                       outputData.CRNumber = customerWrapper.Result.consumers[0].memberships[0].id;
                       if(consumerCRDetailsOrRewards == 'CR Details'){
                           Map<String, Object> dataMap;
                            String memberInfo = '';
                           if(Test.isRunningTest()){
                               memberInfo = '{"YTDPointBalance":"720","PointBalance":120,"LifetimePointsEarned":720,"LastTransactionDate":"2025-08-19","InternalId":"333434","Id":"995012278035","Enrolled":"2025-08-19","CrownRewardsTier":"Member"}';
                               dataMap = (Map<String, Object>) JSON.deserializeUntyped(memberInfo);
                               
                           }else{        
                               //Raghav - 2019 added new parameter hPlusMemberUUID value null    
                               memberInfo = Care_RewardsMbrInfoController.getMemberInfo(customerWrapper.Result.consumers[0].memberships[0].id);
                               System.debug('memberInfo ==='+memberInfo);
                               
                               dataMap = (Map<String, Object>) JSON.deserializeUntyped(memberInfo);
                           }
                           
                           
                           outputData.CRMembershipTier = (String) dataMap.get('CrownRewardsTier');
                           outputData.CRPoints = String.valueOf(dataMap.get('PointBalance') );
                           outputData.integerCRPoints = Integer.valueOf(dataMap.get('PointBalance') );
                           
                           if(outputData.CRMembershipTier != 'Platinum'){
                               YTDPointBalance = Integer.valueOf(dataMap.get('YTDPointBalance') );
                               outputData.CRPointsToPlatinum = String.valueOf(TotalToPlatinum - YTDPointBalance);
                           }
                           //find if consumer is entitled to Hallmark+
                           
                           if (customerWrapper.Result.consumers[0].hPlusMembership == null ||
                               customerWrapper.Result.consumers[0].hPlusMembership.size() == 0
                              ) 
                           {
                               outputData.EntitledToHallmarkPlus = false;
                           }else {
                               CEMS_CustomerData_Wrapper.AlternateId primaryAlternateId =
                                   getPrimaryAlternateId(customerWrapper.Result.consumers[0]);
                               if (primaryAlternateId != null
                                    && primaryAlternateId.hPlusMembership != null
                                    && primaryAlternateId.hPlusMembership.uuid != null){
                                        
                                        Integer iter = 0;
                                        List<CEMS_CustomerData_Wrapper.hPlusMembership> hPlusMemberships = customerWrapper.Result.consumers[0].hPlusMembership;
                                        
                                        for(iter = 0; iter < hPlusMemberships.size(); iter++ ){
                                            if(hPlusMemberships[iter].uuid == String.valueOf(primaryAlternateId.hPlusMembership.uuid) ){
                                                if((String.isNotBlank(hPlusMemberships[iter].entitlementStatus)) && (hPlusMemberships[iter].entitlementStatus == 'true' ))
                                                    outputData.EntitledToHallmarkPlus = True;
                                                else if((String.isNotBlank(hPlusMemberships[iter].entitlementStatus)) && (hPlusMemberships[iter].entitlementStatus == 'false' ))
                                                    outputData.EntitledToHallmarkPlus = False;
                                                else
                                                    outputData.EntitledToHallmarkPlus = False;
                                            }
                                        }
                                        
                                        
                                    }
                           }
                           
                           
                       }
                       if(consumerCRDetailsOrRewards == 'CR Rewards'){
                           
                           List<Care_RewardsCertWrapper> certificates = new List<Care_RewardsCertWrapper>();
                           if(Test.isRunningTest()){
                               Care_RewardsCertWrapper Care_RewardsCert = new Care_RewardsCertWrapper();
                               Care_RewardsCert.PointCost = '10';
                               Care_RewardsCert.status = 'Expired';
                               Care_RewardsCert.ExpirationDate = System.today();
                               certificates.add(Care_RewardsCert);
                           }else{        
                               certificates = Care_RewardsCertDetailsController.getCertificateInfoRaw(customerWrapper.Result.consumers[0].memberships[0].id);
                           }

                           System.debug('certificates == '+ certificates);
                           Integer availableRewardsCount = 0;
                           Integer bonusRewardsCount = 0;
                           Integer expiredRewardsCount = 0;
                           for(Care_RewardsCertWrapper certificate : certificates){
                               System.debug('CR Info n = '+ certificate);
                               
                               //Insert available rewards = Count of issued rewards where point cost > 0 && status = available 
                               if (Decimal.valueOf(certificate.PointCost) > 0 && certificate.status == 'Available') {
                                   availableRewardsCount++;
                               }
                               //Insert bonus rewards = Count of issued rewards where point cost = 0 && status = available 
                               if (Decimal.valueOf(certificate.PointCost) == 0 && certificate.status == 'Available') {
                                   bonusRewardsCount++;
                               }
                               //Expired rewards = Count of issued rewards where point cost > 0 && status = expired && ExpirationDate + 45days > Today. 
                               if (Decimal.valueOf(certificate.PointCost) > 0 && certificate.status == 'Expired' 
                                   && certificate.ExpirationDate != null
                                   && Date.valueOf(certificate.ExpirationDate).addDays(+45) > Date.today()) {
                                       expiredRewardsCount++;
                                   }
                               
                               
                           }
                           outputData.availableRewardsCount = availableRewardsCount;
                           outputData.bonusRewardsCount = bonusRewardsCount;
                           outputData.expiredRewardsCount = expiredRewardsCount;                          
                           
                       }
                       
                   }
                
                
            }
        }
        outputList.add(outputData);    
        System.debug('outputList == '+outputList);
        return outputList;
    }
    
    public class Output {
        
        @InvocableVariable(label='Consumer Found')
        public Boolean consumerFound;
        
        @InvocableVariable(label='Crown Rewards Number')
        public String CRNumber;
        
        @InvocableVariable(label='CR Membership Tier')
        public String CRMembershipTier;
        
        @InvocableVariable(label='CR Point Balance')
        public String CRPoints;
        
        @InvocableVariable(label='Integer CR Point Balance')
        public Integer integerCRPoints;
        
        @InvocableVariable(label='Points Away from Platinum')
        public String CRPointsToPlatinum;
        
        @InvocableVariable(label='CR AvailableRewardsCount')
        public Integer availableRewardsCount;
        
        @InvocableVariable(label='CR BonusRewardsCount')
        public Integer bonusRewardsCount;
        
        @InvocableVariable(label='CR expiredRewardsCount')
        public Integer expiredRewardsCount;
        
        @InvocableVariable(label='EntitledToHallmarkPlus?')
        public Boolean EntitledToHallmarkPlus;
        
        @InvocableVariable(label='No Email on Consumer')
        public Boolean noEmailOnConsumer;
        
        
    }
}
