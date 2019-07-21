/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_BatchApexStatusEventTriggerTest {

    @IsTest
    static void test_publish() {

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

        Mass_Action_Batch_Apex_Status_Event__e evt = new Mass_Action_Batch_Apex_Status_Event__e(
            Job_ID__c = job.Id,
            Phase__c = 'FINISH',
            Message_Type__c = 'Success',
            Message__c = 'TEST MESSAGE',
            Long_Message__c = 'TEST LONG MESSAGE',
            Job_Scope__c = 'TEST JOB SCOPE',
            Timestamp__c = 'TEST TIMESTAMP'
        );

        EventBus.publish( evt );

        Test.stopTest();

        Test.getEventBus().deliver();

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
        System.assertEquals( evt.Message__c, parentLog.Mass_Action_Logs__r[0].Message__c );
        System.assertEquals( 'Success', parentLog.Mass_Action_Logs__r[0].Message_Type__c );
        System.assertEquals( evt.Job_Scope__c, parentLog.Mass_Action_Logs__r[0].Job_Scope__c );

    }

    @IsTest
    static void test_publish_bulk() {

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

        List<Mass_Action_Batch_Apex_Status_Event__e> events = new List<Mass_Action_Batch_Apex_Status_Event__e>();
        for ( Integer i = 0; i < 201; i++ ) {
            events.add( new Mass_Action_Batch_Apex_Status_Event__e(
                Job_ID__c = job.Id,
                Phase__c = 'FINISH',
                Message_Type__c = 'Success',
                Message__c = 'TEST MESSAGE ' + i,
                Long_Message__c = 'TEST LONG MESSAGE ' + i,
                Job_Scope__c = 'TEST JOB SCOPE ' + i,
                Timestamp__c = 'TEST TIMESTAMP ' + i
            ));
        }

        // Our event trigger handler chunks the published events
        // into batches of 200 to keep the scope low because the
        // handler performs DML operations. By default, the event bus
        // could deliver up to 2,000 events at a time. We could run
        // into SOQL and DML governor limits in this trigger handler.
        // The test, then, is to ensure that multiple waves will occur
        // and that the expected number of mass action logs are created.

        // Publish 201 events
        EventBus.publish( events );

        // Delivers 201 events, but the handler will set a resume checkpoint
        // after processing the first 200 events.
        Test.getEventBus().deliver();

        parentLog = [
            SELECT
                Id, Message__c, Message_Type__c,
                ( SELECT Message_Type__c, Message__c, Job_Scope__c FROM Mass_Action_Logs__r )
            FROM
                Mass_Action_Log__c
            WHERE
                Id = :parentLog.Id
        ];

        Integer firstWaveCountOfLogs = parentLog.Mass_Action_Logs__r.size();

        System.debug( 'FIRST WAVE' );
        System.debug( JSON.serializePretty( parentLog ) );

        // Publish all events after the resume checkpoint.
        // In this test, that would be the 201st event.
        Test.getEventBus().deliver();

        parentLog = [
            SELECT
                Id, Message__c, Message_Type__c,
                ( SELECT Message_Type__c, Message__c, Job_Scope__c FROM Mass_Action_Logs__r )
            FROM
                Mass_Action_Log__c
            WHERE
                Id = :parentLog.Id
        ];

        Integer secondWaveCountOfLogs = parentLog.Mass_Action_Logs__r.size();

        System.debug( 'SECOND WAVE' );
        System.debug( JSON.serializePretty( parentLog ) );

        Test.stopTest();

        // assert total events published in each wave and overall
        System.assertEquals( firstWaveCountOfLogs + 1, secondWaveCountOfLogs );
        System.assertEquals( events.size(), secondWaveCountOfLogs );

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