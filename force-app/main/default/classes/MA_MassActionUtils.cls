/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/*
 * Most code coverage comes from MA_EditConfigRestControllerTest
 */
public inherited sharing class MA_MassActionUtils {

    public static final String ORG_DOMAIN_URL = URL.getOrgDomainUrl().toExternalForm();
    public static final String REST_API_PATH = '/services/data/v47.0'; // note the 'v' prefix on the version number
    public static final String SOAP_API_PATH = '/services/Soap/s/47.0'; // note no 'v' prefix on the version number

    public static final String REST_API_SERVICES_URL = ORG_DOMAIN_URL + REST_API_PATH;
    public static final String SOAP_API_SERVICES_URL = ORG_DOMAIN_URL + SOAP_API_PATH;

    // ------------------------------------------------------------------------

    /**
     * Returns the base URL for use with invoking the Salesforce APIs.
     *
     * @param namedCredential
     *      (optional) Name of a Named Credential to use, without the 'callout:' prefix.
     *      If blank then the org's domain URL is used instead.
     *
     * @return URL for use with Salesforce REST API (e.g. https://yourinstance.my.salesforce.com or callout:YourNamedCredential)
     *  with the path '/services/data/v47.0' appended to it.
     */
    public static String getCalloutRestEndpointURL( String namedCredential ) {
        String url;
        if ( String.isBlank( namedCredential ) ) {
            url = REST_API_SERVICES_URL;
        } else {
            url = 'callout:' + namedCredential + REST_API_PATH;
        }
        return url;
    }

    public static String getCalloutSoapEndpointURL( String namedCredential ) {
        String url;
        if ( String.isBlank( namedCredential ) ) {
            url = SOAP_API_SERVICES_URL;
        } else {
            url = 'callout:' + namedCredential + SOAP_API_PATH;
        }
        return url;
    }

    // ------------------------------------------------------------------------

    /**
     * Queries the config record and its related field mappings.
     * Returns null if no record is found.
     */
    public static Mass_Action_Configuration__c getConfiguration( ID recordId ) {

        System.debug( 'MA_MassActionUtils.getConfiguration: recordId=' + recordId );

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
                Source_SOQL_Query__c,
                Source_Apex_Class__c,
                // target
                Target_Type__c,
                Target_SObject_Type__c,
                Target_Action_Name__c,
                Target_Apex_Script__c,
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
     * This method accepts the JSON serialization of the configuration and field mappings
     * because when defining the method params as the custom class type was getting internal server error.
     * I think possibly related to general serialization bugs with Lightning:
     * https://developer.salesforce.com/forums/?id=906F00000005GiwIAE
     * https://blog.texei.com/lightning-components-auraenabled-method-parameters-whats-working-and-what-s-not-83c351356104
     */
    public static Map<String, Object> saveConfiguration( String wrapperJson, String fieldMappingsJson ) {

        System.debug( 'MA_MassActionUtils.saveConfiguration: wrapperJson=\n' + wrapperJson );
        System.debug( 'MA_MassActionUtils.saveConfiguration: fieldMappingsJson=\n' + fieldMappingsJson );

        Map<String, Object> result = new Map<String, Object>();

        MA_MassActionConfigWrapper wrapper = (MA_MassActionConfigWrapper) JSON.deserializeStrict( wrapperJson, MA_MassActionConfigWrapper.class );
        Map<String, String> fieldMappings = (Map<String, String>) JSON.deserializeStrict( fieldMappingsJson, Map<String, String>.class );

        System.debug( 'MA_MassActionUtils.saveConfiguration: wrapper=\n' + wrapper );
        System.debug( 'MA_MassActionUtils.saveConfiguration: fieldMappings=\n' + fieldMappings );

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

        return result;
    }

    // ------------------------------------------------------------------------

    /**
     * The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     * or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
     */
    public static MA_ListViewDescribeResult describeListView( String baseURL, ID listViewId ) {

        System.debug( 'MA_MassActionUtils.describeListView' );
        System.debug( 'baseURL: ' + baseURL );
        System.debug( 'listViewId: ' + listViewId );

        List<ListView> listViews = new List<ListView>([ SELECT id, sobjectType FROM ListView WHERE id = :listViewId LIMIT 1 ]);
        if ( listViews.isEmpty() ) {
            // provide a more helpful message than the default
            // System.QueryException: List has no rows for assignment to SObject
            throw MA_Exceptions.buildException( NoDataFoundException.class, 'No List View found for id: ' + listViewId + '. Ensure the list view exists and is shared to the running user ' + UserInfo.getUserName() );
        }

        ListView lv = listViews[0];

        String endpoint = String.format(
            '{0}/sobjects/{1}/listviews/{2}/describe',
            new String[] { baseURL, lv.sobjectType, lv.id }
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

            Map<String, Object> sourceRowLowerCaseKeyMap = MA_MapUtils.convertKeysToLowercase( sourceRow );

            Map<String, Object> targetRow = new Map<String, Object>();

            for ( Mass_Action_Mapping__c mapping : mappings ) {

                if ( !sourceRowLowerCaseKeyMap.containsKey( mapping.Source_Field_Name__c.toLowerCase() ) ) {
                    throw new MA_Exceptions.NoSourceFieldException( sourceRow, mapping.Source_Field_Name__c );
                }

                targetRow.put( mapping.target_field_name__c, sourceRowLowerCaseKeyMap.get( mapping.Source_Field_Name__c.toLowerCase() ) );

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
     * Designed as a simple way to invoke a configured target action with a given batch of source records.
     * Based on the config's target action and other properties, the appropriate API call will be invoked.
     *
     * Originally designed as an easy way for batch classes to invoke an action from their `execute` methods
     * with a batch of source records. This keeps logic out of the batch classes for knowing "how" to invoke the actions.
     *
     * @param config
     *      Mass Action Configuration record.
     * @param sourceRowMaps
     *      Batch of source records to pass as inputs to the target action.
     */
    public static void invokeTargetAction( Mass_Action_Configuration__c config, List<Map<String, Object>> sourceRowMaps ) {

        if ( config.Target_Type__c == 'Apex' && String.isNotBlank( config.Target_Apex_Script__c ) ) {

            String baseUrl = MA_MassActionUtils.getCalloutSoapEndpointURL( config.Named_Credential__c );
            MA_MassActionUtils.invokeExecuteAnonymous( baseUrl, config, sourceRowMaps );

        } else {

            List<Map<String, Object>> targetRowMaps = MA_MassActionUtils.buildActionInputs( sourceRowMaps, config.Mass_Action_Mappings__r );

            String baseUrl = MA_MassActionUtils.getCalloutRestEndpointURL( config.Named_Credential__c );
            MA_MassActionUtils.invokeAction( baseUrl, config, targetRowMaps );

        }

    }

    /**
     * Invokes Apex SOAP API via http callout.
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_api.htm
     */
    public static void invokeExecuteAnonymous( String baseURL, Mass_Action_Configuration__c config, List<Map<String, Object>> sourceRowMaps ) {

        System.debug( 'MA_MassActionUtils.invokeExecuteAnonymous' );
        System.debug( 'config: ' + config );

        // Executing an anonymous apex block does not accept other input parameters,
        // such as variable values to work with as you can do when invoking the Actions API.
        // Therefore, to provide some semblance of an interface to easily provide data
        // to the anonymous block while supporting the developers to just write code on-the-fly,
        // we prepend to the developer's script our own code that inlines the JSON of the source
        // data then calls an anonymous method named `execute` with a list of maps of source records.
        // In this manner, the developer's anonymous script simply needs to define a method
        // `execute( List<Map<String, Object>> sourceRecordsBatch )`
        // and that is the hook to receive the source records for processing.

        String sourceRowMapsJson = JSON.serialize( sourceRowMaps );

        String apexScript = (
            ' void mas_initApexBlock() { ' +
                ' List<Object> untypedRecords = (List<Object>) JSON.deserializeUntyped( \'' + String.escapeSingleQuotes( sourceRowMapsJson ) + '\' ); ' +
                ' List<Map<String, Object>> typedRecords = new List<Map<String, Object>>(); ' +
                ' for ( Object untypedRecord : untypedRecords ) { ' +
                    ' typedRecords.add( (Map<String, Object>) untypedRecord ); ' +
                ' } ' +
                ' execute( typedRecords ); ' +
            ' } ' +
            ' mas_initApexBlock(); ' +
            config.Target_Apex_Script__c
        );

        try {

            HttpRequest req = buildExecuteAnonymousHttpRequest( baseUrl, apexScript );
            HttpResponse res = sendHttpRequest( req );

            MA_AnonymousApexExecuteResult result = parseAnonymousApexHttpResponse( res );

            // if there was an error compiling or executing the script, the http response will still be OK 200
            // so we need to actually inspect the response body to see if something is wrong
            if ( result.success == false ) {
                throw new MA_Exceptions.AnonymousApexException(
                    req, res, result.compileProblem, result.exceptionMessage, result.exceptionStackTrace
                );
            }

        } catch ( MA_Exceptions.InvokeActionException e ) {

            Exception throwable = e;

            try {

                String responseString = e.response.getBody();
                DOM.Document responseDocument = e.response.getBodyDocument();
                DOM.XMLNode root = responseDocument.getRootElement();

                if ( responseString.containsIgnoreCase( '<soapenv:Fault>' ) ) {

                    String faultCode = MA_XMLUtils.getChildNodeTextByPath( root, '/Body/Fault/faultcode' );
                    String faultString = MA_XMLUtils.getChildNodeTextByPath( root, '/Body/Fault/faultstring' );

                    throwable = new MA_Exceptions.AnonymousApexException(
                        e.request, e.response, null, faultString, faultCode, e
                    );

                }

            } catch ( Exception ex ) {

                // do nothing

            }

            throw throwable;

        }

    }

    /**
     * Invokes REST API via http callout.
     * https://developer.salesforce.com/docs/atlas.en-us.api_action.meta/api_action/actions_intro_invoking.htm
     */
    public static void invokeAction( String baseURL, Mass_Action_Configuration__c config, List<Map<String, Object>> targetRowMaps ) {

        System.debug( 'MA_MassActionUtils.invokeAction' );
        System.debug( 'baseURL: ' + baseURL );
        System.debug( 'config: ' + config );

        HttpRequest req = buildInvokeActionHttpRequest( baseURL, config, targetRowMaps );
        HttpResponse res = sendHttpRequest( req );

    }

    // ------------------------------------------------------------------------

    /**
     * Invokes REST API via http callout.
     * You call this method to get list of object names that can be used with getInvocableActions(..) method.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
     * @param actionType
     *      Value from picklist Mass_Action_Configuration__c.Target_Type__c (e.g. 'QuickAction', 'EmailAlert')
     */
    public static List<String> getObjectsWithInvocableActions( String baseURL, String actionType ) {

        System.debug( 'MA_MassActionUtils.getObjectsWithInvocableActions' );
        System.debug( 'baseURL: ' + baseURL );
        System.debug( 'actionType: ' + actionType );

        HttpRequest req = buildInvocableActionsHttpRequest( baseURL, actionType, '' );
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
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
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
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
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
     * Creates an HttpRequest with a configured enpoint to invoke the Apex SOAP API
     * to execute anonymous Apex. Also sets common headers for an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com'),
     *      with the SOAP API path suffix of '/services/Soap/s/47.0'.
     * @param apexScript
     *      The anonymous apex script to execute. This method URL encodes the string.
     */
    private static HttpRequest buildExecuteAnonymousHttpRequest( String baseURL, String apexScript ) {

        System.debug( 'MA_MassActionUtils.buildExecuteAnonymousHttpRequest' );
        System.debug( 'baseURL: ' + baseURL );
        System.debug( 'apexScript: ' + apexScript );

        Boolean usesNamedCredential = ( baseURL.startsWithIgnoreCase( 'callout:' ) );
        String sessionId = ( usesNamedCredential ? '{!$Credential.OAuthToken}' : UserInfo.getSessionId() );

        String envelopeHeader =
            ' <soapenv:Envelope ' +
                ' xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                ' xmlns:meta="http://soap.sforce.com/2006/04/metadata" ' +
                ' xmlns:apex="http://soap.sforce.com/2006/08/apex" ' +
                ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> ';

        String soapHeader =
            ' <soapenv:Header> ' +
                ' <apex:SessionHeader> ' +
                    ' <apex:sessionId>' + sessionId + '</apex:sessionId> ' +
                ' </apex:SessionHeader> ' +
            ' </soapenv:Header> ';

        String soapBody =
            ' <soapenv:Body> ' +
                ' <apex:executeAnonymous> ' +
                    ' <apex:String> ' + apexScript.escapeXml() + ' </apex:String> ' +
                ' </apex:executeAnonymous> ' +
            ' </soapenv:Body> ';

        String envelopeFooter =
            ' </soapenv:Envelope> ';

        String soapMessage = (
            envelopeHeader +
            soapHeader +
            soapBody +
            envelopeFooter
        );

        HttpRequest req = new HttpRequest();
        req.setEndpoint( baseURL );
        req.setMethod( 'POST' );
        req.setHeader( 'SOAPAction', 'executeAnonymous' );
        req.setTimeout( 120000 ); // max wait of 2 mins
        req.setCompressed( true );
        req.setHeader( 'Content-Type', 'text/xml' );
        req.setHeader( 'Accepts', 'text/xml' );
        req.setHeader( 'Authorization', 'Bearer ' + UserInfo.getSessionId() );
        req.setBody( soapMessage );

        return req;
    }

    // ------------------------------------------------------------------------

    /**
     * Creates an HttpRequest with a configured enpoint to invoke the target action
     * per the configuration. Also sets common headers for an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
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
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
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
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
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
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
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
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
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
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
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
     * Executes a SOQL query via REST API via http callout.
     * https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_query.htm
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
     * @param query
     *      SOQL query to execute.
     * @param batchSize
     *      The preferred max number of records to return at a time.
     *      Choose a value between 200 and 2,000.
     *      If there are more records than requested, you'll need to use the nextRecordsUrl to retrieve them.
     *      https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/headers_queryoptions.htm
     */
    public static MA_SoqlQueryExecuteResult executeSoqlQuery( String baseURL, String query, Integer batchSize ) {

        System.debug( 'MA_MassActionUtils.executeSoqlQuery' );
        System.debug( 'baseURL: ' + baseURL );
        System.debug( 'query: ' + query );
        System.debug( 'batchSize: ' + batchSize );

        try {

            HttpRequest req = buildExecuteSoqlQueryHttpRequest( baseURL, query, batchSize );
            HttpResponse res = sendHttpRequest( req );

            return parseSoqlQueryHttpResponse( res );

        } catch ( MA_Exceptions.InvokeActionException e ) {

            Exception throwable = e;

            // extract the soql error message from "[ { errorCode: xxx, message: yyy } ]"
            List<Object> errors = (List<Object>) JSON.deserializeUntyped( e.response.getBody() );
            for ( Object item : errors ) {
                Map<String, Object> err = (Map<String, Object>) item;
                throwable = new MA_Exceptions.SOQLQueryException(
                    e.request, e.response, query, (String) err.get( 'errorType' ), (String) err.get( 'message' ), e
                );
            }

            throw throwable;

        }
    }

    /**
     * Creates an HttpRequest with a configured enpoint to execute a SOQL query
     * against the REST API. Also sets common headers for an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
     * @param query
     *      SOQL query to execute.
     * @param batchSize
     *      The preferred max number of records to return at a time.
     *      Choose a value between 200 and 2,000.
     *      If there are more records than requested, you'll need to use the nextRecordsUrl to retrieve them.
     *      https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/headers_queryoptions.htm
     */
    private static HttpRequest buildExecuteSoqlQueryHttpRequest( String baseURL, String query, Integer batchSize ) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint( getExecuteSoqlQueryHttpRequestEndpoint( baseURL, query ) );
        req.setMethod( 'GET' );
        req.setTimeout( 120000 ); // max wait of 2 mins
        req.setCompressed( true );
        req.setHeader( 'Content-Type', 'application/json' );
        req.setHeader( 'Accepts', 'application/json' );
        req.setHeader( 'Authorization', 'Bearer ' + UserInfo.getSessionId() );

        if ( batchSize != null ) {
            req.setHeader( 'Sforce-Query-Options', 'batchSize=' + batchSize );
        }

        return req;
    }

    /**
     * Creates an endpoint URL to execute a SOQL query against the REST API.
     * Also sets common headers for an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
     * @param query
     *      SOQL query to execute.
     */
    private static String getExecuteSoqlQueryHttpRequestEndpoint( String baseURL, String query ) {

        String endpoint = String.format(
            '{0}/query/?q={1}',
            new String[] { baseURL, EncodingUtil.urlEncode( query, 'utf-8' ) }
        );

        return endpoint;
    }

    // ------------------------------------------------------------------------

    /**
     * Executes a SOQL query via REST API via http callout.
     * https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/dome_query.htm
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
     * @param nextRecordsId
     *      The last path part in the 'nextRecordsUrl' property from a query response
     *      that identifies the next page of records to return.
     * @param batchSize
     *      The preferred max number of records to return at a time.
     *      Choose a value between 200 and 2,000.
     *      If there are more records than requested, you'll need to use the nextRecordsUrl to retrieve them.
     *      https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/headers_queryoptions.htm
     */
    public static MA_SoqlQueryExecuteResult executeSoqlQueryNextRecords( String baseURL, String nextRecordsId, Integer batchSize ) {

        System.debug( 'MA_MassActionUtils.executeSoqlQueryNextRecords' );
        System.debug( 'baseURL: ' + baseURL );
        System.debug( 'nextRecordsId: ' + nextRecordsId );
        System.debug( 'batchSize: ' + batchSize );

        try {

            HttpRequest req = buildExecuteSoqlQueryNextRecordsHttpRequest( baseURL, nextRecordsId, batchSize );
            HttpResponse res = sendHttpRequest( req );

            return parseSoqlQueryHttpResponse( res );

        } catch ( MA_Exceptions.InvokeActionException e ) {

            Exception throwable = e;

            // extract the soql error message from "[ { errorCode: xxx, message: yyy } ]"
            List<Object> errors = (List<Object>) JSON.deserializeUntyped( e.response.getBody() );
            for ( Object item : errors ) {
                Map<String, Object> err = (Map<String, Object>) item;
                throwable = new MA_Exceptions.SOQLQueryException(
                    e.request, e.response, nextRecordsId, (String) err.get( 'errorType' ), (String) err.get( 'message' ), e
                );
            }

            throw throwable;

        }
    }

    /**
     * Creates an HttpRequest with a configured enpoint to execute a SOQL query
     * against the REST API. Also sets common headers for an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
     * @param nextRecordsId
     *      The last path part in the 'nextRecordsUrl' property from a query response
     *      that identifies the next page of records to return.
     * @param batchSize
     *      The preferred max number of records to return at a time.
     *      Choose a value between 200 and 2,000.
     *      If there are more records than requested, you'll need to use the nextRecordsUrl to retrieve them.
     *      https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/headers_queryoptions.htm
     */
    private static HttpRequest buildExecuteSoqlQueryNextRecordsHttpRequest( String baseURL, String nextRecordsId, Integer batchSize ) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint( getExecuteSoqlQueryNextRecordsHttpRequestEndpoint( baseURL, nextRecordsId ) );
        req.setMethod( 'GET' );
        req.setTimeout( 120000 ); // max wait of 2 mins
        req.setCompressed( true );
        req.setHeader( 'Content-Type', 'application/json' );
        req.setHeader( 'Accepts', 'application/json' );
        req.setHeader( 'Authorization', 'Bearer ' + UserInfo.getSessionId() );

        if ( batchSize != null ) {
            req.setHeader( 'Sforce-Query-Options', 'batchSize=' + batchSize );
        }

        return req;
    }

    /**
     * Creates an endpoint URL to execute a SOQL query against the REST API.
     * Also sets common headers for an authorized JSON request.
     *
     * @param baseURL
     *      The 'baseURL' parameter can either be a Named Credential (e.g. 'callout:YourNC'),
     *      or the org's My Domain URL without any path (e.g. 'https://yourdomain.my.salesforce.com').
     * @param nextRecordsId
     *      The last path part in the 'nextRecordsUrl' property from a query response
     *      that identifies the next page of records to return.
     */
    private static String getExecuteSoqlQueryNextRecordsHttpRequestEndpoint( String baseURL, String nextRecordsId ) {

        String endpoint = String.format(
            '{0}/query/{1}',
            new String[] { baseURL, EncodingUtil.urlEncode( nextRecordsId, 'utf-8' ) }
        );

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
     * JSON deserializes the response.
     *
     * Since Apex won't deserialize into a type that uses generic Object data type,
     * then I'm manually casting the untyped deserialization result to my generic map type.
     * This way, my Apex class that represents a SOQL query result can generically store
     * a list of records as objects (not sobjects, because some results may be aggregate results).
     *
     * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_json_overview.htm
     */
    private static MA_SoqlQueryExecuteResult parseSoqlQueryHttpResponse( HttpResponse res ) {

        Map<String, Object> responseMap = ( Map<String, Object> ) JSON.deserializeUntyped( res.getBody() );

        MA_SoqlQueryExecuteResult result = new MA_SoqlQueryExecuteResult();
        result.totalSize = (Integer) responseMap.get( 'totalSize' );
        result.done = (Boolean) responseMap.get( 'done' );
        result.nextRecordsUrl = (String) responseMap.get( 'nextRecordsUrl' );

        for ( Object item : (List<Object>) responseMap.get( 'records' ) ) {
            result.records.add( (Map<String, Object>) item );
        }

        return result;
    }

    /**
     * JSON deserializes the response and converts the map of key-value pairs into a list of keys.
     */
    private static List<String> parseActionObjectsHttpResponse( HttpResponse res ) {

        List<String> objectNames = new List<String>();

        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.getBody() );

        if ( resMap != null ) {

            for ( String objectName : resMap.keySet() ) {
                objectNames.add( objectName );
            }

        }

        return objectNames;
    }

    /**
     * JSON deserializes the 'actions' property of the response.
     */
    private static List<Map<String, Object>> parseActionsHttpResponse( HttpResponse res ) {

        List<Map<String, Object>> actions = new List<Map<String, Object>>();

        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.getBody() );

        if ( resMap != null ) {

            List<Object> actionRecords = (List<Object>) resMap.get( 'actions' );

            if ( actionRecords != null ) {

                for ( Object actionRecord : actionRecords ) {
                    actions.add( (Map<String, Object>) actionRecord );
                }

            }

        }

        return actions;
    }

    /**
     * JSON deserializes the 'inputs' property of the response.
     */
    private static List<Map<String, Object>> parseActionInputsHttpResponse( HttpResponse res ) {

        List<Map<String, Object>> inputs = new List<Map<String, Object>>();

        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped( res.getBody() );

        if ( resMap != null ) {

            List<Object> inputRecords = (List<Object>) resMap.get( 'inputs' );

            if ( inputRecords != null ) {

                for ( Object inputRecord : inputRecords ) {
                    inputs.add( (Map<String, Object>) inputRecord );
                }

            }

        }

        return inputs;
    }

    /**
     * XML deserializes the response.
     * Assumes this is a succcessful response.
     * A SOAP fault should have been checked prior to calling this method.
     */
    private static MA_AnonymousApexExecuteResult parseAnonymousApexHttpResponse( HttpResponse res ) {

        // Parse the SOAP response
        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/sforce_api_calls_executeanonymous_result.htm

        DOM.Document responseDocument = res.getBodyDocument();
        DOM.XMLNode root = responseDocument.getRootElement();

        MA_AnonymousApexExecuteResult result = new MA_AnonymousApexExecuteResult();

        result.column = Integer.valueOf( MA_XMLUtils.getChildNodeTextByPath( root, 'Body/executeAnonymousResponse/result/column' ) );
        result.line = Integer.valueOf( MA_XMLUtils.getChildNodeTextByPath( root, 'Body/executeAnonymousResponse/result/line' ) );

        result.compiled = Boolean.valueOf( MA_XMLUtils.getChildNodeTextByPath( root, 'Body/executeAnonymousResponse/result/compiled' ) );
        result.compileProblem = MA_XMLUtils.getChildNodeTextByPath( root, 'Body/executeAnonymousResponse/result/compileProblem' );

        result.exceptionMessage = MA_XMLUtils.getChildNodeTextByPath( root, 'Body/executeAnonymousResponse/result/exceptionMessage' );
        result.exceptionStackTrace = MA_XMLUtils.getChildNodeTextByPath( root, 'Body/executeAnonymousResponse/result/exceptionStackTrace' );

        result.success = Boolean.valueOf( MA_XMLUtils.getChildNodeTextByPath( root, 'Body/executeAnonymousResponse/result/success' ) );

        System.debug( 'MA_MassActionUtils.parseAnonymousApexHttpResponse' );
        System.debug( result );

        return result;
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