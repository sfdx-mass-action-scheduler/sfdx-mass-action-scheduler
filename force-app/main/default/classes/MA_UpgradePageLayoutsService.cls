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

    public void upgrade() {

        System.debug( 'MA_UpgradeMassActionConfigPageLayout: upgrade page layouts' );

        Metadata.DeployContainer container = new Metadata.DeployContainer();
        Metadata.DeployCallback callback = new MA_MetadataDeployCallback();

        List<Metadata.Metadata> metadataToDeploy = new List<Metadata.Metadata>();
        metadataToDeploy.addAll( update_MassActionConfiguration_PageLayouts() );

        for ( Metadata.Metadata md : metadataToDeploy ) {
            container.addMetadata( md );
        }

        System.debug( 'MA_UpgradeMassActionConfigPageLayout: enqueue deployment' );
        ID deploymentId = Metadata.Operations.enqueueDeployment( container, callback );
        System.debug( 'deploymentId=' + deploymentId );

    }

    // ------------------------------------------------------------------------

    private List<Metadata.Metadata> update_MassActionConfiguration_PageLayouts() {

        String namespace = MA_MassActionUtils.NAMESPACE_API;

        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(
            Metadata.MetadataType.Layout,
            new List<String>{
                String.format(
                    '{0}Mass_Action_Configuration__c-{0}Mass Action Configuration Layout',
                    new Object[] { namespace }
                )
            }
        );

        System.debug( 'MA_UpgradeMassActionConfigPageLayout.update_MassActionConfiguration_PageLayouts: current page layouts:' );
        System.debug( JSON.serializePretty( layouts ) );

        Metadata.Layout layout = (Metadata.Layout) layouts[0];

        update_MassActionConfigurationLayout_PlatformActionItems( layout );
        update_MassActionConfigurationLayout_RelatedLists( layout );

        System.debug( 'MA_UpgradeMassActionConfigPageLayout.update_MassActionConfiguration_PageLayouts: updated page layouts:' );
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
        String namespace = MA_MassActionUtils.NAMESPACE_API;

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

        Metadata.PlatformActionList platformActionList = layout.platformActionList;

        Metadata.PlatformActionListItem runActionItem;
        Metadata.PlatformActionListItem quickEditActionItem;

        // Check if the Run and Quick Edit action items are already on the page layout
        for ( Metadata.PlatformActionListItem platformActionListItem : platformActionList.platformActionListItems ) {
            if ( MA_StringUtils.matches( platformActionListItem.actionName, runActionItemRegex ) ) {
                runActionItem = platformActionListItem;
            }
            else if ( MA_StringUtils.matches( platformActionListItem.actionName, quickEditActionItemRegex ) ) {
                quickEditActionItem = platformActionListItem;
            }
        }

        // -----------------------------------------------------------

        // If the run action is not in the layout, add it
        if ( runActionItem == null ) {
            runActionItem = new Metadata.PlatformActionListItem();
            runActionItem.actionType = Metadata.PlatformActionTypeEnum.QuickAction;
            platformActionList.platformActionListItems.add( runActionItem );
        }

        // Ensure the run action has the correct fully qualified name
        runActionItem.actionName = String.format(
            '{0}Mass_Action_Configuration__c.{0}Run_via_Flow',
            new Object[] { namespace }
        );

        // -----------------------------------------------------------

        // If the quick edit action is not in the layout, add it
        if ( quickEditActionItem == null ) {
            quickEditActionItem = new Metadata.PlatformActionListItem();
            quickEditActionItem.actionType = Metadata.PlatformActionTypeEnum.QuickAction;
            platformActionList.platformActionListItems.add( quickEditActionItem );
        }

        // Ensure the quick edit action has the correct fully qualified name
        quickEditActionItem.actionName = String.format(
            '{0}Mass_Action_Configuration__c.{0}Quick_Edit',
            new Object[] { namespace }
        );

        // -----------------------------------------------------------

        // Sort the action items.
        // Our Run and Quick Edit actions will be the first two.
        Integer sortIndex = 2;
        for ( Metadata.PlatformActionListItem platformActionListItem : platformActionList.platformActionListItems ) {
            if ( platformActionListItem == runActionItem ) {
                platformActionListItem.sortOrder = 0;
            } else if ( platformActionListItem == quickEditActionItem ) {
                platformActionListItem.sortOrder = 1;
            } else {
                platformActionListItem.sortOrder = sortIndex++;
            }
        }

    }

    private void update_MassActionConfigurationLayout_RelatedLists( Metadata.Layout layout ) {

        // This may or may not be blank depending on if the code is
        // part of the managed package or not
        String namespace = MA_MassActionUtils.NAMESPACE_API;

        // Pattern to identify related lists part of the MAS codebase.
        // Note the `?` to indicate the namespace may or may not exist.
        // This upgrade code handles that by ensuring the appropriate names are assigned.
        String fieldMappingRegex = '(?i)(dca_mass_action__)?Mass_Action_Mapping__c\\.(dca_mass_action__)?Mass_Action_Configuration__c';
        String parentLogsRegex = '(?i)(dca_mass_action__)?Mass_Action_Log__c\\.(dca_mass_action__)?Parent_Log_Configuration__c';
        String allLogsRegex = '(?i)(dca_mass_action__)?Mass_Action_Log__c\\.(dca_mass_action__)?Mass_Action_Configuration__c';

        List<Metadata.RelatedListItem> relatedListItems = layout.relatedLists;

        Metadata.RelatedListItem fieldMappingRelatedListItem;
        Metadata.RelatedListItem parentLogsRelatedListItem;

        for ( Metadata.RelatedListItem relatedListItem : relatedListItems ) {
            if ( MA_StringUtils.matches( relatedListItem.relatedList, fieldMappingRegex ) ) {
                fieldMappingRelatedListItem = relatedListItem;
            } else if ( MA_StringUtils.matches( relatedListItem.relatedList, parentLogsRegex ) ) {
                parentLogsRelatedListItem = relatedListItem;
            }
        }

        // -----------------------------------------------------------

        // If the related list is not in the layout, add it
        if ( fieldMappingRelatedListItem == null ) {
            fieldMappingRelatedListItem = new Metadata.RelatedListItem();
            relatedListItems.add( fieldMappingRelatedListItem );
        }

        // Ensure the related list has the correct fully qualified name
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

        if ( parentLogsRelatedListItem == null ) {
            parentLogsRelatedListItem = new Metadata.RelatedListItem();
            relatedListItems.add( parentLogsRelatedListItem );
        }

        // Ensure the related list has the correct fully qualified name
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

        // Replace the related lists on the page layout
        List<Metadata.RelatedListItem> relatedListItemsToKeep = new List<Metadata.RelatedListItem>();
        for ( Metadata.RelatedListItem relatedListItem : relatedListItems ) {
            Boolean matchesAllLogsList = MA_StringUtils.matches( relatedListItem.relatedList, allLogsRegex );
            if ( !matchesAllLogsList ) {
                relatedListItemsToKeep.add( relatedListItem );
            }
        }
        layout.relatedLists = relatedListItemsToKeep;

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