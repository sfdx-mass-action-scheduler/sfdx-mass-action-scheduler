/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_MassActionLogTriggerHandlerTest {

    @IsTest
    static void test_format_job_id() {

        Test.startTest();

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config'
        );

        insert config;

        Mass_Action_Log__c log = new Mass_Action_Log__c(
            Mass_Action_Configuration__c = config.Id,
            Job_ID__c = ID.valueOf( '707f40000000001' )
        );

        System.assertEquals( 18, log.Job_ID__c.length() );

        insert log;

        Test.stopTest();

        log = [ SELECT Job_ID__c FROM Mass_Action_Log__c WHERE Id = :log.Id ];

        System.assertEquals( 15, log.Job_ID__c.length() );

    }

    @IsTest
    static void test_assign_parent_log_configuration() {

        Test.startTest();

        Map<String,RecordTypeInfo> logRecordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config'
        );

        insert config;

        Mass_Action_Log__c parentLog = new Mass_Action_Log__c(
            RecordTypeId = logRecordTypeInfosMap.get( 'Parent_Log' ).getRecordTypeId(),
            Mass_Action_Configuration__c = config.Id,
            Job_ID__c = ID.valueOf( '707f40000000001' )
        );

        insert parentLog;

        Mass_Action_Log__c childLog = new Mass_Action_Log__c(
            RecordTypeId = logRecordTypeInfosMap.get( 'Child_Log' ).getRecordTypeId(),
            Mass_Action_Configuration__c = config.Id,
            Parent_Log__c = parentLog.Id,
            Job_ID__c = ID.valueOf( '707f40000000001' )
        );

        insert childLog;

        Test.stopTest();

        System.assertEquals( 2, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE Mass_Action_Configuration__c = :config.Id ] );
        System.assertEquals( 1, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE Parent_Log_Configuration__c = :config.Id ] );
        System.assertEquals( 1, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE Parent_Log_Configuration__c = :config.Id AND Id = :parentLog.Id ] );

    }

    @IsTest
    static void test_cascade_delete_child_logs() {

        Map<String,RecordTypeInfo> logRecordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config'
        );

        insert config;

        List<Mass_Action_Log__c> parentLogs = new List<Mass_Action_Log__c>();
        List<Mass_Action_Log__c> childLogs = new List<Mass_Action_Log__c>();

        for ( Integer i = 0; i < 200; i++ ) {
            parentLogs.add( new Mass_Action_Log__c(
                RecordTypeId = logRecordTypeInfosMap.get( 'Parent_Log' ).getRecordTypeId(),
                Mass_Action_Configuration__c = config.Id,
                Job_ID__c = ID.valueOf( '707f40000000001' )
            ));
        }

        insert parentLogs;

        for ( Mass_Action_Log__c parentLog : parentLogs ) {
            for ( Integer i = 0; i < 20; i++ ) {
                childLogs.add( new Mass_Action_Log__c(
                    Mass_Action_Configuration__c = parentLog.Mass_Action_Configuration__c,
                    Parent_Log__c = parentLog.Id,
                    RecordTypeId = logRecordTypeInfosMap.get( 'Child_Log' ).getRecordTypeId()
                ));
            }
        }

        insert childLogs;

        System.assertEquals( parentLogs.size(), [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Parent_Log' ] );
        System.assertEquals( childLogs.size(), [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Child_Log' ] );

        Test.startTest();

        // delete only the parent logs
        // then assert that the child logs
        // were cascade deleted too
        delete parentLogs;

        Test.stopTest();

        System.assertEquals( 0, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Parent_Log' ] );
        System.assertEquals( 0, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE RecordType.DeveloperName = 'Child_Log' ] );

    }

    @IsTest
    static void test_crud() {

        Test.startTest();

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config'
        );

        insert config;

        Mass_Action_Log__c log = new Mass_Action_Log__c(
            Mass_Action_Configuration__c = config.Id
        );

        insert log;

        update log;

        delete log;

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