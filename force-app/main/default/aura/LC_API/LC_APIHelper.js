/*
Author: Doug Ayers
Website: https://douglascayers.com
GitHub: https://github.com/douglascayers/sfdx-lightning-api-component
License: BSD 3-Clause License
 */
({
    handleRestRequest: function( component, request ) {

        var helper = this;

        var defaultRequest = {
            'method' : 'get'
        };

        var defaultHeaders = {
            'Content-Type': 'application/json'
        };

        request = Object.assign( {}, defaultRequest, request );
        request.headers = Object.assign( {}, defaultHeaders, request.headers );

        return helper.getPenpalChild().then( $A.getCallback( function( child ) {
            return helper.makePenpalRequest( 'rest', child, request );
        }));

    },

    handleFetchRequest: function( component, request ) {

        var helper = this;

        return helper.getPenpalChild().then( $A.getCallback( function( child ) {
            return helper.makePenpalRequest( 'fetch', child, request );
        }));

    },

    // ------------------------------------------------------------

    /**
     * For internal use.
     * Returns a promise waiting for the parent-child postmate handshake to complete
     * then resolves with reference to the postmate child for making requests.
     */
    getPenpalChild: function() {

        var helper = this;

        return new Promise( function( resolve, reject ) {

            var child = helper._penpal.child;

            if ( child ) {

                resolve( child );

            } else {

                // all time values in milliseconds
                var timeout = 10000; // ten seconds
                var pollFrequency = 500; // half a second
                var startTime = new Date().getTime();
                var endTime = startTime + timeout;

                var timerId = setInterval( $A.getCallback( function() {

                    child = helper._penpal.child;

                    if ( child ) {

                        // parent-child postmate handshake now complete
                        clearInterval( timerId );
                        resolve( child );

                    } else {

                        // check if we have exceeded our timeout
                        var currentTime = new Date().getTime();
                        if ( currentTime > endTime ) {
                            clearInterval( timerId );
                            reject( 'LC_API: Timeout trying to establish connection to iframe' );
                        }
                        // else, keep polling

                    }

                }), pollFrequency );

            }

        });

    },

    /**
     * For internal use.
     * Returns a promise waiting for the parent-child postmate request to complete
     * then resolves with response from the child iframe.
     */
    makePenpalRequest: function( requestType, child, request ) {

        let p;

        if ( requestType === 'rest' ) {
            p = child.restRequest( request );
        } else if ( requestType === 'fetch' ) {
            p = child.fetchRequest( request );
        } else {
            p = Promise.resolve({
                success: false,
                data: 'LC_API: Invalid request type: ' + requestType
            });
        }

        return p.then( $A.getCallback( function( response ) {
            if ( response.success ) {
                return response.data;
            } else {
                throw new Error( response.data );
            }
        }));

    },

    /**
     * For internal use.
     * Returns a promise waiting for the Apex request to complete
     * then resolves with the JSON response, or rejects if any error.
     *
     * @param component
     *      (required) Reference to the component who has access to the Aura Enabled method specified by `actionName`.
     * @param actionName
     *      (required) Name of the Aura Enabled Apex method in form `c.methodName`.
     * @param params
     *      (optional) JSON map of request parameters to pass to the Apex action.
     * @param options
     *      (optional) JSON map of options to customize the request.
     *      `background` set to true will execute request in background thread.
     *      `storable` set to true will cache the response.
     */
    makeApexRequest: function( component, actionName, params, options ) {

        var helper = this;

        return new Promise( function( resolve, reject ) {

            var action = component.get( actionName );

            if ( params ) {
                action.setParams( params );
            }

            if ( options ) {
                if ( options.background ) { action.setBackground(); }
                if ( options.storable )   { action.setStorable(); }
            }

            action.setCallback( helper, function( response ) {
                if ( component.isValid() && response.getState() === 'SUCCESS' ) {

                    resolve( response.getReturnValue() );

                } else {

                    console.error( 'Error calling action "' + actionName + '" with state: ' + response.getState() );

                    helper.logActionErrors( response.getError() );

                    reject( response.getError() );

                }
            });

            $A.enqueueAction( action );

        });

    },

    /**
     * For internal use.
     * Logs to console errors object.
     * Errors may be a String or Array.
     */
    logActionErrors: function( errors ) {
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
    }

})
/*
BSD 3-Clause License

Copyright (c) 2018, Doug Ayers, douglascayers.com
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