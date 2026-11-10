@IsTest
public class HplusAccountTabContainerControllerTest {

    @TestSetup
    static void setupData() {
        // Create an Account
        //Naeem:Care-2147
        Account acc = new Account(Name = 'Test Account', uuid__c = 'UUID-123456');
        insert acc;

        // Create a Hallmarkplus__c record
        Hallmarkplus__c hallmarkPlus = new Hallmarkplus__c(
            Accountid__c = acc.Id,
            uuid__c = 'UUID-123456',
            //Akamai_Login__c = 'test@example.com',
            Type__c = 'Monthly',
            Auto_Renewel_On__c = 'Yes',
            Current_Start_Date__c = DateTime.now().addMonths(-1),
            Original_Start_Date__c = DateTime.now().addYears(-1),
            Current_End_Date__c = DateTime.now().addMonths(11),
            Status__c = 'Active',
            Crown_Rewards_Tier__c = 'Gold',
            Source__c = 'Online',
            Linked_Login_Status__c = 'Linked',
            Crown_Rewards_Number__c = 'CRN-123456',
            Account_ID__c = '1796831'
        );
        insert hallmarkPlus;
    }

    @IsTest
    static void testGetHplusNumber() {
        // Retrieve the test Account and Hallmarkplus__c records
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test the getHplusNumber method
        String uuid = HplusAccountTabContainerController.getHplusNumber(acc.Id);
        System.assertEquals('UUID-123456', uuid);

        // Test when accountId is null
        uuid = HplusAccountTabContainerController.getHplusNumber(null);
        System.assertEquals('', uuid);
    }

    @IsTest
    static void testGetHplusNumberInfo() {
        Test.setMock(HttpCalloutMock.class, new Care_MPP_ConnectorMock());
        // Retrieve the test Account and Hallmarkplus__c records
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Test the getHplusNumberinfo method
        Test.startTest();
        HPlusInfoWrapper wrapper = HplusAccountTabContainerController.getHplusNumberinfo(acc.Id);
        Test.stopTest();

        //System.assertNotNull(wrapper);
       // System.assertEquals('test@example.com', wrapper.akamaiLogin);
        System.assertEquals('Monthly', wrapper.Type);
        System.assertEquals('Yes', wrapper.Autoren);
        //System.assertEquals(DateTime.now().addMonths(-1), wrapper.csd);
       // System.assertEquals(DateTime.now().addYears(-1), wrapper.osd);
        //System.assertEquals(DateTime.now().addMonths(11), wrapper.ced);
        System.assertEquals('Active', wrapper.status);
        System.assertEquals('Gold', wrapper.crt);
        System.assertEquals('Online', wrapper.source);
        System.assertEquals('Linked', wrapper.lls);
        System.assertEquals('CRN-123456', wrapper.cr);

       
    }

     @IsTest
    static void testGetHplusNumberInfo_NoRecords() {
        // Create a new Account that does not have any Hallmarkplus__c records
        Account accWithoutRecords = new Account(Name = 'Account Without Records');
        insert accWithoutRecords;

        // Test the getHplusNumberinfo method with an AccountId that has no Hallmarkplus__c records
        HPlusInfoWrapper wrapper = HplusAccountTabContainerController.getHplusNumberinfo(accWithoutRecords.Id);

        // Assert that the returned wrapper is empty
       // Test the getHplusNumberinfo method with an AccountId that has no Hallmarkplus__c records
      //  HPlusInfoWrapper wrapper = HplusAccountTabContainerController.getHplusNumberinfo(accWithoutRecords.Id);

        // Assert that the returned wrapper is empty
       // System.assertNotNull(wrapper);
        System.assertEquals(null, wrapper.akamaiLogin);
        System.assertEquals(null, wrapper.Type);
        System.assertEquals(null, wrapper.Autoren);
        System.assertEquals(null, wrapper.csd);
        System.assertEquals(null, wrapper.osd);
        System.assertEquals(null, wrapper.ced);
        System.assertEquals(null, wrapper.status);
        System.assertEquals(null, wrapper.crt);
        System.assertEquals(null, wrapper.source);
        System.assertEquals(null, wrapper.lls);
        System.assertEquals(null, wrapper.cr);
    }

    @IsTest
    static void demoConsumerDisplaysOnlineAccountAndMembershipSource() {
        Account demoAccount = new Account(
            Name = 'Demo TikTok Consumer',
            CID__c = '990000000008'
        );
        insert demoAccount;

        Test.startTest();
        String uuid = HplusAccountTabContainerController.getHplusNumber(demoAccount.Id);
        HPlusInfoWrapper wrapper =
            HplusAccountTabContainerController.getHplusNumberinfo(demoAccount.Id);
        Test.stopTest();

        System.assertEquals('demo-990000000008', uuid);
        System.assertEquals('TikTok Shop', wrapper.membershipSource);
        System.assertEquals('Active', wrapper.status);
        System.assertEquals('ANNUAL', wrapper.Type);
    }
public class Care_MPP_ConnectorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Mock response for getMPPSessionId
            if (req.getEndpoint().contains('bootstrap')) {
                String sessionResponseBody = '{' +
                    '"products": ["product1"],' +
                    '"mppTokenAttributes": {' +
                        '"sessionId": "test-session-id-123",' +
                        '"accountRef": "1796831",' +
                        '"sessionExpiration": "2025-05-12T12:00:00Z"' +
                    '},' +
                    '"subscriptions": []' +
                    '}';
                res.setBody(sessionResponseBody);
            }
            // Mock response for fetchSubscriptions
            else {
                String subscriptionResponseBody = '[{"startDate": "2020-06-15T07:00:00", "expiryDate": "2024-05-21T19:01:23.317", "subscriptionLastUpdated": "2024-06-18T16:14:44.470", "firstNonDiscountedBillingPointUtc": "0001-01-01T00:00:00", "lastDiscountedBillingPointUtc": "0001-01-01T00:00:00", "paymentMethod": "CreditDebitCard", "recurringPaymentInfo": { "subscriptionReference": "0010S8W50GJW42F3H2", "subscribedPrice": 7.99, "recurringPaymentEnable": false, "lockedIn": false, "nextPaymentDate": "2024-05-21T19:01:23.317", "subscriptionStatusDescripton": "CancelledByAutoRenew", "subscriptionStatusId": 4, "subscriptionNote": "Subscription deactivated by Auto-Renew on 5/21/2024 7:01:23 PM", "autoRenewStatus": "Inactive", "renewalCount": 43, "isBeyondGracePeriod": false, "alternativePaymentConnector": false, "previousBillingInfo": { "contractPriceReference": "0010MEOUI2H3MWJVX2", "totalAmount": 5.99, "totalTaxAmount": 0.456, "totalNetAmount": 5.534, "billingDate": "2024-04-21T07:00:31.407", "paymentDate": "2024-05-21T19:01:23.317", "taxInfo": [ { "regionName": "USA", "regionType": "Country", "displayName": "United States", "category": "Standard", "rate": 0.0, "amount": 0.0, "taxRegionGroupId": 36907, "taxRegionGroupName": "" } ] }, "voucherCodes": { "discountPrice": 0.0 }, "subscriptionVoucherCodes": [], "customSubscriptionParameters": {} }, "contractInfo": { "customContractParameters": { "webDescription": "After your free trial ends...", "winbackVoucher": "9M536D9PM4", "saveCampaignVoucher": "9M536D9PM4" }, "status": "active", "title": "H+ Monthly", "licenseLevel": 1, "contractReference": "0010CQLKDIJ2JVYQ23", "serviceId": 15994, "serviceAffiliateId": 5067, "serviceType": "SubscriptionPeriod", "serviceDescription": "Hallmark Movies Now monthly subscription.", "serviceRenewalType": "Forever", "holidayConfigurationIsEnabled": false, "upgradeDowngradePermitted": true, "renewUntil": "-" } }]';
                res.setBody(subscriptionResponseBody);
            }

            return res;
        }
    }
}
