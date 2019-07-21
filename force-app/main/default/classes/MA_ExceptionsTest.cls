/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_ExceptionsTest {

    @IsTest
    static void test_AnonymousApexException() {

        Test.startTest();

        HttpRequest request = new HttpRequest();
        request.setMethod( 'GET' );
        request.setEndpoint( 'https://www.salesforce.com' );

        HttpResponse response = new HttpResponse();
        response.setBody( 'test' );

        String compileProblem = 'compileProblem';
        String exceptionMessage = 'exceptionMessage';
        String exceptionStackTrace = 'exceptionStackTrace';
        Exception cause = new System.NoAccessException();

        try {

            throw new MA_Exceptions.AnonymousApexException( request, response, compileProblem, exceptionMessage, exceptionStackTrace, cause );

        } catch ( MA_Exceptions.AnonymousApexException e ) {

            System.assertEquals( request, e.request );
            System.assertEquals( response, e.response );
            System.assertEquals( compileProblem, e.compileProblem );
            System.assertEquals( exceptionMessage, e.exceptionMessage );
            System.assertEquals( exceptionStackTrace, e.exceptionStackTrace );
            System.assert( e.getMessage().startsWithIgnoreCase( 'Anonymous Apex Error:' ) );
            System.assertEquals( cause, e.getCause() );

        }

        Test.stopTest();

    }

    @IsTest
    static void test_SOQLQueryException() {

        Test.startTest();

        HttpRequest request = new HttpRequest();
        request.setMethod( 'GET' );
        request.setEndpoint( 'https://www.salesforce.com' );

        HttpResponse response = new HttpResponse();
        response.setBody( 'test' );

        String query = 'SELECT Id, Name FROM Foo__c';
        String errorType = 'errorType';
        String errorMessage = 'the error message';
        Exception cause = new System.NoAccessException();

        try {

            throw new MA_Exceptions.SOQLQueryException( request, response, query, errorType, errorMessage, cause );

        } catch ( MA_Exceptions.SOQLQueryException e ) {

            System.assertEquals( request, e.request );
            System.assertEquals( response, e.response );
            System.assertEquals( query, e.query );
            System.assertEquals( errorType, e.errorType );
            System.assertEquals( errorMessage, e.errorMessage );
            System.assert( e.getMessage().startsWithIgnoreCase( 'SOQL Query Error:' ) );
            System.assertEquals( cause, e.getCause() );

        }

        Test.stopTest();

    }

    @IsTest
    static void test_UnsupportedSourceTypeException() {

        Test.startTest();

        ID configId = null;
        String sourceType = '';
        Exception cause = new System.NoAccessException();

        try {

            throw new MA_Exceptions.UnsupportedSourceTypeException( configId, sourceType, cause );

        } catch ( MA_Exceptions.UnsupportedSourceTypeException e ) {

            System.assertEquals( configId, e.configId );
            System.assertEquals( sourceType, e.sourceType );
            System.assert( e.getMessage().startsWithIgnoreCase( 'Error: Unsupported Source Type' ) );
            System.assertEquals( cause, e.getCause() );

        }

        Test.stopTest();

    }

    @IsTest
    static void test_NoSourceFieldException() {

        Test.startTest();

        Map<String, Object> sourceData = new Map<String, Object>{ 'A' => 1 };
        String sourceFieldName = 'fieldName';
        Exception cause = new System.NoAccessException();

        try {

            throw new MA_Exceptions.NoSourceFieldException( sourceData, sourceFieldName, cause );

        } catch ( MA_Exceptions.NoSourceFieldException e ) {

            System.assertEquals( sourceData, e.sourceData );
            System.assertEquals( sourceFieldName, e.sourceFieldName );
            System.assert( e.getMessage().startsWithIgnoreCase( 'Error: Field path' ) );
            System.assertEquals( cause, e.getCause() );

        }

        Test.stopTest();

    }

    @IsTest
    static void test_InvokeActionException() {

        Test.startTest();

        HttpRequest request = new HttpRequest();
        request.setMethod( 'GET' );
        request.setEndpoint( 'https://www.salesforce.com' );

        HttpResponse response = new HttpResponse();
        response.setBody( 'test' );

        Exception cause = new System.NoAccessException();

        try {

            throw new MA_Exceptions.InvokeActionException( request, response, cause );

        } catch ( MA_Exceptions.InvokeActionException e ) {

            System.assertEquals( request, e.request );
            System.assertEquals( response, e.response );

            System.assert( e.getMessage().containsIgnoreCase( response.getBody() ) );
            System.assert( e.getMessage().containsIgnoreCase( request.getEndpoint() ) );
            System.assertEquals( cause, e.getCause() );

        }

        Test.stopTest();

    }

    @IsTest
    static void test_MetadataDeployException() {

        Test.startTest();

        Metadata.DeployResult result = new Metadata.DeployResult();
        result.errorStatusCode = Metadata.StatusCode.INTERNAL_ERROR;
        result.errorMessage = 'the error message';
        result.success = false;

        Exception cause = new System.NoAccessException();

        try {

            throw new MA_Exceptions.MetadataDeployException( result, cause );

        } catch ( MA_Exceptions.MetadataDeployException e ) {

            System.assertEquals( result, e.result );

            System.assert( e.getMessage().containsIgnoreCase( String.valueOf( result.errorStatusCode ) ) );
            System.assert( e.getMessage().containsIgnoreCase( result.errorMessage ) );
            System.assertEquals( cause, e.getCause() );

        }

        Test.stopTest();

    }

    @IsTest
    static void test_buildException() {

        Test.startTest();

        Type t = System.NullPointerException.class;
        String message = 'the error message';
        Exception cause = new System.NoAccessException();

        try {

            throw MA_Exceptions.buildException( t, message, cause );

        } catch ( System.NullPointerException e ) {

            System.assert( e.getMessage().startsWithIgnoreCase( message ) );
            System.assertEquals( cause, e.getCause() );

        } catch ( Exception e ) {

            System.assert( false, 'threw wrong exception' );

        }

        Test.stopTest();

    }

}
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