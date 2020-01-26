/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_JobChangeEventTriggerHandlerTest {

    @IsTest
    static void test_schedule_jobs() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c configA = new Mass_Action_Configuration__c(
            Name = 'Test Config A',
            DeveloperName__c = 'Test_Config_A',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = false,
            Batch_Size__c = 200,
            Source_Type__c = 'ListView',
            Source_List_View_ID__c = lv.Id,
            Target_Type__c = 'Workflow',
            Target_Action_Name__c = null,
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Scheduled',
            Schedule_SecondOfMinute__c = '0',
            Schedule_MinuteOfHour__c = '0',
            Schedule_HourOfDay__c = '1',
            Schedule_DayOfMonth__c = '*',
            Schedule_MonthOfYear__c = '*',
            Schedule_DayOfWeek__c = '?'
        );

        Mass_Action_Configuration__c configB = new Mass_Action_Configuration__c(
            Name = 'Test Config B',
            DeveloperName__c = 'Test_Config_B',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = false,
            Batch_Size__c = 200,
            Source_Type__c = 'ListView',
            Source_List_View_ID__c = lv.Id,
            Target_Type__c = 'Workflow',
            Target_Action_Name__c = null,
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Custom',
            Schedule_Cron__c = '0 0 1 * * ?'
        );

        insert configA;
        insert configB;

        // deliver the events fired from the Mass_Action_Configuration__c triggers
        Test.getEventBus().deliver();

        // then abort any scheduled jobs that may have been scheduled from those triggers
        // because in this test class we want to test our own specific event payloads
        for ( CronTrigger job : [ SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'MA_MassAction_%' ] ) {
            System.abortJob( job.Id );
        }

        MA_MassActionScheduleUtils.unscheduleMassActions( new List<ID>{ configA.Id, configB.Id } );

        Test.startTest();

        MA_JobChangeEvent eventPayload = new MA_JobChangeEvent();
        eventPayload.configIds = new List<ID>{ configA.Id, configB.Id };
        eventPayload.scheduleChangeOperation = MA_JobChangeEvent.ScheduleOperation.SCHEDULE;

        List<Mass_Action_Job_Change_Event__e> events = new List<Mass_Action_Job_Change_Event__e>{
            new Mass_Action_Job_Change_Event__e(
                Payload__c = JSON.serialize( eventPayload )
            )
        };

        EventBus.publish( events );

        Test.stopTest();

        System.debug( [ SELECT Id, Name FROM CronJobDetail ] );
        System.assertEquals( 1, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + configA.Id) ] );
        System.assertEquals( 1, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + configB.Id) ] );

    }

    @IsTest
    static void test_unschedule_jobs() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c configA = new Mass_Action_Configuration__c(
            Name = 'Test Config A',
            DeveloperName__c = 'Test_Config_A',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = false,
            Batch_Size__c = 200,
            Source_Type__c = 'ListView',
            Source_List_View_ID__c = lv.Id,
            Target_Type__c = 'Workflow',
            Target_Action_Name__c = null,
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Scheduled',
            Schedule_SecondOfMinute__c = '0',
            Schedule_MinuteOfHour__c = '0',
            Schedule_HourOfDay__c = '1',
            Schedule_DayOfMonth__c = '*',
            Schedule_MonthOfYear__c = '*',
            Schedule_DayOfWeek__c = '?'
        );

        Mass_Action_Configuration__c configB = new Mass_Action_Configuration__c(
            Name = 'Test Config B',
            DeveloperName__c = 'Test_Config_B',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = false,
            Batch_Size__c = 200,
            Source_Type__c = 'ListView',
            Source_List_View_ID__c = lv.Id,
            Target_Type__c = 'Workflow',
            Target_Action_Name__c = null,
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Custom',
            Schedule_Cron__c = '0 0 1 * * ?'
        );

        insert configA;
        insert configB;

        // deliver the events fired from the Mass_Action_Configuration__c triggers
        Test.getEventBus().deliver();

        // then abort any scheduled jobs that may have been scheduled from those triggers
        // because in this test class we want to test our own specific event payloads
        for ( CronTrigger job : [ SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'MA_MassAction_%' ] ) {
            System.abortJob( job.Id );
        }

        MA_MassActionScheduleUtils.scheduleMassActions( new List<ID>{ configA.Id, configB.Id } );

        Test.startTest();

        MA_JobChangeEvent eventPayload = new MA_JobChangeEvent();
        eventPayload.configIds = new List<ID>{ configA.Id, configB.Id };
        eventPayload.scheduleChangeOperation = MA_JobChangeEvent.ScheduleOperation.UNSCHEDULE;

        List<Mass_Action_Job_Change_Event__e> events = new List<Mass_Action_Job_Change_Event__e>{
            new Mass_Action_Job_Change_Event__e(
                Payload__c = JSON.serialize( eventPayload )
            )
        };

        EventBus.publish( events );

        Test.stopTest();

        System.debug( [ SELECT Id, Name FROM CronJobDetail ] );
        System.assertEquals( 0, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + configA.Id) ] );
        System.assertEquals( 0, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + configB.Id) ] );

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