/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public class MA_InvocableActionsHttpRequestMock implements HttpCalloutMock {

    private String objectName { get; set; }

    public MA_InvocableActionsHttpRequestMock() {}

    public MA_InvocableActionsHttpRequestMock( String objectName ) {
        this.objectName = objectName;
    }

    public HttpResponse respond( HttpRequest request ) {

        HttpResponse response = new HttpResponse();
        response.setStatus( 'OK' );
        response.setStatusCode( 200 );

        if ( request.getEndpoint().containsIgnoreCase( 'listviews' ) && request.getEndpoint().containsIgnoreCase( 'describe' ) ) {

            response.setBody(
                ' { ' +
                '   "id" : "00Bf40000017w5h", ' +
                '   "query" : "SELECT Id FROM Account", ' +
                '   "sobjectType" : "Account", ' +
                '   "columns" : [ { ' +
                '     "label" : "Account ID", ' +
                '     "fieldNameOrPath" : "Id", ' +
                '     "type" : "id" ' +
                '   } ] ' +
                ' } '
            );

        } else if ( request.getEndpoint().containsIgnoreCase( '/actions/custom/flow' ) ) {

            response.setBody(
                ' { ' +
                '   "actions" : [ { ' +
                '     "label" : "Test Flow", ' +
                '     "name" : "Test_Flow", ' +
                '     "type" : "FLOW", ' +
                '     "url" : "/services/data/v41.0/actions/custom/flow/Test_Flow" ' +
                '   } ] ' +
                ' } '
            );

        } else if ( request.getEndpoint().containsIgnoreCase( '/actions/custom/quickAction/' ) ) {

            if ( String.isBlank( this.objectName ) ) {

                response.setBody(
                    ' { ' +
                    '   "Account" : "/services/data/v41.0/actions/custom/quickAction/Account" ' +
                    ' } '
                );

            } else {

                response.setBody(
                    ' { ' +
                    '   "actions" : [ { ' +
                    '     "label" : "Test Quick Action", ' +
                    '     "name" : "Test_Quick_Action", ' +
                    '     "type" : "QUICKACTION", ' +
                    '     "url" : "/services/data/v41.0/actions/custom/quickAction/Account/Test_Quick_Action" ' +
                    '   } ] ' +
                    ' } '
                );

            }

        } else if ( request.getEndpoint().containsIgnoreCase( '/actions/custom/emailAlert/' ) ) {

            if ( String.isBlank( this.objectName ) ) {

                response.setBody(
                    ' { ' +
                    '   "Account" : "/services/data/v41.0/actions/custom/emailAlert/Account" ' +
                    ' } '
                );

            } else {

                response.setBody(
                    ' { ' +
                    '   "actions" : [ { ' +
                    '     "label" : "Test Email Alert", ' +
                    '     "name" : "Test_Email_Alert", ' +
                    '     "type" : "EMAILALERT", ' +
                    '     "url" : "/services/data/v41.0/actions/custom/emailAlert/Account/Test_Email_Alert" ' +
                    '   } ] ' +
                    ' } '
                );

            }

        } else if ( request.getEndpoint().containsIgnoreCase( '/actions/custom/apex' ) ) {

            response.setBody(
                ' { ' +
                '   "actions" : [ { ' +
                '     "label" : "Test Apex", ' +
                '     "name" : "Test_Apex", ' +
                '     "type" : "APEX", ' +
                '     "url" : "/services/data/v41.0/actions/custom/apex/Test_Apex" ' +
                '   } ] ' +
                ' } '
            );

        }

        return response;
    }

}
/*
BSD 3-Clause License

Copyright (c) 2017, Doug Ayers, douglascayers.com
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