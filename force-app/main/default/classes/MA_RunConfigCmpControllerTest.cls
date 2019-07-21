/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_RunConfigCmpControllerTest {

    @IsTest
    static void test_enqueueAction_success() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'ListView',
            Source_List_View_ID__c = lv.Id,
            Target_Type__c = 'Workflow',
            Target_SObject_Type__c = 'Account'
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'Id',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        Map<String, Object> result = MA_RunConfigCmpController.enqueueAction( config.Id );

        System.assertEquals( true, result.get( 'success' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_enqueueAction_error() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = null, // invalid source type
            Source_List_View_ID__c = lv.Id,
            Target_Type__c = 'Workflow',
            Target_SObject_Type__c = 'Account'
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'Id',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        Map<String, Object> result = MA_RunConfigCmpController.enqueueAction( config.Id );

        System.assertEquals( false, result.get( 'success' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getConfiguration() {

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Active__c = false,
            Batch_Size__c = 200,
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Source_Type__c = 'ListView',
            Source_List_View_ID__c = '00Bf40000017w5h',
            Target_Type__c = 'Flow',
            Target_Action_Name__c = 'Test_Flow',
            Schedule_Frequency__c = 'Custom',
            Schedule_Cron__c = '0 0 1 * * ?'
        );

        insert config;

        Mass_Action_Mapping__c fieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'SourceField',
            Target_Field_Name__c = 'TargetField'
        );

        insert fieldMapping;

        Test.startTest();

        MA_MassActionConfigWrapper wrapper = MA_RunConfigCmpController.getConfiguration( config.Id );

        System.assertEquals( config.Id, wrapper.recordId );
        System.assertEquals( config.Name, wrapper.name );
        System.assertEquals( config.DeveloperName__c, wrapper.developerName );
        System.assertEquals( config.Description__c, wrapper.description );
        System.assertEquals( config.Active__c, wrapper.active );
        System.assertEquals( config.Batch_Size__c, wrapper.batchSize );
        System.assertEquals( config.Named_Credential__c, wrapper.namedCredential );
        System.assertEquals( config.Source_Type__c, wrapper.sourceType );
        System.assertEquals( config.Source_List_View_ID__c, wrapper.sourceListViewID );
        System.assertEquals( config.Source_Report_ID__c, wrapper.sourceReportID );
        System.assertEquals( config.Source_Report_Column_Name__c, wrapper.sourceReportColumnName );
        System.assertEquals( config.Target_Type__c, wrapper.targetType );
        System.assertEquals( config.Target_SObject_Type__c, wrapper.targetSobjectType );
        System.assertEquals( config.Target_Action_Name__c, wrapper.targetActionName );
        System.assertEquals( config.Schedule_Frequency__c, wrapper.scheduleFrequency );
        System.assertEquals( config.Schedule_Cron__c, wrapper.scheduleCron );
        System.assertEquals( config.Schedule_SecondOfMinute__c, wrapper.scheduleSecondOfMinute );
        System.assertEquals( config.Schedule_MinuteOfHour__c, wrapper.scheduleMinuteOfHour );
        System.assertEquals( config.Schedule_HourOfDay__c, wrapper.scheduleHourOfDay );
        System.assertEquals( config.Schedule_DayOfMonth__c, wrapper.scheduleDayOfMonth );
        System.assertEquals( config.Schedule_MonthOfYear__c, wrapper.scheduleMonthOfYear );
        System.assertEquals( config.Schedule_DayOfWeek__c, wrapper.scheduleDayOfWeek );

        System.assertEquals( 1, wrapper.fieldMappings.size() );
        System.assertEquals( fieldMapping.Source_Field_Name__c, wrapper.fieldMappings[0].sourceFieldName );
        System.assertEquals( fieldMapping.Target_Field_Name__c, wrapper.fieldMappings[0].targetFieldName );

        Mass_Action_Configuration__c config2 = wrapper.toConfiguration();

        System.assertEquals( config.Id, config2.Id );
        System.assertEquals( config.Name, config2.Name );
        System.assertEquals( config.DeveloperName__c, config2.DeveloperName__c );
        System.assertEquals( config.Description__c, config2.Description__c );
        System.assertEquals( config.Active__c, config2.Active__c );
        System.assertEquals( config.Batch_Size__c, config2.Batch_Size__c );
        System.assertEquals( config.Named_Credential__c, config2.Named_Credential__c );
        System.assertEquals( config.Source_Type__c, config2.Source_Type__c );
        System.assertEquals( config.Source_List_View_ID__c, config2.Source_List_View_ID__c );
        System.assertEquals( config.Source_Report_ID__c, config2.Source_Report_ID__c );
        System.assertEquals( config.Source_Report_Column_Name__c, config2.Source_Report_Column_Name__c );
        System.assertEquals( config.Target_Type__c, config2.Target_Type__c );
        System.assertEquals( config.Target_SObject_Type__c, config2.Target_SObject_Type__c );
        System.assertEquals( config.Target_Action_Name__c, config2.Target_Action_Name__c );
        System.assertEquals( config.Schedule_Frequency__c, config2.Schedule_Frequency__c );
        System.assertEquals( config.Schedule_Cron__c, config2.Schedule_Cron__c );
        System.assertEquals( config.Schedule_SecondOfMinute__c, config2.Schedule_SecondOfMinute__c );
        System.assertEquals( config.Schedule_MinuteOfHour__c, config2.Schedule_MinuteOfHour__c );
        System.assertEquals( config.Schedule_HourOfDay__c, config2.Schedule_HourOfDay__c );
        System.assertEquals( config.Schedule_DayOfMonth__c, config2.Schedule_DayOfMonth__c );
        System.assertEquals( config.Schedule_MonthOfYear__c, config2.Schedule_MonthOfYear__c );
        System.assertEquals( config.Schedule_DayOfWeek__c, config2.Schedule_DayOfWeek__c );

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