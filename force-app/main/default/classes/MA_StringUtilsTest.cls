/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_StringUtilsTest {

    @IsTest
    static void givenBlankStringThenReturnsDefaultString() {

        String defaultStr = 'DEFAULT';

        Test.startTest();

        System.assertEquals( defaultStr, MA_StringUtils.defaultIfBlank( null, defaultStr ) );
        System.assertEquals( defaultStr, MA_StringUtils.defaultIfBlank( '', defaultStr ) );
        System.assertEquals( defaultStr, MA_StringUtils.defaultIfBlank( ' ', defaultStr ) );
        System.assertEquals( defaultStr, MA_StringUtils.defaultIfBlank( '\t', defaultStr ) );
        System.assertEquals( defaultStr, MA_StringUtils.defaultIfBlank( '\n', defaultStr ) );
        System.assertEquals( defaultStr, MA_StringUtils.defaultIfBlank( '\r', defaultStr ) );

        Test.stopTest();

    }

    @IsTest
    static void givenNonBlankStringThenReturnsString() {

        String defaultStr = 'DEFAULT';

        Test.startTest();

        System.assertEquals( 'text', MA_StringUtils.defaultIfBlank( 'text', defaultStr ) );
        System.assertEquals( ' text ', MA_StringUtils.defaultIfBlank( ' text ', defaultStr ) );
        System.assertEquals( ' 1 2 3 ', MA_StringUtils.defaultIfBlank( ' 1 2 3 ', defaultStr ) );

        Test.stopTest();

    }

    @IsTest
    static void test_get_random_letters() {

        Test.startTest();

        String str1 = MA_StringUtils.getRandomLetters( 200 );
        System.assertEquals( 200, str1.length() );
        System.assertEquals( true, str1.isAlpha() );

        String str2 = MA_StringUtils.getRandomLetters( 0 );
        System.assertEquals( 0, str2.length() );

        Test.stopTest();

    }

    @IsTest
    static void test_abbreviateWithinFieldLength() {

        Integer messageLength = Mass_Action_Log__c.Message__c.getDescribe().getLength();

        String shortMessage = ''.leftPad( messageLength - 10, 'x' );
        String longMessage = ''.leftPad( messageLength + 10, 'x' );
        String emptyMessage = '';
        String nullMessage = null;

        Test.startTest();

        String abbrShortMessage = MA_StringUtils.abbreviateWithinFieldLength( shortMessage, Mass_Action_Log__c.Message__c );
        String abbrLongMessage = MA_StringUtils.abbreviateWithinFieldLength( longMessage, Mass_Action_Log__c.Message__c );
        String abbrEmptyMessage = MA_StringUtils.abbreviateWithinFieldLength( emptyMessage, Mass_Action_Log__c.Message__c );
        String abbrNullMessage = MA_StringUtils.abbreviateWithinFieldLength( nullMessage, Mass_Action_Log__c.Message__c );

        Test.stopTest();

        System.assertEquals( messageLength - 10, abbrShortMessage.length() );
        System.assert( !abbrShortMessage.endsWith( '...' ) );

        System.assertEquals( messageLength, abbrLongMessage.length() );
        System.assert( abbrLongMessage.endsWith( '...' ) );

        System.assertEquals( 0, abbrEmptyMessage.length() );
        System.assertEquals( '', abbrEmptyMessage );

        System.assertEquals( 0, abbrNullMessage.length() );
        System.assertEquals( '', abbrNullMessage );

    }

    @IsTest
    static void test_abbreviate() {

        Integer messageLength = 50;

        String shortMessage = ''.leftPad( messageLength - 10, 'x' );
        String longMessage = ''.leftPad( messageLength + 10, 'x' );
        String emptyMessage = '';
        String nullMessage = null;

        Test.startTest();

        String abbrShortMessage = MA_StringUtils.abbreviate( shortMessage, messageLength );
        String abbrLongMessage = MA_StringUtils.abbreviate( longMessage, messageLength );
        String abbrEmptyMessage = MA_StringUtils.abbreviate( emptyMessage, messageLength );
        String abbrNullMessage = MA_StringUtils.abbreviate( nullMessage, messageLength );

        Test.stopTest();

        System.assertEquals( messageLength - 10, abbrShortMessage.length() );
        System.assert( !abbrShortMessage.endsWith( '...' ) );

        System.assertEquals( messageLength, abbrLongMessage.length() );
        System.assert( abbrLongMessage.endsWith( '...' ) );

        System.assertEquals( 0, abbrEmptyMessage.length() );
        System.assertEquals( '', abbrEmptyMessage );

        System.assertEquals( 0, abbrNullMessage.length() );
        System.assertEquals( '', abbrNullMessage );

    }

    @IsTest
    static void test_matches() {

        Test.startTest();

        String regex = 'Hello, [a-zA-Z]+';

        System.assertEquals( true, MA_StringUtils.matches( 'Hello, Salesforce', regex ) );
        System.assertEquals( false, MA_StringUtils.matches( 'Hello, 123', regex ) );
        System.assertEquals( false, MA_StringUtils.matches( 'nope', regex ) );

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