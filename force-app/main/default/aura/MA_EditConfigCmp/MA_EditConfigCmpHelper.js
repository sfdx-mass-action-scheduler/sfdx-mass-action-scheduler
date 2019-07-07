/*
Author: Doug Ayers
Website: https://douglascayers.com
GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
License: BSD 3-Clause License
 */
({
    initScheduleOptions : function( component ) {

        var helper = this;

        var scheduleOptionsHourOfDay = [];
        var scheduleOptionsDayOfMonth = [];
        var scheduleOptionsMonthOfYear = [];
        var scheduleOptionsDayOfWeek = [];

        for ( let i = 0; i < 24; i++ ) {
            scheduleOptionsHourOfDay.push({
                'label' : ( i == 0 ? '12:00 AM' : i == 12 ? '12:00 PM' : ( i < 12 ? i + ':00 AM' : ( i - 12 ) + ':00 PM' ) ).padStart( 8, '0' ),
                'value' : i.toString().padStart( 2, '0' ) + '.' + i.toString()
            });
        }

        for ( let i = 1; i <= 31; i++ ) {
            scheduleOptionsDayOfMonth.push({
                'label' : i.toString(),
                'value' : i.toString().padStart( 2, '0' ) + '.' + i.toString()
            });
        }

        var monthValues = [ 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC' ];
        var localeMonthNames = $A.get( '$Locale.nameOfMonths' );
        for ( let i = 0; i < localeMonthNames.length; i++ ) {
            if ( !helper.isEmpty( localeMonthNames[i].fullName ) ) {
                scheduleOptionsMonthOfYear.push({
                    'label' : localeMonthNames[i].fullName.toUpperCase(),               // display in user's locale
                    'value' : i.toString().padStart( 2, '0' ) + '.' + monthValues[i]    // but capture in english for cron expr.
                });                                                                     // left pad with number for easy sorting
            }
        }

        var weekdayValues = [ 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT' ];
        var localeWeekdayNames = $A.get( '$Locale.nameOfWeekdays' );
        for ( let i = 0; i < localeWeekdayNames.length; i++ ) {
            if ( !helper.isEmpty( localeWeekdayNames[i].fullName ) ) {
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

        // add the "NN." prefix to the values used for sorting
        // so match the schedule options format so the selections are visually shown on the config page

        // exactly one of dayOfMonth or dayOfWeek must be specified and the other must be '?',
        // in our case, '?' means no selections for that value as the other field was specified

        if ( !$A.util.isUndefinedOrNull( record.scheduleHourOfDay ) ) {
            component.set( 'v.scheduleSelectionsHourOfDay', record.scheduleHourOfDay.split(',').map( function( hourOfDay ) { return hourOfDay.padStart( 2, '0' ) + '.' + hourOfDay; } ) );
        } else {
            component.set( 'v.scheduleSelectionsHourOfDay', [] );
        }

        if ( !$A.util.isUndefinedOrNull( record.scheduleDayOfMonth ) && record.scheduleDayOfMonth != '?' ) {
            component.set( 'v.scheduleSelectionsDayOfMonth', record.scheduleDayOfMonth.split(',').map( function( dayOfMonth ) { return dayOfMonth.padStart( 2, '0' ) + '.' + dayOfMonth; } ) );
        } else {
            component.set( 'v.scheduleSelectionsDayOfMonth', [] );
        }

        if ( !$A.util.isUndefinedOrNull( record.scheduleMonthOfYear ) ) {
            component.set( 'v.scheduleSelectionsMonthOfYear', record.scheduleMonthOfYear.split(',').map( function( monthOfYear ) { return monthValues.indexOf( monthOfYear ).toString().padStart( 2, '0' ) + '.' + monthOfYear; } ) );
        } else {
            component.set( 'v.scheduleSelectionsMonthOfYear', [] );
        }

        if ( !$A.util.isUndefinedOrNull( record.scheduleDayOfWeek ) && record.scheduleDayOfWeek != '?' ) {
            component.set( 'v.scheduleSelectionsDayOfWeek', record.scheduleDayOfWeek.split(',').map( function( dayOfWeek ) { return weekdayValues.indexOf( dayOfWeek ).toString().padStart( 2, '0' ) + '.' + dayOfWeek; } ) );
        } else {
            component.set( 'v.scheduleSelectionsDayOfWeek', [] );
        }

    },

    // ----------------------------------------------------------------------------------

    handleSourceTypeChange : function( component ) {

        var helper = this;

        var promises = [];

        var sourceType = component.get( 'v.sourceType' );
        var record = component.get( 'v.record' );

        if ( sourceType != 'Report' ) {

            record.sourceReportID = null;
            record.sourceReportColumnName = null;

            component.set( 'v.sourceReport', null );
            component.set( 'v.sourceReportId', null );
            component.set( 'v.sourceReportFolderId', null );
            component.set( 'v.sourceReportColumns', null );
            component.set( 'v.sourceReportColumnName', null );

        } else {

            if ( helper.isEmpty( component.get( 'v.sourceReportFolders' ) ) ) {

                promises.push( helper.getReportFoldersAsync( component )
                    .then( $A.getCallback( function( reportFolders ) {

                        component.set( 'v.sourceReportFolders', reportFolders );
                        helper.handleSourceReportFolderChange( component );

                    })).catch( $A.getCallback( function( err ) {

                        helper.toastMessage( 'Error Getting Report Folders', err, 'error' );

                    }))
                );

            }

        }

        if ( sourceType != 'ListView' ) {

            record.sourceListViewID = null;

            component.set( 'v.sourceListView', null );
            component.set( 'v.sourceListViewId', null );
            component.set( 'v.sourceListViewSobjectType', null );

        } else {

            if ( helper.isEmpty( component.get( 'v.sourceListViewSobjectTypes' ) ) ) {

                promises.push( helper.getObjectNamesWithListViewsAsync( component )
                    .then( $A.getCallback( function( objectNames ) {

                        component.set( 'v.sourceListViewSobjectTypes', objectNames );
                        helper.handleSourceListViewSobjectTypeChange( component );

                    })).catch( $A.getCallback( function( err ) {

                        helper.toastMessage( 'Error Getting Object Names', err, 'error' );

                    }))
                );

            }

        }

        if ( sourceType != 'SOQL' ) {

            record.sourceSoqlQuery = null;

        }

        component.set( 'v.record', record );
        component.set( 'v.sourceTypeURL', null );

        return Promise.all( promises );

    },

    handleSourceReportFolderChange : function( component ) {

        var helper = this;

        var promises = [];

        var sourceType = component.get( 'v.sourceType' );
        var report = component.get( 'v.sourceReport' );
        var folderId = component.get( 'v.sourceReportFolderId' );

        if ( sourceType == 'Report' ) {

            var reportFolderId = report && report.OwnerId && report.OwnerId.substring( 0, 15 );
            folderId = folderId && folderId.substring( 0, 15 );

            if ( folderId != reportFolderId ) {

                component.set( 'v.sourceReport', null );
                component.set( 'v.sourceReportId', null );
                component.set( 'v.sourceReportColumnName', null );
                component.set( 'v.record.sourceReportID', null );
                component.set( 'v.record.sourceReportColumnName', null );

            }

            promises.push( helper.getReportsByFolderAsync( component, folderId )
                .then( $A.getCallback( function( reports ) {

                    component.set( 'v.sourceReports', reports );
                    return helper.handleSourceReportChange( component );

                })).catch( $A.getCallback( function( err ) {

                    helper.toastMessage( 'Error Getting Reports By Folder', err, 'error' );

                }))
            );

        }

        return Promise.all( promises );

    },

    handleSourceReportChange : function( component ) {

        var helper = this;

        var promises = [];

        var sourceType = component.get( 'v.sourceType' );
        var reportId = component.get( 'v.sourceReportId' );

        if ( sourceType == 'Report' ) {

            if ( helper.isEmpty( reportId ) ) {

                component.set( 'v.sourceTypeURL', null );
                component.set( 'v.sourceReport', null );
                component.set( 'v.sourceReportColumns', null );
                component.set( 'v.sourceReportColumnName', null );
                component.set( 'v.record.sourceReportID', null );
                component.set( 'v.record.sourceReportColumnName', null );

            } else {

                promises.push( helper.getReportAsync( component, reportId )
                    .then( $A.getCallback( function( report ) {

                        component.set( 'v.sourceTypeURL', '/lightning/r/Report/' + report.Id + '/view' );
                        component.set( 'v.sourceReport', report );
                        component.set( 'v.record.sourceReportID', ( report.Id && report.Id.substring( 0, 15 ) ) );

                    })).catch( $A.getCallback( function( err ) {

                        helper.toastMessage( 'Error Getting Report', err, 'error' );

                    }))
                );

                promises.push( helper.getReportColumnsAsync( component, reportId )
                    .then( $A.getCallback( function( reportColumns ) {

                        component.set( 'v.sourceReportColumns', reportColumns );

                        var columnName = component.get( 'v.sourceReportColumnName' );
                        var columnFound = false;

                        for ( var i = 0; i < reportColumns.length; i++ ) {

                            if ( reportColumns[i].value == columnName ) {
                                columnFound = true;
                                break;
                            }
                        }

                        if ( !columnFound ) {
                            component.set( 'v.sourceReportColumnName', null );
                            component.set( 'v.record.sourceReportColumnName', null );
                        } else {
                            component.set( 'v.record.sourceReportColumnName', columnName );
                        }

                    })).catch( $A.getCallback( function( err ) {

                        helper.toastMessage( 'Error Getting Report Columns', err, 'error' );

                    }))
                );

            }

        }

        return Promise.all( promises );

    },

    handleSourceListViewSobjectTypeChange : function( component ) {

        var helper = this;

        var promises = [];

        var sourceType = component.get( 'v.sourceType' );
        var listView = component.get( 'v.sourceListView' );
        var sobjectType = component.get( 'v.sourceListViewSobjectType' );

        if ( sourceType == 'ListView' ) {

            if ( !$A.util.isUndefinedOrNull( listView ) && listView.SobjectType != sobjectType ) {

                component.set( 'v.sourceListViewId', null );
                component.set( 'v.record.sourceListViewID', null );

            }

            promises.push( helper.getListViewsByObjectAsync( component, sobjectType )
                .then( $A.getCallback( function( listViews ) {

                    component.set( 'v.sourceListViews', listViews );
                    return helper.handleSourceListViewChange( component );

                })).catch( $A.getCallback( function( err ) {

                    helper.toastMessage( 'Error Getting List Views By Object', err, 'error' );

                }))
            );

        }

        return Promise.all( promises );

    },

    handleSourceListViewChange : function( component ) {

        var helper = this;

        var promises = [];

        var sourceType = component.get( 'v.sourceType' );
        var listViewId = component.get( 'v.sourceListViewId' );

        if ( sourceType == 'ListView' ) {

            if ( helper.isEmpty( listViewId ) ) {

                component.set( 'v.sourceTypeURL', null );
                component.set( 'v.sourceListView', null );
                component.set( 'v.record.sourceListViewID', null );

            } else {

                promises.push( helper.getListViewAsync( component, listViewId )
                    .then( $A.getCallback( function( listView ) {

                        component.set( 'v.sourceTypeURL', '/lightning/o/' + listView.SobjectType + '/list?filterName=' + listView.Id );
                        component.set( 'v.sourceListView', listView );
                        component.set( 'v.record.sourceListViewID', ( listView.Id && listView.Id.substring( 0, 15 ) ) );

                    })).catch( $A.getCallback( function( err ) {

                        helper.toastMessage( 'Error Getting List View', err, 'error' );

                    }))
                );

            }

        }

        return Promise.all( promises );

    },

    // ----------------------------------------------------------------------------------

    handleTargetTypeChange : function( component ) {

        var helper = this;

        var promises = [];

        var targetType = component.get( 'v.targetType' );
        var targetApexType = component.get( 'v.targetApexType' );
        var targetActionName = component.get( 'v.targetInvocableAction' );

        var record = component.get( 'v.record' );

        // if true then we need to display prompt to user
        // to choose an object before we can show action options
        var targetTypeRequiresSobject = false;
        var targetTypeRequiresAction = false;

        if ( helper.isEmpty( targetType ) || targetType == 'Workflow' ) {

            targetTypeRequiresSobject = false;
            targetTypeRequiresAction = false;

            targetApexType = null;
            targetActionName = null;

            record.targetSobjectType = null;
            record.targetApexScript = null;

        } else if ( targetType == 'Flow' ) {

            targetTypeRequiresSobject = false;
            targetTypeRequiresAction = true;

            targetApexType = null;
            //targetActionName = null;

            record.targetSobjectType = null;
            record.targetApexScript = null;

        } else if ( targetType == 'QuickAction' ) {

            targetTypeRequiresSobject = true;
            targetTypeRequiresAction = true;

            targetApexType = null;
            //targetActionName = null;

            //record.targetSobjectType = null;
            record.targetApexScript = null;

        } else if ( targetType == 'EmailAlert' ) {

            targetTypeRequiresSobject = true;
            targetTypeRequiresAction = true;

            targetApexType = null;
            //targetActionName = null;

            //record.targetSobjectType = null;
            record.targetApexScript = null;

        } else if ( targetType == 'Apex' ) {

            targetTypeRequiresSobject = false;
            targetTypeRequiresAction = true;

            record.targetSobjectType = null;

            if ( targetApexType === 'Invocable' ) {

                targetTypeRequiresAction = true;
                record.targetApexScript = null;

            } else if ( targetApexType === 'Anonymous' ) {

                targetTypeRequiresAction = false;
                targetActionName = null;

                // provide a template as convenience
                if ( $A.util.isEmpty( record.targetApexScript ) ) {
                    record.targetApexScript = (
                        'void execute( List<Map<String, Object>> sourceRecordsBatch ) { \n' +
                        '    // your logic here \n' +
                        '} \n'
                    );
                }

            }

        }

        component.set( 'v.targetTypeRequiresSobject', targetTypeRequiresSobject );
        component.set( 'v.targetTypeRequiresAction', targetTypeRequiresAction );
        component.set( 'v.targetApexType', targetApexType );
        component.set( 'v.targetInvocableAction', targetActionName );

        record.targetActionName = targetActionName;
        component.set( 'v.record', record );

        promises.push( helper.renderTargetSobjectTypes( component ) );
        promises.push( helper.renderTargetInvocableActions( component ) );

        return Promise.all( promises );

    },

    /**
     * Determines if conditions are satisfactory to fetch and render
     * sobject options that have invocable actions. Designed to be called whenever
     * the target type requires sobject input field changes and once conditions met then options appear.
     */
    renderTargetSobjectTypes : function( component ) {

        var helper = this;

        var promises = [];

        var targetTypeRequiresSobject = component.get( 'v.targetTypeRequiresSobject' );

        if ( targetTypeRequiresSobject === true ) {

            var targetType = component.get( 'v.targetType' );

            promises.push( helper.getObjectsWithInvocableActionsAsync( component, targetType )
                .then( $A.getCallback( function( results ) {

                    component.set( 'v.targetSobjectTypes', results );

                }))
            );

        } else {

            component.set( 'v.targetSobjectType', null );
            component.set( 'v.targetSobjectTypes', null );

        }

        return Promise.all( promises );

    },

    /**
     * Determines if conditions are satisfactory to fetch and render
     * the target invocable action options. Designed to be called whenever
     * the target input fields change and once conditions met then options appear.
     */
    renderTargetInvocableActions : function( component ) {

        var helper = this;

        var promises = [];

        var targetType = component.get( 'v.targetType' );
        var targetApexType = component.get( 'v.targetApexType' );
        var targetTypeRequiresSobject = component.get( 'v.targetTypeRequiresSobject' );
        var targetTypeRequiresAction = component.get( 'v.targetTypeRequiresAction' );
        var targetSobjectType = component.get( 'v.targetSobjectType' );
        var targetAction = component.get( 'v.targetInvocableAction' );

        var isValidToRenderActions = true;

        if ( helper.isEmpty( targetType ) ||
             ( !targetTypeRequiresAction ) ||
             ( targetTypeRequiresSobject && helper.isEmpty( targetSobjectType ) ) ||
             ( targetType === 'Apex' && targetApexType !== 'Invocable' ) ) {

            isValidToRenderActions = false;

        }

        if ( isValidToRenderActions ) {

            promises.push( helper.getInvocableActionsAsync( component, targetType, ( targetSobjectType || '' ) )
                .then( $A.getCallback( function( actions ) {

                    component.set( 'v.targetInvocableActions', actions );

                    // if currently selected target action is not in this list then clear the field
                    var targetActionFound = actions.find( function( elmt ) { return elmt.value === targetAction; } );
                    component.set( 'v.targetInvocableAction', ( targetActionFound && targetActionFound.value ) );

                }))
            );

        } else {

            component.set( 'v.targetInvocableActions', null );

            // Don't clear selected target action here because of timing
            // this would clear out the record's initial value on component init.
            // Instead, we try to handle this in the controller function "handleTargetTypeChange"
            //component.set( 'v.targetInvocableAction', null );

        }

        component.set( 'v.isValidToRenderTargetInvocableActions', isValidToRenderActions );

        return Promise.all( promises );

    },

    renderTargetFieldMappingsAsync : function( component ) {

        var helper = this;

        var sourceType = component.get( 'v.sourceType' );
        var sourceReportId = component.get( 'v.sourceReportId' );
        var sourceListViewId = component.get( 'v.sourceListViewId' );
        var sourceSoqlQuery = component.get( 'v.record.sourceSoqlQuery' )

        var targetType = component.get( 'v.targetType' );
        var targetAction = component.get( 'v.targetInvocableAction' );
        var targetSobjectType = component.get( 'v.targetSobjectType' );

        var sourceFields = []; // columns from source report or list view
        var targetFields = []; // inputs from target action

        // provide empty option for source field mapping
        // so user can unmap a field without navigating away
        sourceFields.push({
            'label': '--None--',
            'vaue': null
        });

        return Promise.resolve()
            .then( $A.getCallback( function() {

                if ( sourceType == 'Report' ) {

                    component.set( 'v.sourceFieldsInputType', 'combobox' );

                    return helper.getReportColumnsAsync( component, sourceReportId )
                        .catch( $A.getCallback( function ( err ) {
                            throw new Error( 'Error getting report columns: ' + helper.unwrapAuraErrorMessage( err ) );
                        }));

                } else if ( sourceType == 'ListView' ) {

                    component.set( 'v.sourceFieldsInputType', 'combobox' );

                    return helper.getListViewColumnsAsync( component, sourceListViewId )
                        .catch( $A.getCallback( function ( err ) {
                            throw new Error( 'Error getting list view columns: ' + helper.unwrapAuraErrorMessage( err ) );
                        }));

                } else if ( sourceType == 'SOQL' ) {

                    component.set( 'v.sourceFieldsInputType', 'combobox' );

                    return helper.getSoqlQueryColumnsAsync( component, sourceSoqlQuery )
                        .catch( $A.getCallback( function ( err ) {
                            throw new Error( 'Error getting SOQL query columns: ' + helper.unwrapAuraErrorMessage( err ) );
                        }));

                } else if ( sourceType == 'Apex' ) {

                    component.set( 'v.sourceFieldsInputType', 'text' );

                    return null;

                }

            })).then( $A.getCallback( function( sourceFieldsResult ) {

                if ( !$A.util.isEmpty( sourceFieldsResult ) ) {
                    // performs in-place sort of array
                    sourceFieldsResult.sort( function( first, second ) {
                        return first.label.localeCompare( second.label );
                    });
                    sourceFields.push( ...sourceFieldsResult );
                }

            })).then( $A.getCallback( function() {

                return helper.getInvocableActionInputsAsync( component, targetType, ( targetAction || '' ), ( targetSobjectType || '' ) );

            })).then( $A.getCallback( function( targetFieldsResult ) {

                if ( !$A.util.isEmpty( targetFieldsResult ) ) {
                    // performs in-place sort of array
                    targetFieldsResult.sort( function( first, second ) {
                        return first.name.localeCompare( second.name );
                    });
                    targetFields.push( ...targetFieldsResult );
                }

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

    // ----------------------------------------------------------------------------------

    /**
     * Given an array of aura components representing inputs (have a v.value attribute)
     * then returns a validation result object with any errors for each component.
     */
    validateInputsAsync : function( component, inputCmps ) {

        var helper = this;

        var sourceType = component.get( 'v.sourceType' );
        var sourceTypeIsReport = ( sourceType === 'Report' );
        var sourceTypeIsListView = ( sourceType === 'ListView' );
        var sourceTypeIsSoqlQuery = ( sourceType === 'SOQL' );
        var sourceTypeIsApex = ( sourceType === 'Apex' );

        var targetType = component.get( 'v.targetType' );
        var targetTypeIsFlows = ( targetType === 'Flow' );
        var targetTypeIsWorkflows = ( targetType === 'Workflow' );
        var targetTypeIsQuickActions = ( targetType === 'QuickAction' );
        var targetTypeIsEmailAlerts = ( targetType === 'EmailAlert' );
        var targetTypeIsApex = ( targetType === 'Apex' );

        var targetApexType = component.get( 'v.targetApexType' );
        var targetApexTypeIsInvocable = ( targetApexType === 'Invocable' );
        var targetApexTypeIsAnonymous = ( targetApexType === 'Anonymous' );

        var targetTypeRequiresSobject = component.get( 'v.targetTypeRequiresSobject' );
        var targetTypeRequiresAction = component.get( 'v.targetTypeRequiresAction' );

        var scheduleFrequency = component.get( 'v.scheduleSelectionsFrequency' );
        var scheduleFrequenceIsScheduled = ( scheduleFrequency == 'Scheduled' || ( !$A.util.isUndefinedOrNull( scheduleFrequency ) && scheduleFrequency.length && scheduleFrequency[0] == 'Scheduled' ) );
        var scheduleFrequenceIsCustom = ( scheduleFrequency == 'Custom' || ( !$A.util.isUndefinedOrNull( scheduleFrequency ) && scheduleFrequency.length && scheduleFrequency[0] == 'Custom' ) );

        var inputScheduleWeekdayIsEmpty = helper.isEmpty( component.get( 'v.scheduleSelectionsDayOfWeek' ) );
        var inputScheduleDayOfMonthIsEmpty = helper.isEmpty( component.get( 'v.scheduleSelectionsDayOfMonth' ) );

        var objectDescribe = component.get( 'v.objectDescribe' );

        return Promise.all( inputCmps.map( function( inputCmp ) {

            var validationComponentResult = {
                hasError : false,
                message : null,
                component : inputCmp
            };

            var inputValidityAsync = Promise.resolve( validationComponentResult );

            if ( !$A.util.isUndefinedOrNull( inputCmp ) ) {

                var inputLabel = inputCmp.get( 'v.label' );
                var inputValue = inputCmp.get( 'v.value' );

                var inputIsEmpty = helper.isEmpty( inputValue );
                var inputIsInvalid = !inputCmp.checkValidity();

                // populate a default error message,
                // but don't assign to the validation component result
                // unless we indeed determine the input component is invalid
                var messageWhenValueMissing = inputLabel + ' is required.';

                switch ( inputCmp.getLocalId() ) {

                    // Details

                    case 'inputName':
                    case 'inputDeveloperName':
                    case 'inputBatchSize':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( inputIsEmpty || inputIsInvalid ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    // Source

                    case 'inputSourceType':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( inputIsEmpty || inputIsInvalid ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    // Source: Report

                    case 'inputSourceReportFolder':
                    case 'inputSourceReport':
                    case 'inputSourceReportColumn':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( sourceTypeIsReport && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    // Source: List View

                    case 'inputSourceListViewSobjectType':
                    case 'inputSourceListView':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( sourceTypeIsListView && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    // Source: SOQL Query

                    case 'inputSourceSoqlQuery':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( sourceTypeIsSoqlQuery && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        }).then( $A.getCallback( function( inputValidity ) {
                            // if we haven't already determined the field to be invalid
                            // then perform more rigorous soql query validation
                            if ( sourceTypeIsSoqlQuery && !inputValidity.invalid ) {
                                return helper.validateSoqlQueryAsync( component, inputValue )
                                    .then( $A.getCallback( function( validationResult ) {
                                        return {
                                            'invalid': !validationResult.valid,
                                            'messageWhenInvalid': validationResult.message
                                        };
                                    }));
                            }
                            return inputValidity;
                        }));
                        break;

                    // Source: Apex Class

                    case 'inputSourceApexClass':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( sourceTypeIsApex && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    // Target

                    case 'inputTargetType':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( inputIsEmpty || inputIsInvalid ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    case 'inputTargetSobjectType':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( targetTypeRequiresSobject && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    case 'inputTargetAction':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( targetTypeRequiresAction && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    // Target: Apex

                    case 'inputTargetApexType':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( targetTypeIsApex && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    case 'inputTargetApexScript':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( targetTypeIsApex && targetApexTypeIsAnonymous && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    // Target: Field Mappings

                    case 'inputMappingSourceFieldName':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( ( inputIsEmpty && inputCmp.get( 'v.required' ) ) || inputIsInvalid ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    // Schedule

                    case 'inputScheduleFrequency':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( inputIsEmpty || inputIsInvalid ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    case 'inputScheduleHourOfDay':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( scheduleFrequenceIsScheduled && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    case 'inputScheduleWeekday':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( scheduleFrequenceIsScheduled && ( ( inputIsEmpty == inputScheduleDayOfMonthIsEmpty ) || inputIsInvalid ) ),
                            'messageWhenInvalid': `Select options for either "${objectDescribe.fields.Schedule_DayOfWeek__c.label}" or "${objectDescribe.fields.Schedule_DayOfMonth__c.label}" but not both. Exactly one is required.`
                        });
                        break;

                    case 'inputScheduleDayOfMonth':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( scheduleFrequenceIsScheduled && ( ( inputIsEmpty == inputScheduleWeekdayIsEmpty ) || inputIsInvalid ) ),
                            'messageWhenInvalid': `Select options for either "${objectDescribe.fields.Schedule_DayOfWeek__c.label}" or "${objectDescribe.fields.Schedule_DayOfMonth__c.label}" but not both. Exactly one is required.`
                        });
                        break;

                    case 'inputScheduleMonthOfYear':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( scheduleFrequenceIsScheduled && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    case 'inputScheduleCron':
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( scheduleFrequenceIsCustom && ( inputIsEmpty || inputIsInvalid ) ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                    // Default

                    default:
                        inputValidityAsync = Promise.resolve({
                            'invalid': ( inputIsInvalid ),
                            'messageWhenInvalid': messageWhenValueMissing
                        });
                        break;

                }

                return Promise.resolve( inputValidityAsync )
                    .then( $A.getCallback( function( inputValidity ) {

                        // Consider the input invalid based on either our custom logic above
                        // or that the input component's natural validation (e.g. required="true") is violated.
                        validationComponentResult.hasError = inputValidity.invalid;
                        validationComponentResult.messageWhenInvalid = inputValidity.messageWhenInvalid;

                        return validationComponentResult;

                    }));

            } else {

                return inputValidityAsync;

            }

        })).then( $A.getCallback( function( validationComponentResults ) {

            var validationResult = {
                hasErrors : false,
                components : validationComponentResults
            };

            validationComponentResults.forEach( function( validationComponentResult, idx ) {
                validationResult.hasErrors = ( validationResult.hasErrors || validationComponentResult.hasError );
            });

            return validationResult;

        }));

    },

    // ----------------------------------------------------------------------------------

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

            // parse the "NN." from the values used for sorting then join them by commas.
            // exactly one of dayOfMonth or dayOfWeek must be specified and the other must be '?'

            record.scheduleCron = null;
            record.scheduleSecondOfMinute = '0';
            record.scheduleMinuteOfHour = '0';
            record.scheduleHourOfDay = scheduleHourOfDay.map( function( hourOfDay ) { return hourOfDay.split('.')[1]; } ).join(',');
            record.scheduleDayOfMonth = scheduleDayOfMonth.map( function( dayOfMonth ) { return dayOfMonth.split('.')[1]; } ).join(',') || '?';
            record.scheduleMonthOfYear = scheduleMonthOfYear.map( function( monthOfYear ) { return monthOfYear.split('.')[1]; } ).join(',');
            record.scheduleDayOfWeek = scheduleDayOfWeek.map( function( dayOfWeek ) { return dayOfWeek.split('.')[1]; } ).join(',') || '?';

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

        /*
         * https://success.salesforce.com/issues_view?id=a1p30000000SyhIAAS
         * Due to known issue that execution contexts started from Apex REST endpoints
         * cannot schedule or abort jobs, then my first workaround attempt was
         * to modify the trigger to emit a platform event to get into a different
         * context. However, platform events run as the "Automated Process" user.
         * That wouldn't normally be a problem except when our jobs run they make
         * API callouts using the either a Named Credential or the user's Session ID.
         * If the configuration record doesn't use Named Credentials (one of the major
         * features of Version 2.0), then the "Automated Process" user's session id is null
         * and the http callout fails. Womp womp.
         *
         * Therefore, for saving the configuration record, instead of going through
         * the Apex REST API and instead of the trigger emitting a platform event,
         * this method goes through normal AuraEnabled apex method and the trigger
         * schedules and aborts the job synchronously. This ensures the job itself
         * runs as a real user with a valid session id.
         */

        // return helper.enqueueRestRequest( component, 'saveConfiguration', {
        //     'wrapperJson' : record,
        //     'fieldMappingsJson' : targetFieldMappings
        // });
        return helper.enqueueAction( component, 'c.saveConfiguration', {
            'wrapperJson' : JSON.stringify( record ),
            'fieldMappingsJson' : JSON.stringify( targetFieldMappings )
        });

    },

    // ----------------------------------------------------------------------------------

    getObjectDescribeAsync : function( component ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getConfigurationObjectDescribe', {
        });

    },

    getRecordAsync : function( component, recordId ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getConfiguration', {
            'recordId' : recordId
        });

    },

    // ----------------------------------------------------------------------------------

    getObjectNamesAsync : function( component ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getObjectNames', {
        });

    },

    getObjectNamesWithListViewsAsync : function( component ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getObjectNamesWithListViews', {
        });

    },

    getListViewsByObjectAsync : function( component, objectName ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getListViewsByObject', {
            'objectName' : objectName
        });

    },

    getListViewAsync : function( component, listViewId ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getListView', {
            'recordId' : listViewId
        });

    },

    getListViewColumnsAsync : function( component, listViewId ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getListViewColumns', {
            'listViewId' : listViewId
        });

    },

    // ----------------------------------------------------------------------------------

    getReportFoldersAsync : function( component ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getReportFolders', {
        });

    },

    getReportsByFolderAsync : function( component, folderId ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getReportsByFolder', {
            'folderId' : folderId
        });

    },

    getReportAsync : function( component, reportId ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getReport', {
            'recordId' : reportId
        });

    },

    getReportColumnsAsync : function( component, reportId ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getReportColumns', {
            'reportId' : reportId
        });

    },

    // ----------------------------------------------------------------------------------

    validateSoqlQueryAsync : function( component, query ) {

        // This used to make async calls, but it doesn't anymore.
        // I've kept the method name, signature and response
        // the same so as to minimize impact to other parts of the
        // codebase and because this might become async in the future...

        var helper = this;

        return Promise.resolve()
            .then( $A.getCallback( function() {

                if ( helper.isEmpty( query ) ) {

                    return {
                        'valid': false,
                        'message': 'SOQL Query is required.'
                    };

                } else {

                    // Originally, I used third-party soql-parse library
                    // to parse the query to know things like what the
                    // SELECT clause was, and aliases of functions, etc.
                    // However, the parser was not complete and the effort
                    // to make a fully compliant SOQL parser is out of scope
                    // for Mass Action Scheduler. Therefore, my approach now
                    // is to brute force inspect the query for simple patterns
                    // so that I can deduce what fields are being selected.
                    // Whether the query is valid is another story; we'll find
                    // out soon enough once the configuration runs :)

                    // ================================================================= //
                    // Caution with Regular Expressions with asterisks followed by /     //
                    // https://twitter.com/DouglasCAyers/status/1147002313158090752      //
                    // ================================================================= //

                    // normalize the spaces in the query string (e.g. no new lines or tabs)
                    // and uppercase the string so that we can be case-insensitive in our checks
                    let trimmedQuery = (
                        query                                   // original query
                        .replace( /(\s*(\W+)\s*)/g, ' $2 ' )    // include one whitespace around non-words e.g. "(SELECT" => " ( SELECT"
                        .replace( /\s+/g, ' ' )                 // remove new lines, redundant whitespace
                        .trim()                                 // trim whitespace from start/end of query
                        .toUpperCase()                          // uppercase everything so we're case-insensitive
                    );

                    // SOQL queries must start with SELECT, quick check this isn't a SOSL query
                    if ( !trimmedQuery.startsWith( 'SELECT ' ) ) {
                        return {
                            'valid': false,
                            'message': 'SOQL Query must start with a SELECT clause.'
                        };
                    }

                    let indexOfFromClause = trimmedQuery.indexOf( ' FROM ' );

                    // Make sure there's a FROM clause because
                    // the real validation is going to be inspecting
                    // the text between the SELECT and FROM statements
                    if ( indexOfFromClause < 0 ) {
                        return {
                            'valid': false,
                            'message': 'SOQL Query must include a FROM clause.'
                        };
                    }

                    // At this point we know we have both keywords "SELECT" and "FROM" in our query string
                    // so now let's grab what's between them to determine what fields were selected
                    let selectClause = trimmedQuery.substring( 'SELECT '.length, indexOfFromClause );

                    // SOQL allows child relationship sub-queries in the SELECT clause.
                    // Mass Action Scheduler doesn't support this, and it makes this brute
                    // force parsing of the query to determine the actual selected fields.
                    // Therefore, we don't support sub-queries in the SELECT clause.
                    if ( selectClause.includes( ' SELECT ' ) ) {
                        return {
                            'valid': false,
                            'message': 'Parent-to-child relationship subqueries are not supported.'
                        };
                    }

                    // Given we have what we need, let's determine the selected fields.
                    let selectedFields = (
                        selectClause
                        .split( ',' )
                        .filter( field => {
                            // exclude non-aliased functions
                            return !( /\)\s*$/.test( field ) )
                        })
                        .map( field => {
                            return (
                                field.includes( ')' ) ?                             // is function alias?
                                field.substring( field.lastIndexOf( ')' ) + 1 ) :   // grab the alias
                                field                                               // it's just a field
                            ).replace( /\s+/g, '' )                                 // remove all whitespace
                        })

                    );

                    return {
                        'valid': true,
                        'selectedFields': selectedFields
                    };

                }

            }));

    },

    getSoqlQueryResultsAsync : function( component, query, batchSize ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getSoqlQueryResults', {
            'query' : query,
            'batchSize' : batchSize
        });

    },

    getSoqlQueryColumnsAsync : function( component, soqlQuery ) {

        var helper = this;

        return Promise.resolve()
            .then( $A.getCallback( function() {

                return helper.validateSoqlQueryAsync( component, soqlQuery )
                    .then( $A.getCallback( function( validationResult ) {

                        if ( validationResult.valid ) {

                            return validationResult.selectedFields.map( fieldName => {
                                return {
                                    'label': fieldName,
                                    'value': fieldName
                                }
                            });

                        } else {

                            throw new Error( validationResult.message );

                        }

                    })).catch( $A.getCallback( function( err ) {

                        throw new Error( 'Error validating SOQL query: ' + helper.unwrapAuraErrorMessage( err ) );

                    }));

            }));

    },

    // ----------------------------------------------------------------------------------

    getNamedCredentialsAsync : function( component ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getNamedCredentials', {
        });

    },

    getObjectsWithInvocableActionsAsync : function( component, actionType ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getObjectsWithInvocableActions', {
            'actionType' : actionType
        });

    },

    getInvocableActionsAsync : function( component, actionType, objectName ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getInvocableActions', {
            'actionType' : actionType,
            'objectName' : objectName
        });

    },

    getInvocableActionInputsAsync : function( component, actionType, actionName, objectName ) {

        var helper = this;

        return helper.enqueueRestRequest( component, 'getInvocableActionInputs', {
            'actionType' : actionType,
            'actionName' : actionName,
            'objectName' : objectName
        });

    },

    // ----------------------------------------------------------------------------------

    /**
     * The $A.util.isEmpty() function does not check for blank strings (only whitespace).
     * This method trims string arguments first so '   ' is considered empty.
     */
    isEmpty : function( value ) {
        if ( ( typeof value ).toLowerCase() === 'string' ) {
            return $A.util.isEmpty( value.trim() );
        } else {
            return $A.util.isEmpty( value );
        }
    },

    showSpinner : function( component ) {

        $A.util.removeClass( component.find( 'spinner' ), 'slds-hide' );

        // Minimize flickering of the spinner hiding/showing
        // quickly in succession of multiple async events.
        // As you'd do with a type-ahead widget, when an async event
        // starts and the spinner is shown then clear the timeout
        // that would hide the spinner. This avoids the flickering.
        // When the async event ends, it'll call hide spinner again
        // which will start a new timer.
        let spinnerTimerIds = component.get( 'v.spinnerTimerIds' );
        spinnerTimerIds.forEach( ( spinnerTimerId ) => clearTimeout( spinnerTimerId ) );
        component.set( 'v.spinnerTimerIds', [] );

    },

    hideSpinner : function( component ) {

        // see comments in `showSpinner` about minimizing flickering
        let spinnerTimerId = setTimeout(
            $A.getCallback( function() {
                $A.util.addClass( component.find( 'spinner' ), 'slds-hide' );
            }),
            250
        );

        let spinnerTimerIds = component.get( 'v.spinnerTimerIds' );
        spinnerTimerIds.push( spinnerTimerId );
        component.set( 'v.spinnerTimerIds', spinnerTimerIds );

    },

    toastMessage : function( title, message, type ) {

        // https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/ref_force_showToast.htm

        var helper = this;

        // convenience so code can toast errors without
        // themselves figuring out how to get the real message from them
        if ( message instanceof Error ) {
            message = helper.unwrapAuraErrorMessage( message );
        }

        $A.get( 'e.force:showToast' ).setParams({
            title : ( title || 'Message' ),
            message : ( message || '' ),
            type : ( type || 'info' )
        }).fire();

    },

    navigateToRecord : function( recordId ) {

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

    /**
     * For posting REST request to the MA_EditConfigRestController apex class.
     *
     * @param component
     *      The Lightning component with a 'urlInfo' and 'lc_api' attributes.
     *      'urlInfo' is used to generate the REST API URL.
     *      'lc_api' is used to invoke the REST API as workaround to Lightning session ids.
     * @param operation
     *      Name of the actual action to invoke in the REST controller.
     * @param params
     *      Parameters to pass to the actual action to invoke.
     * @returns a promise.
     */
    enqueueRestRequest : function( component, operation, params ) {

        var helper = this;

        helper.showSpinner( component );

        return Promise.resolve()
            .then( $A.getCallback( function() {

                // return cached value if we've retrieved it before,
                // otherwise fetch the url info as a promise
                var urlInfo = component.get( 'v.urlInfo' );

                if ( helper.isEmpty( urlInfo ) ) {
                    return component.find( 'lc_url' ).getUrlInfo();
                } else {
                    return urlInfo;
                }

            })).then( $A.getCallback( function( urlInfo ) {

                component.set( 'v.urlInfo', urlInfo );

                var nsslash = ( urlInfo.namespace ? urlInfo.namespace + '/' : '' );

                return component.find( 'lc_api' ).restRequest({
                    'url' : urlInfo.orgDomainURL + '/services/apexrest/' + nsslash + 'config/edit?operation=' + operation,
                    'method' : 'POST',
                    'body' : JSON.stringify( ( params || {} ) )
                });

            })).then( $A.getCallback( function( response ) {

                helper.hideSpinner( component );
                if ( response.success ) {
                    return response.result;
                } else {
                    throw new Error( response.error );
                }

            })).catch( $A.getCallback( function( err ) {

                helper.hideSpinner( component );
                console.error( 'Error enqueuing rest request: ' + JSON.stringify({
                    'operation' : operation,
                    'params' : params,
                    'error' : err.message
                }, null, 2));
                throw err;

            }));

    },

    /**
     * For invoking @AuraEnabled apex actions in a normal
     * Lightning component fashion.
     *
     * @param component
     *      The Lightning component that specifies the Apex controller
     *      of the @AuraEnabled method to invoke.
     * @param actionName
     *      The @AuraEnabled method name.
     * @param params
     *      The @AuraEnabled method parameters.
     * @returns a promise.
     */
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
                console.error( 'Error: ' + ( errors.message || errors ) );
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
                text = ( errors.message || errors );
            }
        }
        return text;
    },

    /**
     * When using $A.getCallback() function, if an error is thrown
     * then it wraps the error in an AuraError. The AuraError, unfortunately,
     * has a new message property whose value is "Error in $A.getCallback[YOUR_ORIGINAL_ERROR_MESSAGE]".
     * The only way to obtain YOUR_ORIGINAL_ERROR_MESSAGE is to substring
     * the AuraError text out of its message.
     */
    unwrapAuraErrorMessage : function( err ) {

        var message = err.message;

        var startStr = 'Error in $A.getCallback() [';
        var endStr = ']';

        var startIdx = err.message.indexOf( startStr );
        var endIdx = err.message.lastIndexOf( endStr );

        if ( startIdx >= 0 && endIdx >= 0 ) {
            message = err.message.substring( startIdx + startStr.length, endIdx );
        }

        return message;
    }
})
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