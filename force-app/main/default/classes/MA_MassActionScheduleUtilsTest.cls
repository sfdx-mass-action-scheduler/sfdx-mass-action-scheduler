/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_MassActionScheduleUtilsTest {

    @IsTest
    static void test_schedule_jobs() {

        Mass_Action_Configuration__c configA = new Mass_Action_Configuration__c(
            Name = 'Test Config A',
            DeveloperName__c = 'Test_Config_A',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = false,
            Batch_Size__c = 200,
            Source_Type__c = 'SOQL',
            Source_List_View_ID__c = 'SELECT Id FROM Account LIMIT 1',
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
            Source_Type__c = 'SOQL',
            Source_List_View_ID__c = 'SELECT Id FROM Account LIMIT 1',
            Target_Type__c = 'Workflow',
            Target_Action_Name__c = null,
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Custom',
            Schedule_Cron__c = '0 0 1 * * ?'
        );

        insert configA;
        insert configB;

        System.assertEquals( 0, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + configA.Id) ] );
        System.assertEquals( 0, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + configB.Id) ] );

        Test.startTest();

        MA_MassActionScheduleUtils.scheduleMassActions( new List<ID>{ configA.Id, configB.Id } );

        Test.stopTest();

        System.debug( [ SELECT Id, Name FROM CronJobDetail ] );
        System.assertEquals( 1, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + configA.Id) ] );
        System.assertEquals( 1, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + configB.Id) ] );

        CronTrigger triggerA = [ SELECT Id, CronJobDetail.Name, CronExpression FROM CronTrigger WHERE CronJobDetail.Name LIKE :('%' + configA.Id) ];
        System.assertEquals( MA_MassActionScheduleUtils.buildCron( configA ), triggerA.CronExpression );

        CronTrigger triggerB = [ SELECT Id, CronJobDetail.Name, CronExpression FROM CronTrigger WHERE CronJobDetail.Name LIKE :('%' + configB.Id) ];
        System.assertEquals( configB.Schedule_Cron__c, triggerB.CronExpression );

    }

    @IsTest
    static void test_unschedule_jobs() {

        Mass_Action_Configuration__c configA = new Mass_Action_Configuration__c(
            Name = 'Test Config A',
            DeveloperName__c = 'Test_Config_A',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = false,
            Batch_Size__c = 200,
            Source_Type__c = 'SOQL',
            Source_List_View_ID__c = 'SELECT Id FROM Account LIMIT 1',
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
            Source_Type__c = 'SOQL',
            Source_List_View_ID__c = 'SELECT Id FROM Account LIMIT 1',
            Target_Type__c = 'Workflow',
            Target_Action_Name__c = null,
            Target_SObject_Type__c = 'Account',
            Schedule_Frequency__c = 'Custom',
            Schedule_Cron__c = '0 0 1 * * ?'
        );

        insert configA;
        insert configB;

        MA_MassActionScheduleUtils.scheduleMassActions( new List<ID>{ configA.Id, configB.Id } );

        System.assertEquals( 1, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + configA.Id) ] );
        System.assertEquals( 1, [ SELECT COUNT() FROM CronJobDetail WHERE Name LIKE :('%' + configB.Id) ] );

        Test.startTest();

        MA_MassActionScheduleUtils.unscheduleMassActions( new List<ID>{ configA.Id, configB.Id } );

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