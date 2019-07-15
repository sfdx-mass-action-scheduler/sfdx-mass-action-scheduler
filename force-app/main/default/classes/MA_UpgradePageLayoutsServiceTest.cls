/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_UpgradePageLayoutsServiceTest {

    // https://trailhead.salesforce.com/content/learn/modules/apex_metadata_api/apex_metadata_api_testing

    @IsTest
    static void test_upgrade() {

        Test.startTest();

        MA_UpgradePageLayoutsService service = new MA_UpgradePageLayoutsService();

        ID deploymentId = service.upgrade();

        Test.stopTest();

        // can't actually do a deployment in a test,
        // so assert we got back our mock deploy id
        System.assertEquals( '0Af00000000000TEST', deploymentId );

    }

    @IsTest
    static void test_buildMetadataDeployContainer() {

        String namespace = MA_NamespaceUtils.NAMESPACE_API;

        String MassActionConfigurationPageLayoutName = String.format(
            '{0}Mass_Action_Configuration__c-{0}Mass Action Configuration Layout',
            new Object[] { namespace }
        );

        Test.startTest();

        MA_UpgradePageLayoutsService service = new MA_UpgradePageLayoutsService();

        Metadata.DeployContainer container = service.buildMetadataDeployContainer();

        Test.stopTest();

        System.debug( JSON.serializePretty( container ) );

        Boolean foundMassActionConfigurationPageLayout = false;

        for ( Metadata.Metadata md : container.getMetadata() ) {
            if ( md.fullName == MassActionConfigurationPageLayoutName ) {
                foundMassActionConfigurationPageLayout = true;
                validateMassActionConfigurationPageLayout( (Metadata.Layout) md );
            }
        }

        System.assertEquals( true, foundMassActionConfigurationPageLayout, 'did not find Mass Action Configuration page layout' );

    }

    private static void validateMassActionConfigurationPageLayout( Metadata.Layout layout ) {

        String namespace = MA_NamespaceUtils.NAMESPACE_API;

        String runActionListItemName = String.format( '{0}Mass_Action_Configuration__c.{0}Run', new Object[] { namespace } );
        String runFlowActionListItemName = String.format( '{0}Mass_Action_Configuration__c.{0}Run_via_Flow', new Object[] { namespace } );
        String quickEditActionListItemName = String.format( '{0}Mass_Action_Configuration__c.{0}Quick_Edit', new Object[] { namespace } );

        Boolean foundRunFlowActionListItem = false;
        Boolean foundQuickEditActionListItem = false;

        System.assert( layout.platformActionList.platformActionListItems.size() >= 2, 'missing action list items' );

        for ( Metadata.PlatformActionListItem action : layout.platformActionList.platformActionListItems ) {
            if ( action.actionName == runActionListItemName ) {
                System.assert( false, 'found ' + action.actionName + ' action list item, but it should have been removed' );
            } else if ( action.actionName == runFlowActionListItemName ) {
                foundRunFlowActionListItem = true;
                System.assertEquals( 0, action.sortOrder );
            } else if ( action.actionName == quickEditActionListItemName ) {
                foundQuickEditActionListItem = true;
                System.assertEquals( 1, action.sortOrder );
            }
        }

        System.assertEquals( true, foundRunFlowActionListItem, 'did not find Run Flow action list item' );
        System.assertEquals( true, foundQuickEditActionListItem, 'did not find Quick Edit action list item' );

        // -----------------------------------------------------------

        String fieldMappingsListName = String.format( '{0}Mass_Action_Mapping__c.{0}Mass_Action_Configuration__c', new Object[] { namespace } );
        String parentLogsListName = String.format( '{0}Mass_Action_Log__c.{0}Parent_Log_Configuration__c', new Object[] { namespace } );
        String allLogsListName = String.format( '{0}Mass_Action_Log__c.{0}Mass_Action_Configuration__c', new Object[] { namespace } );

        Boolean foundFieldMappingsList = false;
        Boolean foundParentLogsList = false;

        System.assert( layout.relatedLists.size() >= 2, 'missing related lists' );

        for ( Metadata.RelatedListItem relatedListItem : layout.relatedLists ) {
            if ( relatedListItem.relatedList == allLogsListName ) {
                System.assert( false, 'found ' + relatedListItem.relatedList + ' related list, but it should have been removed' );
            } else if ( relatedListItem.relatedList == fieldMappingsListName ) {
                foundFieldMappingsList = true;
            } else if ( relatedListItem.relatedList == parentLogsListName ) {
                foundParentLogsList = true;
            }
        }

        System.assertEquals( true, foundFieldMappingsList, 'did not find Field Mappings related list' );
        System.assertEquals( true, foundParentLogsList, 'did not find Parent Logs related list' );

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