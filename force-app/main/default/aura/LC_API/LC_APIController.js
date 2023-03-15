/*
Author: Doug Ayers
Website: https://douglascayers.com
GitHub: https://github.com/douglascayers/sfdx-lightning-api-component
License: BSD 3-Clause License
 */
({
    /**
     * Called once during component initialization phase.
     */
    onInit: function( component, event, helper ) {
        helper._penpal = {};
        helper.makeApexRequest( component, 'c.getVisualforceDomainURL' ).then( $A.getCallback( function( vfDomainURL ) {
            component.set( 'v.iframeSrc', `${vfDomainURL}/apex/LC_APIPage` );
        })).catch( $A.getCallback( function( err ) {
            console.error( 'LC_API: Error determining visualforce domain', err );
        }));
    },

    /**
     * Called once after ltng:require has loaded scripts.
     */
    onScriptsLoaded: function( component, event, helper ) {

    },

    /**
     * Called each time the component renders itself.
     */
    onRender: function( component, event, helper ) {

        const isPenpalFrameCreated = component.get( 'v.penpalFrameCreated' );

        // For Penpal to operate correctly, you must ensure that `connectToChild`
        // is called before the iframe has called `connectToParent`.
        // Since the iframe source is calculated asynchronously,
        // we listen to the component's render events and each time
        // check if the iframe source is ready, and if so, then we initialize
        // penpal to connect this component to the iframe.
        // Since we only want to do this once, we also set the initialized flag.
        if ( !isPenpalFrameCreated ) {

            const container = component.find( 'penpalFrameContainer' );
            const iframeSrc = component.get( 'v.iframeSrc' );

            // Ensure the container element has rendered otherwise we can't
            // append child elements to it. And wait for the iframe source to
            // be available otherwise no reason to create the iframe element.
            if ( !$A.util.isEmpty( container ) && !$A.util.isEmpty( iframeSrc ) ) {

                $A.createComponent(
                    "aura:html",
                    {
                        "aura:id": "penpalFrame",
                        "tag": "iframe",
                        "HTMLAttributes": {
                            "src": iframeSrc
                        }
                    },
                    function( iframeCmp, status, errorMessage ) {

                        // This callback happened asynchronously, so make one
                        // more check on whether the penpal frame has been initialized or not
                        // in the off chance a separate render cycle got here before this one.
                        const isPenpalFrameCreated = component.get( 'v.penpalFrameCreated' );

                        if ( isPenpalFrameCreated ) {

                            console.log( 'LC_API: iframe is already initialized' );

                        } else if ( status === 'SUCCESS' ) {

                            // At this point, the iframe component has been constructed
                            // but not yet been rendered, so we don't have access to the
                            // HTML iframe element yet. We need to wait for another render cycle,
                            // that is, we need to wait for the render() method to be called again
                            // after we append the new iframe component to the body of its container.
                            // Once we're able to find the 'penpalFrame' on the page then
                            // we can proceed with the rest of the penpal initialization.

                            component.set( 'v.penpalFrameCreated', true );

                            container.set( 'v.body', [ iframeCmp ] );

                            console.info( 'LC_API: iframe initialized' );

                        } else if ( status === 'INCOMPLETE' ) {

                            console.warn( 'LC_API: No response from server or client is offline' );

                        } else if ( status === 'ERROR' ) {

                            console.error( 'LC_API: Error creating iframe: ' + errorMessage );

                        }

                    }
                );

            } // else, iframe source is empty, keep waiting

        } else {

            const isPenpalFrameConnected = component.get( 'v.penpalFrameConnected' );
            const iframeCmp = component.find( 'penpalFrame' );

            if ( !$A.util.isEmpty( iframeCmp ) && !isPenpalFrameConnected ) {

                const connection = Penpal.connectToChild({
                    // The iframe to which a connection should be made
                    iframe: iframeCmp.getElement()
                });

                helper._penpal.connection = connection;

                connection.promise.then( $A.getCallback( function( child ) {

                    // Cache a reference to the child so that we can
                    // use it in the restRequest/fetchRequest methods,
                    // as well as be able to destroy it when this component unrenders.
                    helper._penpal.child = child;
                    console.info( 'LC_API: connected to iframe ' + iframeCmp.getGlobalId() );
                    component.set( 'v.penpalFrameConnected', true );

                })).catch( $A.getCallback( function( err ) {

                    console.error( 'LC_API: Error establishing connection to iframe ' + iframeCmp.getGlobalId(), err );
                    component.set( 'v.penpalFrameConnected', false );

                }));

            }

        }

    },

    onRestRequest: function( component, event, helper ) {
        const params = event.getParam( 'arguments' );
        return helper.handleRestRequest( component, params.request );
    },

    onFetchRequest: function( component, event, helper ) {
        const params = event.getParam( 'arguments' );
        return helper.handleFetchRequest( component, params.request );
    }
})
/*
BSD 3-Clause License

Copyright (c) 2017-2023, Doug Ayers, douglascayers.com
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