/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_EditConfigCmpControllerTest {

    @IsTest
    static void test_getObjectsWithInvocableActions_Flow() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'Flow';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionsHttpRequestMock() );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getObjectsWithInvocableActions( namedCredential, actionType );

        System.debug( result );

        System.assertEquals( 0, result.size() );

        Test.stopTest();

    }

    @IsTest
    static void test_getObjectsWithInvocableActions_QuickAction() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'QuickAction';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionsHttpRequestMock() );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getObjectsWithInvocableActions( namedCredential, actionType );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Account', result[0].get( 'value' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getObjectsWithInvocableActions_EmailAlert() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'EmailAlert';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionsHttpRequestMock() );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getObjectsWithInvocableActions( namedCredential, actionType );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Account', result[0].get( 'value' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getObjectsWithInvocableActions_Apex() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'Apex';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionsHttpRequestMock() );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getObjectsWithInvocableActions( namedCredential, actionType );

        System.debug( result );

        System.assertEquals( 0, result.size() );

        Test.stopTest();

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_getInvocableActions_Flow() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'Flow';
        String objectName = 'Account';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionsHttpRequestMock( objectName ) );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getInvocableActions( namedCredential, actionType, objectName );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Test Flow', result[0].get( 'label' ) );
        System.assertEquals( 'Test_Flow', result[0].get( 'value' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getInvocableActions_QuickAction() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'QuickAction';
        String objectName = 'Account';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionsHttpRequestMock( objectName ) );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getInvocableActions( namedCredential, actionType, objectName );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Test Quick Action', result[0].get( 'label' ) );
        System.assertEquals( 'Test_Quick_Action', result[0].get( 'value' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getInvocableActions_EmailAlert() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'EmailAlert';
        String objectName = 'Account';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionsHttpRequestMock( objectName ) );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getInvocableActions( namedCredential, actionType, objectName );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Test Email Alert', result[0].get( 'label' ) );
        System.assertEquals( 'Test_Email_Alert', result[0].get( 'value' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getInvocableActions_Apex() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'Apex';
        String objectName = 'Account';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionsHttpRequestMock( objectName ) );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getInvocableActions( namedCredential, actionType, objectName );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Test Apex', result[0].get( 'label' ) );
        System.assertEquals( 'Test_Apex', result[0].get( 'value' ) );

        Test.stopTest();

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_getInvocableActionInputs_Workflow() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'Workflow';
        String actionName = '';
        String objectName = 'Account';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionInputsHttpRequestMock() );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getInvocableActionInputs( namedCredential, actionType, actionName, objectName );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Record ID', result[0].get( 'label' ) );
        System.assertEquals( 'ContextId', result[0].get( 'name' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getInvocableActionInputs_Flow() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'Flow';
        String actionName = 'Test_Flow';
        String objectName = 'Account';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionInputsHttpRequestMock() );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getInvocableActionInputs( namedCredential, actionType, actionName, objectName );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Test Input', result[0].get( 'label' ) );
        System.assertEquals( 'Test_Input', result[0].get( 'name' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getInvocableActionInputs_QuickAction() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'QuickAction';
        String actionName = 'Test_Quick_Action';
        String objectName = 'Account';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionInputsHttpRequestMock() );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getInvocableActionInputs( namedCredential, actionType, actionName, objectName );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Test Input', result[0].get( 'label' ) );
        System.assertEquals( 'Test_Input', result[0].get( 'name' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getInvocableActionInputs_EmailAlert() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'EmailAlert';
        String actionName = 'Test_Email_Alert';
        String objectName = 'Account';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionInputsHttpRequestMock() );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getInvocableActionInputs( namedCredential, actionType, actionName, objectName );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Test Input', result[0].get( 'label' ) );
        System.assertEquals( 'Test_Input', result[0].get( 'name' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getInvocableActionInputs_Apex() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String actionType = 'Apex';
        String actionName = 'Test_Apex';
        String objectName = 'Account';

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionInputsHttpRequestMock() );

        Test.startTest();

        List<Map<String, Object>> result = MA_EditConfigCmpController.getInvocableActionInputs( namedCredential, actionType, actionName, objectName );

        System.debug( result );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Test Input', result[0].get( 'label' ) );
        System.assertEquals( 'Test_Input', result[0].get( 'name' ) );

        Test.stopTest();

    }

    // --------------------------------------------------------------------------

    @IsTest( SeeAllData = true )
    static void test_get_reports() {

        // Reports and Report Folders cannot be created in unit tests as these are considered 'metadata'.
        // So we rely on the package bundling test folder/report and must use SeeAllData = true.

        Folder f = [ SELECT Id FROM Folder WHERE DeveloperName = 'Mass_Action_Test_Reports' ];
        Report r = [ SELECT Id FROM Report WHERE DeveloperName = 'MA_Test_Account_Report' ];

        Test.startTest();

        // ---

        List<Map<String, Object>> reportFolders = MA_EditConfigCmpController.getReportFolders();

        Boolean folderFound = false;
        for ( Map<String, Object> reportFolder : reportFolders ) {
            folderFound = ( folderFound || ( String.valueOf( reportFolder.get( 'value' ) ).left( 15 ) == String.valueOf( f.Id ).left( 15 ) ) );
        }
        System.assertEquals( true, folderFound, 'should have found folder' );

        // ---

        List<Map<String, Object>> reports = MA_EditConfigCmpController.getReportsByFolder( f.Id );

        Boolean reportFound = false;
        for ( Map<String, Object> rpt : reports ) {
            reportFound = ( reportFound || ( String.valueOf( rpt.get( 'value' ) ).left( 15 ) == String.valueOf( r.Id ).left( 15 ) ) );
        }
        System.assertEquals( true, reportFound, 'should have found report' );

        // ---

        Report rpt = MA_EditConfigCmpController.getReport( r.Id );

        System.assertEquals( r.Id, rpt.Id );

        // ---

        List<Map<String, Object>> reportColumns = MA_EditConfigCmpController.getReportColumns( r.Id );

        Boolean columnFound = false;
        for ( Map<String, Object> reportColumn : reportColumns ) {
            columnFound = ( columnFound || reportColumn.get( 'value' ) == 'ACCOUNT_ID' );
        }
        System.assertEquals( true, columnFound, 'report should have account id column' );

        // --

        Test.stopTest();

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_getObjectNames() {

        Test.startTest();

        Map<String, SObjectType> globalDescribeMap = Schema.getGlobalDescribe();

        List<Map<String, Object>> objectNames = MA_EditConfigCmpController.getObjectNames();

        for ( Map<String, Object> objectName : objectNames ) {
            System.assert( globalDescribeMap.containsKey( String.valueOf( objectName.get( 'value' ) ) ) );
        }

        Test.stopTest();

    }

    @IsTest
    static void test_getListViewsByObject() {

        String objectName = MA_MassActionUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Test.startTest();

        List<Map<String, Object>> listViews = MA_EditConfigCmpController.getListViewsByObject( lv.SobjectType );

        Boolean found = false;
        for ( Map<String, Object> listView : listViews ) {
            found = ( found || String.valueOf( listView.get( 'label' ) ).equalsIgnoreCase( lv.Name ) );
        }

        System.assertEquals( true, found );

        Test.stopTest();

    }

    @IsTest
    static void test_getListViewById() {

        String objectName = MA_MassActionUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Test.startTest();

        ListView listView = MA_EditConfigCmpController.getListView( lv.Id );

        System.assertEquals( lv.Id, listView.Id, 'should find list view' );

        System.assertEquals( null, MA_EditConfigCmpController.getListView( UserInfo.getUserId() ), 'should not find list view' );

        Test.stopTest();

    }

    @IsTest
    static void test_getListViewColumns() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';
        String objectName = MA_MassActionUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Test.setMock( HttpCalloutMock.class, new MA_InvocableActionsHttpRequestMock() );

        Test.startTest();

        List<Map<String, Object>> listViewColumns = MA_EditConfigCmpController.getListViewColumns( namedCredential, lv.Id );

        System.assertEquals( 1, listViewColumns.size() );
        System.assertEquals( 'Account ID', listViewColumns[0].get( 'label' ) );
        System.assertEquals( 'Id', listViewColumns[0].get( 'value' ) );
        System.assertEquals( 'ID', listViewColumns[0].get( 'dataType' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getNamedCredentials() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';

        Test.startTest();

        List<Map<String, Object>> namedCredentials = MA_EditConfigCmpController.getNamedCredentials();

        Boolean found = false;
        for ( Map<String, Object> credential : namedCredentials ) {
            found = ( found || String.valueOf( credential.get( 'value' ) ).equalsIgnoreCase( namedCredential ) );
        }

        System.assertEquals( true, found, 'should find named credential' );

        Test.stopTest();

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_getConfiguration() {

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
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

        MA_MassActionConfigWrapper wrapper = MA_EditConfigCmpController.getConfiguration( config.Id );

        System.assertEquals( config.Id, wrapper.recordId );
        System.assertEquals( config.Name, wrapper.name );
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

    @IsTest
    static void test_getConfigurationObjectDescribe() {

        String objectName = MA_MassActionUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get( objectName ).getDescribe();
        Map<String, SObjectField> fieldsMap = objectDescribe.fields.getMap();

        Test.startTest();

        Map<String, Object> configDesc = MA_EditConfigCmpController.getConfigurationObjectDescribe();

        System.assertEquals( objectDescribe.getName(), configDesc.get( 'name' ) );
        System.assertEquals( objectDescribe.getLocalName(), configDesc.get( 'localName' ) );
        System.assertEquals( objectDescribe.getLabel(), configDesc.get( 'label' ) );
        System.assertEquals( objectDescribe.getLabelPlural(), configDesc.get( 'labelPlural' ) );

        Map<String, Map<String, Object>> configFieldsDesc = (Map<String, Map<String, Object>>) configDesc.get( 'fields' );

        for ( String fieldLocalName : configFieldsDesc.keySet() ) {

            Map<String, Object> configFieldDesc = configFieldsDesc.get( fieldLocalName );
            DescribeFieldResult fieldDesc = fieldsMap.get( String.valueOf( configFieldDesc.get( 'name' ) ) ).getDescribe();

            System.assertEquals( fieldDesc.getName(), configFieldDesc.get( 'name' ) );
            System.assertEquals( fieldDesc.getLocalName(), configFieldDesc.get( 'localName' ) );
            System.assertEquals( fieldDesc.getLabel(), configFieldDesc.get( 'label' ) );
            System.assertEquals( fieldDesc.getInlineHelpText(), configFieldDesc.get( 'helpText' ) );

        }

        Test.stopTest();

    }

    @IsTest
    static void test_saveConfiguration() {

        MA_MassActionConfigWrapper wrapper = new MA_MassActionConfigWrapper();
        wrapper.name = 'Test Config';
        wrapper.active = false;
        wrapper.batchSize = 200;
        wrapper.namedCredential = 'Mass_Action_Test_Named_Credential';
        wrapper.sourceType = 'ListView';
        wrapper.sourceListViewID = '00Bf40000017w5h';
        wrapper.targetType = 'Flow';
        wrapper.targetActionName = 'Test_Flow';
        wrapper.scheduleFrequency = 'Custom';
        wrapper.scheduleCron = '0 0 1 * * ?';

        String wrapperJson = JSON.serialize( wrapper );

        String fieldMappingsJson = JSON.serialize( new Map<String, String>{
            'TargetField' => 'SourceField'
        });

        Test.startTest();

        // Test Success

        Map<String, Object> result = MA_EditConfigCmpController.saveConfiguration( wrapperJson, fieldMappingsJson );

        System.assertEquals( true, result.get( 'success' ) );

        Mass_Action_Configuration__c config = MA_MassActionUtils.getConfiguration( (ID) result.get( 'recordId' ) );

        System.assertEquals( wrapper.name, config.Name );
        System.assertEquals( wrapper.active, config.Active__c );
        System.assertEquals( wrapper.batchSize, config.Batch_Size__c );
        System.assertEquals( wrapper.namedCredential, config.Named_Credential__c );
        System.assertEquals( wrapper.sourceType, config.Source_Type__c );
        System.assertEquals( wrapper.sourceListViewID, config.Source_List_View_ID__c );
        System.assertEquals( wrapper.targetType, config.Target_Type__c );
        System.assertEquals( wrapper.targetActionName, config.Target_Action_Name__c );
        System.assertEquals( wrapper.scheduleFrequency, config.Schedule_Frequency__c );
        System.assertEquals( wrapper.scheduleCron, config.Schedule_Cron__c );

        System.assertEquals( 1, config.Mass_Action_Mappings__r.size() );
        System.assertEquals( 'TargetField', config.Mass_Action_Mappings__r[0].Target_Field_Name__c );
        System.assertEquals( 'SourceField', config.Mass_Action_Mappings__r[0].Source_Field_Name__c );

        // Test Error

        try {

            MA_EditConfigCmpController.saveConfiguration( null, null );

            System.assert( false, 'should fail' );

        } catch ( Exception e ) {

            System.assert( true, 'should fail' );

        }

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