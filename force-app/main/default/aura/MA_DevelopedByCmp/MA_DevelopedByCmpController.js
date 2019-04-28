({
    onInit: function( component, event, helper ) {

        const url = 'https://gist.githubusercontent.com/douglascayers/e96c53304dc78dc83e59a85753f29111/raw/83713d855d4d259ee82a1cd7a7f098c72b0dea27/sfdx-mass-action-scheduler-version.js';

        component.find( 'lc_api' ).fetchRequest({
            'url' : url,
            'options': {}
        }).then( function ( response ) {
            // TODO display something to user
            console.log( 'developedByCmp.onInit: response=' + JSON.stringify( response, null, 2 ) );
        }).catch( function ( error ) {
            console.error( 'developedByCmp.onInit: error=' + JSON.stringify( error, null, 2 ) );
        });

    }
})