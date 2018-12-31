({
    // -----------------------------------------------------------------

    showSpinner : function( component ) {

        $A.util.removeClass( component.find( 'spinner' ), 'slds-hide' );

    },

    hideSpinner : function( component ) {

        $A.util.addClass( component.find( 'spinner' ), 'slds-hide' );

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