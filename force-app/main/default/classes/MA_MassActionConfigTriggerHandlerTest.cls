/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_MassActionConfigTriggerHandlerTest {

    @IsTest
    static void test_insert() {

        String objectName = MA_MassActionUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c activeConfig = new Mass_Action_Configuration__c(
            Name = 'Test Config',
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
            Name = 'Test Config',
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

        Test.setMock( HttpCalloutMock.class, new MA_InvokeActionHttpRequestMock() );

        Test.startTest();

        insert activeConfig;
        System.debug( [ SELECT Id, Name FROM CronJobDetail ] );
        System.assertEquals( 1, [ SELECT count() FROM CronJobDetail WHERE Name LIKE :('%' + activeConfig.Id) ] );

        insert inactiveConfig;
        System.assertEquals( 0, [ SELECT count() FROM CronJobDetail WHERE Name LIKE :('%' + inactiveConfig.Id) ] );

        Test.stopTest();

    }

    @IsTest
    static void test_update() {

        String objectName = MA_MassActionUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
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

        Test.setMock( HttpCalloutMock.class, new MA_InvokeActionHttpRequestMock() );

        Test.startTest();

        insert config;
        System.assertEquals( 0, [ SELECT count() FROM CronJobDetail WHERE Name LIKE :('%' + config.Id) ] );

        config.Active__c = true;
        update config;
        System.assertEquals( 1, [ SELECT count() FROM CronJobDetail WHERE Name LIKE :('%' + config.Id) ] );

        config.Active__c = false;
        update config;
        System.assertEquals( 0, [ SELECT count() FROM CronJobDetail WHERE Name LIKE :('%' + config.Id) ] );

        Test.stopTest();

    }

    @IsTest
    static void test_crud() {

        Test.startTest();

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            name = 'Test'
        );

        insert config;

        update config;

        delete config;

        Test.stopTest();

    }

}
/*
BSD 3-Clause License

Copyright (c) 2017, Doug Ayers, douglascayers.com
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