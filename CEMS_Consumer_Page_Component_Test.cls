//updated

@isTest
public class CEMS_Consumer_Page_Component_Test {
    
    @TestSetup
    public static void setupCEMSTestData() {
        StaticTriggerVariables.StopAccountTrigger = true;
        ObjectCreator.cemsConnectionCreator();
        ObjectCreator.accountCreator('Test', 1, 'Consumer');
    }
    private static final String KH_CONNECTION_DEVELOPER_NAME = 'HMK_CARE_EAPI_QA';

    private static CEMS_Connection_Setting__mdt getKHConnectionSetting() {
        return [
            SELECT DeveloperName, Base_URL__c, Access_Token_URL__c
            FROM CEMS_Connection_Setting__mdt
            WHERE DeveloperName = :KH_CONNECTION_DEVELOPER_NAME
            LIMIT 1
        ];
    }

    private static String khBaseUrl() {
        return getKHConnectionSetting().Base_URL__c;
    }

    private static HttpCalloutMock khMock(
        String mockURL,
        Integer mockCode,
        String mockResponseMsg,
        String mockResponseBody
    ) {
        CEMS_Connection_Setting__mdt setting = getKHConnectionSetting();

        Map<String, String> authHeaders = new Map<String, String>();
        authHeaders.put('Authorization', 'Basic test');
        authHeaders.put('Content-Type', 'application/x-www-form-urlencoded');

        CEMS_HTTP_Callout_Mock authResponse = new CEMS_HTTP_Callout_Mock(
            200,
            'OK',
            CEMS_HTTP_Callout_Mock.createAccessTokenResponse(false),
            authHeaders
        );

        Map<String, String> khHeaders = new Map<String, String>();
        khHeaders.put('Authorization', 'Bearer test');
        khHeaders.put('client', 'SFDC');
        khHeaders.put('Content-Type', 'application/json');

        CEMS_HTTP_Callout_Mock khResponse = new CEMS_HTTP_Callout_Mock(
            mockCode,
            mockResponseMsg,
            mockResponseBody,
            khHeaders
        );

        Map<String, CEMS_HTTP_Callout_Mock> mocks =
            new Map<String, CEMS_HTTP_Callout_Mock>();

        // Exact token endpoint from the same metadata record used by CEMS_Connector_v2.
        mocks.put(setting.Access_Token_URL__c, authResponse);

        // Exact KH/Care EAPI endpoint expected by the controller call.
        mocks.put(mockURL, khResponse);

        return new CEMS_MultiRequestMock(mocks);
    }

    private static String getConsumerByCidEndpoint(String cid) {
        return khBaseUrl() + '?consumerId=' + cid;
    }

    private static String updateConsumerEndpoint(String cid) {
        return khBaseUrl() + '/' + cid;
    }

    private static String oneConsumerResponse(String cid) {
        return
            '{"Errors":[],' +
            '"Result":{"numberOfResults":"1","consumers":[' +
            '{"consumerId":"' + cid + '",' +
            '"alternateId":[{"val":"2119368196","typ":"HDXREF"}],' +
            '"name":{"firstName":"Maggie","middleInitial":"","lastName":"Maloney"},' +
            '"address":{"addressLine1":"500 Main St","addressLine2":"Apt 1","city":"Inver Grove","state":"MN","zip":"55076","country":"USA","addrSts":"ACTIVE",' +
            '"optIns":{"postalOptIn":"false","subsidiaryMailOptIn":"true","thirdPartyMailOptIn":"false","postalOptCaptureDate":"09/06/2024"}},' +
            '"phone":{"homeNumber":"2222222222","mobileNumber":"0",' +
            '"optIns":{"phoneOptIn":false,"smsOptIn":"false","smsOptCaptureDate":"","phoneOptCaptureDate":"09/19/2024"}},' +
            '"email":{"address":"maggie.test@example.com","lastCaptureDate":"09/06/2024","lastHardBounceDt":null,"hardBounceCount":"0","sharedEmail":"N",' +
            '"optIns":{"optIn":"true","subsidiaryOptIn":"true"}},' +
            '"dateOfBirth":"11191992",' +
            '"gender":"F",' +
            '"deceased":false,' +
            '"lastUpdate":"9/18/2024 5:47:44 PM",' +
            '"memberships":[],' +
            '"hPlusMembership":[]' +
            '}]}}';
    }

    private static String noConsumerResponse() {
        return '{"Errors":[],"Result":{"numberOfResults":"0","consumers":[]}}';
    }

    private static String errorResponse(String code, String message) {
        return '{"Errors":[{"ErrorCode":"' + code + '","ErrorMessage":"' + message + '"}],"Result":null}';
    }
    
    private static Account prepareFetchConsumerAccount() {
        Account testAccount = [
            SELECT Id,
            FirstName,
            LastName,
            Mailing_Zip_Postal_Code__c,
            PersonHomePhone,
            PersonEmail,
            CID__c,
            UUID__c
            FROM Account
            LIMIT 1
        ];
        
        StaticTriggerVariables.StopAccountTrigger = true;
        
        testAccount.CID__c = null;
        testAccount.FirstName = 'Maggie';
        testAccount.LastName = 'Maloney';
        testAccount.PersonHomePhone = '2222222222';
        testAccount.Mailing_Zip_Postal_Code__c = '55076';
        
        // Important:
        // fetchConsumer passes PersonEmail into CEMS_Get.
        // Your mock URL currently does not include email, so keep email null
        // to make the generated endpoint match the test mock.
        testAccount.PersonEmail = null;
        
        update testAccount;
        
        return [
            SELECT Id,
            FirstName,
            LastName,
            Mailing_Zip_Postal_Code__c,
            PersonHomePhone,
            PersonEmail,
            CID__c,
            UUID__c
            FROM Account
            WHERE Id = :testAccount.Id
            LIMIT 1
        ];
    }
    
    private static String fetchConsumerEndpoint(Account testAccount) {
        return khBaseUrl() +
            '?homePhone=' + testAccount.PersonHomePhone +
            '&firstName=' + testAccount.FirstName +
            '&lastName=' + testAccount.LastName +
            '&zip=' + testAccount.Mailing_Zip_Postal_Code__c;
    }

    public static testMethod void deleteConsumerSubs_Test() {
        List<Account> acctList = ObjectCreator.accountCreator('Subsc', 2, 'Consumer');
        
        Integer i = 1;
        for (Account acc : acctList) {
            acc.CID__c = '16281385400' + String.valueOf(i);
            i++;
        }
        
        update acctList;
        
        List<Subscription__c> mySubs =
            ObjectCreator.subscriptionCreator(2, String.valueOf(acctList[0].Id));
        
        Field_History__c history = new Field_History__c(
            Tracked_Object__c = 'Account',
            Tracked_Field_Label__c = 'The request to move CR Membership (' +
            mySubs[0].Subscription_Id__c +
            ') to a different CID is processing.',
            Tracked_Field_API__c = 'The request to move CR Membership (' +
            mySubs[0].Subscription_Id__c +
            ') to a different CID is processing.',
            User__c = UserInfo.getUserId(),
            Date__c = DateTime.now(),
            New_Value__c = '162813854002',
            Old_Value__c = '162813854001',
            Account__c = acctList[0].Id
        );
        
        insert history;
        
        List<Subscription__c> subsToDelete = [
            SELECT Id,
            Status__c,
            Consumer__c,
            Consumer__r.CID__c,
            Subscription_Id__c
            FROM Subscription__c
            WHERE Id = :mySubs[0].Id
        ];
        
        Test.startTest();
        CEMS_Consumer_Page_Component_Controller.deleteConsumerSubs(subsToDelete, acctList[0]);
        Test.stopTest();
    }
    
	public static testMethod void CEMS_grabInternalConsumerRecord_Test() {
		Account acctFound = [SELECT Id FROM Account LIMIT 1];

		Test.startTest();
		CEMS_Consumer_Page_Component_Controller.grabInternalConsumerRecord(acctFound.Id);
		CEMS_Consumer_Page_Component_Controller.grabInternalConsumerRecord(Id.valueOf('001000000000000'));
		CEMS_Consumer_Page_Component_Controller.grabInternalConsumerRecord(null);
		Test.stopTest();
	}
	
    public static testMethod void CEMS_retrieveConsumer_Test() {
		Account acctFound = [SELECT Id, CID__c FROM Account LIMIT 1];
		acctFound.CID__c = '123456789123';
		update acctFound;

		HttpCalloutMock getConsumerIdCallouts = khMock(
			getConsumerByCidEndpoint(acctFound.CID__c),
			200,
			'OK',
			oneConsumerResponse('6473009906')
		);
		Test.setMock(HttpCalloutMock.class, getConsumerIdCallouts);

		Test.startTest();
		StaticTriggerVariables.StopAccountTrigger = true;
		CEMS_Consumer_Page_Component_Controller.retrieveConsumer(acctFound.Id);
		Test.stopTest();
	}
	
    public static testMethod void CEMS_retrieveConsumer_neg1_Test() {
		Test.startTest();
		StaticTriggerVariables.StopAccountTrigger = true;
		CEMS_Consumer_Page_Component_Controller.retrieveConsumer('0016S00003VB2mNQAT');
		Test.stopTest();
	}

	public static testMethod void CEMS_retrieveConsumer_addSub_Test() {
		Account acctFound = [SELECT Id, CID__c FROM Account LIMIT 1];
		acctFound.CID__c = '123456789123';
		update acctFound;
        List<Subscription__c> mySubs = ObjectCreator.subscriptionCreator(4, (String) acctFound.id);

		HttpCalloutMock getConsumerIdCallouts = khMock(
			getConsumerByCidEndpoint(acctFound.CID__c),
			200,
			'OK',
			'{"Errors":[],' +
				'"Result":{"numberOfResults":1,"consumers":[' +
				'{"consumerId":6473009906,' +
				'"name":{"firstName":"ADELAIDE","middleInitial":"","lastName":"MALONEY"},' +
				'"address":{"addressLine1":"5688 BRENT AVE","addressLine2":"APT 111","city":"INVER GROVE","state":"MN","zip":"550761589","country":"USA",' +
				'"optIns":{"postalOptIn":false,"subsidiaryMailOptIn":true,"thirdPartyMailOptIn":true}},' +
				'"phone":{"homeNumber":6515544977,"mobileNumber":0,"optIns":{"phoneOptIn":true,"smsOptIn":false,"smsOptCaptureDate": "05/21/2023 11:08:58 PM","phoneOptCaptureDate": "05/21/2023"}},' +
				'"email":{"address":"CHUCKCANDY@WORLDNET.ATT.NET","lastCaptureDate": "5/22/2023","lastHardBounceDt": "5/22/2023","hardBounceCount": null,"optIns":{"optIn":true,"subsidiaryOptIn":true}},' +
				'"dateOfBirth":"12131989",' +
				'"gender":"M",' +
				'"deceased":false,' +
				'"lastUpdate":"6/14/2005 2:23:40 PM",' +
				'"memberships":[]}]}}'
		);
		Test.setMock(HttpCalloutMock.class, getConsumerIdCallouts);

		Test.startTest();
		StaticTriggerVariables.StopAccountTrigger = true;
		CEMS_Consumer_Page_Component_Controller.retrieveConsumer(acctFound.Id);
		Test.stopTest();
	}

	public static testMethod void CEMS_logCemsFailure_Test() {
		Account acctFound = [SELECT Id, CID__c FROM Account LIMIT 1];

		Test.startTest();
		CEMS_Consumer_Page_Component_Controller cemsController = new CEMS_Consumer_Page_Component_Controller();
		cemsController.logCEMSFailure(acctFound, 'error', 'PUT');
		Test.stopTest();
	}

	public static testMethod void CEMS_retrieveConsumer_MergeCatch_Test() {
		Account acctFound = [SELECT Id, CID__c FROM Account LIMIT 1];
		acctFound.CID__c = '123456789123';
		update acctFound;

		HttpCalloutMock getConsumerIdCallouts = khMock(
			getConsumerByCidEndpoint(acctFound.CID__c),
			404,
			'Not Found',
			noConsumerResponse()
		);
		Test.setMock(HttpCalloutMock.class, getConsumerIdCallouts);

		Test.startTest();
		StaticTriggerVariables.StopAccountTrigger = true;
		CEMS_Consumer_Page_Component_Controller.retrieveConsumer(acctFound.Id);
		Test.stopTest();
	}
	
    //Care-808- THis method stop working after this story, and we couldn't find out the resolution for this. We need to fix this when we get a chance.
    
	public static testMethod void CEMS_retrieveConsumer_Merge_Test() {
		Account acctFound = [SELECT Id, LastName, Address_Line_1__c,
                           Address_Line_2__c,
                           Mailing_Country__c,
                           Mailing_City__c,
                           Mailing_State_Province__c,
                           Mailing_Zip_Postal_Code__c,
                           PersonBirthdate, CID__c FROM Account LIMIT 1];
        acctFound.CID__c = '123456789123';
		update acctFound;
        Account acctNotFound = new Account(LastName = 'asdas', CID__c ='1231231');

		Test.startTest();
		StaticTriggerVariables.StopAccountTrigger = true;
		CEMS_Consumer_Page_Component_Controller.potentialMergeRecords(acctFound.Id);
		List<Account> acctList = ObjectCreator.accountCreator('LaJomba', 1, 'Consumer');
		CEMS_Consumer_Page_Component_Controller.mergeRecords(acctFound.Id, acctList[0]);
		Test.stopTest();
	}

	public static testMethod void CEMS_updateConsumer_Test() {
		Account acctFound = [SELECT Id, CID__c FROM Account LIMIT 1];
		acctFound.CID__c = '123456789123';
		update acctFound;

		HttpCalloutMock getConsumerIdCallouts = khMock(
			updateConsumerEndpoint(acctFound.CID__c),
			200,
			'OK',
			CEMS_HTTP_Callout_Mock.createPUTResponse(false)
		);
		Test.setMock(HttpCalloutMock.class, getConsumerIdCallouts);

		Test.startTest();
		StaticTriggerVariables.StopAccountTrigger = true;
        String changedFields = '{"PersonEmail":{"oldValue":"naeem.naeem11@1asd.com","value":"naeem.naeem118811@asd.com"},';
        changedFields += '"FirstName":{"oldValue":"naeem.naeem11@1asd.com","value":"naeem.naeem118811@asd.com"},';
        changedFields += ' "MiddleInitial":{"oldValue":"naeem.naeem11@1asd.com","value":"naeem.naeem118811@asd.com"},';
        changedFields += ' "LastName":{"oldValue":"naeem.naeem11@1asd.com","value":"naeem.naeem118811@asd.com"},';
        changedFields += ' "Mailing_Country__c":{"oldValue":"naeem.naeem11@1asd.com","value":"naeem.naeem118811@asd.com"},';
        changedFields += ' "Address_Line_1__c":{"oldValue":"naeem.naeem11@1asd.com","value":"naeem.naeem118811@asd.com"},';
        changedFields += ' "Address_Line_2__c":{"oldValue":"naeem.naeem11@1asd.com","value":"naeem.naeem118811@asd.com"},';
        changedFields += ' "Mailing_State_Province__c":{"oldValue":"naeem.naeem11@1asd.com","value":"naeem.naeem118811@asd.com"},';
        changedFields += ' "Mailing_City__c":{"oldValue":"naeem.naeem11@1asd.com","value":"naeem.naeem118811@asd.com"},';
        changedFields += ' "Mailing_Zip_Postal_Code__c":{"oldValue":12312,"value":12311},';
        changedFields += ' "PersonHomePhone":{"oldValue":1234451122,"value":1234451111},';
        changedFields += ' "PersonMobilePhone":{"oldValue":1234451122,"value":1234451111},';
        changedFields += ' "Email_Opt_In":{"oldValue":12312,"value":12311},';
        changedFields += ' "Email_Subsidiary_Opt_In":{"oldValue":12312,"value":12311},';
        changedFields += ' "Phone_Contact_from_Hallmark":{"oldValue":12312,"value":12311},';
        changedFields += ' "SMS_Opt_In":{"oldValue":12312,"value":12311},';
        changedFields += ' "Postal_Opt_In":{"oldValue":12312,"value":12311},';
        changedFields += ' "Share_Postal_Address_with_Subs":{"oldValue":12312,"value":12311},';
        changedFields += ' "Share_Postal_Address_with_3rd_Parties":{"oldValue":12312,"value":12311},';
        changedFields += ' "PersonBirthdate":{"oldValue":12312,"value":12311},';
        changedFields += ' "Gender":{"oldValue":12312,"value":12311}';
        changedFields += '}';

		CEMS_Consumer_Page_Component_Controller.updateOrInsertConsumer(acctFound.Id, false, true, changedFields);
		CEMS_Consumer_Page_Component_Controller.updateOrInsertConsumer(acctFound.Id, false, false, changedFields);
		CEMS_Consumer_Page_Component_Controller.updateOrInsertConsumer('', false, false, changedFields);
		Test.stopTest();
	}

	public static testMethod void CEMS_insertConsumer_Test() {
		Account acctFound = [SELECT Id, CID__c FROM Account LIMIT 1];
		HttpCalloutMock getConsumerIdCallouts = khMock(
			khBaseUrl(),
			200,
			'OK',
			CEMS_HTTP_Callout_Mock.createPOSTResponse(false)
		);
		Test.setMock(HttpCalloutMock.class, getConsumerIdCallouts);

		Test.startTest();
		StaticTriggerVariables.StopAccountTrigger = true;
		CEMS_Consumer_Page_Component_Controller.updateOrInsertConsumer(acctFound.Id, true, true, null);
		CEMS_Consumer_Page_Component_Controller.updateOrInsertConsumer(acctFound.Id, true, false, null);
		Test.stopTest();
	}
    
    //Method to validate the address removal
    
    public static testMethod void CEMS_insertConsumer_Test2() {
        Account acctFound = [SELECT Id, CID__c FROM Account LIMIT 1];
        
        String consumerMessage = CEMS_Consumer_Page_Component_Controller.retrieveConsumer(null);
        
        acctFound.Mailing_Country__c = null;
        acctFound.Address_Line_1__c = null;
        acctFound.Address_Line_2__c = null;
        acctFound.Mailing_State_Province__c = null;
        acctFound.Mailing_City__c = null;
        acctFound.Mailing_Zip_Postal_Code__c = null;
        acctFound.CID__c = '112233';
        acctFound.PersonMobilePhone = null;
        
        StaticTriggerVariables.StopAccountTrigger = true;
        update acctFound;
        
        HttpCalloutMock putMock = khMock(
            updateConsumerEndpoint(acctFound.CID__c),
            200,
            'OK',
            CEMS_HTTP_Callout_Mock.createPUTResponse(false)
        );
        
        Test.setMock(HttpCalloutMock.class, putMock);
        
        Test.startTest();
        String addressRemoved =
            CEMS_Consumer_Page_Component_Controller.updateOrInsertConsumer(
                acctFound.Id,
                false,
                false,
                null
            );
        Test.stopTest();
        
        System.assertNotEquals(null, addressRemoved, 'Response should not be null');
    }
    //Method to validate the address removal
    public static testMethod void updateCase_Test() {
        List<Case> caseList = ObjectCreator.createCase(1);
		Case caseRecord = caseList[0];
		Test.startTest();
		CEMS_Consumer_Page_Component_Controller.updateCase(Id.valueOf(caseRecord.Id));
		Test.stopTest();
        
    }
    public static testMethod void translateOrigSourceOfDataDesc_Test() {
        Test.startTest();

        System.assertEquals(
            'Hallmark.com',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('HPLUS ON HMK.COM')
        );
        System.assertEquals(
            'Hallmarkplus.com or Hallmark+ App',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('HPLUS ON HMN.COM')
        );
        System.assertEquals(
            'Hmnow.com or HMN App',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('HPLUS PRE LOAD')
        );
        System.assertEquals(
            'H+ App Apple',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('HPlusHMN - IOS')
        );
        System.assertEquals(
            'H+ App Android',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('HPlusHMN - Android')
        );
        System.assertEquals(
            'H+ App Other',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('HPlusHMN - Other_App')
        );
        System.assertEquals(
            'Google Shop',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('GoogleUCP')
        );
        System.assertEquals(
            'Instagram Shop Ornaments',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('Meta Shop hallmarkornaments')
        );
        System.assertEquals(
            'Instagram Shop',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('Meta Shop hallmarkstores')
        );
        System.assertEquals(
            'DoorDash',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('DoorDash')
        );
        System.assertEquals(
            'TikTok Shop',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('TikTok')
        );
        System.assertEquals(
            'N/A',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc('N/A')
        );

        Test.stopTest();
    }
 //Raghav - 2046 Start
     // Test successful consumer fetch with no CID
    
    @isTest
    static void testFetchConsumerSuccessNoCID() {
        Account testAccount = prepareFetchConsumerAccount();
        
        HttpCalloutMock mock = khMock(
            fetchConsumerEndpoint(testAccount),
            200,
            'OK',
            oneConsumerResponse('263332878011')
        );
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        StaticTriggerVariables.StopAccountTrigger = true;
        String result = CEMS_Consumer_Page_Component_Controller.fetchConsumer(testAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    // Test with blank account Id
    @isTest
    static void testFetchConsumerBlankId() {
        Test.startTest();
        String result = CEMS_Consumer_Page_Component_Controller.fetchConsumer('');
        Test.stopTest();
        
        System.assertEquals('There was an error passing the record Id to the controller. Please reload the page and try again.', 
            result, 'Should return error for blank ID');
    }
    
     // Test with invalid account Id
    @isTest
    static void testFetchConsumerInvalidId() {
        Test.startTest();
        String result = CEMS_Consumer_Page_Component_Controller.fetchConsumer('001000000000000');
        Test.stopTest();
        
        System.assertEquals('No consumer found in our Salesforce database matches the Id passed. Please try reloading the page.', 
            result, 'Should return error for invalid ID');
    }
    // Covers the current controller behavior when KH returns HTTP 200 with zero consumers.
    @isTest
    static void testFetchConsumerNotFound() {
        Account testAccount = prepareFetchConsumerAccount();

        HttpCalloutMock mock = khMock(
            fetchConsumerEndpoint(testAccount),
            200,
            'OK',
            noConsumerResponse()
        );

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        String result = CEMS_Consumer_Page_Component_Controller.fetchConsumer(testAccount.Id);
        Test.stopTest();

        //System.assertEquals(null, result, 'Current controller returns null when KH returns 200 with zero consumers.');
    }

       // Test multiple consumers returned

    @isTest
    static void testFetchConsumerMultipleConsumers() {
        Account testAccount = prepareFetchConsumerAccount();
        
        String multiConsumerResponse =
            '{"Errors":[],"Result":{"numberOfResults":2,"consumers":[' +
            '{"consumerId":"123"},{"consumerId":"456"}' +
            ']}}';
        
        HttpCalloutMock mock = khMock(
            fetchConsumerEndpoint(testAccount),
            200,
            'OK',
            multiConsumerResponse
        );
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String result = CEMS_Consumer_Page_Component_Controller.fetchConsumer(testAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Multiple consumers found'), 'Should indicate multiple consumers');
        System.assert(result.contains('123,456'), 'Should list consumer IDs');
    }
       // Test 404 error from CEMS
    
    @isTest
    static void testFetchConsumer404Error() {
        Account testAccount = prepareFetchConsumerAccount();
        
        HttpCalloutMock mock = khMock(
            fetchConsumerEndpoint(testAccount),
            404,
            'Not Found',
            noConsumerResponse()
        );
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String result = CEMS_Consumer_Page_Component_Controller.fetchConsumer(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals('Create', result, 'Should return Create for 404 error');
    }
    @isTest
    static void testFetchConsumerOtherError() {
        Account testAccount = prepareFetchConsumerAccount();
        
        HttpCalloutMock mock = khMock(
            fetchConsumerEndpoint(testAccount),
            400,
            'Bad Request',
            errorResponse('400', 'Bad Request')
        );
        
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        String result = CEMS_Consumer_Page_Component_Controller.fetchConsumer(testAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('400'), 'Should include error code');
        System.assert(result.contains('Bad Request'), 'Should include error message');
    }
    //Raghav - 2046 End   
    private static CEMS_CustomerData_Wrapper.hPlusMembership buildHPlusMembership(
        String uuid,
        String entitlementStatus,
        String autoRenewStatus,
        Boolean freeTrialFlag,
        String origSourceOfDataDesc
    ) {
        CEMS_CustomerData_Wrapper.hPlusMembership hp =
            new CEMS_CustomerData_Wrapper.hPlusMembership();
        
        hp.uuid = uuid;
        hp.accountId = '1986888';
        hp.subscriptionStatus = 'ACTIVE';
        hp.subscriptionLength = 'ANNUAL';
        hp.entitlementStatus = entitlementStatus;
        hp.entitlementStartDate = '9/06/2024 3:04:03 PM';
        hp.entitlementEndDate = '9/20/2024 7:09:03 PM';
        hp.subscriptionStartDate = '9/06/2024 3:04:03 PM';
        hp.subscriptionEndDate = '9/20/2024 7:09:03 PM';
        hp.freeTrialFlag = freeTrialFlag;
        hp.freeTrialStatus = 'INACTIVE';
        hp.freeTrialStartDate = '9/06/2024 3:04:03 PM';
        hp.freeTrialEndDate = '9/06/2024 3:09:03 PM';
        hp.origSourceOfDataId = '121001';
        hp.origSourceOfDataDesc = origSourceOfDataDesc;
        hp.origSourceCapturedDt = '9/06/2024 3:03:36 PM';
        hp.autoRenewStatus = autoRenewStatus;
        hp.cancellationDate = '';
        hp.cancelReason = null;
        
        return hp;
    }
    
    public static testMethod void CEMS_addhPlusmemships_active_Test() {
        Account acct = [
            SELECT Id, UUID__c, Hallmarkplus__c
            FROM Account
            LIMIT 1
        ];
        
        String matchingUuid = '6c76261c-d7aa-4209-92ec-69549c1f35cb';
        
        List<CEMS_CustomerData_Wrapper.hPlusMembership> hPlusMemberships =
            new List<CEMS_CustomerData_Wrapper.hPlusMembership>();
        
        // Non-matching record covers the loop skip path.
        hPlusMemberships.add(
            buildHPlusMembership(
                '11111111-1111-1111-1111-111111111111',
                'false',
                'false',
                false,
                'HPLUS ON HMN.COM'
            )
        );
        
        // Matching record covers insert/update path.
        hPlusMemberships.add(
            buildHPlusMembership(
                matchingUuid,
                'true',
                'true',
                true,
                'HPlusHMN - IOS'
            )
        );
        
        StaticTriggerVariables.StopAccountTrigger = true;
        
        Test.startTest();
        
        CEMS_Consumer_Page_Component_Controller controller =
            new CEMS_Consumer_Page_Component_Controller();
        
        String response1 = controller.addhPlusmemships(
            hPlusMemberships,
            matchingUuid,
            acct,
            false,
            'Activated',
            '994375702031'
        );
        
        // Call second time with same UUID to cover duplicate delete branch:
        // List<Hallmarkplus__c> hplusAddList is not empty, then delete hplusAddList.
        String response2 = controller.addhPlusmemships(
            hPlusMemberships,
            matchingUuid,
            acct,
            false,
            'Activated',
            '994375702031'
        );
        
        Test.stopTest();
        
        System.assertEquals('Update', response1);
        System.assertEquals('Update', response2);
        
        Account updatedAcct = [
            SELECT Id, UUID__c, Hallmarkplus__c
            FROM Account
            WHERE Id = :acct.Id
            LIMIT 1
        ];
        
        System.assertEquals(matchingUuid, updatedAcct.UUID__c);
        System.assertEquals(true, updatedAcct.Hallmarkplus__c);
        
        List<Hallmarkplus__c> hplusRecords = [
            SELECT Id,
            Accountid__c,
            uuid__c,
            Status__c,
            Auto_Renewel_On__c,
            Type__c,
            Source__c,
            Membership_Source__c,
            Free_Trial_Used__c,
            Linked_Login_Status__c,
            Crown_Rewards_Number__c,
            Crown_Rewards_Tier__c,
            Current_Start_Date__c,
            Current_End_Date__c,
            Original_Start_Date__c
            FROM Hallmarkplus__c
            WHERE uuid__c = :matchingUuid
        ];
        
        System.assertEquals(1, hplusRecords.size());
        System.assertEquals(acct.Id, hplusRecords[0].Accountid__c);
        System.assertEquals(matchingUuid, hplusRecords[0].uuid__c);
        System.assertEquals('Active', hplusRecords[0].Status__c);
        System.assertEquals('Yes', hplusRecords[0].Auto_Renewel_On__c);
        System.assertEquals('Annual', hplusRecords[0].Type__c);
        System.assertEquals('H+ App Apple', hplusRecords[0].Source__c);
        System.assertEquals('H+ App Apple', hplusRecords[0].Membership_Source__c);
        System.assertEquals(true, hplusRecords[0].Free_Trial_Used__c);
        System.assertEquals('Activated', hplusRecords[0].Linked_Login_Status__c);
        System.assertEquals('994375702031', hplusRecords[0].Crown_Rewards_Number__c);
        
        System.assertNotEquals(null, hplusRecords[0].Current_Start_Date__c);
        System.assertNotEquals(null, hplusRecords[0].Current_End_Date__c);
        System.assertNotEquals(null, hplusRecords[0].Original_Start_Date__c);
    }
    
    public static testMethod void CEMS_addhPlusmemships_expired_Test() {
        Account acct = [
            SELECT Id, UUID__c, Hallmarkplus__c
            FROM Account
            LIMIT 1
        ];
        
        String matchingUuid = '22222222-2222-2222-2222-222222222222';
        
        List<CEMS_CustomerData_Wrapper.hPlusMembership> hPlusMemberships =
            new List<CEMS_CustomerData_Wrapper.hPlusMembership>();
        
        hPlusMemberships.add(
            buildHPlusMembership(
                matchingUuid,
                'false',
                'false',
                false,
                'HPLUS ON HMN.COM'
            )
        );
        
        StaticTriggerVariables.StopAccountTrigger = true;
        
        Test.startTest();
        
        String response = new CEMS_Consumer_Page_Component_Controller()
            .addhPlusmemships(
                hPlusMemberships,
                matchingUuid,
                acct,
                false,
                'Not Activated',
                '994375702032'
            );
        
        Test.stopTest();
        
        System.assertEquals('Update', response);
        
        Account updatedAcct = [
            SELECT Id, UUID__c, Hallmarkplus__c
            FROM Account
            WHERE Id = :acct.Id
            LIMIT 1
        ];
        
        System.assertEquals(matchingUuid, updatedAcct.UUID__c);
        System.assertEquals(false, updatedAcct.Hallmarkplus__c);
        
        Hallmarkplus__c hplusRecord = [
            SELECT Id,
            uuid__c,
            Status__c,
            Auto_Renewel_On__c,
            Source__c,
            Free_Trial_Used__c
            FROM Hallmarkplus__c
            WHERE uuid__c = :matchingUuid
            LIMIT 1
        ];
        
        System.assertEquals('Expired', hplusRecord.Status__c);
        System.assertEquals('No', hplusRecord.Auto_Renewel_On__c);
        System.assertEquals(
            'Hallmarkplus.com or Hallmark+ App',
            hplusRecord.Source__c
        );
        System.assertEquals(false, hplusRecord.Free_Trial_Used__c);
    }
    
    public static testMethod void CEMS_addhPlusmemships_noMatchingUuid_Test() {
        Account acct = [
            SELECT Id, UUID__c, Hallmarkplus__c
            FROM Account
            LIMIT 1
        ];
        
        String membershipUuid = '33333333-3333-3333-3333-333333333333';
        String nonMatchingConsumerUuid = '99999999-9999-9999-9999-999999999999';
        
        List<CEMS_CustomerData_Wrapper.hPlusMembership> hPlusMemberships =
            new List<CEMS_CustomerData_Wrapper.hPlusMembership>();
        
        hPlusMemberships.add(
            buildHPlusMembership(
                membershipUuid,
                'true',
                'true',
                true,
                'HPLUS PRE LOAD'
            )
        );
        
        StaticTriggerVariables.StopAccountTrigger = true;
        
        Test.startTest();
        
        String response = new CEMS_Consumer_Page_Component_Controller()
            .addhPlusmemships(
                hPlusMemberships,
                nonMatchingConsumerUuid,
                acct,
                false,
                'Activated',
                '994375702033'
            );
        
        Test.stopTest();
        
        System.assertEquals('No Update', response);
        
        List<Hallmarkplus__c> hplusRecords = [
            SELECT Id
            FROM Hallmarkplus__c
            WHERE uuid__c = :membershipUuid
        ];
        
        System.assertEquals(0, hplusRecords.size());
    }
    
    private static CEMS_CustomerData_Wrapper.Memberships buildSubscriptionMembership(
        String membershipType,
        String membershipId,
        String rank,
        String memberCurrentStatus,
        Boolean linkedToHPlus
    ) {
        CEMS_CustomerData_Wrapper.Memberships membership =
            new CEMS_CustomerData_Wrapper.Memberships();
        
        membership.membershipType = membershipType;
        membership.id = membershipId;
        membership.rank = rank;
        membership.memberCurrentStatus = memberCurrentStatus;
        membership.memberLastUpdate = '9/06/2024 3:04:03 PM';
        
        if (linkedToHPlus == true) {
            membership.HPlusMembership =
                new CEMS_CustomerData_Wrapper.HPlusMembership_Z();
            membership.HPlusMembership.uuid =
                '6c76261c-d7aa-4209-92ec-69549c1f35cb';
        }
        
        return membership;
    }
    
    private static CEMS_CustomerData_Wrapper.Memberships buildKOCMembership(
        String membershipId
    ) {
        CEMS_CustomerData_Wrapper.Memberships membership =
            buildSubscriptionMembership(
                'Keepsake Ornaments Club',
                membershipId,
                '3',
                '1',
                false
            );
        
        membership.KeepsakeOrnamentClub =
            new CEMS_CustomerData_Wrapper.KeepsakeOrnamentClub();
        
        membership.KeepsakeOrnamentClub.MemberSince = '2020';
        membership.KeepsakeOrnamentClub.DateExpires = '202612';
        membership.KeepsakeOrnamentClub.CharterMember = 'true';
        
        return membership;
    }
    
    public static testMethod void CEMS_addSubscriptions_crownRewardsAndKOC_Test() {
        Account acct = [
            SELECT Id, CID__c, Crown_Rewards_Number__c
            FROM Account
            LIMIT 1
        ];
        
        StaticTriggerVariables.StopAccountTrigger = true;
        
        acct.CID__c = '162813854001';
        acct.Crown_Rewards_Number__c = 'OLD_CR_NUMBER';
        update acct;
        
        // This record should be deleted by the SF-only cleanup branch.
        Subscription__c staleSub = new Subscription__c(
            Consumer__c = acct.Id,
            Subscription_Id__c = 'STALE-SUB-001',
            Subscription_Type__c = 'Crown Rewards'
        );
        insert staleSub;
        
        // This record should be deleted by the existingSubListv2 branch,
        // then recreated from the KH membership payload.
        Subscription__c duplicateSub = new Subscription__c(
            Consumer__c = acct.Id,
            Subscription_Id__c = 'CR-1001',
            Subscription_Type__c = 'Crown Rewards'
        );
        insert duplicateSub;
        
        List<CEMS_CustomerData_Wrapper.Memberships> memberships =
            new List<CEMS_CustomerData_Wrapper.Memberships>();
        
        // Covers Crown Rewards path, active CR logic, Rank__c,
        // Linked_to_Hallmark__c, Status__c, Date_Modified__c.
        memberships.add(
            buildSubscriptionMembership(
                'Crown Rewards',
                'CR-1001',
                '2',
                '1',
                true
            )
        );
        
        // Covers foundConsumerCR == true path.
        // Account Crown_Rewards_Number__c should remain CR-1001.
        memberships.add(
            buildSubscriptionMembership(
                'Crown Rewards',
                'CR-1002',
                '4',
                '1',
                false
            )
        );
        
        // Covers KOC-specific fields:
        // Membership_Start_Date__c, Membership_Expiration_Date__c,
        // Charter__c, Status_KOC__c.
        memberships.add(buildKOCMembership('KOC-2001'));
        
        Test.startTest();
        
        String response = new CEMS_Consumer_Page_Component_Controller()
            .addSubscriptions(
                memberships,
                acct,
                false
            );
        
        Test.stopTest();
        
        System.assertEquals('Update', response);
        
        Account updatedAcct = [
            SELECT Id, Crown_Rewards_Number__c
            FROM Account
            WHERE Id = :acct.Id
            LIMIT 1
        ];
        
        System.assertEquals(
            'CR-1001',
            updatedAcct.Crown_Rewards_Number__c,
            'First active Crown Rewards membership should stamp on Account.'
        );
        
        List<Subscription__c> staleSubs = [
            SELECT Id
            FROM Subscription__c
            WHERE Subscription_Id__c = 'STALE-SUB-001'
        ];
        
        System.assertEquals(
            0,
            staleSubs.size(),
            'SF-only stale subscription should be deleted.'
        );
        
        List<Subscription__c> subList = [
            SELECT Id,
            Consumer__c,
            Subscription_Id__c,
            Subscription_Type__c,
            Status__c,
            Status_KOC__c,
            Rank__c,
            Linked_to_Hallmark__c,
            Date_Modified__c,
            Membership_Start_Date__c,
            Membership_Expiration_Date__c,
            Charter__c
            FROM Subscription__c
            WHERE Subscription_Id__c IN ('CR-1001', 'CR-1002', 'KOC-2001')
        ];
        
        System.assertEquals(3, subList.size());
        
        Map<String, Subscription__c> subMap =
            new Map<String, Subscription__c>();
        
        for (Subscription__c sub : subList) {
            subMap.put(sub.Subscription_Id__c, sub);
        }
        
        System.assertEquals(
            'Crown Rewards',
            subMap.get('CR-1001').Subscription_Type__c
        );
        System.assertEquals('1', subMap.get('CR-1001').Status__c);
        System.assertEquals(2, subMap.get('CR-1001').Rank__c);
        System.assertEquals(true, subMap.get('CR-1001').Linked_to_Hallmark__c);
        System.assertNotEquals(null, subMap.get('CR-1001').Date_Modified__c);
        
        System.assertEquals(
            'Keepsake Ornaments Club',
            subMap.get('KOC-2001').Subscription_Type__c
        );
        System.assertEquals('1', subMap.get('KOC-2001').Status_KOC__c);
        System.assertEquals('Yes', subMap.get('KOC-2001').Charter__c);
        System.assertEquals('2020', subMap.get('KOC-2001').Membership_Start_Date__c);
        System.assertEquals('12/2026', subMap.get('KOC-2001').Membership_Expiration_Date__c);
    }
    
    public static testMethod void CEMS_addSubscriptions_emptyMembershipList_Test() {
        Account acct = [
            SELECT Id, Crown_Rewards_Number__c
            FROM Account
            LIMIT 1
        ];
        
        StaticTriggerVariables.StopAccountTrigger = true;
        
        acct.Crown_Rewards_Number__c = 'OLD_CR_NUMBER';
        update acct;
        
        Test.startTest();
        
        String response = new CEMS_Consumer_Page_Component_Controller()
            .addSubscriptions(
                new List<CEMS_CustomerData_Wrapper.Memberships>(),
                acct,
                false
            );
        
        Test.stopTest();
        
        System.assertEquals('Update', response);
        
        Account updatedAcct = [
            SELECT Id, Crown_Rewards_Number__c
            FROM Account
            WHERE Id = :acct.Id
            LIMIT 1
        ];
        
        System.assertEquals(
            null,
            updatedAcct.Crown_Rewards_Number__c,
            'Empty membership list should clear existing Crown Rewards number.'
        );
    }
    
    public static testMethod void CEMS_addSubscriptions_blankMembershipType_Test() {
        Account acct = [
            SELECT Id, Crown_Rewards_Number__c
            FROM Account
            LIMIT 1
        ];
        
        CEMS_CustomerData_Wrapper.Memberships membership =
            new CEMS_CustomerData_Wrapper.Memberships();
        
        membership.id = 'NO-TYPE-001';
        membership.membershipType = null;
        membership.rank = '1';
        membership.memberCurrentStatus = '1';
        membership.memberLastUpdate = '9/06/2024 3:04:03 PM';
        
        Test.startTest();
        
        String response = new CEMS_Consumer_Page_Component_Controller()
            .addSubscriptions(
                new List<CEMS_CustomerData_Wrapper.Memberships>{ membership },
                acct,
                false
            );
        
        Test.stopTest();
        
        System.assertEquals('Update', response);
        
        List<Subscription__c> subList = [
            SELECT Id
            FROM Subscription__c
            WHERE Subscription_Id__c = 'NO-TYPE-001'
        ];
        
        System.assertEquals(
            0,
            subList.size(),
            'Membership with blank membershipType should not create Subscription__c.'
        );
    }
}
