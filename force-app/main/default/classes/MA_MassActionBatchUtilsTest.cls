/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_MassActionBatchUtilsTest {

    /*
     * Most of the util methods are tested by
     * separate test classes on the batchable classes
     */

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our test relies on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation here.
     * I include the annotation for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */
    @IsTest( SeeAllData = true )
    static void test_enqueue_report_job() {

        Report r = [ SELECT Id FROM Report WHERE DeveloperName = 'MA_Test_Account_Report' ];

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'Report',
            Source_Report_ID__c = r.Id,
            Source_Report_Column_Name__c = 'ACCOUNT_ID',
            Target_Type__c = 'Workflow',
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Manual'
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'ACCOUNT_ID',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        ID jobId = MA_MassActionBatchUtils.enqueueAction( config.Id );
        System.assertNotEquals( null, jobId );

        Test.stopTest();

        System.assertEquals( 1, [ SELECT COUNT() FROM AsyncApexJob WHERE Id = :jobId ] );

    }

    @IsTest
    static void test_enqueue_listView_job() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Active__c = true,
            Batch_Size__c = 200,
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Source_Type__c = 'ListView',
            Source_List_View_ID__c = lv.Id,
            Target_Type__c = 'Workflow',
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Manual'
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'Id',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        ID jobId = MA_MassActionBatchUtils.enqueueAction( config.Id );
        System.assertNotEquals( null, jobId );

        Test.stopTest();

        System.assertEquals( 1, [ SELECT COUNT() FROM AsyncApexJob WHERE Id = :jobId ] );

    }

    @IsTest
    static void test_enqueue_soql_job() {

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Active__c = true,
            Batch_Size__c = 200,
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Source_Type__c = 'SOQL',
            Source_SOQL_Query__c = 'SELECT Id, Name FROM Account',
            Target_Type__c = 'Workflow',
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Manual'
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'Id',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        ID jobId = MA_MassActionBatchUtils.enqueueAction( config.Id );
        System.assertNotEquals( null, jobId );

        Test.stopTest();

        System.assertEquals( 1, [ SELECT COUNT() FROM AsyncApexJob WHERE Id = :jobId ] );

    }

    @IsTest
    static void test_enqueue_apex_job() {

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Active__c = true,
            Batch_Size__c = 200,
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Source_Type__c = 'Apex',
            Source_Apex_Class__c = 'MA_MassActionBatchUtilsTest.TestIterable',
            Target_Type__c = 'Workflow',
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Manual'
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'Id',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        ID jobId = MA_MassActionBatchUtils.enqueueAction( config.Id );
        System.assertNotEquals( null, jobId );

        Test.stopTest();

        System.assertEquals( 1, [ SELECT COUNT() FROM AsyncApexJob WHERE Id = :jobId ] );

    }

    @IsTest
    static void test_enqueue_apex_job_no_class_exists() {

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Active__c = true,
            Batch_Size__c = 200,
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Source_Type__c = 'Apex',
            Source_Apex_Class__c = 'No_Class_Exists_By_This_Name',
            Target_Type__c = 'Workflow',
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Manual'
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'Id',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        try {

            ID jobId = MA_MassActionBatchUtils.enqueueAction( config.Id );
            System.assertEquals( null, jobId );

        } catch ( NoDataFoundException ex ) {

            System.assert( ex.getMessage().startsWithIgnoreCase( 'No class found for name' ) );

        }

        Test.stopTest();

    }

    public class TestIterable implements Iterable<Map<String, Object>> {
        public Iterator<Map<String, Object>> iterator() {
            return new List<Map<String, Object>>{
                new Map<String, Object>{ 'Id' => '001000000000000' }
            }.iterator();
        }
    }

    @IsTest
    static void test_handle_batch_job_started() {

        AsyncApexJob job = MA_AsyncApexJobMock.getJobById( MA_AsyncApexJobMock.PROCESSING_JOB_ID );

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Active__c = true
        );

        insert config;

        Map<String,RecordTypeInfo> logRecordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        Mass_Action_Log__c parentLog = new Mass_Action_Log__c(
            RecordTypeId = logRecordTypeInfosMap.get( 'Parent_Log' ).getRecordTypeId(),
            Mass_Action_Configuration__c = config.Id,
            Job_ID__c = job.Id,
            Submitted_Date__c = DateTime.now(),
            Timestamp__c = String.valueOf( DateTime.now().getTime() ),
            Message__c = 'Batch job enqueued',
            Message_Type__c = 'Informational'
        );

        insert parentLog;

        Test.startTest();

        MA_MassActionBatchUtils.handleBatchJobStarted( config.Id, job.Id );

        Test.getEventBus().deliver();

        Test.stopTest();

        parentLog = [
            SELECT
                Id, Message__c, Message_Type__c,
                ( SELECT Message_Type__c, Message__c, Job_Scope__c FROM Mass_Action_Logs__r )
            FROM
                Mass_Action_Log__c
            WHERE
                Id = :parentLog.Id
        ];

        System.assertEquals( 'Batch job ' + job.Status.toLowerCase(), parentLog.Message__c );
        System.assertEquals( 'Informational', parentLog.Message_Type__c );

        System.assertEquals( 1, parentLog.Mass_Action_Logs__r.size() );
        System.assertEquals( 'Started', parentLog.Mass_Action_Logs__r[0].Message__c );
        System.assertEquals( 'Informational', parentLog.Mass_Action_Logs__r[0].Message_Type__c );
        System.assertEquals( null, parentLog.Mass_Action_Logs__r[0].Job_Scope__c );

    }

    @IsTest
    static void test_handle_batch_job_execution() {

        AsyncApexJob job = MA_AsyncApexJobMock.getJobById( MA_AsyncApexJobMock.PROCESSING_JOB_ID );

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Active__c = true
        );

        insert config;

        Map<String,RecordTypeInfo> logRecordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        Mass_Action_Log__c parentLog = new Mass_Action_Log__c(
            RecordTypeId = logRecordTypeInfosMap.get( 'Parent_Log' ).getRecordTypeId(),
            Mass_Action_Configuration__c = config.Id,
            Job_ID__c = job.Id,
            Submitted_Date__c = DateTime.now(),
            Timestamp__c = String.valueOf( DateTime.now().getTime() ),
            Message__c = 'Batch job enqueued',
            Message_Type__c = 'Informational'
        );

        insert parentLog;

        Test.startTest();

        MA_MassActionBatchUtils.handleBatchJobExecution( config.Id, job.Id, 1, 'TEST JOB SCOPE' );

        Test.getEventBus().deliver();

        Test.stopTest();

        parentLog = [
            SELECT
                Id, Message__c, Message_Type__c,
                ( SELECT Message_Type__c, Message__c, Job_Scope__c FROM Mass_Action_Logs__r )
            FROM
                Mass_Action_Log__c
            WHERE
                Id = :parentLog.Id
        ];

        System.assertEquals( 'Batch job ' + job.Status.toLowerCase(), parentLog.Message__c );
        System.assertEquals( 'Informational', parentLog.Message_Type__c );

        System.assertEquals( 1, parentLog.Mass_Action_Logs__r.size() );
        System.assertEquals( 'Processed 1 records', parentLog.Mass_Action_Logs__r[0].Message__c );
        System.assertEquals( 'Success', parentLog.Mass_Action_Logs__r[0].Message_Type__c );
        System.assertEquals( 'TEST JOB SCOPE', parentLog.Mass_Action_Logs__r[0].Job_Scope__c );

    }

    @IsTest
    static void test_handle_batch_job_finished() {

        AsyncApexJob job = MA_AsyncApexJobMock.getJobById( MA_AsyncApexJobMock.COMPLETED_JOB_ID );

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Active__c = true
        );

        insert config;

        Map<String,RecordTypeInfo> logRecordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        Mass_Action_Log__c parentLog = new Mass_Action_Log__c(
            RecordTypeId = logRecordTypeInfosMap.get( 'Parent_Log' ).getRecordTypeId(),
            Mass_Action_Configuration__c = config.Id,
            Job_ID__c = job.Id,
            Submitted_Date__c = DateTime.now(),
            Timestamp__c = String.valueOf( DateTime.now().getTime() ),
            Message__c = 'Batch job enqueued',
            Message_Type__c = 'Informational'
        );

        insert parentLog;

        Test.startTest();

        MA_MassActionBatchUtils.handleBatchJobFinished( config.Id, job.Id );

        Test.getEventBus().deliver();

        Test.stopTest();

        parentLog = [
            SELECT
                Id, Message__c, Message_Type__c,
                ( SELECT Message_Type__c, Message__c, Job_Scope__c FROM Mass_Action_Logs__r )
            FROM
                Mass_Action_Log__c
            WHERE
                Id = :parentLog.Id
        ];

        System.assertEquals( 'Batch job ' + job.Status.toLowerCase(), parentLog.Message__c );
        System.assertEquals( 'Success', parentLog.Message_Type__c );

        System.assertEquals( 1, parentLog.Mass_Action_Logs__r.size() );
        System.assertEquals( 'Finished', parentLog.Mass_Action_Logs__r[0].Message__c );
        System.assertEquals( 'Informational', parentLog.Mass_Action_Logs__r[0].Message_Type__c );
        System.assertEquals( null, parentLog.Mass_Action_Logs__r[0].Job_Scope__c );

        config = [
            SELECT
                Id,
                Last_Run_Completed_Date__c,
                Last_Run_Completed_With_Errors__c
            FROM
                Mass_Action_Configuration__c
            WHERE
                Id = :config.Id
        ];

        System.assertEquals( job.CompletedDate, config.Last_Run_Completed_Date__c );
        System.assertEquals( false, config.Last_Run_Completed_With_Errors__c );

    }

    @IsTest
    static void test_mock_jobs() {

        Test.startTest();

        // Specific details of what the mock jobs return
        // is validated by other test methods that use these job ids.
        // This test method is just to ensure code coverage.

        for ( ID jobId : MA_AsyncApexJobMock.MOCK_JOB_IDS ) {
            MA_AsyncApexJobMock.getJobById( jobId );
        }

        Test.stopTest();

    }

}
/*
BSD 3-Clause License

Copyright (c) 2017-2020, Doug Ayers, douglascayers.com
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