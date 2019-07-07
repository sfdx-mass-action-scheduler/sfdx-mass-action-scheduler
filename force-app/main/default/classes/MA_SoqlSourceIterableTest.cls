/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_SoqlSourceIterableTest {

    @IsTest
    static void test_iterable() {

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Active__c = false,
            Batch_Size__c = 200,
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Source_Type__c = 'SOQL',
            Source_SOQL_Query__c = 'SELECT Id, Name FROM Account',
            Target_Type__c = 'Flow',
            Target_Action_Name__c = 'Test_Flow',
            Schedule_Frequency__c = 'Manual'
        );

        insert config;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        // Test Single Http Call

        Integer totalSize = 0;

        MA_SoqlSourceIterable iterable = new MA_SoqlSourceIterable( config.Id );

        while ( iterable.hasNext() ) {

            Map<String, Object> record = iterable.next();
            System.debug( JSON.serializePretty( record ) );

            totalSize++;

            switch on ( totalSize ) {
                when 1 {
                    System.assertEquals( 'Test Account 1', record.get( 'Name' ) );
                }
                when 2 {
                    System.assertEquals( 'Test Account 2', record.get( 'Name' ) );
                }
            }

        }

        System.assertEquals( 1, totalSize );

        // Test Multiple Http Calls

        totalSize = 0;

        iterable = new MA_SoqlSourceIterable( config.Id, 200 );

        while ( iterable.hasNext() ) {

            Map<String, Object> record = iterable.next();
            System.debug( JSON.serializePretty( record ) );

            totalSize++;

            switch on ( totalSize ) {
                when 1 {
                    System.assertEquals( 'Test Account 1', record.get( 'Name' ) );
                }
                when 2 {
                    System.assertEquals( 'Test Account 2', record.get( 'Name' ) );
                }
            }

        }

        System.assertEquals( 2, totalSize );

        Test.stopTest();

    }

    @IsTest
    static void test_iterator() {

        Test.startTest();

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Active__c = false,
            Batch_Size__c = 200,
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Source_Type__c = 'SOQL',
            Source_SOQL_Query__c = 'SELECT Id, Name FROM Account',
            Target_Type__c = 'Flow',
            Target_Action_Name__c = 'Test_Flow',
            Schedule_Frequency__c = 'Manual'
        );

        insert config;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Iterable<Map<String, Object>> iterable = (Iterable<Map<String, Object>>) new MA_SoqlSourceIterable( config.Id );
        Iterator<Map<String, Object>> iterator = iterable.iterator();

        String iterableJSON = JSON.serialize( iterable );
        String iteratorJSON = JSON.serialize( iterator );

        System.debug( 'iterableJSON=' + iterableJSON );
        System.debug( 'iteratorJSON=' + iteratorJSON );

        System.assertEquals( iterableJSON, iteratorJSON );

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