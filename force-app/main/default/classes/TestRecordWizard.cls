/*
*  Purpose         :   This is test class for RecordWizard
*  Created By      :   Soham Datta
*  Created Date    :   27/01/2023
*  Revision Logs   :   V_1.0 - Created
*  Coverage        :   92%%                  
*/

@isTest (seeAllData = false)
private class TestRecordWizard {
    
    //Create Test Data
    @TestSetup
    static void createTestData(){
        
        List<Account> accountToBeInterted = new List<Account>();
        for(Integer i=1; i<=10; i++){
            Account accRecord = new Account(Name = 'Test Account '+i);
            accountToBeInterted.add(accRecord);
        }
        insert accountToBeInterted;
    }
    
    private static User createUser(){
        
        List<Profile> ps = [select id, name from Profile where  name = 'System Administrator'];
        User u = new User(Alias = 'admin', Email='systemadmin@force.com', 
                          EmailEncodingKey='UTF-8', LastName='TestUser', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = ps[0].Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='systemadminuser@force.com');
        return u;
        
    }

    //Test GetObjects method
    @isTest
    static void testGetObjects(){
        
        User adminUser = TestRecordWizard.createUser();
        Test.startTest();
        System.runAs(adminUser) {
            RecordWizard.WrapperData wrapData = RecordWizard.getObjects();
            Assert.isTrue(wrapData.mapAllObjects.size() > 0, 'All sObject Fetched');
        }
        Test.stopTest();
    }

    //Test GetObjectFields method
    @isTest
    static void testGetObjectFields(){

        User adminUser = TestRecordWizard.createUser();
        Test.startTest();
        System.runAs(adminUser) {
            RecordWizard.WrapperData wrapData = RecordWizard.getObjectFields('Account');
            Assert.isTrue(wrapData.mapSelectedObjFields.size() > 0, 'Fields Selected');
        }
        Test.stopTest();
    }

    //Test GetRecords method
    @isTest
    static void testGetRecords(){

        List<Account> accounts = [Select Id, Name From Account];
        List<String> fields = new List<String>();
        User adminUser = TestRecordWizard.createUser();
        
        Test.startTest();
        System.runAs(adminUser) {
            RecordWizard.WrapperData wrapData = RecordWizard.getRecords('Account', fields, '');
            Assert.isTrue(wrapData.lstAllRecords.size() > 0, 'Account Records Found');
        }
        Test.stopTest();
    }
}