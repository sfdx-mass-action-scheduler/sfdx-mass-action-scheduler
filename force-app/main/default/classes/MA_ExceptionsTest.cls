/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_ExceptionsTest {

    @IsTest
    static void test_UnsupportedSourceTypeException() {

        Test.startTest();

        ID configId = null;
        String sourceType = '';

        try {

            throw new MA_Exceptions.UnsupportedSourceTypeException( configId, sourceType );

        } catch ( MA_Exceptions.UnsupportedSourceTypeException e ) {

            System.assertEquals( configId, e.configId );
            System.assertEquals( sourceType, e.sourceType );
            System.assert( e.getMessage().startsWithIgnoreCase( 'Error: Unsupported Source Type' ) );

        }

        Test.stopTest();

    }

    @IsTest
    static void test_NoSourceFieldException() {

        Test.startTest();

        Map<String, Object> sourceData = new Map<String, Object>{ 'A' => 1 };
        String sourceFieldName = 'fieldName';

        try {

            throw new MA_Exceptions.NoSourceFieldException( sourceData, sourceFieldName );

        } catch ( MA_Exceptions.NoSourceFieldException e ) {

            System.assertEquals( sourceData, e.sourceData );
            System.assertEquals( sourceFieldName, e.sourceFieldName );
            System.assert( e.getMessage().startsWithIgnoreCase( 'Error: Field path' ) );

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

        try {

            throw new MA_Exceptions.InvokeActionException( request, response );

        } catch ( MA_Exceptions.InvokeActionException e ) {

            System.assertEquals( request, e.request );
            System.assertEquals( response, e.response );

            System.assert( e.getMessage().containsIgnoreCase( response.getBody() ) );
            System.assert( e.getMessage().containsIgnoreCase( request.getEndpoint() ) );

        }

        Test.stopTest();

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