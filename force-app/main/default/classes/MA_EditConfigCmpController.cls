/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_EditConfigCmpController {

    /**
     * This method is primarily designed for showing list of objects for Email Alerts and Quick Actions.
     * Rather than display user a list of all objects in their org that may or may not have actions setup
     * we instead use the Actions REST API to know the objects (if any) that have actions configured for them.
     * This has the benefit of reducing the unusable object options the user must sift through.
     */
    @AuraEnabled
    public static List<Map<String, Object>> getObjectsWithInvocableActions( String namedCredential, String actionType ) {

        Map<String, SObjectType> globalDescribeMap = Schema.getGlobalDescribe();

        List<ObjectNameWrapper> wrappers = new List<ObjectNameWrapper>();

        for ( String objectName : MA_MassActionUtils.getObjectsWithInvocableActions( namedCredential, actionType ) ) {
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
     * @param namedCredential
     *      Used to make REST API callout to retrieve this data.
     * @param actionType
     *      Specific kind of actions to retrieve like Flows or Email Alerts.
     *      Value should match API value of Mass_Action_Configuration__c.Target_Type__c picklist entry.
     * @param objectName
     *      Only required for certain action types like Quick Actions or Email Alerts.
     *      In the REST API, some actions are object specific and this indicates for which object to return their actions.
     */
    @AuraEnabled
    public static List<Map<String, Object>> getInvocableActions( String namedCredential, String actionType, String objectName ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( Map<String, Object> action : MA_MassActionUtils.getInvocableActions( namedCredential, actionType, objectName ) ) {
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
     * @param namedCredential
     *      Used to make REST API callout to retrieve this data.
     * @param actionType
     *      Specific kind of action like Flows or Email Alerts.
     *      Value should match API value of Mass_Action_Configuration__c.Target_Type__c picklist entry.
     * @param actionName
     *      Specific action name whose inputs to retrieve like the Flow API name or Quick Action API name.
     * @param objectName
     *      Only required for certain action types like Quick Actions or Email Alerts.
     *      In the REST API, some actions are object specific and this indicates for which object to return their actions.
     */
    @AuraEnabled
    public static List<Map<String, Object>> getInvocableActionInputs( String namedCredential, String actionType, String actionName, String objectName ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        if ( actionType == 'Workflow' ) {

            options.add( new Map<String, Object>{
                'label' => 'Record ID',
                'name' => 'ContextId',
                'dataType' => 'ID',
                'required' => true
            });

        } else {

            for ( Map<String, Object> input : MA_MassActionUtils.getInvocableActionInputs( namedCredential, actionType, actionName, objectName ) ) {
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

    @AuraEnabled
    public static List<Map<String, Object>> getReportFolders() {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( Folder folder : [ SELECT id, name FROM Folder WHERE type = 'Report' AND developerName != null ORDER BY name ] ) {
            options.add( new Map<String, Object>{
                'label' => folder.name,
                'value' => String.valueOf( folder.id ).left( 15 )
            });
        }

        return options;
    }

    @AuraEnabled
    public static List<Map<String, Object>> getReportsByFolder( ID folderId ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( Report record : [ SELECT id, name FROM Report WHERE ownerId = :folderId AND format = 'Tabular' ORDER BY name ] ) {
            options.add( new Map<String, Object>{
                'label' => record.name,
                'value' => String.valueOf( record.id ).left( 15 )
            });
        }

        return options;
    }

    @AuraEnabled
    public static Report getReport( ID recordId ) {

        for ( Report record : [ SELECT id, name, ownerId, owner.name, folderName FROM Report WHERE id = :recordId LIMIT 1 ] ) {
            return record;
        }
        return null;
    }

    @AuraEnabled
    public static List<Map<String, Object>> getReportColumns( ID reportId ) {

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

    @AuraEnabled
    public static List<Map<String, Object>> getObjectNames() {

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

    @AuraEnabled
    public static List<Map<String, Object>> getListViewsByObject( String objectName ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( ListView record : [ SELECT id, name FROM ListView WHERE sobjectType = :objectName AND IsSoqlCompatible = true ORDER BY name ] ) {
            options.add( new Map<String, Object>{
                'label' => record.name,
                'value' => String.valueOf( record.id ).substring( 0, 15 )
            });
        }

        return options;
    }

    @AuraEnabled
    public static ListView getListView( ID recordId ) {

        for ( ListView record : [ SELECT id, name, sobjectType FROM ListView WHERE id = :recordId LIMIT 1 ] ) {
            return record;
        }
        return null;
    }

    @AuraEnabled
    public static List<Map<String, Object>> getListViewColumns( String namedCredential, ID listViewId ) {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        if ( String.isNotBlank( listViewId ) ) {

            MA_ListViewDescribeResult describeResult = MA_MassActionUtils.describeListView( namedCredential, listViewId );

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

    @AuraEnabled
    public static List<Map<String, Object>> getNamedCredentials() {

        List<Map<String, Object>> options = new List<Map<String, Object>>();

        for ( NamedCredential credential : [ SELECT id, masterLabel, developerName FROM NamedCredential ORDER BY masterLabel ] ) {
            options.add( new Map<String, Object>{
                'label' => credential.masterLabel,
                'value' => credential.developerName
            });
        }

        return options;
    }

    // -----------------------------------------------------------------------------

    @AuraEnabled
    public static MA_MassActionConfigWrapper getConfiguration( ID recordId ) {

        // return json without org's namespace so our code doesn't have to worry about it
        return new MA_MassActionConfigWrapper( MA_MassActionUtils.getConfiguration( recordId ) );
    }

    @AuraEnabled
    public static Map<String, Object> getConfigurationObjectDescribe() {

        String objectName = MA_MassActionUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';

        DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get( objectName ).getDescribe();

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
    @AuraEnabled
    public static Map<String, Object> saveConfiguration( String wrapperJson, String fieldMappingsJson ) {

        System.debug( 'MA_EditConfigCmpController.saveConfiguration' );
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
                configMappings.add( new Mass_Action_Mapping__c(
                    Mass_Action_Configuration__c = config.Id,
                    Source_Field_Name__c = fieldMappings.get( targetFieldName ),
                    Target_Field_Name__c = targetFieldName
                ));
            }

            insert configMappings;

            result.put( 'success', true );
            result.put( 'recordId', config.Id );

        } catch ( Exception e ) {

            Database.rollback( sp );

            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );

            throw new AuraHandledException( e.getMessage() );

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