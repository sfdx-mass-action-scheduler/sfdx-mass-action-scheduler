/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_MapUtilsTest {

    @IsTest
    static void test_convertKeysToLowercase() {

        Test.startTest();

        Map<String, String> map1 = new Map<String, String>{ 'a' => 'apple', 'B' => 'BANANA', null => 'null-key' };
        Map<String, Object> map2 = MA_MapUtils.convertKeysToLowercase( map1 );

        System.assertEquals( 'apple', map1.get( 'a' ) );
        System.assertEquals( null,    map1.get( 'A' ) );

        System.assertEquals( 'apple', map2.get( 'a' ) );
        System.assertEquals( null,    map2.get( 'A' ) );

        System.assertEquals( null,     map1.get( 'b' ) );
        System.assertEquals( 'BANANA', map1.get( 'B' ) );

        System.assertEquals( 'BANANA', map2.get( 'b' ) );
        System.assertEquals( null,     map2.get( 'B' ) );

        System.assertEquals( 'null-key', map1.get( null ) );
        System.assertEquals( 'null-key', map2.get( null ) );

        System.assertEquals( null, MA_MapUtils.convertKeysToLowercase( null ) );

        Test.stopTest();

    }

    @IsTest
    static void test_visitFieldPaths_sobject() {

        Account parentAcct = new Account(
            Name = 'Test Parent Account'
        );

        insert parentAcct;

        Account childAcct = new Account(
            ParentId = parentAcct.Id,
            Name = 'Test Child Account'
        );

        insert childAcct;

        Contact cont = new Contact(
            AccountId = childAcct.Id,
            FirstName = 'Doug',
            LastName = 'Ayers'
        );

        insert cont;

        Contact record = [
            SELECT
                Id, AccountId, FirstName, LastName,
                Account.Id, Account.Name,
                Account.ParentId, Account.Parent.Id, Account.Parent.Name
            FROM
                Contact
            WHERE
                Id = :cont.Id
        ];

        Test.startTest();

        System.debug( JSON.serializePretty( record ) );

        Map<String, Object> recordMap = MA_MapUtils.visitFieldPaths( record );

        System.debug( JSON.serializePretty( recordMap ) );

        Test.stopTest();

        System.assertEquals( record.Id, recordMap.get( 'Id' ) );
        System.assertEquals( record.FirstName, recordMap.get( 'FirstName' ) );
        System.assertEquals( record.LastName, recordMap.get( 'LastName' ) );
        System.assertEquals( record.AccountId, recordMap.get( 'AccountId' ) );

        System.assertEquals( record.Account.Id, recordMap.get( 'Account.Id' ) );
        System.assertEquals( record.Account.Name, recordMap.get( 'Account.Name' ) );
        System.assertEquals( record.Account.ParentId, recordMap.get( 'Account.ParentId' ) );

        System.assertEquals( record.Account.Parent.Id, recordMap.get( 'Account.Parent.Id' ) );
        System.assertEquals( record.Account.Parent.Name, recordMap.get( 'Account.Parent.Name' ) );

    }

    @IsTest
    static void test_visitFieldPaths_map() {

        Account parentAcct = new Account(
            Name = 'Test Parent Account'
        );

        insert parentAcct;

        Account childAcct = new Account(
            ParentId = parentAcct.Id,
            Name = 'Test Child Account'
        );

        insert childAcct;

        Contact cont = new Contact(
            AccountId = childAcct.Id,
            FirstName = 'Doug',
            LastName = 'Ayers'
        );

        insert cont;

        Contact record = [
            SELECT
                Id, AccountId, FirstName, LastName,
                Account.Id, Account.Name,
                Account.ParentId, Account.Parent.Id, Account.Parent.Name
            FROM
                Contact
            WHERE
                Id = :cont.Id
        ];

        Test.startTest();

        System.debug( JSON.serializePretty( record ) );

        Map<String, Object> recordMap = MA_MapUtils.visitFieldPaths(
            (Map<String, Object>) JSON.deserializeUntyped( JSON.serialize( record ) )
        );

        System.debug( JSON.serializePretty( recordMap ) );

        Test.stopTest();

        System.assertEquals( record.Id, recordMap.get( 'Id' ) );
        System.assertEquals( record.FirstName, recordMap.get( 'FirstName' ) );
        System.assertEquals( record.LastName, recordMap.get( 'LastName' ) );
        System.assertEquals( record.AccountId, recordMap.get( 'AccountId' ) );

        System.assertEquals( record.Account.Id, recordMap.get( 'Account.Id' ) );
        System.assertEquals( record.Account.Name, recordMap.get( 'Account.Name' ) );
        System.assertEquals( record.Account.ParentId, recordMap.get( 'Account.ParentId' ) );

        System.assertEquals( record.Account.Parent.Id, recordMap.get( 'Account.Parent.Id' ) );
        System.assertEquals( record.Account.Parent.Name, recordMap.get( 'Account.Parent.Name' ) );

    }

}
/*
BSD 3-Clause License

Copyright (c) 2017-2020, Doug Ayers, douglascayers.com
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