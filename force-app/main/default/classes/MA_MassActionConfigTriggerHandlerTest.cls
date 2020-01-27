/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_MassActionConfigTriggerHandlerTest {

    @IsTest
    static void test_insert() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c activeConfig = new Mass_Action_Configuration__c(
            Name = 'Test Config 1',
            DeveloperName__c = 'Test_Config1',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'ListView',
            Source_List_View_ID__c = lv.Id,
            Target_Type__c = 'Workflow',
            Target_Action_Name__c = null,
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Custom',
            Schedule_Cron__c = '0 0 1 * * ?'
        );

        Mass_Action_Configuration__c inactiveConfig = new Mass_Action_Configuration__c(
            Name = 'Test Config 2',
            DeveloperName__c = 'Test_Config2',
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

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        insert activeConfig;    // should publish event to schedule job

        System.debug( [ SELECT Id, Name FROM CronJobDetail ] ); // remove if emitting platform events for scheduling
        System.assertEquals( 1, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + activeConfig.Id) ] );

        insert inactiveConfig;  // since inactive, should NOT publish an event

        System.debug( [ SELECT Id, Name FROM CronJobDetail ] ); // remove if emitting platform events for scheduling
        System.assertEquals( 0, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + inactiveConfig.Id) ] );

        Test.stopTest();

        /*
         * 1/1/2019, I switched from emitting platform events in the trigger to schedule jobs.
         * See MA_EditConfigCmpHelper.saveRecordAsync for full details.
         */

        /*
        List<EventBusSubscriber> eventBusSubscribers = new List<EventBusSubscriber>([
            SELECT
                Name, Status, Position, Type, Topic
            FROM
                EventBusSubscriber
            WHERE
                Name = 'MA_JobChangeEventTrigger'
            LIMIT 1
        ]);

        System.assertEquals( 1, eventBusSubscribers[0].Position );
        */

    }

    @IsTest
    static void test_update() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
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

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        insert config; // since inactive, should NOT publish event to schedule job

        System.debug( [ SELECT Id, Name FROM CronJobDetail ] ); // remove if emitting platform events for scheduling
        System.assertEquals( 0, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + config.Id) ] );

        config.Active__c = true;
        update config; // since active, should publish event to unschedule old job and schedule new job

        System.debug( [ SELECT Id, Name FROM CronJobDetail ] ); // remove if emitting platform events for scheduling
        System.assertEquals( 1, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + config.Id) ] );

        config.Active__c = false;
        update config; // since inactive, should publish event to unschedule job

        System.debug( [ SELECT Id, Name FROM CronJobDetail ] ); // remove if emitting platform events for scheduling
        System.assertEquals( 0, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + config.Id) ] );

        Test.stopTest();

        /*
         * 1/1/2019, I switched from emitting platform events in the trigger to schedule jobs.
         * See MA_EditConfigCmpHelper.saveRecordAsync for full details.
         */

        /*
        List<EventBusSubscriber> eventBusSubscribers = new List<EventBusSubscriber>([
            SELECT
                Name, Status, Position, Type, Topic
            FROM
                EventBusSubscriber
            WHERE
                Name = 'MA_JobChangeEventTrigger'
            LIMIT 1
        ]);

        System.assertEquals( 3, eventBusSubscribers[0].Position );
        */

    }

    @IsTest
    static void test_crud() {

        Test.startTest();

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config'
        );

        insert config;

        update config;

        delete config;

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