/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_MassActionLogTriggerHandler {

    public MA_MassActionLogTriggerHandler() {}

    // -------------------------------------------------------
    // INSERT
    // -------------------------------------------------------

    public void handleBeforeInsert( List<Mass_Action_Log__c> newList ) {

        formatJobId( newList );
        assignParentLogConfiguration( newList );

    }

    public void handleAfterInsert( List<Mass_Action_Log__c> newList, Map<ID, Mass_Action_Log__c> newMap ) {

        // no logic yet

    }

    // -------------------------------------------------------
    // UPDATE
    // -------------------------------------------------------

    public void handleBeforeUpdate( List<Mass_Action_Log__c> oldList, Map<ID, Mass_Action_Log__c> oldMap,
                                    List<Mass_Action_Log__c> newList, Map<ID, Mass_Action_Log__c> newMap ) {

        formatJobId( newList );
        assignParentLogConfiguration( newList );

    }

    public void handleAfterUpdate( List<Mass_Action_Log__c> oldList, Map<ID, Mass_Action_Log__c> oldMap,
                                   List<Mass_Action_Log__c> newList, Map<ID, Mass_Action_Log__c> newMap ) {

        // no logic yet

    }

    // -------------------------------------------------------
    // DELETE
    // -------------------------------------------------------

    public void handleBeforeDelete( List<Mass_Action_Log__c> oldList, Map<ID, Mass_Action_Log__c> oldMap ) {

        cascadeDeleteChildLogs( oldMap.keySet() );

    }

    public void handleAfterDelete( List<Mass_Action_Log__c> oldList, Map<ID, Mass_Action_Log__c> oldMap ) {

        // no logic yet

    }

    // -------------------------------------------------------

    /**
     * Designed to be called during `before delete` trigger event.
     *
     * If this were called during `after delete` then the parent logs
     * will have been deleted and the child log's Parent_Log__c field
     * will have been blanked out and so the query will not find any
     * child logs to delete.
     */
    private static void cascadeDeleteChildLogs( Set<ID> parentLogIds ) {
        delete [
            SELECT
                Id
            FROM
                Mass_Action_Log__c
            WHERE
                Parent_Log__c IN :parentLogIds
                AND
                RecordType.DeveloperName = 'Child_Log'
            ORDER BY
                Parent_Log__c
        ];
    }

    /**
     * Designed to be called during `before insert` and `before update` trigger events.
     *
     * We don't have lookup fields to AsyncApexJob records.
     * When filtering by this field in SOQL, since it's technically a text field
     * and not an ID field, then the field value and filter value must match
     * length exactly. So standardizing on the 15 character id, least common denominator.
     */
    private static void formatJobId( List<Mass_Action_Log__c> newLogs ) {

        for ( Mass_Action_Log__c newLog : newLogs ) {

            if ( String.isNotBlank( newLog.Job_ID__c ) ) {
                newLog.Job_ID__c = newLog.Job_ID__c.left( 15 );
            }

        }

    }

    /**
     * Designed to be called during `before insert` and `before update` trigger events.
     *
     * Sets the new log's parent log configuration lookup field based on its record type.
     * This is how we implement filtered related lists on the mass action configuration page.
     * https://douglascayers.com/2015/11/18/salesforce-filter-related-lists-without-code/
     */
    private static void assignParentLogConfiguration( List<Mass_Action_Log__c> newLogs ) {

        Map<ID, RecordTypeInfo> recordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosById();

        for ( Mass_Action_Log__c newLog : newLogs ) {

            RecordTypeInfo rt = recordTypeInfosMap.get( newLog.RecordTypeId );
            Boolean isParentLog = ( rt != null && rt.getDeveloperName() == 'Parent_Log' );
            newLog.Parent_Log_Configuration__c = ( isParentLog ? newLog.Mass_Action_Configuration__c : null );

        }

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