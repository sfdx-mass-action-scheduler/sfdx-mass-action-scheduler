/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_ReportSourceBatchableTest {

    /**
     * The Report object is read-only in Apex. It must be created via Metadata API.
     * Therefore our tests rely on existing data being available to us, unfortunately.
     * Also, when testing Reports API the test will run with SeeAllData = true, regardless the annotation we use.
     * I include the annotation with SeeAllData property for clarity.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_test_reports.htm
     */

    /**
     * Stubs out a simple configuration record with
     * source properties defined. Test methods should set
     * the target properties before calling `test_batchable` method.
     */
    private static Mass_Action_Configuration__c buildTestConfiguration() {

        Report r = [ SELECT Id FROM Report WHERE DeveloperName = 'MA_Test_Account_Report' ];

        return new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'Report',
            Source_Report_ID__c = r.Id,
            Source_Report_Column_Name__c = 'ACCOUNT_ID'
        );

    }

    @IsTest( SeeAllData = true )
    static void test_batchable_Workflow() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Workflow';
        config.Target_Action_Name__c = null;
        config.Target_SObject_Type__c = 'Account';

        test_batchable( config );

    }

    @IsTest( SeeAllData = true )
    static void test_batchable_Flow() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Flow';
        config.Target_Action_Name__c = 'Test_Flow';
        config.Target_SObject_Type__c = null;

        test_batchable( config );

    }

    @IsTest( SeeAllData = true )
    static void test_batchable_QuickAction() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'QuickAction';
        config.Target_Action_Name__c = 'Test_Quick_Action';
        config.Target_SObject_Type__c = 'Account';

        test_batchable( config );

    }

    @IsTest( SeeAllData = true )
    static void test_batchable_EmailAlert() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'EmailAlert';
        config.Target_Action_Name__c = 'Test_Email_Alert';
        config.Target_SObject_Type__c = 'Account';

        test_batchable( config );

    }

    @IsTest( SeeAllData = true )
    static void test_batchable_InvocableApex() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Apex';
        config.Target_Action_Name__c = 'Test_Apex';
        config.Target_SObject_Type__c = null;

        test_batchable( config );

    }

    @IsTest( SeeAllData = true )
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
            Source_Field_Name__c = 'ACCOUNT_ID',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        ID jobId = Database.executeBatch( new MA_ReportSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );

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

    @IsTest( SeeAllData = true )
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

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        try {

            Test.startTest();

            Database.executeBatch( new MA_ReportSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );

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

    @IsTest( SeeAllData = true )
    static void test_batchable_fail_no_report() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Source_Report_ID__c = null;
        config.Target_Type__c = 'Workflow';
        config.Target_SObject_Type__c = 'Account';

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'Id',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        try {

            Test.startTest();

            Database.executeBatch( new MA_ReportSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );

            Test.stopTest();

            System.assert( false, 'should have failed' );

        } catch ( NoDataFoundException e ) {

            // because the batchable throws the error in the start method
            // then we're getting a synchronous exception caught rather than
            // the job's finish method logging the error asynchronously
            System.assert( true );

        } catch ( Exception e ) {

            System.assert( false, 'failed for wrong exception' );

        }

    }

    @IsTest( SeeAllData = true )
    static void test_batchable_fail_bad_apex_script() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Apex';
        config.Target_Apex_Script__c = 'TEST_FAIL'; // callout mock looks for this keyword

        insert config;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        try {

            Test.startTest();

            Database.executeBatch( new MA_ReportSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );

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

    @IsTest( SeeAllData = true )
    static void test_batchable_fail_soap_fault_apex_script() {

        Mass_Action_Configuration__c config = buildTestConfiguration();
        config.Target_Type__c = 'Apex';
        config.Target_Apex_Script__c = 'TEST_SOAP_FAULT'; // callout mock looks for this keyword

        insert config;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        try {

            Test.startTest();

            Database.executeBatch( new MA_ReportSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );

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
    static void test_extract_cell_value() {

        Test.startTest();

        System.assertEquals( true, MA_ReportSourceBatchable.extractCellValue( 'booleanCell', true, Reports.ColumnDataType.BOOLEAN_DATA ) );
        System.assertEquals( false, MA_ReportSourceBatchable.extractCellValue( 'booleanCell', false, Reports.ColumnDataType.BOOLEAN_DATA ) );
        System.assertEquals( 'booleanCell', MA_ReportSourceBatchable.extractCellValue( 'booleanCell', true, Reports.ColumnDataType.STRING_DATA ) );

        System.assertEquals( Date.today(), MA_ReportSourceBatchable.extractCellValue( 'January 3rd, 2019', Date.today(), Reports.ColumnDataType.DATE_DATA ) );
        System.assertEquals( 'January 3rd, 2019', MA_ReportSourceBatchable.extractCellValue( 'January 3rd, 2019', Date.today(), Reports.ColumnDataType.STRING_DATA ) );

        System.assertEquals( DateTime.now(), MA_ReportSourceBatchable.extractCellValue( 'January 3rd, 2019 4:30 PM', DateTime.now(), Reports.ColumnDataType.DATETIME_DATA ) );
        System.assertEquals( 'January 3rd, 2019 4:30 PM', MA_ReportSourceBatchable.extractCellValue( 'January 3rd, 2019 4:30 PM', DateTime.now(), Reports.ColumnDataType.STRING_DATA ) );

        Reports.ReportCurrency currencyAmount = (Reports.ReportCurrency) JSON.deserialize( '{ "currencyCode" : "$", "amount" : 12.34 }', Reports.ReportCurrency.class );
        System.assertEquals( (Decimal) 12.34, MA_ReportSourceBatchable.extractCellValue( '$12.34', currencyAmount, Reports.ColumnDataType.CURRENCY_DATA ) );
        System.assertEquals( '$12.34', MA_ReportSourceBatchable.extractCellValue( '$12.34', currencyAmount, Reports.ColumnDataType.STRING_DATA ) );

        System.assertEquals( (Integer) 12, MA_ReportSourceBatchable.extractCellValue( '12', 12, Reports.ColumnDataType.INT_DATA ) );
        System.assertEquals( '12', MA_ReportSourceBatchable.extractCellValue( '12', 12, Reports.ColumnDataType.STRING_DATA ) );

        System.assertEquals( (Double) 12.34, MA_ReportSourceBatchable.extractCellValue( '12.34', 12.34, Reports.ColumnDataType.DOUBLE_DATA ) );
        System.assertEquals( '12.34', MA_ReportSourceBatchable.extractCellValue( '12.34', 12.34, Reports.ColumnDataType.STRING_DATA ) );

        System.assertEquals( (Double) 0.25, MA_ReportSourceBatchable.extractCellValue( '25%', 0.25, Reports.ColumnDataType.PERCENT_DATA ) );
        System.assertEquals( '25%', MA_ReportSourceBatchable.extractCellValue( '25%', 0.25, Reports.ColumnDataType.STRING_DATA ) );

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