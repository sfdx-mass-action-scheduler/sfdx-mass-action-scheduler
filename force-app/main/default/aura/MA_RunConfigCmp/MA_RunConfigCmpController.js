({
    onInit : function( component, event, helper ) {

        helper.enqueueAction( component, 'c.getConfiguration', {

            'recordId' : component.get( 'v.recordId' )

        }).then( $A.getCallback( function( record ) {

            component.set( 'v.record', record );

        }));

    },

    handleRunButtonClick : function( component, event, helper ) {

        helper.enqueueAction( component, 'c.enqueueAction', {

            'configId' : component.get( 'v.recordId' )

        }).then( $A.getCallback( function( result ) {

            if ( result.success ) {
                helper.toastMessage( 'Job Submitted', result.jobId, 'success' );
            } else {
                helper.toastMessage( 'Error', result.message, 'error' );
            }

            $A.get( 'e.force:closeQuickAction' ).fire();

        }));

    },

    handleCancelButtonClick : function( component, event, helper ) {

        $A.get( 'e.force:closeQuickAction' ).fire();

    }
})