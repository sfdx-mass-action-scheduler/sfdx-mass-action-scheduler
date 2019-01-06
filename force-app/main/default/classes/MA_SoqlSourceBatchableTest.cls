/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_SoqlSourceBatchableTest {

    @IsTest
    static void test_batchable_Workflow() {

        test_batchable( 'Workflow', null, 'Account' );

    }

    @IsTest
    static void test_batchable_Flow() {

        test_batchable( 'Flow', 'Test_Flow', null );

    }

    @IsTest
    static void test_batchable_QuickAction() {

        test_batchable( 'QuickAction', 'Test_Quick_Action', 'Account' );

    }

    @IsTest
    static void test_batchable_EmailAlert() {

        test_batchable( 'EmailAlert', 'Test_Email_Alert', 'Account' );

    }

    @IsTest
    static void test_batchable_Apex() {

        test_batchable( 'Apex', 'Test_Apex', null );

    }

    static void test_batchable( String targetType, String targetActionName, String targetSobjectType ) {

        String objectName = MA_MassActionUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'SOQL',
            Source_SOQL_Query__c = 'SELECT Id, Name FROM Account LIMIT 10',
            Target_Type__c = targetType,
            Target_Action_Name__c = targetActionName,
            Target_SObject_Type__c = targetSobjectType
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'Id',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Account acct = new Account(
            Name = 'Test Account'
        );

        insert acct;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        ID jobId = Database.executeBatch( new MA_SoqlSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );

        Test.stopTest();

        AsyncApexJob job = MA_MassActionBatchUtils.getJobById( jobId );

        config = [
            SELECT
                Id,
                Last_Run_Completed_Date__c,
                Last_Run_Completed_With_Errors__c
            FROM
                Mass_Action_Configuration__c
            WHERE
                Id = :config.Id
        ];

        System.assertEquals( 0, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE Mass_Action_Configuration__c = :config.Id ] );
        System.assertEquals( job.CompletedDate, config.Last_Run_Completed_Date__c );
        System.assertEquals( false, config.Last_Run_Completed_With_Errors__c );

    }

    @IsTest
    static void test_batchable_fail() {

        String objectName = MA_MassActionUtils.NAMESPACE_API + 'Mass_Action_Configuration__c';

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = 'Test Config',
            DeveloperName__c = 'Test_Config',
            Named_Credential__c = 'Mass_Action_Test_Named_Credential',
            Active__c = true,
            Batch_Size__c = 200,
            Source_Type__c = 'SOQL',
            Source_SOQL_Query__c = 'SELECT Id, Name FROM Account LIMIT 10',
            Target_Type__c = 'Flow',
            Target_Action_Name__c = 'Test_Flow',
            Target_SObject_Type__c = null
        );

        insert config;

        Mass_Action_Mapping__c configFieldMapping = new Mass_Action_Mapping__c(
            Mass_Action_Configuration__c = config.Id,
            Source_Field_Name__c = 'NON_EXISTENT_FIELD',
            Target_Field_Name__c = 'ContextId'
        );

        insert configFieldMapping;

        Account acct = new Account(
            Name = 'Test Account'
        );

        insert acct;

        Test.setMock( HttpCalloutMock.class, new MA_HttpCalloutMock() );

        Test.startTest();

        ID jobId = Database.executeBatch( new MA_SoqlSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );

        Test.stopTest();

        AsyncApexJob job = MA_MassActionBatchUtils.getJobById( jobId );

        config = [
            SELECT
                Id,
                Last_Run_Completed_Date__c,
                Last_Run_Completed_With_Errors__c
            FROM
                Mass_Action_Configuration__c
            WHERE
                Id = :config.Id
        ];

        System.assertEquals( 1, [ SELECT COUNT() FROM Mass_Action_Log__c WHERE Mass_Action_Configuration__c = :config.Id ] );
        System.assertEquals( job.CompletedDate, config.Last_Run_Completed_Date__c );
        System.assertEquals( true, config.Last_Run_Completed_With_Errors__c );

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