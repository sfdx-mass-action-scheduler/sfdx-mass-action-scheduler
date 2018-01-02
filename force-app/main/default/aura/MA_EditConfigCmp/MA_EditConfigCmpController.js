({
    doInit : function( component, event, helper ) {

        var recordId = component.get( 'v.recordId' );

        // initialize wizard to first step
        var wizard = component.find( 'wizard' );
        wizard.moveToStage( 0 );
        component.set( 'v.wizardActiveStageIndex', 0 );

        helper.getObjectDescribeAsync( component )
            .then( $A.getCallback( function( objectDescribe ) {

                component.set( 'v.objectDescribe', objectDescribe );

            }));

        helper.getRecordAsync( component, recordId )
            .then( $A.getCallback( function( record ) {

                component.set( 'v.record', record );
                component.set( 'v.sourceType', record.sourceType );
                component.set( 'v.targetType', record.targetType );
                component.set( 'v.targetSobjectType', record.targetSobjectType );
                component.set( 'v.targetInvocableAction', record.targetActionName );

                if ( !$A.util.isUndefinedOrNull( record.sourceReportID ) ) {

                    helper.getReportAsync( component, record.sourceReportID )
                        .then( $A.getCallback( function( report ) {

                            if ( !$A.util.isUndefinedOrNull( report ) ) {
                                component.set( 'v.sourceReport', report );
                                component.set( 'v.sourceReportId', ( report.Id && report.Id.substring( 0, 15 ) ) );
                                component.set( 'v.sourceReportFolderId', ( report.OwnerId && report.OwnerId.substring( 0, 15 ) ) );
                                component.set( 'v.sourceReportColumnName', record.sourceReportColumnName );
                            }

                        }));

                }

                if ( !$A.util.isUndefinedOrNull( record.sourceListViewID ) ) {

                    helper.getListViewAsync( component, record.sourceListViewID )
                        .then( $A.getCallback( function( listView ) {

                            if ( !$A.util.isUndefinedOrNull( listView ) ) {
                                component.set( 'v.sourceListView', listView );
                                component.set( 'v.sourceListViewId', ( listView.Id && listView.Id.substring( 0, 15 ) ) );
                                component.set( 'v.sourceListViewSobjectType', listView.SobjectType );
                            }

                        }));

                }

                helper.initScheduleOptions( component );

            }));

        helper.getNamedCredentialsAsync( component )
            .then( $A.getCallback( function( namedCredentials ) {

                component.set( 'v.targetNamedCredentials', namedCredentials );

            }));

    },

    handleNavigationButtonClick : function( component, event, helper ) {

        var wizard = component.find( 'wizard' );
        var currentStageIndex = wizard.get( 'v.activeChevron' );

        var button = event.getSource();
        var buttonLabel = button.get( 'v.label' );

        if ( buttonLabel == 'Previous' ) {

            wizard.moveToStage( currentStageIndex - 1 );

        } else if ( buttonLabel == 'Next' ) {

            var isValidToProceed = true;
            var inputCmps = []; // fields to validate to proceed to next step

            if ( currentStageIndex === 0 ) {                // Choose Source

                inputCmps = [
                    component.find( 'inputName' ),
                    component.find( 'inputSourceType' ),
                    component.find( 'inputSourceReportFolder' ),
                    component.find( 'inputSourceReport' ),
                    component.find( 'inputSourceReportColumn' ),
                    component.find( 'inputSourceListViewSobjectType' ),
                    component.find( 'inputSourceListView' )
                ];

            } else if ( currentStageIndex === 1 ) {         // Choose Action

                inputCmps = [
                    component.find( 'inputTargetNamedCredential' ),
                    component.find( 'inputTargetType' ),
                    component.find( 'inputTargetSobjectType' ),
                    component.find( 'inputTargetAction' )
                ];

            } else if ( currentStageIndex === 2 ) {         // Field Mappings

                var inputSourceFieldNames = component.find( 'inputMappingSourceFieldName' );

                if ( $A.util.isArray( inputSourceFieldNames ) ) {
                    for ( var i = 0; i < inputSourceFieldNames.length; i++ ) {
                        inputCmps.push( inputSourceFieldNames[i] );
                    }
                } else {
                    inputCmps.push( inputSourceFieldNames );
                }

            }

            isValidToProceed = ( helper.validateInputs( component, inputCmps ) && isValidToProceed );

            if ( isValidToProceed ) {

                wizard.advanceProgress();

                // if advancing to field mappings section then
                // determine the action inputs and any current mappings
                if ( currentStageIndex === 1 ) {
                    helper.renderTargetFieldMappings( component );
                }

            } else {

                helper.toastMessage( 'Step Incomplete', 'Please fill out all required fields before proceeding to next step.', 'error' );

            }

        }

    },

    handleSaveButtonClick : function( component, event, helper ) {

        var inputCmps = [
            component.find( 'inputScheduleFrequency' ),
            component.find( 'inputScheduleHourOfDay' ),
            component.find( 'inputScheduleWeekday' ),
            component.find( 'inputScheduleMonthOfYear' ),
            component.find( 'inputScheduleCron' )
        ];

        var isValidToSave = helper.validateInputs( component, inputCmps );

        if ( isValidToSave ) {

            helper.saveRecordAsync( component )
                .then( $A.getCallback( function( result ) {

                    if ( result.success ) {

                        helper.toastMessage( 'Save Successful', '', 'success' );

                        // Cause lightning data service to invalidate it's cache.
                        // I added this after realizing the compact layout was not
                        // picking up changes to fields by this component.
                        // I started out firing the force:refreshView event but
                        // that only worked if the record already existed, if we
                        // just saved a new record then we needed to still navigate to it.
                        // And I didn't know how to listen for the refreshView event to complete
                        // but I did find that I could use a callback in the LDS reloadRecord method.
                        var lds = component.find( 'lds' );
                        lds.set( 'v.recordId', result.recordId );
                        lds.reloadRecord( true, function() {
                            helper.navigateToRecord( result.recordId );
                        });

                    }

                })).catch( $A.getCallback( function( error ) {

                    helper.toastMessage( 'Error', error, 'error' );

                }));

        } else {

            helper.toastMessage( 'Step Incomplete', 'Please fill out all required fields before saving.', 'error' );

        }

    },

    // ----------------------------------------------------------------------------------

    handleInputFieldChanged : function( component, event, helper ) {

        var inputCmp = event.getSource();

        helper.validateInputs( component, [ inputCmp ] );

    },

    // ----------------------------------------------------------------------------------

    handleSourceTypeChange : function( component, event, helper ) {

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

            if ( $A.util.isEmpty( component.get( 'v.sourceReportFolders' ) ) ) {

                helper.getReportFoldersAsync( component )
                    .then( $A.getCallback( function( reportFolders ) {

                        component.set( 'v.sourceReportFolders', reportFolders );

                    }));

            }

        }

        if ( sourceType != 'ListView' ) {

            record.sourceListViewID = null;

            component.set( 'v.sourceListView', null );
            component.set( 'v.sourceListViewId', null );
            component.set( 'v.sourceListViewSobjectType', null );

        } else {

            if ( $A.util.isEmpty( component.get( 'v.sourceListViewSobjectTypes' ) ) ) {

                helper.getObjectNamesAsync( component )
                    .then( $A.getCallback( function( objectNames ) {

                        component.set( 'v.sourceListViewSobjectTypes', objectNames );

                    }));

            }

        }

        component.set( 'v.record', record );
        component.set( 'v.sourceTypeURL', null );

    },

    // ----------------------------------------------------------------------------------

    handleSourceReportFolderChange : function( component, event, helper ) {

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

            helper.getReportsByFolderAsync( component, folderId )
                .then( $A.getCallback( function( reports ) {

                    component.set( 'v.sourceReports', reports );

                }));

        }

    },

    handleSourceReportChange : function( component, event, helper ) {

        var sourceType = component.get( 'v.sourceType' );
        var reportId = component.get( 'v.sourceReportId' );

        if ( sourceType == 'Report' ) {

            if ( $A.util.isEmpty( reportId ) ) {

                component.set( 'v.sourceTypeURL', null );
                component.set( 'v.sourceReport', null );
                component.set( 'v.sourceReportColumns', null );
                component.set( 'v.sourceReportColumnName', null );
                component.set( 'v.record.sourceReportID', null );
                component.set( 'v.record.sourceReportColumnName', null );

            } else {

                helper.getReportAsync( component, reportId )
                    .then( $A.getCallback( function( report ) {

                        component.set( 'v.sourceTypeURL', '/one/one.app#/sObject/' + report.Id + '/view' );
                        component.set( 'v.sourceReport', report );
                        component.set( 'v.record.sourceReportID', ( report.Id && report.Id.substring( 0, 15 ) ) );

                    }));

                helper.getReportColumnsAsync( component, reportId )
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

                    }));

            }

        }

    },

    // -----------------------------------------------------------------

    handleSourceListViewSobjectTypeChange : function( component, event, helper ) {

        var sourceType = component.get( 'v.sourceType' );
        var listView = component.get( 'v.sourceListView' );
        var sobjectType = component.get( 'v.sourceListViewSobjectType' );

        if ( sourceType == 'ListView' ) {

            if ( !$A.util.isUndefinedOrNull( listView ) && listView.SobjectType != sobjectType ) {

                component.set( 'v.sourceListViewID', null );
                component.set( 'v.record.sourceListViewID', null );

            }

            helper.getListViewsByObjectAsync( component, sobjectType )
                .then( $A.getCallback( function( listViews ) {

                    component.set( 'v.sourceListViews', listViews );

                }));

        }

    },

    handleSourceListViewChange : function( component, event, helper ) {

        var sourceType = component.get( 'v.sourceType' );
        var listViewId = component.get( 'v.sourceListViewId' );

        if ( sourceType == 'ListView' ) {

            if ( $A.util.isEmpty( listViewId ) ) {

                component.set( 'v.sourceTypeURL', null );
                component.set( 'v.sourceListView', null );
                component.set( 'v.record.sourceListViewID', null );

            } else {

                helper.getListViewAsync( component, listViewId )
                    .then( $A.getCallback( function( listView ) {

                        component.set( 'v.sourceTypeURL', '/one/one.app#/sObject/' + listView.SobjectType + '/list?filterName=' + listView.Id );
                        component.set( 'v.sourceListView', listView );
                        component.set( 'v.record.sourceListViewID', ( listView.Id && listView.Id.substring( 0, 15 ) ) );

                    }));

            }

        }

    },

    // ----------------------------------------------------------------------------------

    handleTargetTypeChange : function( component, event, helper ) {

        var targetType = component.get( 'v.targetType' );
        var record = component.get( 'v.record' );

        // if true then we need to display prompt to user
        // to choose an object before we can show action options
        var targetTypeRequiresSobject = false;
        var targetTypeRequiresAction = false;

        if ( $A.util.isEmpty( targetType ) || targetType == 'Workflow' ) {

            targetTypeRequiresSobject = false;
            targetTypeRequiresAction = false;

            record.targetActionName = null;
            record.targetSobjectType = null;

        } else if ( targetType == 'Flow' ) {

            targetTypeRequiresSobject = false;
            targetTypeRequiresAction = true;

            //record.targetActionName = null;
            record.targetSobjectType = null;

        } else if ( targetType == 'QuickAction' ) {

            targetTypeRequiresSobject = true;
            targetTypeRequiresAction = true;

            //record.targetActionName = null;
            //record.targetSobjectType = null;

        } else if ( targetType == 'EmailAlert' ) {

            targetTypeRequiresSobject = true;
            targetTypeRequiresAction = true;

            //record.targetActionName = null;
            //record.targetSobjectType = null;

        } else if ( targetType == 'Apex' ) {

            targetTypeRequiresSobject = false;
            targetTypeRequiresAction = true;

            //record.targetActionName = null;
            record.targetSobjectType = null;

        }

        component.set( 'v.targetTypeRequiresSobject', targetTypeRequiresSobject );
        component.set( 'v.targetTypeRequiresAction', targetTypeRequiresAction );
        component.set( 'v.record', record );

        helper.renderTargetSobjectTypes( component );
        helper.renderTargetInvocableActions( component );

    },

    handleTargetSobjectTypeChange : function( component, event, helper ) {

        helper.renderTargetInvocableActions( component );

    },

    handleTargetTypeRequiresSobjectChange : function( component, event, helper ) {

        helper.renderTargetSobjectTypes( component );

    }

})