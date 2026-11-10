@IsTest
private class KH_DemoDataProviderTest {
    @IsTest
    static void demoSourcesUseContractInfoTranslationsForEmailAndPhoneHistory() {
        List<String> emails = new List<String>{
            'demo.kh.ios@hallmark.test',
            'demo.kh.android@hallmark.test',
            'demo.kh.otherapp@hallmark.test',
            'demo.kh.googleshop@hallmark.test',
            'demo.kh.instagramornaments@hallmark.test',
            'demo.kh.instagram@hallmark.test',
            'demo.kh.doordash@hallmark.test',
            'demo.kh.tiktok@hallmark.test'
        };
        List<String> phones = new List<String>{
            '5552100001', '5552100002', '5552100003', '5552100004',
            '5552100005', '5552100006', '5552100007', '5552100008'
        };
        List<String> expectedLabels = new List<String>{
            'H+ App Apple', 'H+ App Android', 'H+ App Other', 'Google Shop',
            'Instagram Shop Ornaments', 'Instagram Shop', 'DoorDash', 'TikTok Shop'
        };
        List<String> rawSources = new List<String>{
            'HPlusHMN - IOS', 'HPlusHMN - Android', 'HPlusHMN - Other_App',
            'GoogleUCP', 'Meta Shop hallmarkornaments',
            'Meta Shop hallmarkstores', 'DoorDash', 'TikTok'
        };
        KH_DemoDataProvider provider = new KH_DemoDataProvider();

        for (Integer index = 0; index < emails.size(); index++) {
            List<KH_ConsumerMergeWrapper> matches = KH_FindConsumer.checkKnowHer(
                new Account(PersonEmail = emails[index])
            );
            System.assertEquals(1, matches.size(), 'Each demo email should return one KH consumer.');

            List<CareConsumerEmails_Wrapper.Emails> emailHistory =
                KH_FindConsumer.getConsumerEmails(matches[0].CID);
            List<CareConsumerPhones_Wrapper.Phones> phoneHistory =
                KH_FindConsumer.getConsumerPhones(matches[0].CID);

            System.assertEquals(1, emailHistory.size());
            System.assertEquals(1, phoneHistory.size());
            System.assertEquals(expectedLabels[index], emailHistory[0].sourceOfDataDesc);
            System.assertEquals(expectedLabels[index], phoneHistory[0].sourceOfDataDesc);

            CEMS_CustomerData_Wrapper rawResponse = provider.findCustomer(
                null,
                null,
                emails[index]
            );
            System.assertEquals(
                rawSources[index],
                rawResponse.Result.consumers[0].hPlusMembership[0].origSourceOfDataDesc,
                'Each demo consumer must carry its raw KH source.'
            );
            System.assertEquals(
                rawSources[index],
                provider.findEmails(matches[0].CID).Result.emails[0].sourceOfDataDesc
            );
            System.assertEquals(
                rawSources[index],
                provider.findPhones(matches[0].CID).Result.phones[0].sourceOfDataDesc
            );
            System.assertEquals(
                expectedLabels[index],
                provider.findMembershipSource('demo-' + matches[0].CID),
                'The same translation must be used for Online Accounts/H+ source.'
            );
            HPlusInfoWrapper membershipInfo =
                provider.findMembershipInfo(matches[0].CID);
            System.assertEquals(
                expectedLabels[index],
                membershipInfo.membershipSource,
                'Each CID-only demo lookup must populate Membership Source.'
            );

            List<KH_ConsumerMergeWrapper> phoneMatches = KH_FindConsumer.checkKnowHer(
                new Account(PersonHomePhone = phones[index])
            );
            System.assertEquals(1, phoneMatches.size(), 'Each demo phone should return one KH consumer.');
            System.assertEquals(matches[0].CID, phoneMatches[0].CID);
        }
    }

    @IsTest
    static void formattedDemoPhoneIsRecognized() {
        List<KH_ConsumerMergeWrapper> matches = KH_FindConsumer.checkKnowHer(
            new Account(PersonHomePhone = '(555) 210-0008')
        );

        System.assertEquals(1, matches.size());
        System.assertEquals('990000000008', matches[0].CID);
        System.assertEquals('5552100008', matches[0].phone);
        System.assertEquals(
            'TikTok Shop',
            KH_FindConsumer.getConsumerPhones(matches[0].CID)[0].sourceOfDataDesc
        );
    }

    @IsTest
    static void fullMockResponseContainsRawConsumerAndHPlusSources() {
        KH_DemoDataProvider provider = new KH_DemoDataProvider();

        CEMS_CustomerData_Wrapper iosResponse = provider.findCustomer(
            null,
            null,
            'demo.kh.ios@hallmark.test'
        );
        System.assertEquals(0, iosResponse.Errors.size());
        System.assertEquals('1', iosResponse.Result.numberOfResults);
        System.assertEquals(1, iosResponse.Result.consumers[0].alternateId.size());
        System.assertEquals(
            'HDXREF',
            iosResponse.Result.consumers[0].alternateId[0].typ
        );
        System.assertEquals(
            'demo.kh.ios@hallmark.test',
            iosResponse.Result.consumers[0].alternateId[0].loginEmail
        );
        System.assertEquals(
            'HPlusHMN - IOS',
            iosResponse.Result.consumers[0].hPlusMembership[0].origSourceOfDataDesc
        );
        System.assertEquals(
            'H+ App Apple',
            CEMS_Consumer_Page_Component_Controller.translateOrigSourceOfDataDesc(
                iosResponse.Result.consumers[0].hPlusMembership[0].origSourceOfDataDesc
            )
        );

        CEMS_CustomerData_Wrapper shoppingResponse = provider.findCustomer(
            null,
            null,
            'demo.kh.tiktok@hallmark.test'
        );
        System.assertEquals(
            'TikTok',
            shoppingResponse.Result.consumers[0].hPlusMembership[0].origSourceOfDataDesc
        );
        System.assertEquals(
            'TikTok',
            provider.findEmails('990000000008').Result.emails[0].sourceOfDataDesc
        );
        System.assertEquals(
            'TikTok',
            provider.findPhones('990000000008').Result.phones[0].sourceOfDataDesc
        );
        System.assertEquals(
            'H+ App Apple',
            provider.findMembershipSource('demo-990000000001')
        );
        System.assertEquals(
            'TikTok Shop',
            provider.findMembershipSource('demo-990000000008')
        );
        System.assertEquals(null, provider.findMembershipSource('real-uuid'));
        System.assertEquals(
            null,
            provider.findCustomer(null, null, 'real.consumer@example.com')
        );
        System.assertEquals(null, provider.findEmails('123456789012'));
        System.assertEquals(null, provider.findPhones('123456789012'));
    }

    @IsTest
    static void onlineAccountsUsesDemoMembershipSourceWithoutMppCallout() {
        Account consumer = new Account(
            Name = 'KH Demo Consumer',
            uuid__c = 'demo-990000000005'
        );
        insert consumer;

        Hallmarkplus__c membership = new Hallmarkplus__c(
            Accountid__c = consumer.Id,
            uuid__c = 'demo-990000000005',
            Type__c = 'Annual',
            Status__c = 'Active'
        );
        insert membership;

        Test.startTest();
        HPlusInfoWrapper result =
            HplusAccountTabContainerController.getHplusNumberinfo(consumer.Id);
        Test.stopTest();

        System.assertEquals('Instagram Shop Ornaments', result.membershipSource);
    }

    @IsTest
    static void membershipInfoSupportsCidOnlyOnlineAccountsTab() {
        KH_DemoDataProvider provider = new KH_DemoDataProvider();

        HPlusInfoWrapper wrapper = provider.findMembershipInfo('990000000008');

        System.assertNotEquals(null, wrapper);
        System.assertEquals('TikTok Shop', wrapper.membershipSource);
        System.assertEquals('https://care.hallmarkplus.com', wrapper.akamaiLogin);
        System.assertEquals(null, wrapper.cr, 'Demo H+ rendering must not call the real CR API.');
        System.assertEquals(null, provider.findMembershipInfo('263564366011'));
    }
}
