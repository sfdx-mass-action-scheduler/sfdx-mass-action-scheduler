/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_EditConfigRestControllerTest {

    @IsTest
    static void test_getObjectsWithInvocableActions_Flow() {

        String operation = 'getObjectsWithInvocableActions';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'Flow'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 0, result.size() );

    }

    @IsTest
    static void test_getObjectsWithInvocableActions_QuickAction() {

        String operation = 'getObjectsWithInvocableActions';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'QuickAction'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Account', ((Map<String, Object>) result[0]).get( 'value' ) );

    }

    @IsTest
    static void test_getObjectsWithInvocableActions_EmailAlert() {

        String operation = 'getObjectsWithInvocableActions';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'EmailAlert'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );

        System.assertEquals( 1, result.size() );
        System.assertEquals( 'Account', ((Map<String, Object>) result[0]).get( 'value' ) );

    }

    @IsTest
    static void test_getObjectsWithInvocableActions_Apex() {

        String operation = 'getObjectsWithInvocableActions';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'Apex'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );

        System.assertEquals( 0, result.size() );

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_getInvocableActions_Flow() {

        String operation = 'getInvocableActions';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'Flow',
            'objectName' => 'Account'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 1, result.size() );

        Map<String, Object> resultAction = (Map<String, Object>) result[0];

        System.assertEquals( 'Test Flow', resultAction.get( 'label' ) );
        System.assertEquals( 'Test_Flow', resultAction.get( 'value' ) );

    }

    @IsTest
    static void test_getInvocableActions_QuickAction() {

        String operation = 'getInvocableActions';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'QuickAction',
            'objectName' => 'Account'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 1, result.size() );

        Map<String, Object> resultAction = (Map<String, Object>) result[0];

        System.assertEquals( 'Test Quick Action', resultAction.get( 'label' ) );
        System.assertEquals( 'Test_Quick_Action', resultAction.get( 'value' ) );

    }

    @IsTest
    static void test_getInvocableActions_EmailAlert() {

        String operation = 'getInvocableActions';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'EmailAlert',
            'objectName' => 'Account'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 1, result.size() );

        Map<String, Object> resultAction = (Map<String, Object>) result[0];

        System.assertEquals( 'Test Email Alert', resultAction.get( 'label' ) );
        System.assertEquals( 'Test_Email_Alert', resultAction.get( 'value' ) );

    }

    @IsTest
    static void test_getInvocableActions_Apex() {

        String operation = 'getInvocableActions';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'Apex',
            'objectName' => 'Account'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 1, result.size() );

        Map<String, Object> resultAction = (Map<String, Object>) result[0];

        System.assertEquals( 'Test Apex', resultAction.get( 'label' ) );
        System.assertEquals( 'Test_Apex', resultAction.get( 'value' ) );

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_getInvocableActionInputs_Workflow() {

        String operation = 'getInvocableActionInputs';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'Workflow',
            'actionName' => '',
            'objectName' => 'Account'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 1, result.size() );

        Map<String, Object> resultAction = (Map<String, Object>) result[0];

        System.assertEquals( 'Record ID', resultAction.get( 'label' ) );
        System.assertEquals( 'ContextId', resultAction.get( 'name' ) );

    }

    @IsTest
    static void test_getInvocableActionInputs_Flow() {

        String operation = 'getInvocableActionInputs';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'Flow',
            'actionName' => 'Test_Flow',
            'objectName' => 'Account'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 1, result.size() );

        Map<String, Object> resultAction = (Map<String, Object>) result[0];

        System.assertEquals( 'Test Input', resultAction.get( 'label' ) );
        System.assertEquals( 'Test_Input', resultAction.get( 'name' ) );

    }

    @IsTest
    static void test_getInvocableActionInputs_QuickAction() {

        String operation = 'getInvocableActionInputs';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'QuickAction',
            'actionName' => 'Test_Quick_Action',
            'objectName' => 'Account'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 1, result.size() );

        Map<String, Object> resultAction = (Map<String, Object>) result[0];

        System.assertEquals( 'Test Input', resultAction.get( 'label' ) );
        System.assertEquals( 'Test_Input', resultAction.get( 'name' ) );

    }

    @IsTest
    static void test_getInvocableActionInputs_EmailAlert() {

        String operation = 'getInvocableActionInputs';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'EmailAlert',
            'actionName' => 'Test_Email_Alert',
            'objectName' => 'Account'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 1, result.size() );

        Map<String, Object> resultAction = (Map<String, Object>) result[0];

        System.assertEquals( 'Test Input', resultAction.get( 'label' ) );
        System.assertEquals( 'Test_Input', resultAction.get( 'name' ) );

    }

    @IsTest
    static void test_getInvocableActionInputs_Apex() {

        String operation = 'getInvocableActionInputs';
        Map<String, Object> params = new Map<String, Object>{
            'actionType' => 'Apex',
            'actionName' => 'Test_Apex',
            'objectName' => 'Account'
        };

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( operation, params );

        Test.stopTest();

        List<Object> result = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 1, result.size() );

        Map<String, Object> resultAction = (Map<String, Object>) result[0];

        System.assertEquals( 'Test Input', resultAction.get( 'label' ) );
        System.assertEquals( 'Test_Input', resultAction.get( 'name' ) );

    }

    // --------------------------------------------------------------------------

    @IsTest( SeeAllData = true )
    static void test_get_reports() {

        // Reports and Report Folders cannot be created in unit tests as these are considered 'metadata'.
        // So we rely on the package bundling test folder/report and must use SeeAllData = true.

        Folder f = [ SELECT Id FROM Folder WHERE DeveloperName = 'Mass_Action_Test_Reports' ];
        Report r = [ SELECT Id FROM Report WHERE DeveloperName = 'MA_Test_Account_Report' ];

        Map<String, Object> responseBodyMap;

        Test.startTest();

        // ---

        responseBodyMap = test_handlePost( 'getReportFolders', new Map<String, Object>() );

        List<Object> reportFolders = (List<Object>) responseBodyMap.get( 'result' );

        Boolean folderFound = false;
        for ( Object item : reportFolders ) {
            Map<String, Object> reportFolder = (Map<String, Object>) item;
            folderFound = ( folderFound || ( String.valueOf( reportFolder.get( 'value' ) ).left( 15 ) == String.valueOf( f.Id ).left( 15 ) ) );
        }
        System.assertEquals( true, folderFound, 'should have found folder' );

        // ---

        responseBodyMap = test_handlePost( 'getReportsByFolder', new Map<String, Object>{
            'folderId' => f.Id
        });

        List<Object> reports = (List<Object>) responseBodyMap.get( 'result' );

        Boolean reportFound = false;
        for ( Object item : reports ) {
            Map<String, Object> rpt = (Map<String, Object>) item;
            reportFound = ( reportFound || ( String.valueOf( rpt.get( 'value' ) ).left( 15 ) == String.valueOf( r.Id ).left( 15 ) ) );
        }
        System.assertEquals( true, reportFound, 'should have found report' );

        // ---

        responseBodyMap = test_handlePost( 'getReport', new Map<String, Object>{
            'recordId' => r.Id
        });

        Map<String, Object> rpt = (Map<String, Object>) responseBodyMap.get( 'result' );

        System.assertEquals( r.Id, rpt.get( 'Id' ) );

        // ---

        responseBodyMap = test_handlePost( 'getReportColumns', new Map<String, Object>{
            'reportId' => r.Id
        });

        List<Object> reportColumns = (List<Object>) responseBodyMap.get( 'result' );

        Boolean columnFound = false;
        for ( Object item : reportColumns ) {
            Map<String, Object> reportColumn = (Map<String, Object>) item;
            columnFound = ( columnFound || reportColumn.get( 'value' ) == 'ACCOUNT_ID' );
        }
        System.assertEquals( true, columnFound, 'report should have account id column' );

        // --

        Test.stopTest();

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_getObjectNames() {

        Map<String, SObjectType> globalDescribeMap = Schema.getGlobalDescribe();

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( 'getObjectNames', new Map<String, Object>() );

        Test.stopTest();

        List<Object> objectNames = (List<Object>) responseBodyMap.get( 'result' );

        for ( Object item : objectNames ) {
            Map<String, Object> objectName = (Map<String, Object>) item;
            System.assert( globalDescribeMap.containsKey( String.valueOf( objectName.get( 'value' ) ) ) );
        }

    }

    @IsTest
    static void test_getObjectNamesWithListViews() {

        Set<String> sobjectsWithListViews = new Set<String>();
        for ( AggregateResult result : [
            SELECT SObjectType
            FROM ListView
            WHERE IsSoqlCompatible = true AND SObjectType != null
            GROUP BY SObjectType
            ORDER BY SObjectType ASC
            LIMIT 2000
        ]) {
            // lowercase the object names to match keys in the global describe map
            // because the Set method `contains` is case-sensitive
            sobjectsWithListViews.add( ( (String) result.get( 'SObjectType' ) ).toLowerCase() );
        }

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( 'getObjectNamesWithListViews', new Map<String, Object>() );

        Test.stopTest();

        List<Object> objectNames = (List<Object>) responseBodyMap.get( 'result' );

        for ( Object item : objectNames ) {
            Map<String, Object> objectName = (Map<String, Object>) item;
            System.assert( sobjectsWithListViews.contains( String.valueOf( objectName.get( 'value' ) ).toLowerCase() ) );
        }

    }

    @IsTest
    static void test_getListViewsByObject() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( 'getListViewsByObject', new Map<String, Object>{
            'objectName' => objectName
        });

        Test.stopTest();

        List<Object> listViews = (List<Object>) responseBodyMap.get( 'result' );

        Boolean found = false;
        for ( Object item : listViews ) {
            Map<String, Object> listView = (Map<String, Object>) item;
            found = ( found || String.valueOf( listView.get( 'label' ) ).equalsIgnoreCase( lv.Name ) );
        }

        System.assertEquals( true, found );

    }

    @IsTest
    static void test_getListViewById() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( 'getListView', new Map<String, Object>{
            'recordId' => lv.Id
        });

        Test.stopTest();

        Map<String, Object> listView = (Map<String, Object>) responseBodyMap.get( 'result' );

        System.assertEquals( lv.Id, listView.get( 'Id' ), 'should find list view' );

    }

    @IsTest
    static void test_getListViewColumns() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( 'getListViewColumns', new Map<String, Object>{
            'listViewId' => lv.Id
        });

        Test.stopTest();

        List<Object> listViewColumns = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 3, listViewColumns.size() );

        Boolean hasAccountIdColumn = false;
        Boolean hasAccountNameColumn = false;
        Boolean hasOwnerIdColumn = false;

        for ( Object item : listViewColumns ) {

            Map<String, Object> listViewColumn = (Map<String, Object>) item;

            switch on ( (String) listViewColumn.get( 'label' ) ) {
                when 'Account ID' {
                    System.assertEquals( 'Id', listViewColumn.get( 'value' ) );
                    System.assertEquals( 'ID', listViewColumn.get( 'dataType' ) );
                    hasAccountIdColumn = true;
                }
                when 'Account Name' {
                    System.assertEquals( 'Name', listViewColumn.get( 'value' ) );
                    System.assertEquals( 'STRING', listViewColumn.get( 'dataType' ) );
                    hasAccountNameColumn = true;
                }
                when 'Owner ID' {
                    System.assertEquals( 'Owner.Id', listViewColumn.get( 'value' ) );
                    System.assertEquals( 'ID', listViewColumn.get( 'dataType' ) );
                    hasOwnerIdColumn = true;
                }
            }

        }

        System.assert( hasAccountIdColumn, 'missing Account ID column' );
        System.assert( hasAccountNameColumn, 'missing Account Name column' );
        System.assert( hasOwnerIdColumn, 'missing Owner ID column' );

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_getSoqlQueryResults() {

        // we return mock results, the query doesn't matter
        // other than to provide the illusion of realism
        // because we execute the query via the REST API
        String query = 'SELECT Id, Name FROM Account LIMIT 1';

        Test.startTest();

        // Test Success (no next records url)

        Map<String, Object> responseBodyMap = test_handlePost( 'getSoqlQueryResults', new Map<String, Object>{
            'query' => query
        });

        Map<String, Object> result = (Map<String, Object>) responseBodyMap.get( 'result' );

        System.assertEquals( 1, (Integer) result.get( 'totalSize' ) );
        System.assertEquals( true, (Boolean) result.get( 'done' ) );
        System.assert( String.isBlank( (String) result.get( 'nextRecordsUrl' ) ) );

        List<Object> records = (List<Object>) result.get( 'records' );
        System.assertEquals( 1, records.size() );

        for ( Object item : records ) {
            Map<String, Object> row = (Map<String, Object>) item;
            System.assertEquals( '001f400000CukanAAB', row.get( Account.Id.getDescribe().getName() ) );
            System.assertEquals( 'Test Account 1', row.get( Account.Name.getDescribe().getName() ) );
        }

        // Test Success (yes next records url)

        responseBodyMap = test_handlePost( 'getSoqlQueryResults', new Map<String, Object>{
            'query' => query,
            'batchSize' => 500
        });

        result = (Map<String, Object>) responseBodyMap.get( 'result' );

        System.assertEquals( 501, (Integer) result.get( 'totalSize' ), 'should be 1 more than requested query options batch size' );
        System.assertEquals( false, (Boolean) result.get( 'done' ) );
        System.assert( String.isNotBlank( (String) result.get( 'nextRecordsUrl' ) ) );

        records = (List<Object>) result.get( 'records' );
        System.assertEquals( 1, records.size() );

        for ( Object item : records ) {
            Map<String, Object> row = (Map<String, Object>) item;
            System.assertEquals( '001f400000CukanAAB', row.get( Account.Id.getDescribe().getName() ) );
            System.assertEquals( 'Test Account 1', row.get( Account.Name.getDescribe().getName() ) );
        }

        // Test Error

        try {

            responseBodyMap = test_handlePost( 'getSoqlQueryResults', new Map<String, Object>{
                'query' => 'TEST_FAIL'
            });

            System.assertEquals( false, responseBodyMap.get( 'success' ), 'should fail' );
            System.assert( ( (String) responseBodyMap.get( 'error' ) ).startsWithIgnoreCase( 'SOQL Query Error:' ), 'failed for wrong reason' );

        } catch ( Exception e ) {

            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );
            System.assert( false, 'failed for wrong reason: ' + e.getMessage() );

        }

        Test.stopTest();

    }

    @IsTest
    static void test_getSoqlQueryNextRecordsResults() {

        Test.startTest();

        // Test Success

        Integer queryOptionsBatchSize = 500;

        Map<String, Object> responseBodyMap = test_handlePost( 'getSoqlQueryNextRecordsResults', new Map<String, Object>{
            'nextRecordsId' => '01gf400001MMCpeAAH-' + queryOptionsBatchSize
        });

        Map<String, Object> result = (Map<String, Object>) responseBodyMap.get( 'result' );

        System.assertEquals( queryOptionsBatchSize + 1, (Integer) result.get( 'totalSize' ), 'should be one more than query options batch size' );
        System.assertEquals( true, (Boolean) result.get( 'done' ) );
        System.assert( String.isBlank( (String) result.get( 'nextRecordsUrl' ) ) );

        List<Object> records = (List<Object>) result.get( 'records' );
        System.assertEquals( 1, records.size() );

        for ( Object item : records ) {
            Map<String, Object> row = (Map<String, Object>) item;
            System.assertEquals( '001f400000lxT2JAAU', row.get( Account.Id.getDescribe().getName() ) );
            System.assertEquals( 'Test Account 2', row.get( Account.Name.getDescribe().getName() ) );
        }

        // Test Error

        try {

            responseBodyMap = test_handlePost( 'getSoqlQueryNextRecordsResults', new Map<String, Object>{
                'nextRecordsId' => 'TEST_FAIL'
            });

            System.assertEquals( false, responseBodyMap.get( 'success' ), 'should fail' );
            System.assert( ( (String) responseBodyMap.get( 'error' ) ).startsWithIgnoreCase( 'SOQL Query Error:' ), 'failed for wrong reason' );

        } catch ( Exception e ) {

            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );
            System.assert( false, 'failed for wrong reason: ' + e.getMessage() );

        }

        Test.stopTest();

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_getNamedCredentials() {

        String namedCredential = 'Mass_Action_Test_Named_Credential';

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( 'getNamedCredentials', new Map<String, Object>() );

        Test.stopTest();

        List<Object> namedCredentials = (List<Object>) responseBodyMap.get( 'result' );
        System.assertEquals( 1, namedCredentials.size() );

        for ( Object item : namedCredentials ) {
            Map<String, Object> credential = (Map<String, Object>) item;
            System.assertEquals( namedCredential, credential.get( 'value' ) );
        }

    }

    // --------------------------------------------------------------------------

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

        Map<String, Object> responseBodyMap = test_handlePost( 'getConfiguration', new Map<String, Object>{
            'recordId' => config.Id
        });

        Object result = responseBodyMap.get( 'result' );

        MA_MassActionConfigWrapper wrapper = (MA_MassActionConfigWrapper) JSON.deserialize( JSON.serialize( result ), MA_MassActionConfigWrapper.class );

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
        System.assertEquals( config.Target_Apex_Script__c, wrapper.targetApexScript );
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
        System.assertEquals( config.Target_Apex_Script__c, config2.Target_Apex_Script__c );
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

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get( objectName ).getDescribe();
        Map<String, SObjectField> fieldsMap = objectDescribe.fields.getMap();

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( 'getConfigurationObjectDescribe', new Map<String, Object>() );

        Test.stopTest();

        Map<String, Object> configDesc = (Map<String, Object>) responseBodyMap.get( 'result' );

        System.assertEquals( objectDescribe.getName(), configDesc.get( 'name' ) );
        System.assertEquals( objectDescribe.getLocalName(), configDesc.get( 'localName' ) );
        System.assertEquals( objectDescribe.getLabel(), configDesc.get( 'label' ) );
        System.assertEquals( objectDescribe.getLabelPlural(), configDesc.get( 'labelPlural' ) );

        Map<String, Object> configFieldsDesc = (Map<String, Object>) configDesc.get( 'fields' );

        for ( String fieldLocalName : configFieldsDesc.keySet() ) {

            Map<String, Object> configFieldDesc = (Map<String, Object>) configFieldsDesc.get( fieldLocalName );
            DescribeFieldResult fieldDesc = fieldsMap.get( String.valueOf( configFieldDesc.get( 'name' ) ) ).getDescribe();

            System.assertEquals( fieldDesc.getName(), configFieldDesc.get( 'name' ) );
            System.assertEquals( fieldDesc.getLocalName(), configFieldDesc.get( 'localName' ) );
            System.assertEquals( fieldDesc.getLabel(), configFieldDesc.get( 'label' ) );
            System.assertEquals( fieldDesc.getInlineHelpText(), configFieldDesc.get( 'helpText' ) );

        }

    }

    @IsTest
    static void test_saveConfiguration() {

        MA_MassActionConfigWrapper wrapper = new MA_MassActionConfigWrapper();
        wrapper.name = 'Test Config';
        wrapper.developerName = 'Test_Config';
        wrapper.active = false;
        wrapper.batchSize = 200;
        wrapper.namedCredential = 'Mass_Action_Test_Named_Credential';
        wrapper.sourceType = 'ListView';
        wrapper.sourceListViewID = '00Bf40000017w5h';
        wrapper.targetType = 'Flow';
        wrapper.targetActionName = 'Test_Flow';
        wrapper.scheduleFrequency = 'Custom';
        wrapper.scheduleCron = '0 0 1 * * ?';

        Map<String, String> fieldMappings = new Map<String, String>{
            'TargetField' => 'SourceField'
        };

        Test.startTest();

        // Test Success

        Map<String, Object> responseBodyMap = test_handlePost( 'saveConfiguration', new Map<String, Object>{
            'wrapperJson' => wrapper,
            'fieldMappingsJson' => fieldMappings
        });

        Map<String, Object> result = (Map<String, Object>) responseBodyMap.get( 'result' );

        System.assertEquals( true, responseBodyMap.get( 'success' ) );

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

            responseBodyMap = test_handlePost( 'saveConfiguration', new Map<String, Object>() );

            System.assertEquals( false, responseBodyMap.get( 'success' ), 'should fail' );

        } catch ( Exception e ) {

            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );
            System.assert( false, 'failed for wrong reason: ' + e.getMessage() );

        }

        Test.stopTest();

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_getCalloutRestEndpointURL() {

        Test.startTest();

        System.assertEquals( 'callout:TestNamedCredential' + MA_MassActionUtils.REST_API_PATH, MA_MassActionUtils.getCalloutRestEndpointURL( 'TestNamedCredential' ) );
        System.assertEquals( MA_MassActionUtils.REST_API_SERVICES_URL, MA_MassActionUtils.getCalloutRestEndpointURL( null ) );
        System.assertEquals( MA_MassActionUtils.REST_API_SERVICES_URL, MA_MassActionUtils.getCalloutRestEndpointURL( '' ) );
        System.assertEquals( MA_MassActionUtils.REST_API_SERVICES_URL, MA_MassActionUtils.getCalloutRestEndpointURL( ' ' ) );

        Test.stopTest();

    }

    @IsTest
    static void test_getCalloutSoapEndpointURL() {

        Test.startTest();

        System.assertEquals( 'callout:TestNamedCredential' + MA_MassActionUtils.SOAP_API_PATH, MA_MassActionUtils.getCalloutSoapEndpointURL( 'TestNamedCredential' ) );
        System.assertEquals( MA_MassActionUtils.SOAP_API_SERVICES_URL, MA_MassActionUtils.getCalloutSoapEndpointURL( null ) );
        System.assertEquals( MA_MassActionUtils.SOAP_API_SERVICES_URL, MA_MassActionUtils.getCalloutSoapEndpointURL( '' ) );
        System.assertEquals( MA_MassActionUtils.SOAP_API_SERVICES_URL, MA_MassActionUtils.getCalloutSoapEndpointURL( ' ' ) );

        Test.stopTest();

    }

    // --------------------------------------------------------------------------

    @IsTest
    static void test_unsupported_operation() {

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        Map<String, Object> responseBodyMap = test_handlePost( 'FAKE_OPERATION', new Map<String, Object>() );

        Test.stopTest();

        System.assertEquals( false, responseBodyMap.get( 'success' ), 'should fail' );

    }

    @IsTest
    static void test_calloutMock_noMatchingURL() {

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        // Test GET

        HttpRequest getReq = new HttpRequest();
        getReq.setMethod( 'GET' );
        getReq.setEndpoint( 'nowhere' );

        HttpResponse getRes = new Http().send( getReq );
        System.assertEquals( 'ERROR', getRes.getStatus() );
        System.assertEquals( 400, getRes.getStatusCode() );
        System.assert( getRes.getBody().startsWithIgnoreCase( 'Unsupported endpoint' ) );

        // Test POST

        HttpRequest postReq = new HttpRequest();
        postReq.setMethod( 'POST' );
        postReq.setEndpoint( 'nowhere' );

        HttpResponse postRes = new Http().send( postReq );
        System.assertEquals( 'ERROR', postRes.getStatus() );
        System.assertEquals( 400, postRes.getStatusCode() );
        System.assert( postRes.getBody().startsWithIgnoreCase( 'Unsupported endpoint' ) );

        Test.stopTest();

    }

    // --------------------------------------------------------------------------

    static Map<String, Object> test_handlePost( String operation, Map<String, Object> params ) {

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        req.httpMethod = 'POST';
        req.requestURI = '/config/edit/';
        req.addParameter( 'operation', operation );
        req.requestBody = Blob.valueOf( JSON.serializePretty( params ) );
        req.addHeader( 'Origin', 'https://testdomain.my.salesforce.com' );
        req.addHeader( 'Content-Type', 'application/json; charset=utf-8' );
        req.addHeader( 'Accepts', 'application/json' );

        MA_EditConfigRestController.handlePost();

        System.debug( res );
        System.debug( res.responseBody.toString() );

        Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped( res.responseBody.toString() );

        return responseBodyMap;
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