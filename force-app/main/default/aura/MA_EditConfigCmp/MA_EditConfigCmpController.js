/*
Author: Doug Ayers
Website: https://douglascayers.com
GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
License: BSD 3-Clause License
 */
({
    onInit : function( component, event, helper ) {

        var recordId = component.get( 'v.recordId' );

        // initialize wizard to first step
        var wizard = component.find( 'wizard' );
        wizard.moveToStage( 0 );
        component.set( 'v.wizardActiveStageIndex', 0 );

        Promise.resolve()
            .then( $A.getCallback( function() {

                let promises = [];

                promises.push( helper.getObjectDescribeAsync( component )
                    .then( $A.getCallback( function( objectDescribe ) {

                        component.set( 'v.objectDescribe', objectDescribe );

                    })).catch( $A.getCallback( function( err ) {

                        helper.toastMessage( 'Error Getting Object Describe', err, 'error' );

                    }))
                );

                promises.push( helper.getRecordAsync( component, recordId )
                    .then( $A.getCallback( function( record ) {

                        component.set( 'v.record', record );
                        component.set( 'v.sourceType', record.sourceType );
                        component.set( 'v.targetType', record.targetType );
                        component.set( 'v.targetSobjectType', record.targetSobjectType );
                        component.set( 'v.targetInvocableAction', record.targetActionName );

                        if ( record.targetType === 'Apex' ) {

                            if ( !$A.util.isEmpty( record.targetActionName ) ) {
                                component.set( 'v.targetApexType', 'Invocable' );
                            }
                            else if ( !$A.util.isEmpty( record.targetApexScript ) ) {
                                component.set( 'v.targetApexType', 'Anonymous' );
                            }

                        }

                        helper.initScheduleOptions( component );

                        return record;

                    })).then( $A.getCallback( function( record ) {

                        if ( !$A.util.isUndefinedOrNull( record.sourceReportID ) ) {

                            return helper.getReportAsync( component, record.sourceReportID )
                                .then( $A.getCallback( function( report ) {

                                    if ( !$A.util.isUndefinedOrNull( report ) ) {
                                        component.set( 'v.sourceReport', report );
                                        component.set( 'v.sourceReportId', ( report.Id && report.Id.substring( 0, 15 ) ) );
                                        component.set( 'v.sourceReportFolderId', ( report.OwnerId && report.OwnerId.substring( 0, 15 ) ) );
                                        component.set( 'v.sourceReportColumnName', record.sourceReportColumnName );
                                    }

                                })).catch( $A.getCallback( function( err ) {

                                    helper.toastMessage( 'Error Getting Report', err, 'error' );

                                }));

                        }

                        if ( !$A.util.isUndefinedOrNull( record.sourceListViewID ) ) {

                            return helper.getListViewAsync( component, record.sourceListViewID )
                                .then( $A.getCallback( function( listView ) {

                                    if ( !$A.util.isUndefinedOrNull( listView ) ) {
                                        component.set( 'v.sourceListView', listView );
                                        component.set( 'v.sourceListViewId', ( listView.Id && listView.Id.substring( 0, 15 ) ) );
                                        component.set( 'v.sourceListViewSobjectType', listView.SobjectType );
                                    }

                                })).catch( $A.getCallback( function( err ) {

                                    helper.toastMessage( 'Error Getting List View', err, 'error' );

                                }));

                        }

                    })).then( $A.getCallback( function() {

                        // avoid race condition where as the page loads,
                        // several change handlers call controller methods
                        // and those methods end up reading/writing attribtues
                        // before the above async operations have completed.
                        // https://github.com/douglascayers-org/sfdx-mass-action-scheduler/issues/94

                        component.set( 'v.didInitConfig', true );

                        return Promise.all([
                            helper.handleSourceTypeChange( component ),
                            helper.handleTargetTypeChange( component )
                        ]);

                    })).catch( $A.getCallback( function( err ) {

                        helper.toastMessage( 'Error Getting Mass Action Configuration', err, 'error' );

                    }))
                );

                promises.push( helper.getNamedCredentialsAsync( component )
                    .then( $A.getCallback( function( namedCredentials ) {

                        var emptyOption = {
                            'label': '--None--',
                            'value': null
                        };

                        component.set( 'v.targetNamedCredentials', [ emptyOption ].concat( namedCredentials ) );

                    })).catch( $A.getCallback( function( err ) {

                        helper.toastMessage( 'Error Getting Named Credentials', err, 'error' );

                    }))
                );

                return Promise.all( promises );

            })).catch( $A.getCallback( function( err ) {

                helper.toastMessage( 'Error initializing component', err, 'error' );

            }));

    },

    handleNavigationButtonClick : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        var wizard = component.find( 'wizard' );
        var currentStageIndex = wizard.get( 'v.activeChevron' );

        var button = event.getSource();
        var buttonLabel = button.get( 'v.label' );

        if ( buttonLabel == 'Previous' ) {

            wizard.moveToStage( currentStageIndex - 1 );

        } else if ( buttonLabel == 'Next' ) {

            var inputCmps = []; // fields to validate to proceed to next step

            if ( currentStageIndex === 0 ) {                // Details

                inputCmps = [
                    component.find( 'inputName' ),
                    component.find( 'inputDeveloperName' ),
                    component.find( 'inputDescription' ),
                    component.find( 'inputActive' ),
                    component.find( 'inputBatchSize' ),
                    component.find( 'inputNamedCredential' )
                ];

            } else if ( currentStageIndex === 1 ) {         // Choose Source

                inputCmps = [
                    component.find( 'inputSourceType' ),
                    component.find( 'inputSourceReportFolder' ),
                    component.find( 'inputSourceReport' ),
                    component.find( 'inputSourceReportColumn' ),
                    component.find( 'inputSourceListViewSobjectType' ),
                    component.find( 'inputSourceListView' ),
                    component.find( 'inputSourceSoqlQuery' ),
                    component.find( 'inputSourceApexClass' )
                ];

            } else if ( currentStageIndex === 2 ) {         // Choose Action

                inputCmps = [
                    component.find( 'inputTargetType' ),
                    component.find( 'inputTargetSobjectType' ),
                    component.find( 'inputTargetAction' ),
                    component.find( 'inputTargetApexType' ),
                    component.find( 'inputTargetApexScript' )
                ];

            } else if ( currentStageIndex === 3 ) {         // Field Mappings

                var inputSourceFieldNames = component.find( 'inputMappingSourceFieldName' );

                if ( $A.util.isArray( inputSourceFieldNames ) ) {
                    for ( var i = 0; i < inputSourceFieldNames.length; i++ ) {
                        inputCmps.push( inputSourceFieldNames[i] );
                    }
                } else {
                    inputCmps.push( inputSourceFieldNames );
                }

            }

            helper.validateInputsAsync( component, inputCmps )
                .then( $A.getCallback( function( validationResult ) {

                    var isValidToProceed = !validationResult.hasErrors;

                    if ( isValidToProceed ) {

                        return Promise.resolve()
                            .then( $A.getCallback( function() {

                                // if advancing to field mappings section then
                                // determine the action inputs and any current mappings
                                if ( currentStageIndex === 2 ) {

                                    return helper.renderTargetFieldMappingsAsync( component );
                                }

                            })).then( $A.getCallback( function() {

                                wizard.advanceProgress();

                            }));

                    } else {

                        validationResult.components.forEach( function( validationComponentResult ) {
                            if ( validationComponentResult.hasError ) {
                                helper.toastMessage( 'Step Incomplete', validationComponentResult.messageWhenInvalid, 'error' );
                                validationComponentResult.component.reportValidity();
                            }
                        });

                    }

                })).catch( $A.getCallback( function( err ) {

                    helper.toastMessage( 'Error Advancing to Next Step', err, 'error' );

                }));

        }

    },

    handleSaveButtonClick : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        var inputCmps = [
            component.find( 'inputScheduleFrequency' ),
            component.find( 'inputScheduleHourOfDay' ),
            component.find( 'inputScheduleWeekday' ),
            component.find( 'inputScheduleDayOfMonth' ),
            component.find( 'inputScheduleMonthOfYear' ),
            component.find( 'inputScheduleCron' )
        ];

        helper.validateInputsAsync( component, inputCmps )
            .then( $A.getCallback( function( validationResult ) {

                var isValidToSave = !validationResult.hasErrors;

                if ( isValidToSave ) {

                    return helper.saveRecordAsync( component )
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

                            } else {

                                helper.toastMessage( 'Save Failed', '', 'error' );

                            }

                        }));

                } else {

                    validationResult.components.forEach( function( validationComponentResult ) {
                        if ( validationComponentResult.hasError ) {
                            helper.toastMessage( 'Step Incomplete', validationComponentResult.messageWhenInvalid, 'error' );
                            validationComponentResult.component.reportValidity();
                        }
                    });

                }

            })).catch( $A.getCallback( function( err ) {

                helper.toastMessage( 'Error Saving Configuration', err, 'error' );

            }));

    },

    // ----------------------------------------------------------------------------------

    handleInputNameFieldBlur : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        var inputCmp = event.getSource();
        var inputValue = inputCmp.get( 'v.value' );

        // predict the developer name from the name, a familiar feature to admins
        if ( !helper.isEmpty( inputValue ) && helper.isEmpty( component.get( 'v.record.developerName' ) ) ) {
            component.set( 'v.record.developerName', inputValue.trim().replace( /[ ]+/g, '_' ) );
        }

    },

    handleOnBlurInputSourceSoqlQuery : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        var inputCmp = event.getSource();
        var inputValue = inputCmp.get( 'v.value' );

        if ( !$A.util.isUndefinedOrNull( inputValue ) ) {
            inputCmp.set( 'v.value', inputValue.trim() );
        }

    },

    handleOnBlurInputTargetApexScript : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        var inputCmp = event.getSource();
        var inputValue = inputCmp.get( 'v.value' );

        if ( !$A.util.isUndefinedOrNull( inputValue ) ) {
            inputCmp.set( 'v.value', inputValue.trim() );
        }

    },

    handleInputListBoxChanged : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        var selectedOptions = event.getParam( 'value' );

        if ( !helper.isEmpty( selectedOptions ) ) {
            selectedOptions.sort();
        }

    },

    // ----------------------------------------------------------------------------------

    handleSourceTypeChange : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        helper.handleSourceTypeChange( component );

    },

    // ----------------------------------------------------------------------------------

    handleSourceReportFolderChange : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        helper.handleSourceReportFolderChange( component );

    },

    handleSourceReportChange : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        helper.handleSourceReportChange( component );

    },

    // -----------------------------------------------------------------

    handleSourceListViewSobjectTypeChange : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        helper.handleSourceListViewSobjectTypeChange( component );

    },

    handleSourceListViewChange : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        helper.handleSourceListViewChange( component );

    },

    // ----------------------------------------------------------------------------------

    handleTargetTypeChange : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        helper.handleTargetTypeChange( component );

    },

    handleTargetApexTypeChange : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        helper.handleTargetTypeChange( component );

    },

    handleTargetSobjectTypeChange : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        helper.renderTargetInvocableActions( component );

    },

    handleTargetTypeRequiresSobjectChange : function( component, event, helper ) {

        if ( component.get( 'v.didInitConfig' ) !== true ) {
            return;
        }

        helper.renderTargetSobjectTypes( component );

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