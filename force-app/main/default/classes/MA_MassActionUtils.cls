/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/*
 * Most code coverage comes from MA_EditConfigCmpControllerTest
 */
public with sharing class MA_MassActionUtils {

    // -- private --

    private static final String MY_NAMESPACE = [ SELECT NamespacePrefix FROM ApexClass WHERE Name = 'MA_MassActionUtils' LIMIT 1 ].NamespacePrefix;

    // -- public --

    public static final String NAMESPACE = String.isBlank( MY_NAMESPACE ) ? '' : MY_NAMESPACE;
    public static final String NAMESPACE_API = String.isBlank( MY_NAMESPACE ) ? '' : MY_NAMESPACE + '__';

    public static final String EMPTY_STRING = '';

    public static final String REST_API_SERVICES_DATA_URL = Url.getOrgDomainUrl().toExternalForm() + '/services/data/v44.0';

    // ------------------------------------------------------------------------

    /**
     * Queries the config record and its related field mappings.
     * Returns null if no record is found.
     */
    public static Mass_Action_Configuration__c getConfiguration( ID recordId ) {

        Mass_Action_Configuration__c config = null;

        for ( Mass_Action_Configuration__c record : [
            SELECT
                Id,
                OwnerId,
                Name,
                DeveloperName__c,
                Named_Credential__c,
                Active__c,
                Batch_Size__c,
                Description__c,
                // source
                Source_Type__c,
                Source_Report_ID__c,
                Source_Report_Column_Name__c,
                Source_List_View_ID__c,
                // target
                Target_Type__c,
                Target_SObject_Type__c,
                Target_Action_Name__c,
                // schedule
                Schedule_Frequency__c,
                Schedule_Cron__c,
                Schedule_SecondOfMinute__c,
                Schedule_MinuteOfHour__c,
                Schedule_HourOfDay__c,
                Schedule_DayOfMonth__c,
                Schedule_MonthOfYear__c,
                Schedule_DayOfWeek__c,
                // system
                CreatedById,
                CreatedDate,
                LastModifiedById,
                LastModifiedDate,
                // mappings
                (
                    SELECT
                        Id,
                        Source_Field_Name__c,
                        Target_Field_Name__c
                    FROM
                        Mass_Action_Mappings__r
                    FOR REFERENCE
                )
            FROM
                Mass_Action_Configuration__c
            WHERE
                Id = :recordId
            FOR VIEW
        ]) {
            config = record;
        }

        return config;
    }

    /**
     * The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     * or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     */
    public static MA_ListViewDescribeResult describeListView( String baseURL, ID listViewId ) {

        ListView listView = [ SELECT id, sobjectType FROM ListView WHERE id = :listViewId LIMIT 1 ];

        String endpoint = String.format(
            '{0}/sobjects/{1}/listviews/{2}/describe',
            new String[] { baseURL, listView.sobjectType, listView.id }
        );

        HttpRequest req = new HttpRequest();
        req.setEndpoint( endpoint );
        req.setMethod( 'GET' );
        req.setTimeout( 120000 ); // max wait of 2 mins
        req.setCompressed( true );
        req.setHeader( 'Content-Type', 'application/json' );
        req.setHeader( 'Accepts', 'application/json' );
        req.setHeader( 'Authorization', 'Bearer ' + UserInfo.getSessionId() );

        HttpResponse res = sendHttpRequest( req );

        return (MA_ListViewDescribeResult) JSON.deserialize( res.getBody(), MA_ListViewDescribeResult.class );
    }

    // ------------------------------------------------------------------------

    /**
     * Given maps of source data whose keys match Mass_Action_Mapping__c.Source_Field_Name__c then
     * returns new maps whose keys match Mass_Action_Mapping__c.Target_Field_Name__c and whose values
     * match the source data. The returned maps will have as many keys as there are mappings.
     *
     * When considering a new source for Mass Action Service, then it is the source provider's
     * responsibility to transform its raw data format into source map format for reuse of this method.
     * For example, the report source and list view source classes handle their own transformations.
     */
    public static List<Map<String, Object>> buildActionInputs( List<Map<String, Object>> sourceRows, List<Mass_Action_Mapping__c> mappings ) {

        System.debug( 'MA_MassActionUtils.buildActionInputs' );
        System.debug( 'mappings: ' + mappings );
        System.debug( '----------' );

        List<Map<String, Object>> targetRows = new List<Map<String, Object>>();

        for ( Map<String, Object> sourceRow : sourceRows ) {

            Map<String, Object> targetRow = new Map<String, Object>();

            for ( Mass_Action_Mapping__c mapping : mappings ) {

                if ( !sourceRow.containsKey( mapping.source_field_name__c ) ) {
                    throw new MA_Exceptions.NoSourceFieldException( sourceRow, mapping.source_field_name__c );
                }

                targetRow.put( mapping.target_field_name__c, sourceRow.get( mapping.source_field_name__c ) );

            }

            System.debug( 'sourceRow: ' + sourceRow );
            System.debug( 'targetRow: ' + targetRow );
            System.debug( '----------' );

            targetRows.add( targetRow );

        }

        return targetRows;
    }

    // ------------------------------------------------------------------------

    /**
     * Invokes REST API via http callout.
     * https://developer.salesforce.com/docs/atlas.en-us.api_action.meta/api_action/actions_intro_invoking.htm
     */
    public static void invokeAction( String baseURL, Mass_Action_Configuration__c config, List<Map<String, Object>> targetRowMaps ) {

        System.debug( 'MA_MassActionUtils.invokeAction' );
        System.debug( 'config: ' + config );

        HttpRequest req = buildInvokeActionHttpRequest( baseURL, config, targetRowMaps );
        HttpResponse res = sendHttpRequest( req );

    }

    /**
     * Invokes REST API via http callout.
     * You call this method to get list of object names that can be used with getInvocableActions(..) method.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param actionType
     *      Value from picklist Mass_Action_Configuration__c.Target_Type__c (e.g. 'QuickAction', 'EmailAlert')
     */
    public static List<String> getObjectsWithInvocableActions( String baseURL, String actionType ) {

        System.debug( 'MA_MassActionUtils.getObjectsWithInvocableActions' );
        System.debug( 'baseURL: ' + baseURL );
        System.debug( 'actionType: ' + actionType );

        HttpRequest req = buildInvocableActionsHttpRequest( baseURL, actionType, EMPTY_STRING );
        HttpResponse res = sendHttpRequest( req );

        List<String> objectNames = parseActionObjectsHttpResponse( res );

        return objectNames;
    }

    /**
     * Invokes REST API via http callout.
     * You call this method to get list of available actions for given type and object.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param actionType
     *      Value from picklist Mass_Action_Configuration__c.Target_Type__c (e.g. 'QuickAction', 'EmailAlert')
     * @param objectName
     *      API name of object whose actions to get of the given type (e.g. 'Account', 'Foo__c')
     */
    public static List<Map<String, Object>> getInvocableActions( String baseURL, String actionType, String objectName ) {

        System.debug( 'MA_MassActionUtils.getInvocableActions' );
        System.debug( 'baseURL: ' + baseURL );
        System.debug( 'actionType: ' + actionType );
        System.debug( 'objectName: ' + objectName );

        HttpRequest req = buildInvocableActionsHttpRequest( baseURL, actionType, objectName );
        HttpResponse res = sendHttpRequest( req );

        List<Map<String, Object>> actions = parseActionsHttpResponse( res );

        return actions;
    }

    /**
     * Gets the input variables for the given invocable action.
     * Use this to know what to prompt user for when binding source fields to target fields.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param actionType
     *      Value from picklist Mass_Action_Configuration__c.Target_Type__c (e.g. 'QuickAction', 'EmailAlert')
     * @param actionName
     *      API Name of the invocable action whose inputs to request.
     * @param objectName
     *      API Name of the object whose action to request.
     */
    public static List<Map<String, Object>> getInvocableActionInputs( String baseURL, String actionType, String actionName, String objectName ) {

        System.debug( 'MA_MassActionUtils.getInvocableActionInputs' );
        System.debug( 'baseURL: ' + baseURL );
        System.debug( 'actionType: ' + actionType );
        System.debug( 'actionName: ' + actionName );
        System.debug( 'objectName: ' + objectName );

        HttpRequest req = buildInvocableActionInputsHttpRequest( baseURL, actionType, actionName, objectName );
        HttpResponse res = sendHttpRequest( req );

        List<Map<String, Object>> inputs = parseActionInputsHttpResponse( res );

        return inputs;
    }

    // ------------------------------------------------------------------------

    /**
     * Creates an HttpRequest with a configured enpoint to invoke the target action
     * per the configuration. Also sets common headers for an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param config
     *      Mass Action Configuration record.
     * @param targetRowMaps
     *      Field mappings from the data source (e.g. list view or report) and
     *      inputs to the target action (e.g. quick action, apex, process, etc.).
     */
    private static HttpRequest buildInvokeActionHttpRequest( String baseURL, Mass_Action_Configuration__c config, List<Map<String, Object>> targetRowMaps ) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint( getInvokeActionHttpRequestEndpoint( baseURL, config ) );
        req.setBody( getInvokeActionHttpRequestBody( config, targetRowMaps ) );
        req.setMethod( 'POST' );
        req.setTimeout( 120000 ); // max wait of 2 mins
        req.setCompressed( true );
        req.setHeader( 'Content-Type', 'application/json' );
        req.setHeader( 'Accepts', 'application/json' );
        req.setHeader( 'Authorization', 'Bearer ' + UserInfo.getSessionId() );

        return req;
    }

    /**
     * Creates an endpoint URL to REST API to invoke the target action per the configuration.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param config
     *      Mass Action Configuration record.
     */
    private static String getInvokeActionHttpRequestEndpoint( String baseURL, Mass_Action_Configuration__c config ) {

        String endpoint = null;

        if ( 'Workflow' == config.target_type__c ) {

            endpoint = String.format(
                '{0}/process/rules',
                new String[] { baseURL }
            );

        } else if ( 'Flow' == config.target_type__c ) {

            endpoint = String.format(
                '{0}/actions/custom/flow/{1}',
                new String[] { baseURL, config.target_action_name__c }
            );

        } else if ( 'QuickAction' == config.target_type__c ) {

            endpoint = String.format(
                '{0}/actions/custom/quickAction/{1}/{2}',
                new String[] { baseURL, config.target_sobject_type__c, config.target_action_name__c }
            );

        } else if ( 'EmailAlert' == config.target_type__c ) {

            endpoint = String.format(
                '{0}/actions/custom/emailAlert/{1}/{2}',
                new String[] { baseURL, config.target_sobject_type__c, config.target_action_name__c }
            );

        } else if ( 'Apex' == config.target_type__c ) {

            endpoint = String.format(
                '{0}/actions/custom/apex/{1}',
                new String[] { baseURL, config.target_action_name__c }
            );

        }

        return endpoint;
    }

    private static String getInvokeActionHttpRequestBody( Mass_Action_Configuration__c config, List<Map<String, Object>> targetRowMaps ) {

        Set<String> processRulesAPI = new Set<String> {
            'Workflow'
        };

        Set<String> actionsAPI = new Set<String> {
            'Flow',
            'QuickAction',
            'EmailAlert',
            'Apex'
        };

        String body = null;

        if ( processRulesAPI.contains( config.target_type__c ) ) {

            body = getInvokeActionHttpRequestBody_ProcessRules( targetRowMaps );

        } else if ( actionsAPI.contains( config.target_type__c ) ) {

            body = getInvokeActionHttpRequestBody_Actions( targetRowMaps );

        }

        return body;
    }

    /**
     * Builds up the JSON request body for the REST Process Rules API.
     * This includes references under '/services/data/<version>/process/rules'
     * Like Workflow Rules.
     *
     * https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_process_rules_trigger.htm
     */
    private static String getInvokeActionHttpRequestBody_ProcessRules( List<Map<String, Object>> targetRowMaps ) {

        Set<ID> contextIds = new Set<ID>();

        // In all seriousness, for workflow actions then only
        // one mapping should exist with target field name of 'ContextId'.
        // Just in case I ever change that key name then just going to iterate
        // all keys in the map and add to our set.
        // But there should only be one key in the map regardless.
        for ( Map<String, Object> targetRow : targetRowMaps ) {
            for ( String key : targetRow.keySet() ) {
                contextIds.add( ID.valueOf( String.valueOf( targetRow.get( key ) ) ) );
            }
        }

        Map<String, Object> inputsRequest = new Map<String, Object>{
            'contextIds' => contextIds
        };

        return JSON.serializePretty( inputsRequest );
    }

    /**
     * Builds up the JSON request body for the REST Actions API.
     * This includes references under '/services/data/<version>/actions'
     * like Process Builder, Flows, Quick Actions, Email Alerts, and Invocable Apex.
     *
     * https://developer.salesforce.com/docs/atlas.en-us.api_action.meta/api_action/actions_intro_invoking.htm
     */
    private static String getInvokeActionHttpRequestBody_Actions( List<Map<String, Object>> targetRowMaps ) {

        Map<String, Object> inputsRequest = new Map<String, Object>{
            'inputs' => targetRowMaps
        };

        return JSON.serializePretty( inputsRequest );
    }

    // ------------------------------------------------------------------------

    /**
     * Creates an HttpRequest with a configured enpoint to retrieve invocable actions
     * for the given object accessible by the REST API. Also sets common headers for
     * an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param actionType
     *      Value from picklist Mass_Action_Configuration__c.Target_Type__c (e.g. 'QuickAction', 'EmailAlert')
     * @param objectName
     *      API Name of the object whose actions to request.
     */
    private static HttpRequest buildInvocableActionsHttpRequest( String baseURL, String actionType, String objectName ) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint( getInvocableActionsHttpRequestEndpoint( baseURL, actionType, objectName ) );
        req.setMethod( 'GET' );
        req.setTimeout( 120000 ); // max wait of 2 mins
        req.setCompressed( true );
        req.setHeader( 'Content-Type', 'application/json' );
        req.setHeader( 'Accepts', 'application/json' );
        req.setHeader( 'Authorization', 'Bearer ' + UserInfo.getSessionId() );

        return req;
    }

    /**
     * Creates an endpoint URL to retrieve invocable actions for the given object
     * accessible by the REST API. Also sets common headers for an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param actionType
     *      Value from picklist Mass_Action_Configuration__c.Target_Type__c (e.g. 'QuickAction', 'EmailAlert')
     * @param objectName
     *      API Name of the object whose actions to request.
     */
    private static String getInvocableActionsHttpRequestEndpoint( String baseURL, String actionType, String objectName ) {

        String endpoint = null;

        if ( 'Flow' == actionType ) {

            endpoint = String.format(
                '{0}/actions/custom/flow',
                new String[] { baseURL }
            );

        } else if ( 'QuickAction' == actionType ) {

            endpoint = String.format(
                '{0}/actions/custom/quickAction/{1}',
                new String[] { baseURL, objectName }
            );

        } else if ( 'EmailAlert' == actionType ) {

            endpoint = String.format(
                '{0}/actions/custom/emailAlert/{1}',
                new String[] { baseURL, objectName }
            );

        } else if ( 'Apex' == actionType ) {

            endpoint = String.format(
                '{0}/actions/custom/apex',
                new String[] { baseURL }
            );

        }

        return endpoint;
    }

    // ------------------------------------------------------------------------

    /**
     * Creates an HttpRequest with a configured enpoint to retrieve inputs for an invocable action
     * for the given object accessible by the REST API. Also sets common headers for an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param actionType
     *      Value from picklist Mass_Action_Configuration__c.Target_Type__c (e.g. 'QuickAction', 'EmailAlert')
     * @param actionName
     *      API Name of the invocable action whose inputs to request.
     * @param objectName
     *      API Name of the object whose action to request.
     */
    private static HttpRequest buildInvocableActionInputsHttpRequest( String baseURL, String actionType, String actionName, String objectName ) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint( getInvocableActionInputsHttpRequestEndpoint( baseURL, actionType, actionName, objectName ) );
        req.setMethod( 'GET' );
        req.setTimeout( 120000 ); // max wait of 2 mins
        req.setCompressed( true );
        req.setHeader( 'Content-Type', 'application/json' );
        req.setHeader( 'Accepts', 'application/json' );
        req.setHeader( 'Authorization', 'Bearer ' + UserInfo.getSessionId() );

        return req;
    }

    /**
     * Creates an endpoint URL to retrieve inputs for an invocable action
     * for the given object accessible by the REST API. Also sets common headers for an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the full path, to REST API (e.g. 'https://yourdomain.my.salesforce.com/services/data/v44.0').
     * @param actionType
     *      Value from picklist Mass_Action_Configuration__c.Target_Type__c (e.g. 'QuickAction', 'EmailAlert')
     * @param actionName
     *      API Name of the invocable action whose inputs to request.
     * @param objectName
     *      API Name of the object whose action to request.
     */
    private static String getInvocableActionInputsHttpRequestEndpoint( String baseURL, String actionType, String actionName, String objectName ) {

        String endpoint = null;

        if ( 'Flow' == actionType ) {

            endpoint = String.format(
                '{0}/actions/custom/flow/{1}',
                new String[] { baseURL, actionName }
            );

        } else if ( 'QuickAction' == actionType ) {

            endpoint = String.format(
                '{0}/actions/custom/quickAction/{1}/{2}',
                new String[] { baseURL, objectName, actionName }
            );

        } else if ( 'EmailAlert' == actionType ) {

            endpoint = String.format(
                '{0}/actions/custom/emailAlert/{1}/{2}',
                new String[] { baseURL, objectName, actionName }
            );

        } else if ( 'Apex' == actionType ) {

            endpoint = String.format(
                '{0}/actions/custom/apex/{1}',
                new String[] { baseURL, actionName }
            );

        }

        return endpoint;
    }

    // ------------------------------------------------------------------------

    /**
     * Sends the http request and returns the http response.
     * Logs the request/response.
     * Throws exception if status code is not 200 OK.
     */
    private static HttpResponse sendHttpRequest( HttpRequest req ) {

        System.debug( req );
        System.debug( req.getBody() );

        HttpResponse res = new Http().send( req );

        System.debug( res );
        System.debug( res.getBody() );

        for ( String header : res.getHeaderKeys() ) {
            System.debug( header + '=' + res.getHeader( header ) );
        }

        if ( res.getStatusCode() != 200 ) {
            throw new MA_Exceptions.InvokeActionException( req, res );
        }

        return res;
    }

    // ------------------------------------------------------------------------

    /**
     * JSON deserializes the response and converts the map of key-value pairs into a list of keys.
     */
    private static List<String> parseActionObjectsHttpResponse( HttpResponse res ) {

        List<String> objectNames = new List<String>();

        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.getBody() );

        for ( String objectName : resMap.keySet() ) {
            objectNames.add( objectName );
        }

        return objectNames;
    }

    /**
     * JSON deserializes the 'actions' property of the response.
     */
    private static List<Map<String, Object>> parseActionsHttpResponse( HttpResponse res ) {

        List<Map<String, Object>> actions = new List<Map<String, Object>>();

        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.getBody() );

        List<Object> actionRecords = (List<Object>) resMap.get( 'actions' );

        for ( Object actionRecord : actionRecords ) {
            actions.add( (Map<String, Object>) actionRecord );
        }

        return actions;
    }

    /**
     * JSON deserializes the 'inputs' property of the response.
     */
    private static List<Map<String, Object>> parseActionInputsHttpResponse( HttpResponse res ) {

        List<Map<String, Object>> inputs = new List<Map<String, Object>>();

        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.getBody() );

        List<Object> inputRecords = (List<Object>) resMap.get( 'inputs' );

        for ( Object inputRecord : inputRecords ) {
            inputs.add( (Map<String, Object>) inputRecord );
        }

        return inputs;
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