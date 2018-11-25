/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@RestResource( urlMapping = '/config/edit/*' )
global with sharing class MA_EditConfigRestController {

    /**
     * Entry point into this REST class.
     *
     * Expects one URL parameter named 'operation',
     * which translates to an actual Apex method in this class.
     *
     * Expects JSON body with parameters to pass to the actual
     * Apex method indicated by the 'operation' URL parameter.
     *
     * Example:
     *   POST: /services/apexrest/dca_mass_action/config/edit?operation=getReportsByFolder
     *   {
     *     "reportId" : "00lf4000000pezaAAA"
     *   }
     *
     * See handleRequestOperation(..) method comments for full details.
     */
    @HttpPost
    global static void handlePost() {

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {

            System.debug( req );

            Map<String, String> requestUrlParams = req.params;
            Map<String, Object> requestBodyParams = (Map<String, Object>) JSON.deserializeUntyped( ( req.requestBody == null ) ? '{}' : req.requestBody.toString() );
            Map<String, Object> responseBodyParams = new Map<String, Object>{ 'success' => true };

            String operation = requestUrlParams.get( 'operation' );

            System.debug( 'RequestUrlParams: ' + JSON.serializePretty( requestUrlParams ) );
            System.debug( 'RequestBody: ' + JSON.serializePretty( requestBodyParams ) );

            handleRequestOperation( operation, requestBodyParams, responseBodyParams );

            if ( (Boolean) responseBodyParams.get( 'success' ) ) {
                res.responseBody = Blob.valueOf( JSON.serializePretty( responseBodyParams ) );
                res.statusCode = 200;
            } else {
                res.responseBody = Blob.valueOf( (String) responseBodyParams.get( 'error' ) );
                res.statusCode = 400;
            }

        } catch ( Exception e ) {

            res.responseBody = Blob.valueOf( e.getMessage() );
            res.statusCode = 400;

        }

        // To avoid customers having to setup their own CORS Whitelist then
        // I whitelist their VF domain for them on the fly in the http response.
        // https://github.com/douglascayers/sfdx-lightning-api-component#access-denied-or-no-access-control-allow-origin-header-is-present-on-the-requested-resource-origin-httpsyourinstancevisualforcecom-is-therefore-not-allowed-access
        res.addHeader( 'Access-Control-Allow-Origin', req.headers.get( 'Origin' ) );
        res.addHeader( 'Content-Type', 'application/json; charset=utf-8' );

        System.debug( res );
        System.debug( 'ResponseBody: ' + res.responseBody.toString() );

    }

    /**
     * This method serves as a translation layer between the REST API request and
     * the actual implementation methods. Originally, the implementation methods
     * for each operation were @AuraEnabled and called directly from Lightning components.
     *
     * To adapt those operations for use with the LC_API component then this class was
     * introduced as a pure REST API endpoint for the same operations. However, since
     * Apex REST services can only include a single @HttpGet, @HttpPost, etc. methods
     * then I chose a single REST class and http method to handle all operations rather
     * than creating a separate REST class for each operation. Thus, the need for this
     * translation method.
     *
     * @param operation
     *      Which implementation method to call.
     *      These are the same names as the original AuraEnabled methods.
     * @param requestBody
     *      Map of key=value parameters from the REST request.
     *      Method arguments will be pulled from these.
     * @param responseBody
     *      Map of key=value parameters for the REST response.
     *      This method puts 'result' key into the map, or 'success=false' and 'error=...' entries if operation is not supported.
     *
     * Exceptions bubble up to calling method.
     */
    private static void handleRequestOperation( String operation, Map<String, Object> requestBody, Map<String, Object> responseBody ) {

        switch on ( operation ) {

            // -----------------------------------------------------------------------------

            when 'getObjectsWithInvocableActions' {
                responseBody.put( 'result', getObjectsWithInvocableActions(
                    MA_MassActionUtils.REST_API_SERVICES_DATA_URL,
                    (String) requestBody.get( 'actionType' )
                ));
            }

            when 'getInvocableActions' {
                responseBody.put( 'result', getInvocableActions(
                    MA_MassActionUtils.REST_API_SERVICES_DATA_URL,
                    (String) requestBody.get( 'actionType' ),
                    (String) requestBody.get( 'objectName' )
                ));
            }

            when 'getInvocableActionInputs' {
                responseBody.put( 'result', getInvocableActionInputs(
                    MA_MassActionUtils.REST_API_SERVICES_DATA_URL,
                    (String) requestBody.get( 'actionType' ),
                    (String) requestBody.get( 'actionName' ),
                    (String) requestBody.get( 'objectName' )
                ));
            }

            // -----------------------------------------------------------------------------

            when 'getReportFolders' {
                responseBody.put( 'result', getReportFolders() );
            }

            when 'getReportsByFolder' {
                responseBody.put( 'result', getReportsByFolder(
                    (ID) requestBody.get( 'folderId' )
                ));
            }

            when 'getReport' {
                responseBody.put( 'result', getReport(
                    (ID) requestBody.get( 'recordId' )
                ));
            }

            when 'getReportColumns' {
                responseBody.put( 'result', getReportColumns(
                    (String) requestBody.get( 'reportId' )
                ));
            }

            // -----------------------------------------------------------------------------

            when 'getObjectNames' {
                responseBody.put( 'result', getObjectNames() );
            }

            when 'getListViewsByObject' {
                responseBody.put( 'result', getListViewsByObject(
                    (String) requestBody.get( 'objectName' )
                ));
            }

            when 'getListView' {
                responseBody.put( 'result', getListView(
                    (ID) requestBody.get( 'recordId' )
                ));
            }

            when 'getListViewColumns' {
                responseBody.put( 'result', getListViewColumns(
                    MA_MassActionUtils.REST_API_SERVICES_DATA_URL,
                    (ID) requestBody.get( 'listViewId' )
                ));
            }

            // -----------------------------------------------------------------------------

            when 'getNamedCredentials' {
                responseBody.put( 'result', getNamedCredentials() );
            }

            // -----------------------------------------------------------------------------

            when 'getConfiguration' {
                responseBody.put( 'result', getConfiguration(
                    (ID) requestBody.get( 'recordId' )
                ));
            }

            when 'getConfigurationObjectDescribe' {
                responseBody.put( 'result', getConfigurationObjectDescribe() );
            }

            when 'saveConfiguration' {
                responseBody.put( 'result', saveConfiguration(
                    JSON.serialize( requestBody.get( 'wrapperJson' ) ),
                    JSON.serialize( requestBody.get( 'fieldMappingsJson' ) )
                ));
            }

            // -----------------------------------------------------------------------------

            when else {

                responseBody.put( 'success', false );
                responseBody.put( 'error', 'Unsupported operation value: ' + operation );

            }

        }

    }

    // -----------------------------------------------------------------------------

    /**
     * This method is primarily designed for showing list of objects for Email Alerts and Quick Actions.
     * Rather than display user a list of all objects in their org that may or may not have actions setup
     * we instead use the Actions REST API to know the objects (if any) that have actions configured for them.
     * This has the benefit of reducing the unusable object options the user must sift through.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param actionType
     *      Value from picklist Mass_Action_Configuration__c.Target_Type__c (e.g. 'QuickAction', 'EmailAlert')
     */
    private static List<Map<String, Object>> getObjectsWithInvocableActions( String baseURL, String actionType ) {

        Map<String, SObjectType> globalDescribeMap = Schema.getGlobalDescribe();

        List<ObjectNameWrapper> wrappers = new List<ObjectNameWrapper>();

        for ( String objectName : MA_MassActionUtils.getObjectsWithInvocableActions( baseURL, actionType ) ) {
            if ( globalDescribeMap.containsKey( objectName ) ) {
                DescribeSObjectResult objDescribe = globalDescribeMap.get( objectName ).getDescribe();
                wrappers.add( new ObjectNameWrapper( objDescribe.getLabel(), objDescribe.getName() ) );
            }
        }

        wrappers.sort();

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( ObjectNameWrapper wrapper : wrappers ) {
            options.add( new Map<String, Object>{
                'label' => String.format( '{0} ({1})', new String[] { wrapper.objectLabel, wrapper.objectName } ),
                'value' => wrapper.objectName
            });
        }

        return options;
    }

    /**
     * Get list of actions that can be invoked.
     * Used when user is configuring the target action to invoke.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param actionType
     *      Specific kind of actions to retrieve like Flows or Email Alerts.
     *      Value should match API value of Mass_Action_Configuration__c.Target_Type__c picklist entry.
     * @param objectName
     *      Only required for certain action types like Quick Actions or Email Alerts.
     *      In the REST API, some actions are object specific and this indicates for which object to return their actions.
     */
    private static List<Map<String, Object>> getInvocableActions( String baseURL, String actionType, String objectName ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( Map<String, Object> action : MA_MassActionUtils.getInvocableActions( baseURL, actionType, objectName ) ) {
            options.add( new Map<String, Object>{
                'label' => action.get( 'label' ),
                'value' => action.get( 'name' )
            });
        }

        return options;
    }

    /**
     * Get list of action inputs.
     * Used when user is configuring the target action to invoke.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param actionType
     *      Specific kind of action like Flows or Email Alerts.
     *      Value should match API value of Mass_Action_Configuration__c.Target_Type__c picklist entry.
     * @param actionName
     *      Specific action name whose inputs to retrieve like the Flow API name or Quick Action API name.
     * @param objectName
     *      Only required for certain action types like Quick Actions or Email Alerts.
     *      In the REST API, some actions are object specific and this indicates for which object to return their actions.
     */
    private static List<Map<String, Object>> getInvocableActionInputs( String baseURL, String actionType, String actionName, String objectName ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        if ( actionType == 'Workflow' ) {

            options.add( new Map<String, Object>{
                'label' => 'Record ID',
                'name' => 'ContextId',
                'dataType' => 'ID',
                'required' => true
            });

        } else {

            for ( Map<String, Object> input : MA_MassActionUtils.getInvocableActionInputs( baseURL, actionType, actionName, objectName ) ) {
                options.add( new Map<String, Object>{
                    'label' => input.get( 'label' ),
                    'name' => input.get( 'name' ),
                    'dataType' => String.valueOf( input.get( 'type' ) ).toUpperCase(),
                    'required' => Boolean.valueOf( input.get( 'required' ) ),
                    'description' => String.valueOf( input.get( 'description' ) )
                });
            }

        }

        return options;
    }

    // -----------------------------------------------------------------------------

    private static List<Map<String, Object>> getReportFolders() {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( Folder folder : [ SELECT id, name FROM Folder WHERE type = 'Report' AND developerName != null ORDER BY name ] ) {
            options.add( new Map<String, Object>{
                'label' => folder.name,
                'value' => String.valueOf( folder.id ).left( 15 )
            });
        }

        return options;
    }

    private static List<Map<String, Object>> getReportsByFolder( ID folderId ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( Report record : [ SELECT id, name FROM Report WHERE ownerId = :folderId AND format = 'Tabular' ORDER BY name ] ) {
            options.add( new Map<String, Object>{
                'label' => record.name,
                'value' => String.valueOf( record.id ).left( 15 )
            });
        }

        return options;
    }

    private static Report getReport( ID recordId ) {

        for ( Report record : [ SELECT id, name, ownerId, owner.name, folderName FROM Report WHERE id = :recordId LIMIT 1 ] ) {
            return record;
        }
        return null;
    }

    private static List<Map<String, Object>> getReportColumns( ID reportId ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        if ( String.isNotBlank( reportId ) ) {

            Reports.ReportExtendedMetadata metadata = Reports.ReportManager.describeReport( reportId ).getReportExtendedMetadata();
            Map<String, Reports.DetailColumn> reportColumnsMap = metadata.getDetailColumnInfo();

            for ( Reports.DetailColumn column : reportColumnsMap.values() ) {
                options.add( new Map<String, Object>{
                    'label' => column.getLabel(),
                    'value' => column.getName(),
                    'dataType' => String.valueOf( column.getDataType().name() ).toUpperCase()
                });
            }

        }

        return options;
    }

    // -----------------------------------------------------------------------------

    private static List<Map<String, Object>> getObjectNames() {

        Map<String, SObjectType> globalDescribeMap = Schema.getGlobalDescribe();

        List<ObjectNameWrapper> wrappers = new List<ObjectNameWrapper>();

        for ( String key : globalDescribeMap.keySet() ) {
            DescribeSObjectResult objDescribe = globalDescribeMap.get( key ).getDescribe();
            wrappers.add( new ObjectNameWrapper( objDescribe.getLabel(), objDescribe.getName() ) );
        }

        wrappers.sort();

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( ObjectNameWrapper wrapper : wrappers ) {
            options.add( new Map<String, Object>{
                'label' => String.format( '{0} ({1})', new String[] { wrapper.objectLabel, wrapper.objectName } ),
                'value' => wrapper.objectName
            });
        }

        return options;
    }

    private static List<Map<String, Object>> getListViewsByObject( String objectName ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( ListView record : [ SELECT id, name FROM ListView WHERE sobjectType = :objectName AND IsSoqlCompatible = true ORDER BY name ] ) {
            options.add( new Map<String, Object>{
                'label' => record.name,
                'value' => String.valueOf( record.id ).substring( 0, 15 )
            });
        }

        return options;
    }

    private static ListView getListView( ID recordId ) {

        for ( ListView record : [ SELECT id, name, sobjectType FROM ListView WHERE id = :recordId LIMIT 1 ] ) {
            return record;
        }
        return null;
    }

    /**
     * The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     * or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     */
    private static List<Map<String, Object>> getListViewColumns( String baseURL, ID listViewId ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        if ( String.isNotBlank( listViewId ) ) {

            MA_ListViewDescribeResult describeResult = MA_MassActionUtils.describeListView( baseURL, listViewId );

            for ( Map<String, Object> column : describeResult.columns ) {
                options.add( new Map<String, Object>{
                    'label' => column.get( 'label' ),
                    'value' => column.get( 'fieldNameOrPath' ),
                    'dataType' => String.valueOf( column.get( 'type' ) ).toUpperCase()
                });
            }

        }

        return options;
    }

    // -----------------------------------------------------------------------------

    private static List<Map<String, Object>> getNamedCredentials() {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        // exclude test credential, for unit tests only
        String whereClause = Test.isRunningTest() ? '' : ' WHERE developerName != \'Mass_Action_Test_Named_Credential\' ';

        String query =
            ' SELECT ' +
                ' id, masterLabel, developerName ' +
            ' FROM ' +
                ' NamedCredential ' +
            whereClause
        ;

        for ( NamedCredential credential : Database.query( query ) ) {
            options.add( new Map<String, Object>{
                'label' => credential.masterLabel,
                'value' => credential.developerName
            });
        }

        return options;
    }

    // -----------------------------------------------------------------------------

    private static MA_MassActionConfigWrapper getConfiguration( ID recordId ) {

        // return json without org's namespace so our code doesn't have to worry about it
        return new MA_MassActionConfigWrapper( MA_MassActionUtils.getConfiguration( recordId ) );
    }

    private static Map<String, Object> getConfigurationObjectDescribe() {

        String objectName = MA_MassActionUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';

        // https://salesforce.stackexchange.com/questions/218982/why-is-schema-describesobjectstypes-slower-than-schema-getglobaldescribe
        DescribeSObjectResult objectDescribe = ( (SObject) Type.forName( objectName ).newInstance() ).getSObjectType().getDescribe();

        Map<String, Object> describeMap = new Map<String, Object>{
            'name' => objectDescribe.getName(),
            'localName' => objectDescribe.getLocalName(),
            'label' => objectDescribe.getLabel(),
            'labelPlural' => objectDescribe.getLabelPlural(),
            'keyPrefix' => objectDescribe.getKeyPrefix(),
            'fields' => getFieldDescribeMaps( objectDescribe.fields.getMap() )
        };

        return describeMap;
    }

    /**
     * This method accepts the JSON serialization of the configuration and field mappings
     * because when defining the method params as the custom class type was getting internal server error.
     * I think possibly related to general serialization bugs with Lightning:
     * https://developer.salesforce.com/forums/?id=906F00000005GiwIAE
     * https://blog.texei.com/lightning-components-auraenabled-method-parameters-whats-working-and-what-s-not-83c351356104
     */
    private static Map<String, Object> saveConfiguration( String wrapperJson, String fieldMappingsJson ) {

        System.debug( 'MA_EditConfigRestController.saveConfiguration' );
        System.debug( wrapperJson );
        System.debug( fieldMappingsJson );

        Map<String, Object> result = new Map<String, Object>();

        SavePoint sp = Database.setSavepoint();

        try {

            MA_MassActionConfigWrapper wrapper = (MA_MassActionConfigWrapper) JSON.deserializeStrict( wrapperJson, MA_MassActionConfigWrapper.class );
            Map<String, String> fieldMappings = (Map<String, String>) JSON.deserializeStrict( fieldMappingsJson, Map<String, String>.class );

            System.debug( wrapper );
            System.debug( fieldMappings );

            Mass_Action_Configuration__c config = wrapper.toConfiguration();
            upsert config;

            delete [ SELECT Id FROM Mass_Action_Mapping__c WHERE Mass_Action_Configuration__c = :config.Id ];

            List<Mass_Action_Mapping__c> configMappings = new List<Mass_Action_Mapping__c>();
            for ( String targetFieldName : fieldMappings.keySet() ) {

                // if a target field is not required for the chosen action
                // then ignore it if there is no source field selected
                String sourceFieldName = fieldMappings.get( targetFieldName );

                if ( String.isNotBlank( sourceFieldName ) ) {
                    configMappings.add( new Mass_Action_Mapping__c(
                        Mass_Action_Configuration__c = config.Id,
                        Source_Field_Name__c = sourceFieldName,
                        Target_Field_Name__c = targetFieldName
                    ));
                }

            }

            insert configMappings;

            result.put( 'success', true );
            result.put( 'recordId', config.Id );

        } catch ( Exception e ) {

            Database.rollback( sp );

            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );

            throw e;

        }

        return result;
    }

    // -----------------------------------------------------------------------------

    private static Map<String, Map<String, Object>> getFieldDescribeMaps( Map<String, SObjectField> fieldsMap ) {

        Map<String, Map<String, Object>> describeMaps = new Map<String, Map<String, Object>>();

        for ( String fieldName : fieldsMap.keySet() ) {

            DescribeFieldResult fieldDescribe = fieldsMap.get( fieldName ).getDescribe();

            // using local name to stay namespace agnostic wherever this code runs
            describeMaps.put( fieldDescribe.getLocalName(), new Map<String, Object>{
                'name' => fieldDescribe.getName(),
                'localName' => fieldDescribe.getLocalName(),
                'label' => fieldDescribe.getLabel(),
                'helpText' => fieldDescribe.getInlineHelpText(),
                'picklistValues' => getPicklistValuesMaps( fieldDescribe.getPicklistValues() )
            });

        }

        return describeMaps;
    }

    private static List<Map<String, Object>> getPicklistValuesMaps( List<PicklistEntry> picklistEntries ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( PicklistEntry pke : picklistEntries ) {
            if ( pke.isActive() ) {
                options.add( new Map<String, Object>{
                    'label' => pke.getLabel(),
                    'value' => pke.getValue()
                });
            }
        }

        return options;
    }

    private class ObjectNameWrapper implements Comparable {

        private String objectLabel { get; set; }
        private String objectName { get; set; }

        public ObjectNameWrapper( String objectLabel, String objectName ) {
            this.objectLabel = objectLabel;
            this.objectName = objectName;
        }

        public Integer compareTo( Object other ) {

            ObjectNameWrapper thisWrapper = this;
            ObjectNameWrapper thatWrapper = (ObjectNameWrapper) other;

            Integer compareResult = ( thisWrapper.objectLabel.compareTo( thatWrapper.objectLabel ) );

            if ( compareResult == 0 ) {
                compareResult = ( thisWrapper.objectName.compareTo( thatWrapper.objectName ) );
            }

            return compareResult;
        }

    }

}
/*
BSD 3-Clause License

Copyright (c) 2018, Doug Ayers, douglascayers.com
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