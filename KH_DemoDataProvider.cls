/**
 * QA/demo-only KH responses. Do not include this class or its metadata file in
 * the PROD deployment package.
 */
public without sharing class KH_DemoDataProvider
    implements CEMS_Connector_v2.KhDemoResponseProvider {
    private class Fixture {
        String cid;
        String email;
        String phone;
        String source;

        Fixture(String cid, String email, String phone, String source) {
            this.cid = cid;
            this.email = email;
            this.phone = phone;
            this.source = source;
        }
    }

    private static List<Fixture> fixtures() {
        return new List<Fixture>{
            new Fixture('990000000001', 'demo.kh.ios@hallmark.test', '5552100001', 'HPlusHMN - IOS'),
            new Fixture('990000000002', 'demo.kh.android@hallmark.test', '5552100002', 'HPlusHMN - Android'),
            new Fixture('990000000003', 'demo.kh.otherapp@hallmark.test', '5552100003', 'HPlusHMN - Other_App'),
            new Fixture('990000000004', 'demo.kh.googleshop@hallmark.test', '5552100004', 'GoogleUCP'),
            new Fixture('990000000005', 'demo.kh.instagramornaments@hallmark.test', '5552100005', 'Meta Shop hallmarkornaments'),
            new Fixture('990000000006', 'demo.kh.instagram@hallmark.test', '5552100006', 'Meta Shop hallmarkstores'),
            new Fixture('990000000007', 'demo.kh.doordash@hallmark.test', '5552100007', 'DoorDash'),
            new Fixture('990000000008', 'demo.kh.tiktok@hallmark.test', '5552100008', 'TikTok')
        };
    }

    private static Fixture findFixture(String email, String phone, String cid) {
        String normalizedEmail = String.isNotBlank(email) ? email.trim().toLowerCase() : null;
        String normalizedPhone = String.isNotBlank(phone) ? phone.replaceAll('[^0-9]', '') : null;
        String normalizedCid = String.isNotBlank(cid) ? cid.trim() : null;

        for (Fixture fixture : fixtures()) {
            if (normalizedEmail == fixture.email
                || normalizedPhone == fixture.phone
                || normalizedCid == fixture.cid) {
                return fixture;
            }
        }
        return null;
    }

    private static String hPlusSource(Fixture fixture) {
        return fixture.source;
    }

    private static String translatedSource(Fixture fixture) {
        Map<String, String> translations = new Map<String, String>{
            'HPlusHMN - IOS' => 'H+ App Apple',
            'HPlusHMN - Android' => 'H+ App Android',
            'HPlusHMN - Other_App' => 'H+ App Other',
            'GoogleUCP' => 'Google Shop',
            'Meta Shop hallmarkornaments' => 'Instagram Shop Ornaments',
            'Meta Shop hallmarkstores' => 'Instagram Shop',
            'DoorDash' => 'DoorDash',
            'TikTok' => 'TikTok Shop'
        };
        return translations.get(fixture.source);
    }

    public CEMS_CustomerData_Wrapper findCustomer(
        String cid,
        String phoneNumber,
        String email
    ) {
        Fixture fixture = findFixture(email, phoneNumber, cid);
        if (fixture == null) {
            return null;
        }

        String uuid = 'demo-' + fixture.cid;
        CEMS_CustomerData_Wrapper response = new CEMS_CustomerData_Wrapper();
        response.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
        response.Result = new CEMS_CustomerData_Wrapper.Result();
        response.Result.numberOfResults = '1';
        response.Result.consumers = new List<CEMS_CustomerData_Wrapper.Consumers>();

        CEMS_CustomerData_Wrapper.Consumers consumer =
            new CEMS_CustomerData_Wrapper.Consumers();
        consumer.consumerId = fixture.cid;
        consumer.hPlusSharedIdentity = 'Activated';

        CEMS_CustomerData_Wrapper.AlternateId alternateId =
            new CEMS_CustomerData_Wrapper.AlternateId();
        alternateId.val = '21' + fixture.cid.right(8);
        alternateId.typ = 'HDXREF';
        alternateId.lastUpdatedFrom = 'HPlusHmk';
        alternateId.lastLoginTS = '2026-08-06T15:19:00Z';
        alternateId.loginEmail = fixture.email;
        alternateId.hPlusMembership =
            new CEMS_CustomerData_Wrapper.HPlusMembership_Z();
        alternateId.hPlusMembership.uuid = uuid;
        consumer.alternateId = new List<CEMS_CustomerData_Wrapper.AlternateId>{
            alternateId
        };

        consumer.name = new CEMS_CustomerData_Wrapper.Name();
        consumer.name.firstName = 'Demo';
        consumer.name.lastName = 'Consumer';

        consumer.email = new CEMS_CustomerData_Wrapper.Email();
        consumer.email.address = fixture.email;
        consumer.email.sharedEmail = 'N';

        consumer.phone = new CEMS_CustomerData_Wrapper.Phone();
        consumer.phone.homeNumber = fixture.phone;
        consumer.phone.mobileNumber = fixture.phone;

        consumer.address = new CEMS_CustomerData_Wrapper.Address();
        consumer.address.zip = '64108';

        CEMS_CustomerData_Wrapper.Memberships crownRewards =
            new CEMS_CustomerData_Wrapper.Memberships();
        crownRewards.membershipType = 'Crown Rewards';
        crownRewards.id = fixture.cid;
        crownRewards.memberCurrentStatus = '1';
        crownRewards.rank = '1';
        crownRewards.HPlusMembership =
            new CEMS_CustomerData_Wrapper.HPlusMembership_Z();
        crownRewards.HPlusMembership.uuid = uuid;
        consumer.memberships = new List<CEMS_CustomerData_Wrapper.Memberships>{
            crownRewards
        };

        CEMS_CustomerData_Wrapper.hPlusMembership membership =
            new CEMS_CustomerData_Wrapper.hPlusMembership();
        membership.uuid = uuid;
        membership.accountId = '2052868';
        membership.subscriptionStatus = 'ACTIVE';
        membership.subscriptionLength = 'ANNUAL';
        membership.entitlementStatus = 'true';
        membership.entitlementStartDate = '3/19/2026 12:00:00 AM';
        membership.entitlementEndDate = '3/19/2027 12:00:00 AM';
        membership.subscriptionStartDate = '3/19/2026 12:00:00 AM';
        membership.subscriptionEndDate = '3/19/2027 12:00:00 AM';
        membership.freeTrialFlag = true;
        membership.freeTrialStatus = 'INACTIVE';
        membership.freeTrialStartDate = '3/19/2026 12:00:00 AM';
        membership.freeTrialEndDate = '3/19/2026 12:00:00 AM';
        membership.origSourceOfDataId = '121001';
        membership.origSourceOfDataDesc = hPlusSource(fixture);
        membership.origSourceCapturedDt = '3/19/2026 12:00:00 AM';
        membership.autoRenewStatus = 'true';
        membership.cancellationDate = '';
        consumer.hPlusMembership =
            new List<CEMS_CustomerData_Wrapper.hPlusMembership>{ membership };

        response.Result.consumers.add(consumer);
        return response;
    }

    public CareConsumerEmails_Wrapper findEmails(String cid) {
        Fixture fixture = findFixture(null, null, cid);
        if (fixture == null) {
            return null;
        }
        CareConsumerEmails_Wrapper response = new CareConsumerEmails_Wrapper();
        response.Errors = new List<CareConsumerEmails_Wrapper.Errors>();
        response.Result = new CareConsumerEmails_Wrapper.Result();
        response.Result.consumerId = Long.valueOf(fixture.cid);
        response.Result.numberOfEmails = 1;
        response.Result.emails = new List<CareConsumerEmails_Wrapper.Emails>{
            buildEmail(fixture)
        };
        return response;
    }

    public CareConsumerPhones_Wrapper findPhones(String cid) {
        Fixture fixture = findFixture(null, null, cid);
        if (fixture == null) {
            return null;
        }
        CareConsumerPhones_Wrapper response = new CareConsumerPhones_Wrapper();
        response.Errors = new List<CareConsumerPhones_Wrapper.Errors>();
        response.Result = new CareConsumerPhones_Wrapper.Result();
        response.Result.consumerId = Long.valueOf(fixture.cid);
        response.Result.numberOfPhones = 1;
        response.Result.phones = new List<CareConsumerPhones_Wrapper.Phones>{
            buildPhone(fixture)
        };
        return response;
    }

    public String findMembershipSource(String uuid) {
        if (String.isBlank(uuid) || !uuid.startsWith('demo-')) {
            return null;
        }
        Fixture fixture = findFixture(null, null, uuid.substring(5));
        if (fixture == null) {
            return null;
        }
        return translatedSource(fixture);
    }

    public HPlusInfoWrapper findMembershipInfo(String cid) {
        Fixture fixture = findFixture(null, null, cid);
        if (fixture == null) {
            return null;
        }

        return new HPlusInfoWrapper(
            'https://care.hallmarkplus.com',
            'ANNUAL',
            'Yes',
            DateTime.newInstance(2026, 3, 19, 0, 0, 0),
            DateTime.newInstance(2026, 3, 19, 0, 0, 0),
            DateTime.newInstance(2027, 3, 19, 0, 0, 0),
            'Active',
            'Platinum',
            translatedSource(fixture),
            'Activated',
            null,
            translatedSource(fixture),
            true
        );
    }

    private static CareConsumerEmails_Wrapper.Emails buildEmail(Fixture fixture) {
        CareConsumerEmails_Wrapper.Emails email = new CareConsumerEmails_Wrapper.Emails();
        email.address = fixture.email;
        email.dfltInd = 'Y';
        email.lastUpdateDate = '11/2/2026 10:00:00 AM';
        email.CapturedDt = '11/2/2026 9:00:00 AM';
        email.sharedEmail = 'N';
        email.status = 'ACTIVE';
        email.sourceOfDataDesc = fixture.source;
        return email;
    }

    private static CareConsumerPhones_Wrapper.Phones buildPhone(Fixture fixture) {
        CareConsumerPhones_Wrapper.Phones phone = new CareConsumerPhones_Wrapper.Phones();
        phone.phone = fixture.phone;
        phone.phoneType = 'HOME';
        phone.dfltInd = 'Y';
        phone.internationalPrefix = '+1';
        phone.lastUpdateDate = '11/2/2026 10:00:00 AM';
        phone.CapturedDt = '11/2/2026 9:00:00 AM';
        phone.phoneOptIn = 'Y';
        phone.sourceOfDataDesc = fixture.source;
        return phone;
    }

}
