/**
* This class is utilized to connect to Care Experience KH APIs. At the time of original creation of this class you can do
* GET, PUT and POST requests
* This class is coverage is covered by:
*     1. CEMS_Connection_v2_Test 
*	   2. CareConsumerKHControllerTest
*     3. KH_FindConsumerTest 
*/


public with sharing class CEMS_Connector_v2 {
    // QA-only response hook. KH_DemoDataProvider is dynamically loaded so the
    // provider class and its test can be excluded completely from PROD.
    private static final Boolean KH_DEMO_MODE_ENABLED = true;
    private static final String KH_DEMO_PROVIDER_CLASS = 'KH_DemoDataProvider';

    public interface KhDemoResponseProvider {
        CEMS_CustomerData_Wrapper findCustomer(
            String cid,
            String phoneNumber,
            String email
        );
        CareConsumerEmails_Wrapper findEmails(String cid);
        CareConsumerPhones_Wrapper findPhones(String cid);
        String findMembershipSource(String uuid);
        HPlusInfoWrapper findMembershipInfo(String cid);
    }

    public static KhDemoResponseProvider getKhDemoResponseProvider() {
        if (!KH_DEMO_MODE_ENABLED) {
            return null;
        }
        try {
            Type providerType = Type.forName(KH_DEMO_PROVIDER_CLASS);
            return providerType == null
                ? null
                : (KhDemoResponseProvider) providerType.newInstance();
        } catch (Exception ignored) {
            return null;
        }
    }
    //Declaring final variables that are utilized for CEMS API connections
    
    private final String KNOWHER_KEY;
    private final String KNOWHER_SECRET;
    private final String ACCESS_TOKEN_URL;
    private final String CLIENT_HEADER;
    private final String CONTENT_TYPE;
    private final String CONTENT_TYPE_JSON;
    private final String BASE_URL;
    private final String API_BASE_URL;
    private final String ACCESS_TOKEN_FAILURE = 'Authorization Token Failure';
    private final String CEMS_CONNECTION_FAILURE_CODE = '999';
    private final String CEMS_CONNECTION_FAILURE_MESSAGE = 'Connection to CCDB Failed. Exception code was: ';
    private final String CEMS_AUTHORIZATION_FAILURE_CODE = '777';
    private final String CEMS_AUTHORIZATION_FAILURE_MESSAGE = 'Failed to retrieve access token to CEMS successfully. Please check the CEMS configuration settings';
    private String CALLOUT_METHOD;
    private String REQ_BODY;
    private String X_Gravitee_Api_Key;
    
    //Constructor, we're initializing our final variables here from our CEMS Connection Setting Custom Metadata. The CEMS Connection custom setting allows you to turn on and off the connection
    //to prod. I prefer this over the checking if the org is a sandbox method as there are cases in prod we may want to turn off the connection for.
    public CEMS_Connector_v2(String calloutMethodPassed, String reqBodyPassed) {
        CEMS_Connection__c connectionVals = CEMS_Connection__c.getOrgDefaults();
        string connectionName ='';
        String currentUrl = URL.getOrgDomainURL().toExternalForm();
        system.debug('??'+currentUrl);
        
        if (currentUrl.contains('projectdev')) {
            //connectionName = 'CEMS_Dev_Connection';
            connectionName = 'HMK_CARE_EAPI_DEV';
        } else if ( currentUrl.contains('projectqa') || currentUrl.contains('hplusdev') || currentUrl.contains('hplusqa') ) {
            connectionName = 'HMK_CARE_EAPI_QA';
        }
        else {
            connectionName = 'HMK_CARE_EAPI_PROD'; 
        }
        
        if(Test.isRunningTest())
        {
            connectionName = 'HMK_CARE_EAPI_QA';
        }
        
        CEMS_Connection_Setting__mdt cemConnectionSettings = [
            SELECT
            Id,
            DeveloperName,
            Access_Token_URL__c,
            Base_URL__c,
            API_Base_URL__c,
            KnowHer_Key__c,
            KnowHer_Secret__c,
            Client_Header__c,
            Content_Type__c,
            Content_Type_JSON__c,
            X_Gravitee_Api_Key__c 
            FROM CEMS_Connection_Setting__mdt
            WHERE DeveloperName = :connectionName
        ];
        
        System.debug('CEMS_Connection_Setting__mdt called = cemConnectionSettings =' +cemConnectionSettings);
        
        KNOWHER_KEY = cemConnectionSettings.KnowHer_Key__c;
        KNOWHER_SECRET = cemConnectionSettings.KnowHer_Secret__c;
        ACCESS_TOKEN_URL = cemConnectionSettings.Access_Token_URL__c;
        CLIENT_HEADER = cemConnectionSettings.Client_Header__c;
        CONTENT_TYPE = cemConnectionSettings.Content_Type__c;
        BASE_URL = cemConnectionSettings.Base_URL__c;
        API_BASE_URL = cemConnectionSettings.API_Base_URL__c;
        CONTENT_TYPE_JSON = cemConnectionSettings.Content_Type_JSON__c;
        CALLOUT_METHOD = calloutMethodPassed;
        REQ_BODY = reqBodyPassed;
        X_Gravitee_Api_Key = cemConnectionSettings.X_Gravitee_Api_Key__c ;
    }
    
    
    //This method will generate a GET request to the CEMS API to query for records in CCDB. All parameters are options but there must be at least a firstName + lastName + zip or an email, or a memberId, or a phoneNumber.
    public CEMS_CustomerData_Wrapper CEMS_Get(
        String CID,
        String phoneNumber,
        String email,
        String firstName,
        String lastName,
        String zip,
        String memberId,
        String hPlusMemberUUID,
        Boolean processRecords
    ) {
        //Setting up our return variable and then retrieving an access token from CEMS
        CEMS_CustomerData_Wrapper customerWrapper = new CEMS_CustomerData_Wrapper();
        KhDemoResponseProvider demoProvider = getKhDemoResponseProvider();
        CEMS_CustomerData_Wrapper demoResponse = demoProvider == null
            ? null
            : demoProvider.findCustomer(CID, phoneNumber, email);
        if (demoResponse != null) {
            return demoResponse;
        }
        String accessToken = getAccessToken();
        System.debug('@@accessToken='+accessToken);
        String secureCID = null;
        String securePhone = null;
        String secureEmail = null;
        String secureFirstName = null;
        String secureLastName = null;
        String secureZip = null;
        String secureMemberId = null;
        //Raghav - care-2019
        String securehPlusMemberUUID = null;
        
        //Preventing malicious user input
        if (CID != null) {
            secureCID = String.escapeSingleQuotes(CID);
        }
        
        if (phoneNumber != null && phoneNumber != '') {
            securePhone = String.escapeSingleQuotes(phoneNumber);
        }
        
        if (email != null && email != '') {
            secureEmail = String.escapeSingleQuotes(email);
        }
        
        if (firstName != null && firstName != '' ) {
            secureFirstName = String.escapeSingleQuotes(firstName);
        }
        
        if (lastName != null && lastName != '') {
            secureLastName = String.escapeSingleQuotes(lastName);
        }
        
        if (zip != null && zip != '') {
            secureZip = String.escapeSingleQuotes(zip);
        }
        
        if (memberId != null && memberId != '') {
            secureMemberId = String.escapeSingleQuotes(memberId);
        }
        
        if (hPlusMemberUUID != null && hPlusMemberUUID != '') {
            securehPlusMemberUUID = String.escapeSingleQuotes(hPlusMemberUUID);
        }
        
        //If we retrieved an access token continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            //Setting up our URL for our GET request
            String urlEndpoint = BASE_URL + '?';
            urlEndpoint = urlGenerator(urlEndpoint, 'consumerId', secureCID);
            urlEndpoint = urlGenerator(urlEndpoint, 'homePhone', securePhone);
            urlEndpoint = urlGenerator(urlEndpoint, 'email', secureEmail);
            urlEndpoint = urlGenerator(urlEndpoint, 'firstName', secureFirstName);
            urlEndpoint = urlGenerator(urlEndpoint, 'lastName', secureLastName);
            urlEndpoint = urlGenerator(urlEndpoint, 'zip', secureZip);
            urlEndpoint = urlGenerator(urlEndpoint, 'memberId', secureMemberId);
            urlEndpoint = urlGenerator(urlEndpoint, 'hPlusMemberUUID', securehPlusMemberUUID);
            
            System.debug('This is the URL generated ::: ' + urlEndpoint);
            
            //Setting up our HttpRequest for our CEMS callout
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD, urlEndpoint, accessToken, REQ_BODY, true, false);
            Http http = new Http();
            HttpResponse reqResponse = null;
            
            //Trying to connect to CEMS
            try {
                reqResponse = http.send(CEMS_Req);
            } catch (Exception e) {
                //If we didn't successfully connect to CEMS setup a custom error message to return to the method that was attempting to call CEMS
                customerWrapper = new CEMS_CustomerData_Wrapper();
                customerWrapper.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
                customerWrapper.Errors = generateCustomError(CEMS_CONNECTION_FAILURE_CODE, CEMS_CONNECTION_FAILURE_MESSAGE + e.getMessage());
                System.debug('Exception caught was ::: ' + e.getMessage());
                return customerWrapper;
            }
            
            if (reqResponse.getStatusCode() == 200) {
                //Parsing our JSON response into our wrapper object for GET requests and returning it
                //System.debug('CEMS_Connector_v2.CEMS_Get reqResponse.getBody() === '+ reqResponse.getBody());
                customerWrapper = CEMS_CustomerData_Wrapper.parseCustomerData(reqResponse.getBody(),urlEndpoint);
                system.debug('customerWrapper'+customerWrapper);
                
                if (processRecords) {
                    System.debug('Processing Record ::: ');
                    customerWrapper = processCEMSResults(customerWrapper, securePhone, secureEmail, secureFirstName, secureLastName, secureZip);
                }
                
                return customerWrapper;
            } else if (reqResponse.getStatusCode() == 404) {
                //If we got a 404 (consumer not found) status code we need to return the 404 status code as the only error to run duplicate merge logic
                customerWrapper = CEMS_CustomerData_Wrapper.parseCustomerData(reqResponse.getBody(),urlEndpoint);
                
                if (customerWrapper.Errors == null) {
                    customerWrapper.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
                }
                
                customerWrapper.Errors = generateCustomError(String.valueOf(reqResponse.getStatusCode()), reqResponse.getStatus());
                System.debug('Exception caught was ::: ' + reqResponse.getStatus());
                return customerWrapper;
            } else {
                //If we didn't get a 200 status when contacting CEMS setup a custom error message to return to the method that was attempting to call CEMS
                customerWrapper = CEMS_CustomerData_Wrapper.parseCustomerData(reqResponse.getBody(), urlEndpoint);
                
                if (customerWrapper.Errors == null) {
                    customerWrapper.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
                }
                
                customerWrapper.Errors.addAll(generateCustomError(String.valueOf(reqResponse.getStatusCode()), reqResponse.getStatus()));
                System.debug('Exception caught was ::: ' + reqResponse.getStatus());
                return customerWrapper;
            }
        } else {
            //If our access token wasn't generated, return an access token error using our custom error message generator
            customerWrapper = new CEMS_CustomerData_Wrapper();
            customerWrapper.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
            customerWrapper.Errors = generateCustomError(CEMS_AUTHORIZATION_FAILURE_CODE, CEMS_AUTHORIZATION_FAILURE_MESSAGE);
            System.debug('Access Token Failure');
            return customerWrapper;
        }
    }
    
    //This method is utilized to process the CCDB results from CEMS to produce exact consumer matches (CEMS does OR statements for all matching except when matching on CID or memberId, so to ensure our results return consumers we expect we
    //have to process the results)
    private CEMS_CustomerData_Wrapper processCEMSResults(
        CEMS_CustomerData_Wrapper originalConsumer,
        String phoneNumber,
        String email,
        String firstName,
        String lastName,
        String zip
    ) {
        System.debug('Here are the passed values ::: ' + phoneNumber + ' ::: ' + firstName + ' ::: ' + lastName + ' ::: ' + email + ' ::: ' + zip);
        //Setting up our new list of consumers
        List<CEMS_CustomerData_Wrapper.Consumers> newConsumerList = new List<CEMS_CustomerData_Wrapper.Consumers>();
        
        //Checking to ensure our consumer wrapper actually contained results
        if (originalConsumer.Result != null) {
            //Ensuring our list of consumers isn't empty
            if (!originalConsumer.Result.consumers.isEmpty()) {
                //Looping through our consumers and checking to see if they actually match our requested parameters or not.
                for (CEMS_CustomerData_Wrapper.Consumers consumer : originalConsumer.Result.consumers) {
                    //This boolean determines whether or not the current record should be kept in the consumer list we output
                    Boolean keepRecord = true;
                    //commented below phoneNumber logic as part of 2082 story
                    //If our phone number isn't null, check to see if the current records phone number matches the phone number we passed in.
                    /*	if (String.isNotBlank(phoneNumber)) {
if (consumer.phone != null) {
if (consumer.phone.mobileNumber != null || consumer.phone.homeNumber != null) {
if (
consumer.phone.mobileNumber != phoneNumber.replaceAll('\\D', '') &&
consumer.phone.homeNumber != phoneNumber.replaceAll('\\D', '')
) {
keepRecord = false;
}
} else {
keepRecord = false;
}
} else {
keepRecord = false;
}
}*/
                    
                    //If our first name isn't null, check to see if the current records first name matches what we passed in.
                    if (String.isNotBlank(firstName)) {
                        if (consumer.name != null) {
                            if (consumer.name.firstName != null) {
                                System.debug('WHO ARE YOUUUUUU' + consumer.name.firstName);
                                if (!consumer.name.firstName.containsIgnoreCase(firstName)) {
                                    keepRecord = false;
                                }
                            } else {
                                keepRecord = false;
                            }
                        } else {
                            keepRecord = false;
                        }
                    }
                    
                    //If our first name isn't null, check to see if the current records first name matches what we passed in.
                    if (String.isNotBlank(lastName)) {
                        if (consumer.name != null) {
                            if (consumer.name.lastName != null) {
                                if (!consumer.name.lastName.containsIgnoreCase(lastName)) {
                                    keepRecord = false;
                                }
                            } else {
                                keepRecord = false;
                            }
                        } else {
                            keepRecord = false;
                        }
                    }
                    //system.debug('??email'+consumer.email);
                    //system.debug('??consumer.email.address'+consumer.email.address);
                    //If our email isn't null, check to see if the current records email matches what we passed in.
                    ////Change as a part of CARE-838- CHanging to address historical email issues
                    /*if (String.isNotBlank(email)) {
if (consumer.email != null) {
if (consumer.email.address != null) {

if (!consumer.email.address.containsIgnoreCase(email)) {
keepRecord = false;
}
} else {
keepRecord = false;
}
} else {
keepRecord = false;
}
}*/
                    
                    //If our zip isn't null, check to see if the current records zip matches what we passed in.
                    if (String.isNotBlank(zip)) {
                        System.debug('OOOO WE HIT ZIPPY BOIS');
                        if (consumer.address != null) {
                            System.debug('one step clooooooOOOOOSERRRRR');
                            if (consumer.address.zip != null && consumer.address.zip != '') {
                                System.debug('consumer address zip ' + consumer.address.zip + ' and ' + zip);
                                if (consumer.address.zip.substring(0, 4) != zip.substring(0, 4)) {
                                    keepRecord = false;
                                }
                            } else {
                                keepRecord = false;
                            }
                        } else {
                            keepRecord = false;
                        }
                    }
                    
                    System.debug('This is the keep record value ::: ' + keepRecord + ' ::: This is the record ::: ' + consumer);
                    //If our record matches the users input criteria, add it to the new list of consumers
                    if (keepRecord) {
                        newConsumerList.add(consumer);
                    }
                }
                
                //Clear out the original list of consumers
                originalConsumer.Result.consumers.clear();
                
                //If we had values returned that matched criteria, assign those values to consumer list
                if (!newConsumerList.isEmpty()) {
                    originalConsumer.Result.consumers = newConsumerList;
                    System.debug('Result List ::: ' + originalConsumer.Result.consumers);
                    return originalConsumer;
                }
            } else {
                return originalConsumer;
            }
        } else {
            return originalConsumer;
        }
        
        return originalConsumer;
    }
    
    //This method is utilized to do PUT or update calls to CCDB via the CEMS API
    public CEMS_ConsumerDataPUT_Wrapper CEMS_Put(String CID) {
        System.debug('The CID I received was ::: ' + CID);
        //Setting up our return variable and then retrieving an access token from CEMS
        CEMS_ConsumerDataPUT_Wrapper putResponse = new CEMS_ConsumerDataPUT_Wrapper();
        String accessToken = getAccessToken();
        
        //If we successfully returned an access token, continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            //Setting up our variables to make our PUT request to CEMS
            String urlEndpoint = BASE_URL + '/' + CID;
            System.debug(
                'This is the PUT request ::: Callout Method ' +
                CALLOUT_METHOD +
                ' ::: url ::: ' +
                urlEndpoint +
                ' ::: accessToken :::: ' +
                accessToken +
                ' ::: Body ::: ' +
                REQ_BODY
            );
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD, urlEndpoint, accessToken, REQ_BODY, true, false);
            Http http = new Http();
            HttpResponse reqResponse = null;
            
            //Trying to call out to CEMS
            try {
                reqResponse = http.send(CEMS_Req);
                System.debug('@@reqResponse.getBody()='+reqResponse.getBody());
            } catch (Exception e) {
                //If our CEMS connection failed, generate a custom error message and return it.
                putResponse = new CEMS_ConsumerDataPUT_Wrapper();
                putResponse.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
                putResponse.Errors.addAll(generateCustomError(CEMS_CONNECTION_FAILURE_CODE, CEMS_CONNECTION_FAILURE_MESSAGE + e.getMessage()));
                return putResponse;
            }
            
            if (reqResponse.getStatusCode() == 200) {
                //Parsing our JSON response from CEMS into a wrapper object and returning it.
                System.debug('PUT Response body: ' + reqResponse.getBody());
                putResponse = CEMS_ConsumerDataPUT_Wrapper.parsePut(reqResponse.getBody());
                return putResponse;
            } else {
                //If we didn't get a 200 status when contacting CEMS setup a custom error message to return to the method that was attempting to call CEMS
                try {
                    putResponse = CEMS_ConsumerDataPUT_Wrapper.parsePut(reqResponse.getBody());
                } catch(Exception e) {
                    Universal_Error_Logger.auraGenerateErrorLog('CEMS_Connector_v2', 'CEMS_Connector_v2.CEMS_Put', '', reqResponse.getBody(), null);
                }
                
                if (putResponse.Errors == null) {
                    putResponse.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
                }
                
                putResponse.Errors.addAll(generateCustomError(String.valueOf(reqResponse.getStatusCode()), reqResponse.getStatus()));
                System.debug('Exception caught was ::: ' + reqResponse.getStatus());
                return putResponse;
            }
        } else {
            //If we didn't get an access code, generate an error for that and return it.
            putResponse = new CEMS_ConsumerDataPUT_Wrapper();
            putResponse.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
            putResponse.Errors = generateCustomError(CEMS_AUTHORIZATION_FAILURE_CODE, CEMS_AUTHORIZATION_FAILURE_MESSAGE);
            return putResponse;
        }
    }
    
    //Method is utilized to do POST/Insert requests into CCDB via the CEMS API
    public CEMS_ConsumerDataPOST_Wrapper CEMS_Post() {
        //Setting up returning variable and getting access token
        CEMS_ConsumerDataPOST_Wrapper postResponse = new CEMS_ConsumerDataPOST_Wrapper();
        String accessToken = getAccessToken();
        
        //If we retrieved an access token continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD, BASE_URL, accessToken, REQ_BODY, true, false);
            
            Http http = new Http();
            HttpResponse reqResponse = null;
            
            try {
                reqResponse = http.send(CEMS_Req);
            } catch (Exception e) {
                //If our CEMS connection failed, generate a custom error message and return it.
                postResponse = new CEMS_ConsumerDataPOST_Wrapper();
                postResponse.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
                postResponse.Errors.addAll(generateCustomError(CEMS_CONNECTION_FAILURE_CODE, CEMS_CONNECTION_FAILURE_MESSAGE + e.getMessage()));
                return postResponse;
            }
            
            if (reqResponse.getStatusCode() == 200) {
                postResponse = CEMS_ConsumerDataPOST_Wrapper.parsePOST(reqResponse.getBody());
                return postResponse;
            } else {
                //If we didn't get a 200 status when contacting CEMS setup a custom error message to return to the method that was attempting to call CEMS
                postResponse = CEMS_ConsumerDataPOST_Wrapper.parsePOST(reqResponse.getBody());
                
                if (postResponse.Errors == null) {
                    postResponse.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
                }
                
                postResponse.Errors.addAll(generateCustomError(String.valueOf(reqResponse.getStatusCode()), reqResponse.getStatus()));
                System.debug('Exception caught was ::: ' + reqResponse.getStatus());
                return postResponse;
            }
        } else {
            //If we didn't get an access code, generate an error for that and return it.
            postResponse = new CEMS_ConsumerDataPOST_Wrapper();
            postResponse.Errors = new List<CEMS_CustomerData_Wrapper.Errors>();
            postResponse.Errors = generateCustomError(CEMS_AUTHORIZATION_FAILURE_CODE, CEMS_AUTHORIZATION_FAILURE_MESSAGE);
            return postResponse;
        }
    }
    
    //Naeem: care-817 Move Membership
    public MoveMembership_Wrapper KH_MoveMembership_Post() {
        //Setting up returning variable and getting access token
        MoveMembership_Wrapper postResponse = new MoveMembership_Wrapper();
        String accessToken = getAccessToken();
        
        //If we retrieved an access token continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD, BASE_URL+'/movemember', accessToken, REQ_BODY, true, false);
            
            Http http = new Http();
            HttpResponse reqResponse = null;
            
            try {
                reqResponse = http.send(CEMS_Req);
                System.debug('reqResponse == '+reqResponse);
                
            } catch (Exception e) {
                //If our KH connection failed, generate a custom error message and return it.
                postResponse = new MoveMembership_Wrapper();
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + e.getMessage());
                return postResponse;
            }
            
            if (reqResponse.getStatusCode() == 200) {
                postResponse = MoveMembership_Wrapper.parsePOST(reqResponse.getBody());
                return postResponse;
            }else if (reqResponse.getStatusCode() == 500) {
                //postResponse = MoveMembership_Wrapper.parsePOST(reqResponse.getBody());
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + ' API Response: ' + reqResponse.getBody());
                return postResponse;
            }else {
                //If we didn't get a 200 status when contacting CEMS setup a custom error message to return to the method that was attempting to call CEMS
                postResponse = MoveMembership_Wrapper.parsePOST(reqResponse.getBody());
                
                if (postResponse.Errors == null) {
                    generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + postResponse.Errors);
                }
                return postResponse;
            }
        } else {
            //If we didn't get an access code, generate an error for that and return it.
            postResponse = new MoveMembership_Wrapper();
            return postResponse;
        }
    }
    
    //Naeem: care-1156 Ability to delete email association to Consumer record
    public CareConsumerEmails_Wrapper KH_ConsumerEmails_Get(String CID) {
        //Setting up returning variable and getting access token
        CareConsumerEmails_Wrapper postResponse = new CareConsumerEmails_Wrapper();
        KhDemoResponseProvider demoProvider = getKhDemoResponseProvider();
        CareConsumerEmails_Wrapper demoResponse = demoProvider == null
            ? null
            : demoProvider.findEmails(CID);
        if (demoResponse != null) {
            return demoResponse;
        }
        String accessToken = getAccessToken();
        
        //If we retrieved an access token continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD, BASE_URL+'?consumerId='+CID+'&retrieveAllEmails=true', accessToken, REQ_BODY, true, false);
            
            Http http = new Http();
            HttpResponse reqResponse = null;
            
            try {
                reqResponse = http.send(CEMS_Req);
                System.debug('reqResponse == '+reqResponse);
                
            } catch (Exception e) {
                //If our KH connection failed, generate a custom error message and return it.
                postResponse = new CareConsumerEmails_Wrapper();
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + e.getMessage());
                return postResponse;
            }
            
            if (reqResponse.getStatusCode() == 200) {
                postResponse = CareConsumerEmails_Wrapper.parsePOST(reqResponse.getBody());
                return postResponse;
            }else if (reqResponse.getStatusCode() == 500) {
                //postResponse = MoveMembership_Wrapper.parsePOST(reqResponse.getBody());
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + ' API Response: ' + reqResponse.getBody());
                return postResponse;
            }else {
                //If we didn't get a 200 status when contacting CEMS setup a custom error message to return to the method that was attempting to call CEMS
                postResponse = CareConsumerEmails_Wrapper.parsePOST(reqResponse.getBody());
                
                if (postResponse.Errors == null) {
                    generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + postResponse.Errors);
                }
                return postResponse;
            }
        } else {
            //If we didn't get an access code, generate an error for that and return it.
            postResponse = new CareConsumerEmails_Wrapper();
            return postResponse;
        }
    }
    
    //Naeem: care-1156 Ability to delete email association to Consumer record
    public CareConEmailDelete_Wrapper KH_ConsumerEmails_Delete() {
        //Setting up returning variable and getting access token
        CareConEmailDelete_Wrapper postResponse = new CareConEmailDelete_Wrapper();
        String accessToken = getAccessToken();
        
        //If we retrieved an access token continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD, BASE_URL+'/deleteEmails', accessToken, REQ_BODY, true, false);
            
            Http http = new Http();
            HttpResponse reqResponse = null;
            
            try {
                reqResponse = http.send(CEMS_Req);
                System.debug('KH_ConsumerEmails_Delete reqResponse == '+reqResponse);
                System.debug('KH_ConsumerEmails_Delete reqResponse.getBody() == '+reqResponse.getBody());
            } catch (Exception e) {
                //If our KH connection failed, generate a custom error message and return it.
                postResponse = new CareConEmailDelete_Wrapper();
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + e.getMessage());
                return postResponse;
            }
            
            if (reqResponse.getStatusCode() == 200) {
                postResponse = CareConEmailDelete_Wrapper.parsePOST(reqResponse.getBody());
                System.debug('KH_ConsumerEmails_Delete reqResponse.getBody() == '+reqResponse.getBody());
                return postResponse;
            }else if (reqResponse.getStatusCode() == 500) {
                //postResponse = MoveMembership_Wrapper.parsePOST(reqResponse.getBody());
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + ' API Response: ' + reqResponse.getBody());
                return postResponse;
            }else {
                //If we didn't get a 200 status when contacting CEMS setup a custom error message to return to the method that was attempting to call CEMS
                postResponse = CareConEmailDelete_Wrapper.parsePOST(reqResponse.getBody());
                return postResponse;
            }
        } else {
            //If we didn't get an access code, generate an error for that and return it.
            postResponse = new CareConEmailDelete_Wrapper();
            return postResponse;
        }
    }
    
    
    //Start: H+ Care-1512 Pull in Eligible H+ Rewards into CareTools
    public careEligibleRewards_Wrapper KH_ConsumerEligibleRewards_Get(String memberId) {
        //Setting up returning variable and getting access token
        careEligibleRewards_Wrapper postResponse = new careEligibleRewards_Wrapper();
        String accessToken = getAccessToken();
        
        //      String str = 'https://apiwaf-dev.hallmark.com/secure/hmk-care-knowher-exp-api-dev/api/v1/hmkretail/consumers';
        //system.debug('strValue: ' + str.left(str.length()-19));
        
        //If we retrieved an access token continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            System.debug('KH_ConsumerEligibleRewards_Get REQ_BODY == '+REQ_BODY);
            //we used left() method to remove last 19 chars of the BASEURL and make it the baseURL that will return the Eligible Rewards 
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD,
                                                 BASE_URL.left(BASE_URL.length()-19)+'member/'+memberId+'/memberEligibleChoiceRewardsExtended',
                                                 accessToken, REQ_BODY, true, false);
            Http http = new Http();
            HttpResponse reqResponse = null;
            System.debug('KH_ConsumerEligibleRewards_Get REQ_BODY == '+REQ_BODY);
            
            try {
                reqResponse = http.send(CEMS_Req);
                System.debug('KH_ConsumerEligibleRewards_Get reqResponse == '+reqResponse);
                System.debug('KH_ConsumerEligibleRewards_Get reqResponse.getBody() == '+reqResponse.getBody());
                
            } catch (Exception e) {
                //If our KH connection failed, generate a custom error message and return it.
                postResponse = new careEligibleRewards_Wrapper();
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + e.getMessage());
                return postResponse;
            }
            
            if (reqResponse.getStatusCode() == 200) {
                postResponse = careEligibleRewards_Wrapper.parsePOST(reqResponse.getBody());
                return postResponse;
            }else if (reqResponse.getStatusCode() == 500) {
                
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + ' API Response: ' + reqResponse.getBody());
                return postResponse;
            }else {
                //If we didn't get a 200 status when contacting CEMS setup a custom error message to return to the method that was attempting to call CEMS
                postResponse = careEligibleRewards_Wrapper.parsePOST(reqResponse.getBody());
                
                if (postResponse.status == 'failed') {
                    //generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + postResponse.message);
                }
                return postResponse;
            }
        } else {
            //If we didn't get an access code, generate an error for that and return it.
            postResponse = new careEligibleRewards_Wrapper();
            return postResponse;
        }
    }
    
    //End: H+ Care-1512 Pull in Eligible H+ Rewards into CareTools
    
    
    //Naeem: care-3406 Pull Consumer Email Preferences
    public CareConEmailPrefGETWrapper KH_ConsumerEmailPrefs_Get(String CID) {
        //Setting up returning variable and getting access token
        CareConEmailPrefGETWrapper postResponse = new CareConEmailPrefGETWrapper();
        String accessToken = getAccessToken();
        
        //If we retrieved an access token continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD, API_BASE_URL+'/hmk-digital-eapi/consumers/preferences?consumerId='+CID, accessToken, REQ_BODY, true, false);
            
            Http http = new Http();
            HttpResponse reqResponse = null;
            
            try {
                reqResponse = http.send(CEMS_Req);
                System.debug('reqResponse == '+reqResponse);
                
            } catch (Exception e) {
                 //If our KH connection failed, generate a custom error message and return it.
                Universal_Error_Logger.auraGenerateErrorLog('CEMS_Connector_v2', 'CEMS_Connector_v2.KH_ConsumerEmailPrefs_Get', '', reqResponse.getBody(), null);
                postResponse.Errors = new List<Object>{ new Map<String, String>{
                    'ErrorCode' => '500',
                    'ErrorMessage' => e.getMessage()
                }};
                return postResponse;
            }
            
            if (reqResponse.getStatusCode() == 200) {
                postResponse = CareConEmailPrefGETWrapper.parsePOST(reqResponse.getBody());
                return postResponse;
            }else if (reqResponse.getStatusCode() == 500) {
                postResponse = CareConEmailPrefGETWrapper.parsePOST(reqResponse.getBody());
                // If external API returned error
                if (postResponse.Errors != null && !postResponse.Errors.isEmpty()) {
                    System.debug('External API Error: ' + postResponse.Errors);
                }
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + ' API Response: ' + reqResponse.getBody());
                return postResponse;
            }else {
                //If we didn't get a 200 status when contacting CEMS setup a custom error message to return to the method that was attempting to call CEMS
                postResponse = CareConEmailPrefGETWrapper.parsePOST(reqResponse.getBody());
                
                if (postResponse.Errors == null) {
                    generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + postResponse.Errors);
                }
                // If external API returned error
                if (postResponse.Errors != null && !postResponse.Errors.isEmpty()) {
                    System.debug('External API Error: ' + postResponse.Errors);
                }
                return postResponse;
            }
        } else {
            //If we didn't get an access code, generate an error for that and return it.
            postResponse = new CareConEmailPrefGETWrapper();
            return postResponse;
        }
    }
    
    //Naeem: care-3406 Pull Consumer Email Preferences
    public Integer KH_ConsumerEmailPrefs_PUT(String CID) {
        Integer statusCode;
        //Setting up returning variable and getting access token
        String accessToken = getAccessToken();
        
        //If we retrieved an access token continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD, API_BASE_URL+'/hmk-digital-eapi/consumers/preferences/'+CID, accessToken, REQ_BODY, true, false);
            
            Http http = new Http();
            HttpResponse reqResponse = null;
            System.debug('KH_ConsumerEmailPrefs_PUT CEMS_Req == '+CEMS_Req);
            try {
                reqResponse = http.send(CEMS_Req);
                System.debug('KH_ConsumerEmailPrefs_PUT reqResponse == '+reqResponse);
                
            } catch (Exception e) {
                //If our KH connection failed, generate a custom error message and return it.
                Universal_Error_Logger.auraGenerateErrorLog('CEMS_Connector_v2', 'CEMS_Connector_v2.KH_ConsumerEmailPrefs_PUT', '', reqResponse.getBody(), null);
            }
            statusCode = reqResponse.getStatusCode();
            
        }
        return statusCode;
    }
    
    
    //This method dynamically generates URLs for CEMS GET requests
    private String urlGenerator(String currentURL, String fieldToAdd, String fieldData) {
        //If our field data isn't equal to null, we need to append that data to the URL
        if (fieldData != null) {
            //If the URL already contains an equals sign we know that this is the second parameter or greater in the URL
            //so we need to append an & symbol
            if (currentURL.contains('=')) {
                currentURL += '&';
            }
            
            if (fieldData.contains(' ')) {
                fieldData = fieldData.replace(' ', '+');
            }
            
            System.debug('field data:' + fieldToAdd + '=' + fieldData);
            
            //Adding the field to the URL
            currentURL += fieldToAdd + '=' + fieldData;
        }
        
        //returning the new URL
        return currentURL;
    }
    /*
    
    public String getAccessToken() {
        
        String accessToken = null;
        blob authHeader = null;
        String authHeaderParams = null;
        HttpRequest cemsAuthRequest = null;
        String requestBody = 'grant_type=client_credentials';
        
        //Setting up our header parameters for the request and setting up the KNOWHER authorization token request
        authHeader = blob.valueOf(KNOWHER_KEY + ':' + KNOWHER_SECRET);
        authHeaderParams = 'Basic ' + EncodingUtil.base64Encode(authHeader);
        cemsAuthRequest = connectToCEMS('POST', ACCESS_TOKEN_URL, authHeaderParams, requestBody, false, true);
        
        Http http = new Http();
        HttpResponse authReqResponse = null;
        
        //Trying to callout to CEMS to retrieve our authorization token
        try {
            authReqResponse = http.send(cemsAuthRequest);
        } catch (Exception e) {
            //If we fail to callout return our access token failure message
            System.debug('The exception was ::: ' + e.getMessage());
            return ACCESS_TOKEN_FAILURE;
        }
        
        //If the callout is successful deserialize our JSON, retrieve the access token from the deserialized JSON and return it.
        System.debug(
            'JSON Returned ::: ' +
            authReqResponse.getBody() +
            ' ::: response message ::: ' +
            authReqResponse.getStatus() +
            ' ::: response code ::: ' +
            authReqResponse.getStatusCode()
        );
        Map<String, Object> returnedResults = (Map<String, Object>) JSON.deserializeUntyped(authReqResponse.getBody());
        System.debug('Desearlized JSON Result ::: ' + returnedResults);
        accessToken = 'Bearer ' + String.valueOf(returnedResults.get('access_token'));
        System.debug('Access Token ::: ' + accessToken);
        return accessToken;
    }*/
    
    
    public String getAccessToken() {
        String requestBody = 'grant_type=client_credentials';
        
        Blob authHeader = Blob.valueOf(KNOWHER_KEY + ':' + KNOWHER_SECRET);
        String authHeaderParams = 'Basic ' + EncodingUtil.base64Encode(authHeader);
        
        HttpRequest cemsAuthRequest = connectToCEMS(
            'POST',
            ACCESS_TOKEN_URL,
            authHeaderParams,
            requestBody,
            false,
            true
        );
        
        HttpResponse authReqResponse;
        
        try {
            Http http = new Http();
            authReqResponse = http.send(cemsAuthRequest);
        } catch (Exception e) {
            System.debug('Access token callout failed ::: ' + e.getMessage());
            return ACCESS_TOKEN_FAILURE;
        }
        
        if (authReqResponse == null) {
            System.debug('Access token response was null');
            return ACCESS_TOKEN_FAILURE;
        }
        
        Integer statusCode = authReqResponse.getStatusCode();
        String responseBody = authReqResponse.getBody();
        
        System.debug(
            'JSON Returned ::: ' + responseBody +
            ' ::: response message ::: ' + authReqResponse.getStatus() +
            ' ::: response code ::: ' + statusCode
        );
        
        if (statusCode != 200 || String.isBlank(responseBody)) {
            return ACCESS_TOKEN_FAILURE;
        }
        
        try {
            Map<String, Object> returnedResults =
                (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            
            Object accessTokenObj = returnedResults.get('access_token');
            
            if (accessTokenObj == null || String.isBlank(String.valueOf(accessTokenObj))) {
                return ACCESS_TOKEN_FAILURE;
            }
            
            return 'Bearer ' + String.valueOf(accessTokenObj);
            
        } catch (Exception e) {
            System.debug('Access token JSON parsing failed ::: ' + e.getMessage());
            return ACCESS_TOKEN_FAILURE;
        }
    }
    
    
    //This method is utilized to generate the appropriate httprequest for our CEMS callout
    private HttpRequest connectToCEMS(
        String calloutMethod,
        String urlEndpoint,
        String authHeaderValue,
        String reqBody,
        Boolean needsClient,
        Boolean isGeneratingAccToken
    ) {
        //Setting up our request variable
        HttpRequest cemsReq = new HttpRequest();
        
        //Determines the amount of time we have to connect to and retrieve a response for our endpoint in milliseconds
        cemsReq.setTimeout(40000);
        
        //This sets the callout method GET, POST or PUT
        cemsReq.setMethod(calloutMethod);
        
        //Setting the urlEndpoint for our request
        cemsReq.setEndpoint(urlEndpoint);
        
        //Setting our authorization token header
        cemsReq.setHeader('Authorization', authHeaderValue);
        
        
        //If we need a client header for our CEMS request, generate one
        if (needsClient) {
            System.debug('Setting header client ::: ' + CLIENT_HEADER);
            cemsReq.setHeader('client', CLIENT_HEADER);
        }
        
        //If we are retrieving an access token, set the following header parameters
        if (isGeneratingAccToken) {
            cemsReq.setHeader('X-Gravitee-Api-Key', X_Gravitee_Api_Key);
            cemsReq.setHeader('Content-Type', CONTENT_TYPE);
        }
        else
            cemsReq.setHeader('Content-Type', CONTENT_TYPE_JSON);
        
        
        //If we passed a request body, add a body to our HttpRequest
        if (reqBody != null) {
            System.debug('Setting Body :::  ' + reqBody);
            cemsReq.setBody(reqBody);
            
        }
        
        //return the request
        System.debug('@@cemsReq='+cemsReq);
        return cemsReq;
    }
    
    //Generates a custom error message to be returned when CEMS returns no error messages for the operation
    private List<CEMS_CustomerData_Wrapper.Errors> generateCustomError(String errorCode, String errorMsg) {
        CEMS_CustomerData_Wrapper.Errors errorToAttach = new CEMS_CustomerData_Wrapper.Errors();
        List<CEMS_CustomerData_Wrapper.Errors> errorsList = new List<CEMS_CustomerData_Wrapper.Errors>();
        errorToAttach.ErrorCode = errorCode;
        errorToAttach.ErrorMessage = errorMsg;
        errorsList.add(errorToAttach);
        
        return errorsList;
    }
    //Raghav 2003 - Start
    public CareConsumerPhones_Wrapper KH_ConsumerPhones_Get(String CID) {
        //Setting up returning variable and getting access token
        CareConsumerPhones_Wrapper postResponse = new CareConsumerPhones_Wrapper();
        KhDemoResponseProvider demoProvider = getKhDemoResponseProvider();
        CareConsumerPhones_Wrapper demoResponse = demoProvider == null
            ? null
            : demoProvider.findPhones(CID);
        if (demoResponse != null) {
            return demoResponse;
        }
        String accessToken = getAccessToken();
        
        //If we retrieved an access token continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD, BASE_URL+'?consumerId='+CID+'&retrieveAllPhones=true', accessToken, REQ_BODY, true, false);
            
            Http http = new Http();
            HttpResponse reqResponse = null;
            
            try {
                reqResponse = http.send(CEMS_Req);
                System.debug('reqResponse == '+reqResponse);
                
            } catch (Exception e) {
                //If our KH connection failed, generate a custom error message and return it.
                postResponse = new CareConsumerPhones_Wrapper();
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + e.getMessage());
                return postResponse;
            }
            
            if (reqResponse.getStatusCode() == 200) {
                postResponse = CareConsumerPhones_Wrapper.parsePOST(reqResponse.getBody());
                return postResponse;
            }else if (reqResponse.getStatusCode() == 500) {
                //postResponse = MoveMembership_Wrapper.parsePOST(reqResponse.getBody());
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + ' API Response: ' + reqResponse.getBody());
                return postResponse;
            }else {
                //If we didn't get a 200 status when contacting CEMS setup a custom error message to return to the method that was attempting to call CEMS
                postResponse = CareConsumerPhones_Wrapper.parsePOST(reqResponse.getBody());
                
                if (postResponse.Errors == null) {
                    generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + postResponse.Errors);
                }
                return postResponse;
            }
        } else {
            //If we didn't get an access code, generate an error for that and return it.
            postResponse = new CareConsumerPhones_Wrapper();
            return postResponse;
        }
    }
    
    public CareConPhoneDelete_Wrapper KH_ConsumerPhones_Delete() {
        //Setting up returning variable and getting access token
        CareConPhoneDelete_Wrapper postResponse = new CareConPhoneDelete_Wrapper();
        String accessToken = getAccessToken();
        
        //If we retrieved an access token continue
        if (accessToken != ACCESS_TOKEN_FAILURE) {
            HttpRequest CEMS_Req = connectToCEMS(CALLOUT_METHOD, BASE_URL+'/deletePhones', accessToken, REQ_BODY, true, false);
            
            Http http = new Http();
            HttpResponse reqResponse = null;
            
            try {
                reqResponse = http.send(CEMS_Req);
                System.debug('KH_ConsumerPhones_Delete reqResponse == '+reqResponse);
                System.debug('KH_ConsumerPhones_Delete reqResponse.getBody() == '+reqResponse.getBody());
            } catch (Exception e) {
                //If our KH connection failed, generate a custom error message and return it.
                postResponse = new CareConPhoneDelete_Wrapper();
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + e.getMessage());
                return postResponse;
            }
            
            if (reqResponse.getStatusCode() == 200) {
                postResponse = CareConPhoneDelete_Wrapper.parsePOST(reqResponse.getBody());
                System.debug('KH_ConsumerPhones_Delete reqResponse.getBody() == '+reqResponse.getBody());
                return postResponse;
            }else if (reqResponse.getStatusCode() == 500) {
                //postResponse = MoveMembership_Wrapper.parsePOST(reqResponse.getBody());
                generateCustomError(String.valueOf(reqResponse.getStatusCode()), CEMS_CONNECTION_FAILURE_MESSAGE + ' API Response: ' + reqResponse.getBody());
                return postResponse;
            }else {
                //If we didn't get a 200 status when contacting CEMS setup a custom error message to return to the method that was attempting to call CEMS
                postResponse = CareConPhoneDelete_Wrapper.parsePOST(reqResponse.getBody());
                return postResponse;
            }
        } else {
            //If we didn't get an access code, generate an error for that and return it.
            postResponse = new CareConPhoneDelete_Wrapper();
            return postResponse;
        }
    }
    //Raghav 2003 - End
}
