/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_UpgradeMassActionLogsBatchableTest {

    @IsTest
    static void test_non_existant_job() {

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config'
        );

        insert config;

        Mass_Action_Log__c log = new Mass_Action_Log__c(
            Mass_Action_Configuration__c = config.Id,
            Message__c = 'the error message',
            Job_ID__c = '707f400NOTEXIST'
        );

        insert log;

        System.assertEquals( 0, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Parent_Log' ] );
        System.assertEquals( 0, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Child_Log' ] );

        Test.startTest();

        Database.executeBatch( new MA_UpgradeMassActionLogsBatchable() );

        Test.stopTest();

        System.assertEquals( 1, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Parent_Log' ] );
        System.assertEquals( 1, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Child_Log' ] );

        Mass_Action_Log__c parentLog = [
            SELECT Id, Message__c, Message_Type__c, Submitted_Date__c, Total_Batches__c, Processed_Batches__c, Failed_Batches__c
            FROM Mass_Action_Log__c
            WHERE RecordType.DeveloperName = 'Parent_Log' AND Job_ID__c = :String.valueOf( log.Job_ID__c ).left( 15 )
        ];

        System.assertEquals( 1, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE Parent_Log__c = :parentLog.Id ] );

        System.assertEquals( 'Informational', parentLog.Message_Type__c );
        System.assertEquals( 'Batch job information incomplete', parentLog.Message__c );
        System.assertEquals( null, parentLog.Submitted_Date__c );
        System.assertEquals( 0, parentLog.Total_Batches__c );
        System.assertEquals( 0, parentLog.Processed_Batches__c );
        System.assertEquals( 1, parentLog.Failed_Batches__c, 'should match number of child logs that were converted' );

    }

    @IsTest
    static void test_batch_200() {

        AsyncApexJob job1 = MA_AsyncApexJobMock.getJobById( MA_AsyncApexJobMock.ABORTED_JOB_ID );
        AsyncApexJob job2 = MA_AsyncApexJobMock.getJobById( MA_AsyncApexJobMock.COMPLETED_WITH_ERRORS_JOB_ID );

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config'
        );

        insert config;

        List<Mass_Action_Log__c> logs = new List<Mass_Action_Log__c>();

        for ( Integer i = 0; i < 200; i++ ) {
            logs.add( new Mass_Action_Log__c(
                Mass_Action_Configuration__c = config.Id,
                Message__c = 'Error ' + String.valueOf( i ).leftPad( 3, '0' ),
                Job_ID__c = ( i < 100 ? job1.Id : job2.Id )
            ));
        }

        insert logs;

        System.assertEquals( 0, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Parent_Log' ] );
        System.assertEquals( 0, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Child_Log' ] );

        Test.startTest();

        Database.executeBatch( new MA_UpgradeMassActionLogsBatchable() );

        Test.stopTest();

        System.assertEquals( 2, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Parent_Log' ] );
        System.assertEquals( 200, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Child_Log' ] );

        Mass_Action_Log__c parentLog1 = [
            SELECT Id, Message__c, Message_Type__c, Submitted_Date__c, Total_Batches__c, Processed_Batches__c, Failed_Batches__c
            FROM Mass_Action_Log__c
            WHERE RecordType.DeveloperName = 'Parent_Log' AND Job_ID__c = :String.valueOf( job1.Id ).left( 15 )
        ];

        Mass_Action_Log__c parentLog2 = [
            SELECT Id, Message__c, Message_Type__c, Submitted_Date__c, Total_Batches__c, Processed_Batches__c, Failed_Batches__c
            FROM Mass_Action_Log__c
            WHERE RecordType.DeveloperName = 'Parent_Log' AND Job_ID__c = :String.valueOf( job2.Id ).left( 15 )
        ];

        System.assertEquals( 100, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE Parent_Log__c = :parentLog1.Id ] );
        System.assertEquals( 100, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE Parent_Log__c = :parentLog2.Id ] );

        System.assertEquals( 'Error', parentLog1.Message_Type__c );
        System.assertEquals( 'Batch job aborted', parentLog1.Message__c );
        System.assertEquals( true, job1.CreatedDate.isSameDay( parentLog1.Submitted_Date__c ) );
        System.assertEquals( job1.TotalJobItems, parentLog1.Total_Batches__c );
        System.assertEquals( job1.JobItemsProcessed, parentLog1.Processed_Batches__c );
        System.assertEquals( 100, parentLog1.Failed_Batches__c, 'should match number of child logs that were converted' );

        System.assertEquals( 'Error', parentLog2.Message_Type__c );
        System.assertEquals( 'Batch job completed with errors', parentLog2.Message__c );
        System.assertEquals( true, job2.CreatedDate.isSameDay( parentLog2.Submitted_Date__c ) );
        System.assertEquals( job2.TotalJobItems, parentLog2.Total_Batches__c );
        System.assertEquals( job2.JobItemsProcessed, parentLog2.Processed_Batches__c );
        System.assertEquals( 100, parentLog2.Failed_Batches__c, 'should match number of child logs that were converted' );

    }

}
/*
BSD 3-Clause License

Copyright (c) 2017-2019, Doug Ayers, douglascayers.com
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