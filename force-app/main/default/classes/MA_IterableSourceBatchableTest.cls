/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_IterableSourceBatchableTest {

    /**
     * Stubs out a simple configuration record with
     * source properties defined. Test methods should set
     * the target properties before calling `test_batchable` method.
     */
    private static Mass_Action_Configuration__c buildTestConfiguration() {

        return new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'SOQL',
            Source_SOQL_Query__c = 'SELECT Id FROM Account'
        );

    }

    @IsTest
    static void test_batchable_Workflow() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Workflow';
        config.Target_Action_Name__c = null;
        config.Target_SObject_Type__c = 'Account';

        test_batchable( config );

    }

    @IsTest
    static void test_batchable_Flow() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Flow';
        config.Target_Action_Name__c = 'Test_Flow';
        config.Target_SObject_Type__c = null;

        test_batchable( config );

    }

    @IsTest
    static void test_batchable_QuickAction() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'QuickAction';
        config.Target_Action_Name__c = 'Test_Quick_Action';
        config.Target_SObject_Type__c = 'Account';

        test_batchable( config );

    }

    @IsTest
    static void test_batchable_EmailAlert() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'EmailAlert';
        config.Target_Action_Name__c = 'Test_Email_Alert';
        config.Target_SObject_Type__c = 'Account';

        test_batchable( config );

    }

    @IsTest
    static void test_batchable_InvocableApex() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Apex';
        config.Target_Action_Name__c = 'Test_Apex';
        config.Target_SObject_Type__c = null;

        test_batchable( config );

    }

    @IsTest
    static void test_batchable_AnonymousApex() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Apex';
        config.Target_Action_Name__c = null;
        config.Target_SObject_Type__c = null;
        config.Target_Apex_Script__c = 'void execute( List<Map<String, Object>> sourceRecordsBatch ) { System.debug( sourceRecordsBatch ); }';

        test_batchable( config );

    }

    static void test_batchable( Mass_Action_Configuration__c config ) {

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'Id',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Account acct = new Account(
            Name = 'Test Account'
        );

        insert acct;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        ListOfMapsIterable iterable = new ListOfMapsIterable( new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => acct.Id,
                'Name' => acct.Name
            }
        });

        ID jobId = Database.executeBatch( new MA_IterableSourceBatchable( config.Id, iterable ), config.Batch_Size__c.intValue() );

        Test.stopTest();

        AsyncApexJob job = MA_MassActionBatchUtils.getJobById( jobId );

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

        System.debug( [ SELECT Id, Message__c FROM Mass_Action_Log__c WHERE Mass_Action_Configuration__c = :config.Id ] );
        System.assertEquals( 0, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE Mass_Action_Configuration__c = :config.Id ] );
        System.assertEquals( job.CompletedDate, config.Last_Run_Completed_Date__c );
        System.assertEquals( false, config.Last_Run_Completed_With_Errors__c );

    }

    @IsTest
    static void test_batchable_fail_bad_field_mapping() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Workflow';
        config.Target_SObject_Type__c = 'Account';

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'NON_EXISTENT_FIELD',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Account acct = new Account(
            Name = 'Test Account'
        );

        insert acct;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        ListOfMapsIterable iterable = new ListOfMapsIterable( new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => acct.Id,
                'Name' => acct.Name
            }
        });

        try {

            Test.startTest();

            Database.executeBatch( new MA_IterableSourceBatchable( config.Id, iterable ), config.Batch_Size__c.intValue() );

            // Async code completes once the test stops,
            // and any exceptions that occurred will be thrown.
            // To avoid the test failing because of that,
            // we have a try..catch block. An event will
            // still be raised that the batch job failed.
            Test.stopTest();

            System.assert( false, 'should have failed' );

        } catch ( MA_Exceptions.NoSourceFieldException e ) {

            System.assertEquals( configFieldMapping.Source_Field_Name__c, e.sourceFieldName );

        } catch ( Exception e ) {

            System.assert( false, 'failed for wrong exception' );

        } finally {

            Test.getEventBus().deliver();

        }

    }

    @IsTest
    static void test_batchable_fail_bad_apex_script() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Apex';
        config.Target_Apex_Script__c = 'TEST_FAIL'; // callout mock looks for this keyword

        insert config;

        Account acct = new Account(
            Name = 'Test Account'
        );

        insert acct;

        ListOfMapsIterable iterable = new ListOfMapsIterable( new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => acct.Id,
                'Name' => acct.Name
            }
        });

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        try {

            Test.startTest();

            Database.executeBatch( new MA_IterableSourceBatchable( config.Id, iterable ), config.Batch_Size__c.intValue() );

            // Async code completes once the test stops,
            // and any exceptions that occurred will be thrown.
            // To avoid the test failing because of that,
            // we have a try..catch block. An event will
            // still be raised that the batch job failed.
            Test.stopTest();

            System.assert( false, 'should have failed' );

        } catch ( MA_Exceptions.AnonymousApexException e ) {

            System.assert( true );

        } catch ( Exception e ) {

            System.assert( false, 'failed for wrong exception' );

        } finally {

            Test.getEventBus().deliver();

        }

    }

    @IsTest
    static void test_batchable_fail_soap_fault_apex_script() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Apex';
        config.Target_Apex_Script__c = 'TEST_SOAP_FAULT'; // callout mock looks for this keyword

        insert config;

        Account acct = new Account(
            Name = 'Test Account'
        );

        insert acct;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        ListOfMapsIterable iterable = new ListOfMapsIterable( new List<Map<String, Object>>{
            new Map<String, Object>{
                'Id' => acct.Id,
                'Name' => acct.Name
            }
        });

        try {

            Test.startTest();

            Database.executeBatch( new MA_IterableSourceBatchable( config.Id, iterable ), config.Batch_Size__c.intValue() );

            // Async code completes once the test stops,
            // and any exceptions that occurred will be thrown.
            // To avoid the test failing because of that,
            // we have a try..catch block. An event will
            // still be raised that the batch job failed.
            Test.stopTest();

            System.assert( false, 'should have failed' );

        } catch ( MA_Exceptions.AnonymousApexException e ) {

            System.assert( true );

        } catch ( Exception e ) {

            System.assert( false, 'failed for wrong exception' );

        } finally {

            Test.getEventBus().deliver();

        }

    }

    private class ListOfMapsIterable implements Iterable<Map<String, Object>> {

        private List<Map<String, Object>> records { get; set; }

        public ListOfMapsIterable( List<Map<String, Object>> records ) {
            this.records =  records;
        }

        public Iterator<Map<String, Object>> iterator() {
            return this.records.iterator();
        }

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