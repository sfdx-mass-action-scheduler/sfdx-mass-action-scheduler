/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_RunConfigInvocableTest {

    @TestSetup
    static void setup() {

        String objectName = MA_NamespaceUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';
        ListView lv = [ SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE DeveloperName = 'All' AND SobjectType = :objectName AND IsSoqlCompatible = true LIMIT 1 ];

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'ListView',
            Source_List_View_ID__c = lv.Id,
            Target_Type__c = 'Apex',
            Target_Action_Name__c = 'Test_Apex',
            Target_SObject_Type__c = null
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'Id',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

    }

    @IsTest
    static void test_invocable_by_id() {

        Mass_Action_Configuration__c config = [ SELECT Id FROM Mass_Action_Configuration__c WHERE DeveloperName__c = 'Test_Config' LIMIT 1 ];

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        MA_RunConfigInvocable.Request req = new MA_RunConfigInvocable.Request();
        req.configId = config.Id;

        List<MA_RunConfigInvocable.Response> responses = MA_RunConfigInvocable.execute( new List<MA_RunConfigInvocable.Request>{ req } );

        System.assertEquals( 1, responses.size() );
        System.assertEquals( 1, [ SELECT COUNT() FROM AsyncApexJob WHERE Id = :responses[0].jobId ] );

    }

    @IsTest
    static void test_invocable_by_unique_name() {

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        MA_RunConfigInvocable.Request req = new MA_RunConfigInvocable.Request();
        req.configUniqueName = 'Test_Config';

        List<MA_RunConfigInvocable.Response> responses = MA_RunConfigInvocable.execute( new List<MA_RunConfigInvocable.Request>{ req } );

        System.assertEquals( 1, responses.size() );
        System.assertEquals( 1, [ SELECT COUNT() FROM AsyncApexJob WHERE Id = :responses[0].jobId ] );

    }

    @IsTest
    static void test_invocable_no_data_found() {

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        try {

            MA_RunConfigInvocable.execute( new List<MA_RunConfigInvocable.Request>{ new MA_RunConfigInvocable.Request() } );

            System.assert( false, 'should have failed' );

        } catch ( Exception e ) {

            System.assert( e instanceof System.NoDataFoundException, 'expected NoDataFoundException but got ' + e );

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