/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_ReportSourceBatchableTest {

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @IsTest( SeeAllData = true )
    static void test_batchable() {

        Report r = [ SELECT Id FROM Report WHERE DeveloperName = 'MA_Test_Account_Report' ];

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'Report',
            Source_Report_ID__c = r.Id,
            Source_Report_Column_Name__c = 'ACCOUNT_ID',
            Target_Type__c = 'Workflow',
            Target_SObject_Type__c = 'Account'
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'ACCOUNT_ID',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_InvokeActionHttpRequestMock() );

        Test.startTest();

        Database.executeBatch( new MA_ReportSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );

        Test.stopTest();

        System.assertEquals( 0, [ SELECT count() FROM Mass_Action_Log__c WHERE Mass_Action_Configuration__c = :config.Id ] );

    }

    @IsTest( SeeAllData = true )
    static void test_batchable_fail() {

        Report r = [ SELECT Id FROM Report WHERE DeveloperName = 'MA_Test_Account_Report' ];

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'Report',
            Source_Report_ID__c = r.Id,
            Source_Report_Column_Name__c = 'ACCOUNT_ID',
            Target_Type__c = 'Workflow',
            Target_SObject_Type__c = 'Account'
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'NON_EXISTENT_FIELD',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_InvokeActionHttpRequestMock() );

        Test.startTest();

        Database.executeBatch( new MA_ReportSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );

        Test.stopTest();

        System.assertEquals( 1, [ SELECT count() FROM Mass_Action_Log__c WHERE Mass_Action_Configuration__c = :config.Id ] );

    }

}
/*
BSD 3-Clause License

Copyright (c) 2017, Doug Ayers, douglascayers.com
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/