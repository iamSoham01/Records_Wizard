/*
*  Purpose         :   This is test class for RecordWizard
*  Created By      :   Soham Datta
*  Created Date    :   27/01/2023
*  Revision Logs   :   V_1.0 - Created
*  Coverage        :   94%                  
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

    //Test GetObjects method
    @isTest
    static void testGetObjects(){

        Test.startTest();
            RecordWizard.WrapperData wrapData = RecordWizard.getObjects();
            Assert.isTrue(wrapData.objectMap.size() > 0, 'All sObject Fetched');
        Test.stopTest();
    }

    //Test GetObjectFields method
    @isTest
    static void testGetObjectFields(){

        Test.startTest();
            RecordWizard.WrapperData wrapData = RecordWizard.getObjectFields('Account');
            Assert.isTrue(wrapData.mapObjFields.size() > 0, 'Fields Selected');
        Test.stopTest();
    }

    //Test GetRecords method
    @isTest
    static void testGetRecords(){

        List<Account> accounts = [Select Id, Name From Account];
        List<String> fields = new List<String>();

        Test.startTest();
            RecordWizard.WrapperData wrapData = RecordWizard.getRecords('Account', fields, '');
            Assert.isTrue(wrapData.allRecords.size() > 0, 'Account Records Found');
        Test.stopTest();
    }
}