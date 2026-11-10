/*
 * Test class for CEMS_CustomerData_Wrapper
 * Created by James DuClos -- Hallmark -- 7-16-2019
 */

@isTest
public with sharing class CEMS_CustomerData_Wrapper_Test {
	@isTest
	static void CEMS_CustomerData_Wrapper_Test() {
String jsonString = '{'+ '"Errors": [],'+ '"Result": {'+ '"numberOfResults": 1,'+ '"consumers": ['+ '{'+ '"consumerId": 17872788908,'+ '"name": {'+ '"firstName": "PAT",'+ '"middleInitial": "A",'+ '"lastName": "FITZGERALD"'+ '},'+ '"address": {'+ '"addressLine1": "500 CORONADO WAY",'+ '"addressLine2": "APT 208",'+ '"city": "PALM BCH GDNS",'+ '"state": "FL",'+ '"zip": "334105318",'+ '"country": "USA",'+ '"deliverable": true,'+ '"optIns": {'+ '"postalOptIn": true,'+ '"subsidiaryMailOptIn": false,'+ '"thirdPartyMailOptIn": false'+ '}'+ '},'+ '"phone": {'+ '"homeNumber": 5613123449,'+ '"mobileNumber": 0,'+ '"mobileCaptureDate": null,'+ '"optIns": {'+ '"phoneOptIn": true,'+ '"smsOptIn": false,'+ '"textOptIn": false,'+ '"smsOptCaptureDate": null'+ '}'+ '},'+ '"email": {'+ '"address": "PATSYF34@ICLOUD.COM",'+ '"captureDate": "3/6/2020",'+ '"lastCaptureDate": "3/6/2020",'+ '"deliverable": true,'+ '"optIns": {'+ '"optIn": null,'+ '"subsidiaryOptIn": true'+ '}'+ '},'+ '"dateOfBirth": "1934-06-23T00:00:00Z",'+ '"gender": null,'+ '"deceased": false,'+ '"hallmarkSweepstakesOpt": true,'+ '"lastUpdate": "3/05/2020 11:15:45 PM",'+ '"memberships": ['+ '{'+ '"membershipType": "Crown Rewards",'+ '"id" : 915220663013,'+ '"memberCurrentStatus": "11",'+ '"memberCurrentStatusHD": "EARN AND ISSUE",'+ '"memberLastUpdate": "3/06/2020 8:34:23 PM",'+ '"CrownRewardsLoyalty": {'+ '"currentTierNumber": 3,'+ '"MemberPointsAvailable": 0,'+ '"currentTier": "PLATINUM",'+ '"CardCount": 0'+ '},'+ '"KeepsakeOrnamentClub": {'+ '"CharterMember": false,'+ '"MemberSince": 0,'+ '"DateExpires": null'+ '}'+ '}'+ ']'+ '}'+ ']'+ '}'+ '}';

		// String jsonString = 
		// '{'+
		// 	'"Errors": [],'+
		// 	'"Result": {'+
		// 		'"numberOfResults": 1,'+
		// 		'"consumers": ['+
		// 			'{'+
		// 				'"consumerId": 11296897900,'+
		// 				'"name": {'+
		// 					'"firstName": "MARYBETH",'+
		// 					'"middleInitial": "",'+
		// 					'"lastName": "PAOLOEMILIO"'+
		// 				'},'+
		// 				'"address": {'+
		// 					'"addressLine1": "2737 LAFAYETTE BLVD",'+
		// 					'"addressLine2": "",'+
		// 					'"city": "STEUBENVILLE",'+
		// 					'"state": "OH",'+
		// 					'"zip": "439521103",'+
		// 					'"country": "USA",'+
		// 					'"deliverable": true,'+
		// 					'"optIns": {'+
		// 						'"postalOptIn": false,'+
		// 						'"subsidiaryMailOptIn": true,'+
		// 						'"thirdPartyMailOptIn": true'+
		// 					'}'+
		// 				'},'+
		// 				'"phone": {'+
		// 					'"homeNumber": 7402642754,'+
		// 					'"mobileNumber": 0,'+
		// 					'"mobileCaptureDate": null,'+
		// 					'"optIns": {'+
		// 						'"phoneOptIn": true,'+
		// 						'"smsOptIn": false,'+
		// 						'"textOptIn": false,'+
		// 						'"smsOptCaptureDate": null'+
		// 					'}'+
		// 				'},'+
		// 				'"email": null,'+
		// 				'"dateOfBirth": "07131974",'+
		// 				'"gender": "F",'+
		// 				'"deceased": false,'+
		// 				'"hallmarkSweepstakesOpt": true,'+
		// 				'"lastUpdate": "3/23/2004 11:35:20 AM",'+
		// 				'"memberships": ['+
		// 					'{'+
		// 						'"membershipType": "Crown Rewards",'+
		// 						'"id": 905074207014,'+
		// 						'"memberCurrentStatus": "31",'+
		// 						'"memberLastUpdate": "12/30/2005 12:00:00 AM",'+
		// 						'"CrownRewardsLoyalty": {'+
		// 							'"currentTierNumber": 0,'+
		// 							'"MemberPointsAvailable": 0,'+
		// 							'"currentTier": null,'+
		// 							'"CardCount": 0'+
		// 						'},'+
		// 						'"KeepsakeOrnamentClub": {'+
		// 							'"CharterMember": false,'+
		// 							'"MemberSince": 0,'+
		// 							'"DateExpires": null'+
		// 						'}'+
		// 					'}'+
		// 				']'+
		// 			'}'+
		// 		']'+
		// 	'}'+
		// '}';
		

		CEMS_CustomerData_Wrapper myWrapper = new CEMS_CustomerData_Wrapper();
		myWrapper = CEMS_CustomerData_Wrapper.parseCustomerData(jsonString,null);
	}

    @isTest
    static void parsesAlternateIdArrayAndLegacyObject() {
        String arrayJson =
            '{"Errors":[],"Result":{"numberOfResults":"1","consumers":[{' +
            '"consumerId":"263564366011","alternateId":[{' +
            '"val":"2118703872","typ":"HDXREF",' +
            '"loginEmail":"demo@example.com",' +
            '"hPlusMembership":{"uuid":"uuid-array"}}]}]}}';

        CEMS_CustomerData_Wrapper arrayResult =
            CEMS_CustomerData_Wrapper.parseCustomerData(arrayJson, null);
        System.assertEquals(1, arrayResult.Result.consumers[0].alternateId.size());
        System.assertEquals('2118703872', arrayResult.Result.consumers[0].alternateId[0].val);
        System.assertEquals(
            'uuid-array',
            arrayResult.Result.consumers[0].alternateId[0].hPlusMembership.uuid
        );

        String legacyObjectJson =
            '{"Errors":[],"Result":{"numberOfResults":"1","consumers":[{' +
            '"consumerId":"263564366012","alternateId":{' +
            '"val":"2118703873","typ":"HDXREF",' +
            '"hPlusMembership":{"uuid":"uuid-object"}}}]}}';

        CEMS_CustomerData_Wrapper legacyResult =
            CEMS_CustomerData_Wrapper.parseCustomerData(legacyObjectJson, null);
        System.assertEquals(1, legacyResult.Result.consumers[0].alternateId.size());
        System.assertEquals('2118703873', legacyResult.Result.consumers[0].alternateId[0].val);
        System.assertEquals(
            'uuid-object',
            legacyResult.Result.consumers[0].alternateId[0].hPlusMembership.uuid
        );
    }
}
