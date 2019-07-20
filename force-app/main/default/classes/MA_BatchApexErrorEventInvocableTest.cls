/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_BatchApexErrorEventInvocableTest {

    @IsTest
    static void test_invocable() {

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

        BatchApexErrorEvent evt = (BatchApexErrorEvent) JSON.deserialize( JSON.serialize( new Map<String, Object>{
            'AsyncApexJobId' => job.Id,
            'Phase' => 'START',
            'Message' => 'TEST ERROR MESSAGE',
            'ExceptionType' => 'TEST EXCEPTION TYPE',
            'StackTrace' => 'TEST STACK TRACE',
            'JobScope' => 'TEST JOB SCOPE',
            'ReplayId' => 'TEST REPLAY ID',
            'RequestId' => 'TEST REQUEST ID',
            'CreatedById' => UserInfo.getUserId(),
            'CreatedDate' => DateTime.now()
        }), BatchApexErrorEvent.class );

        List<MA_BatchApexErrorEventInvocable.Request> requests = new List<MA_BatchApexErrorEventInvocable.Request>{
            new MA_BatchApexErrorEventInvocable.Request( evt )
        };

        List<MA_BatchApexErrorEventInvocable.Response> responses = MA_BatchApexErrorEventInvocable.execute( requests );

        Test.stopTest();

        Test.getEventBus().deliver();

        System.assertEquals( requests.size(), responses.size() );
        System.assertEquals( true, responses[0].success );

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
        System.assertEquals( 'Error in job phase ' + evt.Phase + ': ' + evt.Message, parentLog.Mass_Action_Logs__r[0].Message__c );
        System.assertEquals( 'Error', parentLog.Mass_Action_Logs__r[0].Message_Type__c );
        System.assertEquals( evt.JobScope, parentLog.Mass_Action_Logs__r[0].Job_Scope__c );

    }

    @IsTest
    static void instantiate_request_and_response() {

        // Gotta get that code coverage!

        Test.startTest();

        MA_BatchApexErrorEventInvocable.Request req = new MA_BatchApexErrorEventInvocable.Request();

        MA_BatchApexErrorEventInvocable.Response res = new MA_BatchApexErrorEventInvocable.Response();

        Test.stopTest();

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