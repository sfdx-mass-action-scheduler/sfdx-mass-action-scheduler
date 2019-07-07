/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_SetConfigUniqueNameBatchableTest {

    @IsTest
    private static void test_batch() {

        Mass_Action_Configuration__c c1 = new Mass_Action_Configuration__c(
            Name = ' Foo Bar '
        );

        Mass_Action_Configuration__c c2 = new Mass_Action_Configuration__c(
            Name = 'x'.repeat( Mass_Action_Configuration__c.Name.getDescribe().getLength() )
        );

        Mass_Action_Configuration__c c3 = new Mass_Action_Configuration__c(
            Name = 'duplicate'
        );

        Mass_Action_Configuration__c c4 = new Mass_Action_Configuration__c(
            Name = 'duplicate'
        );

        List<Mass_Action_Configuration__c> records = new List<Mass_Action_Configuration__c>{
            c1, c2, c3, c4
        };

        insert records;

        System.assertEquals( 4, [ SELECT COUNT() FROM Mass_Action_Configuration__c WHERE DeveloperName__c = null ] );

        Test.startTest();

        Database.executeBatch( new MA_SetConfigUniqueNameBatchable() );

        Test.stopTest();

        System.debug( 'batch updated records:' );
        for ( Mass_Action_Configuration__c record : [ SELECT Id, Name, DeveloperName__c FROM Mass_Action_Configuration__c ] ) {
            System.debug( record );
        }

        System.assertEquals( 4, [ SELECT COUNT() FROM Mass_Action_Configuration__c WHERE DeveloperName__c != null ] );
        System.assertEquals( 'Foo_Bar', [ SELECT DeveloperName__c FROM Mass_Action_Configuration__c WHERE Id = :c1.Id ].DeveloperName__c );
        System.assertEquals( c2.Name, [ SELECT DeveloperName__c FROM Mass_Action_Configuration__c WHERE Id = :c2.Id ].DeveloperName__c );
        System.assertEquals( 1, [ SELECT COUNT() FROM Mass_Action_Configuration__c WHERE DeveloperName__c = 'duplicate' ] );
        System.assertEquals( 1, [ SELECT COUNT() FROM Mass_Action_Configuration__c WHERE DeveloperName__c LIKE 'duplicate_%' ] );

    }

    @IsTest
    static void test_batch_200() {

        List<Mass_Action_Configuration__c> records = new List<Mass_Action_Configuration__c>();

        for ( Integer i = 0; i < 200; i++ ) {
            records.add( new Mass_Action_Configuration__c(
                Name = 'duplicate'
            ));
        }

        insert records;

        System.assertEquals( records.size(), [ SELECT COUNT() FROM Mass_Action_Configuration__c WHERE Name = 'duplicate' ] );
        System.assertEquals( records.size(), [ SELECT COUNT() FROM Mass_Action_Configuration__c WHERE DeveloperName__c = null ] );

        Test.startTest();

        // should generate new unique names for 199 of the 200 records
        Database.executeBatch( new MA_SetConfigUniqueNameBatchable() );

        Test.stopTest();

        System.assertEquals( 1, [ SELECT COUNT() FROM Mass_Action_Configuration__c WHERE DeveloperName__c = 'duplicate' ] );
        System.assertEquals( records.size() - 1, [ SELECT COUNT() FROM Mass_Action_Configuration__c WHERE DeveloperName__c LIKE 'duplicate_%' ] );

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