({
    initScheduleOptions : function( component ) {

        var scheduleOptionsHourOfDay = [];
        var scheduleOptionsDayOfMonth = [];
        var scheduleOptionsMonthOfYear = [];
        var scheduleOptionsDayOfWeek = [];

        for ( var i = 0; i < 24; i++ ) {
            scheduleOptionsHourOfDay.push({
                'label' : ( i == 0 ? '12:00 AM' : i == 12 ? '12:00 PM' : ( i < 12 ? i + ':00 AM' : ( i - 12 ) + ':00 PM' ) ).padStart( 8, '0' ),
                'value' : i.toString().padStart( 2, '0' ) + '.' + i.toString()
            });
        }

        for ( var i = 1; i <= 31; i++ ) {
            scheduleOptionsDayOfMonth.push({
                'label' : i.toString(),
                'value' : i.toString().padStart( 2, '0' ) + '.' + i.toString()
            });
        }

        var monthValues = [ 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC' ];
        var localeMonthNames = $A.get( '$Locale.nameOfMonths' );
        for ( var i = 0; i < localeMonthNames.length; i++ ) {
            if ( !$A.util.isEmpty( localeMonthNames[i].fullName ) ) {
                scheduleOptionsMonthOfYear.push({
                    'label' : localeMonthNames[i].fullName.toUpperCase(),               // display in user's locale
                    'value' : i.toString().padStart( 2, '0' ) + '.' + monthValues[i]    // but capture in english for cron expr.
                });                                                                     // left pad with number for easy sorting
            }
        }

        var weekdayValues = [ 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT' ];
        var localeWeekdayNames = $A.get( '$Locale.nameOfWeekdays' );
        for ( var i = 0; i < localeWeekdayNames.length; i++ ) {
            if ( !$A.util.isEmpty( localeWeekdayNames[i].fullName ) ) {
                scheduleOptionsDayOfWeek.push({
                    'label' : localeWeekdayNames[i].fullName.toUpperCase(),             // display in user's locale
                    'value' : i.toString().padStart( 2, '0' ) + '.' + weekdayValues[i]  // but capture in english for cron expr.
                });                                                                     // left pad with number for easy sorting
            }
        }

        component.set( 'v.scheduleOptionsHourOfDay', scheduleOptionsHourOfDay );
        component.set( 'v.scheduleOptionsDayOfMonth', scheduleOptionsDayOfMonth );
        component.set( 'v.scheduleOptionsMonthOfYear', scheduleOptionsMonthOfYear );
        component.set( 'v.scheduleOptionsDayOfWeek', scheduleOptionsDayOfWeek );

        var record = component.get( 'v.record' );

        component.set( 'v.scheduleSelectionsFrequency', record.scheduleFrequency );

        if ( !$A.util.isUndefinedOrNull( record.scheduleHourOfDay ) ) {
            component.set( 'v.scheduleSelectionsHourOfDay', record.scheduleHourOfDay.split(',') );
        } else {
            component.set( 'v.scheduleSelectionsHourOfDay', [] );
        }

        if ( !$A.util.isUndefinedOrNull( record.scheduleDayOfMonth ) ) {
            component.set( 'v.scheduleSelectionsDayOfMonth', record.scheduleDayOfMonth.split(',') );
        } else {
            component.set( 'v.scheduleSelectionsDayOfMonth', [] );
        }

        if ( !$A.util.isUndefinedOrNull( record.scheduleMonthOfYear ) ) {
            component.set( 'v.scheduleSelectionsMonthOfYear', record.scheduleMonthOfYear.split(',') );
        } else {
            component.set( 'v.scheduleSelectionsMonthOfYear', [] );
        }

        if ( !$A.util.isUndefinedOrNull( record.scheduleDayOfWeek ) ) {
            component.set( 'v.scheduleSelectionsDayOfWeek', record.scheduleDayOfWeek.split(',') );
        } else {
            component.set( 'v.scheduleSelectionsDayOfWeek', [] );
        }

    },

    /**
     * Determines if conditions are satisfactory to fetch and render
     * sobject options that have invocable actions. Designed to be called whenever
     * the target type requires sobject input field changes and once conditions met then options appear.
     */
    renderTargetSobjectTypes : function( component ) {

        var helper = this;

        var targetTypeRequiresSobject = component.get( 'v.targetTypeRequiresSobject' );

        if ( targetTypeRequiresSobject === true ) {

            var targetType = component.get( 'v.targetType' );
            var targetNamedCredential = component.get( 'v.record.namedCredential' );

            helper.getObjectsWithInvocableActionsAsync( component, targetNamedCredential, targetType )
                .then( $A.getCallback( function( results ) {

                    component.set( 'v.targetSobjectTypes', results );

                }));

        } else {

            component.set( 'v.targetSobjectType', null );
            component.set( 'v.targetSobjectTypes', null );

        }

    },

    /**
     * Determines if conditions are satisfactory to fetch and render
     * the target invocable action options. Designed to be called whenever
     * the target input fields change and once conditions met then options appear.
     */
    renderTargetInvocableActions : function( component ) {

        var helper = this;

        var targetType = component.get( 'v.targetType' );
        var targetTypeRequiresSobject = component.get( 'v.targetTypeRequiresSobject' );
        var targetTypeRequiresAction = component.get( 'v.targetTypeRequiresAction' );
        var targetSobjectType = component.get( 'v.targetSobjectType' );
        var targetAction = component.get( 'v.targetInvocableAction' );
        var targetNamedCredential = component.get( 'v.record.namedCredential' );

        var isValidToRenderActions = true;

        if ( $A.util.isEmpty( targetNamedCredential ) ||
             $A.util.isEmpty( targetType ) ||
             ( !targetTypeRequiresAction ) ||
             ( targetTypeRequiresSobject && $A.util.isEmpty( targetSobjectType ) ) ) {

            isValidToRenderActions = false;

        }

        if ( isValidToRenderActions ) {

            helper.getInvocableActionsAsync( component, targetNamedCredential, targetType, ( targetSobjectType || '' ) )
                .then( $A.getCallback( function( actions ) {

                    component.set( 'v.targetInvocableActions', actions );

                    // if currently selected target action is not in this list then clear the field
                    var targetActionFound = actions.find( function( elmt ) { return elmt.value === targetAction; } );
                    component.set( 'v.targetInvocableAction', ( targetActionFound && targetActionFound.value ) );

                }));

        } else {

            component.set( 'v.targetInvocableActions', null );

            // Don't clear selected target action here because of timing
            // this would clear out the record's initial value on component init.
            // Instead, we try to handle this in the controller function "handleTargetTypeChange"
            //component.set( 'v.targetInvocableAction', null );

        }

        component.set( 'v.isValidToRenderTargetInvocableActions', isValidToRenderActions );

    },

    renderTargetFieldMappings : function( component ) {

        var helper = this;

        var sourceType = component.get( 'v.sourceType' );
        var sourceReportId = component.get( 'v.sourceReportId' );
        var sourceListViewId = component.get( 'v.sourceListViewId' );

        var targetType = component.get( 'v.targetType' );
        var targetAction = component.get( 'v.targetInvocableAction' );
        var targetSobjectType = component.get( 'v.targetSobjectType' );
        var targetNamedCredential = component.get( 'v.record.namedCredential' );

        var sourceFields = []; // columns from source report or list view
        var targetFields = []; // inputs from target action

        var p = Promise.resolve()
            .then( $A.getCallback( function() {

               if ( sourceType == 'Report' ) {

                    return helper.getReportColumnsAsync( component, sourceReportId )
                        .then( $A.getCallback( function( result ) {
                            sourceFields = result;
                        }));

               } else if ( sourceType == 'ListView' ) {

                    return helper.getListViewColumnsAsync( component, targetNamedCredential, sourceListViewId )
                        .then( $A.getCallback( function( result ) {
                            sourceFields = result;
                        }));

               }

            })).then( $A.getCallback( function() {

                return helper.getInvocableActionInputsAsync( component, targetNamedCredential, targetType, ( targetAction || '' ), ( targetSobjectType || '' ) )
                    .then( $A.getCallback( function( result ) {
                        targetFields = result;
                    }));

            })).then( $A.getCallback( function() {

                // target action types that we don't prompt user for to avoid confusion
                var ignoreDataTypes = [ 'SOBJECT', 'BLOB' ];

                var recordFieldMappings = component.get( 'v.record.fieldMappings' ); // what currently has been mapped in database
                var targetFieldMappings = []; // what user will work with in UI to assign source fields to target fields

                for ( var i = 0; i < targetFields.length; i++ ) {

                    var targetField = targetFields[i];

                    if ( !ignoreDataTypes.includes( targetField.dataType ) ) {

                        var recordFieldMapping = { 'sourceFieldName' : null, 'targetFieldName' : null };

                        // find existing mapping for this target field, if any exists
                        for ( var j = 0; j < recordFieldMappings.length; j++ ) {
                            if ( targetField.name == recordFieldMappings[j].targetFieldName ) {
                                recordFieldMapping = recordFieldMappings[j];
                                break;
                            }
                        }

                        targetFieldMappings.push({
                            'targetField' : targetField,
                            'sourceFieldName' : recordFieldMapping.sourceFieldName
                        });

                    }

                }

                component.set( 'v.sourceFields', sourceFields );
                component.set( 'v.targetFields', targetFields );
                component.set( 'v.targetFieldMappings', targetFieldMappings );

            }));

    },

    /**
     * Given an array of aura components representing inputs (have a v.value attribute)
     * then returns a validation result object with any errors for each component.
     */
    validateInputs : function( component, inputCmps ) {

        var validationResult = {
            hasErrors : false,
            components : [] // { hasError : boolean, message : string, component : aura.component }
        };

        var sourceType = component.get( 'v.sourceType' );
        var sourceTypeIsReport = ( sourceType === 'Report' );
        var sourceTypeIsListView = ( sourceType === 'ListView' );

        var targetType = component.get( 'v.targetType' );
        var targetTypeIsFlows = ( targetType === 'Flow' );
        var targetTypeIsWorkflows = ( targetType === 'Workflow' );
        var targetTypeIsQuickActions = ( targetType === 'QuickAction' );
        var targetTypeIsEmailAlerts = ( targetType === 'EmailAlert' );
        var targetTypeIsApex = ( targetType === 'Apex' );

        var targetTypeRequiresSobject = component.get( 'v.targetTypeRequiresSobject' );
        var targetTypeRequiresAction = component.get( 'v.targetTypeRequiresAction' );

        var scheduleFrequency = component.get( 'v.scheduleSelectionsFrequency' );
        var scheduleFrequenceIsScheduled = ( scheduleFrequency == 'Scheduled' || ( !$A.util.isUndefinedOrNull( scheduleFrequency ) && scheduleFrequency.length && scheduleFrequency[0] == 'Scheduled' ) );
        var scheduleFrequenceIsCustom = ( scheduleFrequency == 'Custom' || ( !$A.util.isUndefinedOrNull( scheduleFrequency ) && scheduleFrequency.length && scheduleFrequency[0] == 'Custom' ) );

        var inputScheduleWeekdayIsEmpty = $A.util.isEmpty( component.get( 'v.scheduleSelectionsDayOfWeek' ) );
        var inputScheduleDayOfMonthIsEmpty = $A.util.isEmpty( component.get( 'v.scheduleSelectionsDayOfMonth' ) );

        var objectDescribe = component.get( 'v.objectDescribe' );

        var hasErrors = false;

        inputCmps.forEach( function( inputCmp ) {

            var validationComponentResult = {
                hasError : false,
                message : null,
                component : inputCmp
            };

            var inputLabel = null;
            var inputValue = null;

            var inputIsEmpty = false;
            var inputIsInvalid = false;

            var errorMessage = null;

            if ( !$A.util.isUndefinedOrNull( inputCmp ) ) {

                inputLabel = inputCmp.get( 'v.label' );
                inputValue = inputCmp.get( 'v.value' );
                inputIsEmpty = $A.util.isEmpty( inputValue );

                // populate a default error message,
                // but don't assign to the validation component result
                // unless we indeed determine the input component is invalid
                if ( inputIsEmpty ) {
                    errorMessage = inputLabel + ' is required.';
                }

                switch ( inputCmp.getLocalId() ) {

                    // Source

                    case 'inputName':
                    case 'inputDeveloperName':
                    case 'inputSourceType':
                        inputIsInvalid = ( inputIsEmpty );
                        break;

                    // Source: Report

                    case 'inputSourceReportFolder':
                    case 'inputSourceReport':
                    case 'inputSourceReportColumn':
                        inputIsInvalid = ( sourceTypeIsReport && inputIsEmpty );
                        break;

                    // Source: List View

                    case 'inputSourceListViewSobjectType':
                    case 'inputSourceListView':
                        inputIsInvalid = ( sourceTypeIsListView && inputIsEmpty );
                        break;

                    // Target

                    case 'inputTargetNamedCredential':
                    case 'inputTargetType':
                        inputIsInvalid = ( inputIsEmpty );
                        break;

                    case 'inputTargetSobjectType':
                        inputIsInvalid = ( targetTypeRequiresSobject && inputIsEmpty );
                        break;

                    case 'inputTargetAction':
                        inputIsInvalid = ( targetTypeRequiresAction && inputIsEmpty );
                        break;

                    // Target: Field Mappings

                    case 'inputMappingSourceFieldName':
                        inputIsInvalid = ( inputIsEmpty && inputCmp.get( 'v.required' ) );
                        break;

                    // Schedule

                    case 'inputScheduleFrequency':
                        inputIsInvalid = ( inputIsEmpty );
                        break;

                    case 'inputScheduleHourOfDay':
                        inputIsInvalid = ( scheduleFrequenceIsScheduled && inputIsEmpty );
                        break;

                    case 'inputScheduleWeekday':
                        inputIsInvalid = ( scheduleFrequenceIsScheduled && ( inputIsEmpty == inputScheduleDayOfMonthIsEmpty ) );
                        errorMessage = 'Select options for either "' + objectDescribe.fields.Schedule_DayOfWeek__c.label + '" or "' + objectDescribe.fields.Schedule_DayOfMonth__c.label + '" but not both. Exactly one is required.';
                        break;

                    case 'inputScheduleDayOfMonth':
                        inputIsInvalid = ( scheduleFrequenceIsScheduled && ( inputIsEmpty == inputScheduleWeekdayIsEmpty ) );
                        errorMessage = 'Select options for either "' + objectDescribe.fields.Schedule_DayOfWeek__c.label + '" or "' + objectDescribe.fields.Schedule_DayOfMonth__c.label + '" but not both. Exactly one is required.';
                        break;

                    case 'inputScheduleMonthOfYear':
                        inputIsInvalid = ( scheduleFrequenceIsScheduled && inputIsEmpty );
                        break;

                    case 'inputScheduleCron':
                        inputIsInvalid = ( scheduleFrequenceIsCustom && inputIsEmpty );
                        break;

                }

                if ( inputIsInvalid ) {
                    validationComponentResult.message = errorMessage;
                }

            }

            hasErrors = ( hasErrors || inputIsInvalid );

            validationComponentResult.hasError = inputIsInvalid;
            validationResult.components.push( validationComponentResult );

        });

        validationResult.hasErrors = hasErrors;

        return validationResult;
    },

    // -----------------------------------------------------------------

    saveRecordAsync : function( component ) {

        var helper = this;
        var record = component.get( 'v.record' );

        // source
        record.sourceType = component.get( 'v.sourceType' );
        record.sourceReportID = component.get( 'v.sourceReportId' );
        record.sourceReportColumnName = component.get( 'v.sourceReportColumnName' );
        record.sourceListViewID = component.get( 'v.sourceListViewId' );

        // target
        record.targetType = component.get( 'v.targetType' );
        record.targetSobjectType = component.get( 'v.targetSobjectType' );
        record.targetActionName = component.get( 'v.targetInvocableAction' );

        // schedule

        /*
            Unfortunately, the radioGroup component changes the value type to an array,
            so even though my source value is a single string I need to check both data types
            or introduce a shadow variable to bind to the radio group and use change events
            to copy the newly selected value; neither of which I want to do.
            https://org62.lightning.force.com/one/one.app#/sObject/0D50M00003LvvAqSAJ/view
         */
        var scheduleFrequency = component.get( 'v.scheduleSelectionsFrequency' );
        var scheduleHourOfDay = component.get( 'v.scheduleSelectionsHourOfDay' );
        var scheduleDayOfWeek = component.get( 'v.scheduleSelectionsDayOfWeek' );
        var scheduleDayOfMonth = component.get( 'v.scheduleSelectionsDayOfMonth' );
        var scheduleMonthOfYear = component.get( 'v.scheduleSelectionsMonthOfYear' );

        record.scheduleFrequency = ( $A.util.isArray( scheduleFrequency ) ? ( scheduleFrequency.length > 0 ? scheduleFrequency[0] : null ) : scheduleFrequency );

        // if manual then null the other schedule fields
        // if scheduled then parse the schedule fields, null the cron field
        // if custom then null the schedule fields except cron field

        if ( record.scheduleFrequency == 'Manual' ) {

            record.scheduleCron = null;
            record.scheduleSecondOfMinute = null;
            record.scheduleMinuteOfHour = null;
            record.scheduleHourOfDay = null;
            record.scheduleDayOfMonth = null;
            record.scheduleMonthOfYear = null;
            record.scheduleDayOfWeek = null;

        }
        else if ( record.scheduleFrequency == 'Scheduled' ) {

            // parse the "NN." from the values used for sorting then join them by commas

            record.scheduleCron = null;
            record.scheduleSecondOfMinute = '0';
            record.scheduleMinuteOfHour = '0';
            record.scheduleHourOfDay = scheduleHourOfDay.map( function( hourOfDay ) { return hourOfDay.split('.')[1]; } ).join(',');
            record.scheduleDayOfMonth = '?';
            record.scheduleMonthOfYear = scheduleMonthOfYear.map( function( monthOfYear ) { return monthOfYear.split('.')[1]; } ).join(',');
            record.scheduleDayOfWeek = scheduleDayOfWeek.map( function( dayOfWeek ) { return dayOfWeek.split('.')[1]; } ).join(',');

        }
        else if ( record.scheduleFrequency == 'Custom' ) {

            record.scheduleSecondOfMinute = null;
            record.scheduleMinuteOfHour = null;
            record.scheduleHourOfDay = null;
            record.scheduleDayOfMonth = null;
            record.scheduleMonthOfYear = null;
            record.scheduleDayOfWeek = null;

        }

        // because source fields can be mapped to multiple target fields
        // but a target field can only have one mapping then we build up a map
        // of target fields to their source field
        var targetFieldMappings = {};
        component.get( 'v.targetFieldMappings' ).forEach( function( item ) {
            targetFieldMappings[item.targetField.name] = item.sourceFieldName;
        });

        return helper.enqueueAction( component, 'c.saveConfiguration', {

            'wrapperJson' : JSON.stringify( record ),
            'fieldMappingsJson' : JSON.stringify( targetFieldMappings )

        }).then( $A.getCallback( function( result ) {

            return result;

        }));

    },

    // -----------------------------------------------------------------

    getObjectDescribeAsync : function( component ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getConfigurationObjectDescribe', {

        }).then( $A.getCallback( function( objectDescribe ) {

            return objectDescribe;

        }));

    },

    getRecordAsync : function( component, recordId ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getConfiguration', {

            'recordId' : recordId

        }).then( $A.getCallback( function( record ) {

            return record;

        }));

    },

    // -----------------------------------------------------------------

    getObjectNamesAsync : function( component ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getObjectNames', {

        }).then( $A.getCallback( function( objectNames ) {

            return objectNames;

        }));

    },

    getListViewsByObjectAsync : function( component, objectName ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getListViewsByObject', {

            'objectName' : objectName

        }).then( $A.getCallback( function( listViews ) {

            return listViews;

        }));

    },

    getListViewAsync : function( component, listViewId ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getListView', {

            'recordId' : listViewId

        }).then( $A.getCallback( function( record ) {

            return record;

        }));

    },

    getListViewColumnsAsync : function( component, namedCredential, listViewId ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getListViewColumns', {

            'namedCredential' : namedCredential,
            'listViewId' : listViewId

        }).then( $A.getCallback( function( listViewColumns ) {

            return listViewColumns;

        }));

    },

    // -----------------------------------------------------------------

    getReportFoldersAsync : function( component ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getReportFolders', {

        }).then( $A.getCallback( function( reportFolders ) {

            return reportFolders;

        }));

    },

    getReportsByFolderAsync : function( component, folderId ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getReportsByFolder', {

            'folderId' : folderId

        }).then( $A.getCallback( function( reports ) {

            return reports;

        }));

    },

    getReportAsync : function( component, reportId ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getReport', {

            'recordId' : reportId

        }).then( $A.getCallback( function( record ) {

            return record;

        }));

    },

    getReportColumnsAsync : function( component, reportId ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getReportColumns', {

            'reportId' : reportId

        }).then( $A.getCallback( function( reportColumns ) {

            return reportColumns;

        }));

    },

    // -----------------------------------------------------------------

    getNamedCredentialsAsync : function( component ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getNamedCredentials', {

        }).then( $A.getCallback( function( namedCredentials ) {

            return namedCredentials;

        }));

    },

    getObjectsWithInvocableActionsAsync : function( component, namedCredential, actionType ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getObjectsWithInvocableActions', {

            'namedCredential' : namedCredential,
            'actionType' : actionType

        }).then( $A.getCallback( function( results ) {

            return results;

        }));

    },

    getInvocableActionsAsync : function( component, namedCredential, actionType, objectName ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getInvocableActions', {

            'namedCredential' : namedCredential,
            'actionType' : actionType,
            'objectName' : objectName

        }).then( $A.getCallback( function( results ) {

            return results;

        }));

    },

    getInvocableActionInputsAsync : function( component, namedCredential, actionType, actionName, objectName ) {

        var helper = this;

        return helper.enqueueAction( component, 'c.getInvocableActionInputs', {

            'namedCredential' : namedCredential,
            'actionType' : actionType,
            'actionName' : actionName,
            'objectName' : objectName

        }).then( $A.getCallback( function( results ) {

            return results;

        }));

    },

    // -----------------------------------------------------------------

    showSpinner : function( component ) {

        $A.util.removeClass( component.find( 'spinner' ), 'slds-hide' );

    },

    hideSpinner : function( component ) {

        $A.util.addClass( component.find( 'spinner' ), 'slds-hide' );

    },

    toastMessage : function( title, message, type ) {

        // https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/ref_force_showToast.htm

        $A.get( 'e.force:showToast' ).setParams({
            title : title,
            message : message,
            type : ( type || 'info' )
        }).fire();

    },

    navigateToRecord : function( recordId ) {

        console.log( 'navigating to record: ' + recordId );

        var event = $A.get( 'e.force:navigateToSObject' );

        if ( event ) {

            event.setParams({
                'recordId' : recordId
            }).fire();

        } else if ( ( typeof sforce !== 'undefined' ) && ( typeof sforce.one !== 'undefined' ) ) {

            sforce.one.navigateToSObject( recordId );

        } else {

            window.location.href = '/' + recordId;

        }

    },

    navigateToURL : function( url ) {

        console.log( 'navigating to url: ' + url );

        var event = $A.get( 'e.force:navigateToURL' );

        if ( event ) {

            event.setParams({
                'url' : url
            }).fire();

        } else if ( ( typeof sforce !== 'undefined' ) && ( typeof sforce.one !== 'undefined' ) ) {

            sforce.one.navigateToURL( url );

        } else {

            window.location.href = url;

        }

    },

    enqueueAction : function( component, actionName, params ) {

        var helper = this;

        var p = new Promise( function( resolve, reject ) {

            helper.showSpinner( component );

            var action = component.get( actionName );

            if ( params ) {
                action.setParams( params );
            }

            action.setCallback( helper, function( response ) {

                helper.hideSpinner( component );

                if ( component.isValid() && response.getState() === 'SUCCESS' ) {

                    resolve( response.getReturnValue() );

                } else {

                    console.error( 'Error calling action "' + actionName + '" with state: ' + response.getState() );

                    helper.logActionErrors( response.getError() );

                    reject( helper.getMessageFromActionResponseError( response.getError() ) );

                }
            });

            $A.enqueueAction( action );

        });

        return p;
    },

    logActionErrors : function( errors ) {
        if ( errors ) {
            if ( errors.length > 0 ) {
                for ( var i = 0; i < errors.length; i++ ) {
                    console.error( 'Error: ' + errors[i].message );
                }
            } else {
                console.error( 'Error: ' + errors );
            }
        } else {
            console.error( 'Unknown error' );
        }
    },

    getMessageFromActionResponseError : function( errors ) {
        var text = '';
        if ( errors ) {
            if ( errors.length > 0 ) {
                for ( var i = 0; i < errors.length; i++ ) {
                    text += '\n' + errors[i].message;
                }
            } else {
                text = errors;
            }
        }
        return text;
    }
})