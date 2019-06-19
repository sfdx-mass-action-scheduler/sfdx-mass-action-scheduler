({
    onInit: function( component, event, helper ) {

        let promises = [];
        let lcApi = component.find( 'lc_api' );

        // get the latest package version available
        promises.push(
            lcApi.fetchRequest({
                'url' : 'https://gist.githubusercontent.com/douglascayers/e96c53304dc78dc83e59a85753f29111/raw/sfdx-mass-action-scheduler-version.js'
            }).then( function ( response ) {
                return response;
            })
        );

        // get the currently installed package version
        promises.push(
            lcApi.restRequest({
                'url' : '/services/data/v46.0/tooling/query?q=SELECT+Id,+SubscriberPackageId,+SubscriberPackage.Name,+SubscriberPackage.NamespacePrefix,+SubscriberPackageVersion.MajorVersion,+SubscriberPackageVersion.MinorVersion+FROM+InstalledSubscriberPackage'
            }).then( function ( response ) {
                // The InstalledSubscriberPackage object doesn't support WHERE clause filtering on the package's namespace
                // so we have to filter the results ourselves
                return response.records.find( ( record ) => {
                    return ( record.SubscriberPackage.NamespacePrefix === 'dca_mass_action' );
                });
            })
        );

        // notify user if there's a newer package version to upgrade to
        Promise.all( promises ).then( $A.getCallback( function( results ) {

            let linkToLatest = ( results[0] && results[0].url );
            let linkToInstalled = ( results[1] && `/${results[1].Id}` );

            let latestVersion = ( results[0] && results[0].version );
            let installedVersion = ( results[1] && `${results[1].SubscriberPackageVersion.MajorVersion}.${results[1].SubscriberPackageVersion.MinorVersion}` );

            if ( latestVersion > installedVersion ) {

                component.set( 'v.upgradeAvailable', true );

                component.set( 'v.linkToInstalledVersion', linkToInstalled );
                component.set( 'v.installedVersionNumber', installedVersion );

                component.set( 'v.linkToLatestVersion', linkToLatest );
                component.set( 'v.latestVersionNumber', latestVersion );

            }

        })).catch( $A.getCallback( function( error ) {

            component.set( 'v.upgradeAvailable', false );
            console.error( 'MA_CheckForPackageUpdatesCmp.onInit: error=' + JSON.stringify( error, null, 2 ) );

        }));

    }
})