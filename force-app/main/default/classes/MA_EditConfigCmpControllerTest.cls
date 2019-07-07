/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_EditConfigCmpControllerTest {

    @IsTest
    static void test_saveConfiguration() {

        MA_MassActionConfigWrapper wrapper = new MA_MassActionConfigWrapper();
        wrapper.name = 'Test Config';
        wrapper.developerName = 'Test_Config';
        wrapper.active = false;
        wrapper.batchSize = 200;
        wrapper.namedCredential = 'Mass_Action_Test_Named_Credential';
        wrapper.sourceType = 'ListView';
        wrapper.sourceListViewID = '00Bf40000017w5h';
        wrapper.targetType = 'Flow';
        wrapper.targetActionName = 'Test_Flow';
        wrapper.scheduleFrequency = 'Custom';
        wrapper.scheduleCron = '0 0 1 * * ?';

        String wrapperJson = JSON.serialize( wrapper );

        String fieldMappingsJson = JSON.serialize( new Map<String, String>{
            'TargetField' => 'SourceField'
        });

        Test.startTest();

        // Test Success

        Map<String, Object> result = MA_EditConfigCmpController.saveConfiguration( wrapperJson, fieldMappingsJson );

        System.assertEquals( true, result.get( 'success' ) );

        Mass_Action_Configuration__c config = MA_MassActionUtils.getConfiguration( (ID) result.get( 'recordId' ) );

        System.assertEquals( wrapper.name, config.Name );
        System.assertEquals( wrapper.active, config.Active__c );
        System.assertEquals( wrapper.batchSize, config.Batch_Size__c );
        System.assertEquals( wrapper.namedCredential, config.Named_Credential__c );
        System.assertEquals( wrapper.sourceType, config.Source_Type__c );
        System.assertEquals( wrapper.sourceListViewID, config.Source_List_View_ID__c );
        System.assertEquals( wrapper.targetType, config.Target_Type__c );
        System.assertEquals( wrapper.targetActionName, config.Target_Action_Name__c );
        System.assertEquals( wrapper.scheduleFrequency, config.Schedule_Frequency__c );
        System.assertEquals( wrapper.scheduleCron, config.Schedule_Cron__c );

        System.assertEquals( 1, config.Mass_Action_Mappings__r.size() );
        System.assertEquals( 'TargetField', config.Mass_Action_Mappings__r[0].Target_Field_Name__c );
        System.assertEquals( 'SourceField', config.Mass_Action_Mappings__r[0].Source_Field_Name__c );

        // Test Error

        try {

            MA_EditConfigCmpController.saveConfiguration( null, null );

            System.assert( false, 'should fail' );

        } catch ( Exception e ) {

            System.assert( true, 'should fail' );

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