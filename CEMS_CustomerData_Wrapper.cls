//updated
//
// This class is utilized as a wrapper class for deserializing CEMS JSON responses containing CCDB consumer records
// Created By Matt Gerry ::: Hallmark ::: 04/30/2019
//

public class CEMS_CustomerData_Wrapper {
    public class email {
        public String address;
        public String sharedEmail;
        public String lastCaptureDate;
        public String hardBounceCount;
        public String lastHardBounceDt;
        public OptIns_Email optIns;
    }
    
    public class Address {
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String zip;
        public String country;
        //Care-564 Enable Preferred Postal Mail Opt Fields from CCDB
        public String addrSts;
        //End-Care-564 Enable Preferred Postal Mail Opt Fields from CCDB
        public OptIns_Mail optIns;
    }
    public class AlternateId {
        public String val;
        public String typ;
        public String lastUpdatedFrom;
        public String lastLoginTS;
        public String loginEmail;
        public HPlusMembership_Z  hPlusMembership;
    }
    
    
    public class Consumers {
        public String consumerId;
        
        public String hPlusSharedIdentity;
        public List<AlternateId> alternateId;
        public Name name;
        public Address address;
        public Phone phone;
        public Email email;
        public String dateOfBirth;
        public String gender;
        public Boolean deceased;
        public List<Memberships> memberships;
        public List<hPlusMembership> hPlusMembership;
    }
    //Start: Naeem, Care-1330 H+ story
    public class HPlusMembership_Z
    {
        public String uuid;	
    }
    //End: Naeem, Care-1330 H+ story
   
    public class hPlusMembership {
        public String uuid;
        //Raghav - 1507 getting H+ Membership Source field data 
        public String accountId;
        public String subscriptionStatus;
        public String subscriptionLength;
        public String entitlementStatus;
        public String entitlementStartDate;
        public String entitlementEndDate;
        public String subscriptionStartDate;
        public String subscriptionEndDate;
        public Boolean freeTrialFlag;
        public String freeTrialStartDate;
        public String freeTrialStatus;
        public String freeTrialEndDate;
        public String origSourceOfDataId;
        public String origSourceOfDataDesc;
        public String origSourceCapturedDt;
        public String autoRenewStatus;
        public String cancellationDate;
        public String cancelReason;
        
    }
    
    public class Memberships {
        public String membershipType;
        public String rank;
        public String id;
        public String memberCurrentStatus;
        public String memberLastUpdate;
        //Start: Naeem, Care-1330 H+ story
        public HPlusMembership_Z HPlusMembership;
        //End: Naeem, Care-1330 H+ story
        public CrownRewardsLoyalty CrownRewardsLoyalty;
        public KeepsakeOrnamentClub KeepsakeOrnamentClub;
    }
    
    public class CrownRewardsLoyalty {
        public String currentTierNumber;
        public String MemberPointsAvailable;
        public String currentTier;
    }
    
    public class Name {
        public String firstName;
        public String middleInitial;
        public String lastName;
    }
    
    public class Result {
        public String numberOfResults;
        public List<Consumers> consumers;
    }
    
    public class Errors {
        public String ErrorMessage;
        public String ErrorCode;
    }
    
    public class KeepsakeOrnamentClub {
        public String CharterMember;
        public String MemberSince;
        public String DateExpires;
    }
    
    public class OptIns_Email {
        public String optIn;
        public String subsidiaryOptIn;
    }
    
    public class OptIns_Mail {
        public String postalOptIn;
        public String subsidiaryMailOptIn;
        public String thirdPartyMailOptIn;
        //Care-564 Enable Preferred Postal Mail Opt Fields from CCDB
        public String postalOptCaptureDate;
        //End-Care-564 Enable Preferred Postal Mail Opt Fields from CCDB
        
    }
    
    public class Phone {
        public String homeNumber;
        public String mobileNumber;
        public OptIns_Phone optIns;
    }
    
    public class OptIns_Phone {
        //Care-565 Enable Preferred Phone Opt Fields from CCDB
        public Boolean phoneOptIn;
        public String phoneOptCaptureDate;
        
        public String smsOptIn;
        public String smsOptCaptureDate;
        
    }
    
    public List<Errors> Errors;
    public Result Result;
    
    public static CEMS_CustomerData_Wrapper parseCustomerData(String json, String reqbody) {
        boolean test1 = true;
        boolean test2 = true;
        boolean test3 = true;
        boolean test4 = true;
        boolean test5 = true;
        boolean test6 = true;
        boolean test7 = true;
        boolean test8 = true;
        system.debug('??json'+json);
        try {
            return (CEMS_CustomerData_Wrapper) System.JSON.deserialize(
                normalizeAlternateIdShape(json),
                CEMS_CustomerData_Wrapper.class
            );
        } catch (exception e) {  
            // Change as per 1029
            // Universal_Error_Logger.auraGenerateErrorLog('There was an error parsing KH response Data. Your administrators have been notified of this error','CEMS_CustomerData_Wrapper.parseCustomerData', e.getMessage());
            system.debug('??Exception');
            Universal_Error_Logger.auraGenerateErrorLog('There was an error parsing KH response Data. Your administrators have been notified of this error','CEMS_CustomerData_Wrapper.parseCustomerData', e.getMessage(),json + ' + reqbody + ' + reqbody,'');
            
        }
        return new CEMS_CustomerData_Wrapper();
    }

    @TestVisible
    private static String normalizeAlternateIdShape(String json) {
        if (String.isBlank(json)) {
            return json;
        }

        Object parsed = JSON.deserializeUntyped(json);
        if (!(parsed instanceof Map<String, Object>)) {
            return json;
        }
        Map<String, Object> root = (Map<String, Object>) parsed;
        Map<String, Object> result = (Map<String, Object>) root.get('Result');
        if (result == null) {
            return json;
        }
        List<Object> consumers = (List<Object>) result.get('consumers');
        if (consumers == null) {
            return json;
        }

        for (Object consumerValue : consumers) {
            Map<String, Object> consumer = (Map<String, Object>) consumerValue;
            Object alternateIdValue = consumer.get('alternateId');
            if (alternateIdValue instanceof Map<String, Object>) {
                consumer.put('alternateId', new List<Object>{ alternateIdValue });
            }
        }
        return JSON.serialize(root);
    }
}
