/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/**
 * Designed to upgrade the Mass Action Configuration page layout to include new
 * actions, fields, and related lists introduced in new package versions.
 *
 * This class uses the Apex Metadata API, and when deployed as a managed package
 * requires the Apex Setting "Deploy Metadata from Non-Certified Package Versions via Apex" enabled
 * because this app is not offered through the AppExchange.
 *
 * If you do not want to enable the setting for automatic page layout updates,
 * you can install the code from source from the project repository.
 *
 * This class explicitly uses 'without sharing' because it is invoked by the package install handler
 * and it is documented that the use of 'with sharing' by apex classes called by the handler may prevent installation.
 * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_install_handler.htm
 */
public without sharing class MA_UpgradePageLayoutsService {

    /**
     * Updates page layouts bundled with the Mass Action Scheduler managed package,
     * such as ensure action buttons are on the layout and related lists are configured.
     *
     * Returns the enqueued metadata deployment id.
     */
    public ID upgrade() {

        System.debug( 'MA_UpgradePageLayoutsService.upgrade' );

        Metadata.DeployContainer container = buildMetadataDeployContainer();
        Metadata.DeployCallback callback = new MA_MetadataDeployCallback();

        ID deploymentId = ( Test.isRunningTest() ? '0Af00000000000TEST' : Metadata.Operations.enqueueDeployment( container, callback ) );

        System.debug( 'MA_UpgradePageLayoutsService.upgrade: deploymentId=' + deploymentId );

        return deploymentId;
    }

    /**
     * Builds a metadata deploy container to include any page layout
     * changes to make in this package upgrade.
     *
     * For easier testability, this exists as its own method.
     */
    @TestVisible
    private Metadata.DeployContainer buildMetadataDeployContainer() {

        Metadata.DeployContainer container = new Metadata.DeployContainer();

        List<Metadata.Metadata> metadataToDeploy = new List<Metadata.Metadata>();
        metadataToDeploy.addAll( update_MassActionConfiguration_PageLayouts() );

        for ( Metadata.Metadata md : metadataToDeploy ) {
            container.addMetadata( md );
        }

        return container;
    }

    // ------------------------------------------------------------------------

    private List<Metadata.Metadata> update_MassActionConfiguration_PageLayouts() {

        String namespace = MA_NamespaceUtils.NAMESPACE_API;

        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(
            Metadata.MetadataType.Layout,
            new List<String>{
                String.format(
                    '{0}Mass_Action_Configuration__c-{0}Mass Action Configuration Layout',
                    new Object[] { namespace }
                )
            }
        );

        System.debug( 'MA_UpgradePageLayoutsService.update_MassActionConfiguration_PageLayouts: current page layouts:' );
        System.debug( JSON.serializePretty( layouts ) );

        Metadata.Layout layout = (Metadata.Layout) layouts[0];

        update_MassActionConfigurationLayout_PlatformActionItems( layout );
        update_MassActionConfigurationLayout_RelatedLists( layout );

        System.debug( 'MA_UpgradePageLayoutsService.update_MassActionConfiguration_PageLayouts: updated page layouts:' );
        System.debug( JSON.serializePretty( layouts ) );

        return layouts;
    }

    /**
     * Ensures our "Run_via_Flow" and "Quick_Edit" action items are on the page layout.
     * Switches out the original "Run" action item with the newer "Run_via_Flow" action item.
     */
    private void update_MassActionConfigurationLayout_PlatformActionItems( Metadata.Layout layout ) {

        // This may or may not be blank depending on if the code is
        // part of the managed package or not
        String namespace = MA_NamespaceUtils.NAMESPACE_API;

        // Pattern to identify action items part of the MAS codebase.
        // Note the `?` to indicate the namespace may or may not exist
        // in the platform actions names, which is part of the problem
        // when upgrading and the actions disappearing from page layouts
        // as the namespace might not exist in the name and so when
        // admins would save the page layout then the actions would drop off
        // and have to be readded manually in the Page Layout Editor.
        // This upgrade code handles that by ensuring the appropriate names are assigned.
        String runActionItemRegex = '(?i)(dca_mass_action__)?Mass_Action_Configuration__c\\.(dca_mass_action__)?(Run|Run_via_Flow)';
        String quickEditActionItemRegex = '(?i)(dca_mass_action__)?Mass_Action_Configuration__c\\.(dca_mass_action__)?Quick_Edit';

        List<Metadata.PlatformActionListItem> platformActionListItemsToKeep = new List<Metadata.PlatformActionListItem>();

        for ( Metadata.PlatformActionListItem platformActionListItem : layout.platformActionList.platformActionListItems ) {

            Boolean matchesRunActionItem = MA_StringUtils.matches( platformActionListItem.actionName, runActionItemRegex );
            Boolean matchesQuickEditActionItem = MA_StringUtils.matches( platformActionListItem.actionName, quickEditActionItemRegex );

            if ( !matchesRunActionItem && !matchesQuickEditActionItem ) {
                platformActionListItemsToKeep.add( platformActionListItem );
            }

        }

        // -----------------------------------------------------------

        Metadata.PlatformActionListItem runActionItem = new Metadata.PlatformActionListItem();
        runActionItem.actionType = Metadata.PlatformActionTypeEnum.QuickAction;
        runActionItem.actionName = String.format(
            '{0}Mass_Action_Configuration__c.{0}Run_via_Flow',
            new Object[] { namespace }
        );

        platformActionListItemsToKeep.add( runActionItem );

        // -----------------------------------------------------------

        Metadata.PlatformActionListItem quickEditActionItem = new Metadata.PlatformActionListItem();
        quickEditActionItem.actionType = Metadata.PlatformActionTypeEnum.QuickAction;
        quickEditActionItem.actionName = String.format(
            '{0}Mass_Action_Configuration__c.{0}Quick_Edit',
            new Object[] { namespace }
        );

        platformActionListItemsToKeep.add( quickEditActionItem );

        // -----------------------------------------------------------

        // Sort the action items.
        // Our Run and Quick Edit actions will be the first two.
        Integer sortIndex = 2;
        for ( Metadata.PlatformActionListItem platformActionListItem : platformActionListItemsToKeep ) {
            if ( platformActionListItem == runActionItem ) {
                platformActionListItem.sortOrder = 0;
            } else if ( platformActionListItem == quickEditActionItem ) {
                platformActionListItem.sortOrder = 1;
            } else {
                platformActionListItem.sortOrder = sortIndex++;
            }
        }

        // -----------------------------------------------------------

        layout.platformActionList.platformActionListItems = platformActionListItemsToKeep;

    }

    private void update_MassActionConfigurationLayout_RelatedLists( Metadata.Layout layout ) {

        // This may or may not be blank depending on if the code is
        // part of the managed package or not
        String namespace = MA_NamespaceUtils.NAMESPACE_API;

        // Pattern to identify related lists part of the MAS codebase.
        // Note the `?` to indicate the namespace may or may not exist.
        // This upgrade code handles that by ensuring the appropriate names are assigned.
        String fieldMappingsListRegex = '(?i)(dca_mass_action__)?Mass_Action_Mapping__c\\.(dca_mass_action__)?Mass_Action_Configuration__c';
        String parentLogsListRegex = '(?i)(dca_mass_action__)?Mass_Action_Log__c\\.(dca_mass_action__)?Parent_Log_Configuration__c';
        String allLogsListRegex = '(?i)(dca_mass_action__)?Mass_Action_Log__c\\.(dca_mass_action__)?Mass_Action_Configuration__c';

        // existing related lists to keep on page layout
        List<Metadata.RelatedListItem> relatedListItemsToKeep = new List<Metadata.RelatedListItem>();

        // exclude any of our related lists while preserving ones the subscriber org has added
        for ( Metadata.RelatedListItem relatedListItem : layout.relatedLists ) {

            Boolean matchesFieldMappingList = MA_StringUtils.matches( relatedListItem.relatedList, fieldMappingsListRegex );
            Boolean matchesParentLogsList = MA_StringUtils.matches( relatedListItem.relatedList, parentLogsListRegex );
            Boolean matchesAllLogsList = MA_StringUtils.matches( relatedListItem.relatedList, allLogsListRegex );

            if ( !matchesFieldMappingList && !matchesParentLogsList && !matchesAllLogsList ) {
                relatedListItemsToKeep.add( relatedListItem );
            }

        }

        // -----------------------------------------------------------

        Metadata.RelatedListItem fieldMappingRelatedListItem = new Metadata.RelatedListItem();

        fieldMappingRelatedListItem.relatedList = String.format(
            '{0}Mass_Action_Mapping__c.{0}Mass_Action_Configuration__c',
            new Object[] { namespace }
        );

        fieldMappingRelatedListItem.fields = new String[] {
            'NAME',
            String.format(
                '{0}Source_Field_Name__c',
                new Object[] { namespace }
            ),
            String.format(
                '{0}Target_Field_Name__c',
                new Object[] { namespace }
            )
        };

        fieldMappingRelatedListItem.sortField = String.format(
            '{0}Source_Field_Name__c',
            new Object[] { namespace }
        );
        fieldMappingRelatedListItem.sortOrder = Metadata.SortOrder.Asc_x;

        // -----------------------------------------------------------

        Metadata.RelatedListItem parentLogsRelatedListItem = new Metadata.RelatedListItem();

        parentLogsRelatedListItem.relatedList = String.format(
            '{0}Mass_Action_Log__c.{0}Parent_Log_Configuration__c',
            new Object[] { namespace }
        );

        parentLogsRelatedListItem.fields = new String[] {
            'NAME',
            String.format(
                '{0}Job_ID__c',
                new Object[] { namespace }
            ),
            String.format(
                '{0}Message__c',
                new Object[] { namespace }
            ),
            String.format(
                '{0}Batch_Success_Rate__c',
                new Object[] { namespace }
            ),
            String.format(
                '{0}Total_Batches__c',
                new Object[] { namespace }
            ),
            String.format(
                '{0}Processed_Batches__c',
                new Object[] { namespace }
            ),
            String.format(
                '{0}Failed_Batches__c',
                new Object[] { namespace }
            ),
            String.format(
                '{0}Timestamp__c',
                new Object[] { namespace }
            )
        };

        parentLogsRelatedListItem.sortField = String.format(
            '{0}Timestamp__c',
            new Object[] { namespace }
        );
        parentLogsRelatedListItem.sortOrder = Metadata.SortOrder.Desc_x;

        // -----------------------------------------------------------

        // add related lists in the order we want them
        List<Metadata.RelatedListItem> relatedListItemsToAdd = new List<Metadata.RelatedListItem>();
        relatedListItemsToAdd.add( fieldMappingRelatedListItem );
        relatedListItemsToAdd.add( parentLogsRelatedListItem );
        relatedListItemsToAdd.addAll( relatedListItemsToKeep );

        layout.relatedLists = relatedListItemsToAdd;

    }

    // ------------------------------------------------------------------------

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