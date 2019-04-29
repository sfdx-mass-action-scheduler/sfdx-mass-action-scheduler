/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/*
 * Most code coverage comes from MA_EditConfigRestControllerTest
 */
public inherited sharing class MA_HttpCalloutMock implements HttpCalloutMock {

    public HttpResponse respond( HttpRequest request ) {

        HttpResponse response = new HttpResponse();

        switch on ( request.getMethod().toLowerCase() ) {

            when 'get' {
                response = respondToGet( request );
            }

            when 'post' {
                response = respondToPost( request );
            }

        }

        return response;
    }

    private HttpResponse respondToGet( HttpRequest request ) {

        HttpResponse response = new HttpResponse();
        response.setStatus( 'OK' );
        response.setStatusCode( 200 );

        // List View Describe
        if ( matches( request.getEndpoint(), '(.)*/sobjects/[\\w]+/listviews/[\\w]+/describe(/.*)*' ) ) {

            response.setBody(
                ' { ' +
                '   "id" : "00Bf40000017w5h", ' +
                '   "query" : "SELECT Id, Name, Owner.Id FROM Account", ' +
                '   "sobjectType" : "Account", ' +
                '   "columns" : [ ' +
                '     { ' +
                '       "label" : "Account ID", ' +
                '       "fieldNameOrPath" : "Id", ' +
                '       "type" : "id" ' +
                '     }, ' +
                '     { ' +
                '       "label" : "Account Name", ' +
                '       "fieldNameOrPath" : "Name", ' +
                '       "type" : "string" ' +
                '     }, ' +
                '     { ' +
                '       "label" : "Owner ID", ' +
                '       "fieldNameOrPath" : "Owner.Id", ' +
                '       "type" : "id" ' +
                '     } ' +
                '   ] ' +
                ' } '
            );

        }
        // Flows
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/flow(/)?' ) ) {

            response.setBody(
                ' { ' +
                '   "actions" : [ { ' +
                '     "label" : "Test Flow", ' +
                '     "name" : "Test_Flow", ' +
                '     "type" : "FLOW", ' +
                '     "url" : "/services/data/v45.0/actions/custom/flow/Test_Flow" ' +
                '   } ] ' +
                ' } '
            );

        }
        // Quick Actions
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/quickAction(/)?' ) ) {

            response.setBody(
                ' { ' +
                '   "Account" : "/services/data/v45.0/actions/custom/quickAction/Account" ' +
                ' } '
            );

        }
        // Quick Actions for an object
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/quickAction/[\\w]+(/)?' ) ) {

            response.setBody(
                ' { ' +
                '   "actions" : [ { ' +
                '     "label" : "Test Quick Action", ' +
                '     "name" : "Test_Quick_Action", ' +
                '     "type" : "QUICKACTION", ' +
                '     "url" : "/services/data/v45.0/actions/custom/quickAction/Account/Test_Quick_Action" ' +
                '   } ] ' +
                ' } '
            );

        }
        // Email Alerts
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/emailAlert(/)?' ) ) {

            response.setBody(
                ' { ' +
                '   "Account" : "/services/data/v45.0/actions/custom/emailAlert/Account" ' +
                ' } '
            );

        }
        // Email Alerts for an object
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/emailAlert/[\\w]+(/)?' ) ) {

            response.setBody(
                ' { ' +
                '   "actions" : [ { ' +
                '     "label" : "Test Email Alert", ' +
                '     "name" : "Test_Email_Alert", ' +
                '     "type" : "EMAILALERT", ' +
                '     "url" : "/services/data/v45.0/actions/custom/emailalert/Account/Test_Email_Alert" ' +
                '   } ] ' +
                ' } '
            );

        }
        // Apex
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/apex(/)?' ) ) {

            response.setBody(
                ' { ' +
                '   "actions" : [ { ' +
                '     "label" : "Test Apex", ' +
                '     "name" : "Test_Apex", ' +
                '     "type" : "APEX", ' +
                '     "url" : "/services/data/v45.0/actions/custom/apex/Test_Apex" ' +
                '   } ] ' +
                ' } '
            );

        }
        // Flow Inputs
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/flow/[\\w]+(/)?' ) ) {

            response.setBody(
                ' { ' +
                '   "inputs" : [ { ' +
                '     "label" : "Test Input", ' +
                '     "name" : "Test_Input", ' +
                '     "type" : "STRING", ' +
                '     "required" : true, ' +
                '     "description" : null ' +
                '   } ] ' +
                ' } '
            );

        }
        // Quick Action Inputs
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/quickAction/[\\w]+/[\\w]+(/.*)*' ) ) {

            response.setBody(
                ' { ' +
                '   "inputs" : [ { ' +
                '     "label" : "Test Input", ' +
                '     "name" : "Test_Input", ' +
                '     "type" : "STRING", ' +
                '     "required" : true, ' +
                '     "description" : null ' +
                '   } ] ' +
                ' } '
            );

        }
        // Email Alert Inputs
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/emailAlert/[\\w]+/[\\w]+(/)?' ) ) {

            response.setBody(
                ' { ' +
                '   "inputs" : [ { ' +
                '     "label" : "Test Input", ' +
                '     "name" : "Test_Input", ' +
                '     "type" : "STRING", ' +
                '     "required" : true, ' +
                '     "description" : null ' +
                '   } ] ' +
                ' } '
            );

        }
        // Apex Inputs
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/apex/[\\w]+(/)?' ) ) {

            response.setBody(
                ' { ' +
                '   "inputs" : [ { ' +
                '     "label" : "Test Input", ' +
                '     "name" : "Test_Input", ' +
                '     "type" : "STRING", ' +
                '     "required" : true, ' +
                '     "description" : null ' +
                '   } ] ' +
                ' } '
            );

        }
        // SOQL Query (success)
        else if ( matches( request.getEndpoint(), '(.*)/query(/)?\\?q=SELECT(.*)' ) ) {

            Boolean isDone = true;
            String nextRecordsUrl = null;
            Integer batchSize = null;
            Integer totalSize = 1;

            String queryOptions = request.getHeader( 'Sforce-Query-Options' );

            // get batch size query option, if set
            if ( String.isNotEmpty( queryOptions ) ) {
                for ( String optionPair : queryOptions.split( ';' ) ) {
                    if ( optionPair.deleteWhitespace().startsWithIgnoreCase( 'batchSize=' ) ) {
                        batchSize = Integer.valueOf( optionPair.split( '=' )[1].trim() );
                    }
                }
            }

            // if a batch size was given, simulate that there's another page of records to return
            if ( batchSize != null ) {
                isDone = false;
                nextRecordsUrl = request.getEndpoint().substringBefore( '/query' ) + '/query/01gf400001MMCpeAAH-' + batchSize;
                totalSize = batchSize + 1;
            }

            response.setBody(
                ' { ' +
                '   "totalSize" : ' + totalSize + ', ' +
                '   "done" : ' + isDone + ', ' +
        ( String.isNotBlank( nextRecordsUrl ) ?
            (   '   "nextRecordsUrl" : "' + nextRecordsUrl + '", ' ) :
                ''
        ) +
                '   "records" : [ { ' +
                '     "attributes" : { ' +
                '       "type" : "Account", ' +
                '       "url" : "/services/data/v45.0/sobjects/Account/001f400000CukanAAB" ' +
                '     }, ' +
                '     "Id" : "001f400000CukanAAB", ' +
                '     "Name" : "Test Account 1" ' +
                '   } ] ' +
                ' } '
            );

        }
        // SOQL Query Next Records URL
        else if ( matches( request.getEndpoint(), '(.*)/query/(\\w){15,18}-(\\d+)(.*)' ) ) {

            Pattern p = Pattern.compile( '(\\w){15,18}-(\\d+)' );
            Matcher m = p.matcher( request.getEndpoint() );

            Integer totalSize = 2;
            while ( m.find() ) {
                totalSize = Integer.valueOf( m.group().substringAfter( '-' ) ) + 1;
            }

            response.setBody(
                ' { ' +
                '   "totalSize" : ' + totalSize + ', ' +
                '   "done" : true, ' +
                '   "records" : [ { ' +
                '     "attributes" : { ' +
                '       "type" : "Account", ' +
                '       "url" : "/services/data/v45.0/sobjects/Account/001f400000lxT2JAAU" ' +
                '     }, ' +
                '     "Id" : "001f400000lxT2JAAU", ' +
                '     "Name" : "Test Account 2" ' +
                '   } ] ' +
                ' } '
            );

        }
        // SOQL Query (failure)
        else if ( matches( request.getEndpoint(), '(.*)/query(/)?(\\?q=)?TEST_FAIL(.*)' ) ) {

            response.setStatus( 'ERROR' );
            response.setStatusCode( 400 );
            response.setBody(
                ' [ ' +
                '   { ' +
                '     "errorCode" : "TEST_FAIL", ' +
                '     "message" : "Test Fail" ' +
                '   } ' +
                ' ] '
            );

        }
        // Anonymous Apex (failure)
        else if ( matches( request.getEndpoint(), '(.*)/tooling/executeAnonymous(/)?\\?anonymousBody=(.*)TEST_FAIL(.*)' ) ) {

            response.setBody(
                ' { ' +
                '   "line" : 1, ' +
                '   "column" : 14, ' +
                '   "compiled" : false, ' +
                '   "success" : false, ' +
                '   "compileProblem" : "Some error about why Apex did not compile", ' +
                '   "exceptionStackTrace" : null, ' +
                '   "exceptionMessage" : null ' +
                ' } '
            );

        }
        // Anonymous Apex (success)
        else if ( matches( request.getEndpoint(), '(.*)/tooling/executeAnonymous(/)?\\?anonymousBody=(.*)' ) ) {

            response.setBody(
                ' { ' +
                '   "line" : -1, ' +
                '   "column" : -1, ' +
                '   "compiled" : true, ' +
                '   "success" : true, ' +
                '   "compileProblem" : null, ' +
                '   "exceptionStackTrace" : null, ' +
                '   "exceptionMessage" : null ' +
                ' } '
            );

        }
        else {

            response.setStatus( 'ERROR' );
            response.setStatusCode( 400 );
            response.setBody( 'Unsupported endpoint: ' + request.getEndpoint() );

        }

        return response;
    }

    private HttpResponse respondToPost( HttpRequest request ) {

        HttpResponse response = new HttpResponse();
        response.setStatus( 'OK' );
        response.setStatusCode( 200 );

        // Workflow Rules
        if ( matches( request.getEndpoint(), '(.)*/process/rules(/)?' ) ) {

            response.setBody(
                ' { ' +
                '   "errors" : null, ' +
                '   "success" : true ' +
                ' } '
            );

        }
        // Flows
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/flow/[\\w]+(/)?' ) ) {

            response.setBody(
                ' [ { ' +
                '   "actionName" : "Mass_Action_Configuration__c.Test_Flow, ' +
                '   "errors" : [ ], ' +
                '   "isSuccess" : true, ' +
                '   "outputValues" : null ' +
                ' } ] '
            );

        }
        // Quick Actions
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/quickAction/[\\w]+/[\\w]+(/.*)*' ) ) {

            response.setBody(
                ' [ { ' +
                '   "actionName" : "Mass_Action_Configuration__c.Test_Quick_Action", ' +
                '   "errors" : [ ], ' +
                '   "isSuccess" : true, ' +
                '   "outputValues" : null ' +
                ' } ] '
            );
        }
        // Email Alerts
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/emailAlert/[\\w]+/[\\w]+(/)?' ) ) {

            response.setBody(
                ' [ { ' +
                '   "actionName" : "Mass_Action_Configuration__c.Test_Email_Alert, ' +
                '   "errors" : [ ], ' +
                '   "isSuccess" : true, ' +
                '   "outputValues" : null ' +
                ' } ] '
            );

        }
        // Invocable Apex
        else if ( matches( request.getEndpoint(), '(.)*/actions/custom/apex/[\\w]+(/)?' ) ) {

            response.setBody(
                ' [ { ' +
                '   "actionName" : "Test_Apex, ' +
                '   "errors" : [ ], ' +
                '   "isSuccess" : true, ' +
                '   "outputValues" : { "foo" : "bar" } ' +
                ' } ] '
            );


        }
        else {

            response.setStatus( 'ERROR' );
            response.setStatusCode( 400 );
            response.setBody( 'Unsupported endpoint: ' + request.getEndpoint() );

        }

        return response;
    }

    private Boolean matches( String text, String regex ) {

        Pattern p = Pattern.compile( regex );
        Matcher m = p.matcher( text );

        return m.matches();
    }

}
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