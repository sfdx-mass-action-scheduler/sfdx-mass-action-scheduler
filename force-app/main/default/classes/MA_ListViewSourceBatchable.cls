/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_ListViewSourceBatchable implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    private ID configId { get; set; }

    private Mass_Action_Configuration__c config { get; set; }

    private MA_ListViewDescribeResult listViewDescribe { get; set; }

    public MA_ListViewSourceBatchable( ID configId ) {
        this.configId = configId;
    }

    // ------------------------------------------------------------------------

    public Database.QueryLocator start( Database.BatchableContext context ) {

        System.debug( 'MA_ListViewSourceBatchable.start: ' + context + ', configId=' + this.configId );

        this.config = MA_MassActionUtils.getConfiguration( this.configId );

        this.listViewDescribe = MA_MassActionUtils.describeListView( this.config.named_credential__c, this.config.source_list_view_id__c );

        return Database.getQueryLocator( this.listViewDescribe.query );
    }

    public void execute( Database.BatchableContext context, List<SObject> records ) {

        try {

            System.debug( 'MA_ListViewSourceBatchable.execute: ' + context + ', configId=' + this.configId );

            List<Map<String, Object>> sourceRowMaps = convertRecordsToMaps( records, this.listViewDescribe );

            List<Map<String, Object>> targetRowMaps = MA_MassActionUtils.buildActionInputs( sourceRowMaps, this.config.mass_action_mappings__r );

            MA_MassActionUtils.invokeAction( this.config, targetRowMaps );

        } catch ( Exception e ) {

            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );

            MA_MassActionBatchUtils.logJobException( this.config.Id, context.getJobId(), e );

        }

    }

    public void finish( Database.BatchableContext context ) {

        System.debug( 'MA_ListViewSourceBatchable.finish: ' + context + ', configId=' + this.configId );

        MA_MassActionBatchUtils.logJobErrors( this.configId, context.getJobId() );

    }

    // ------------------------------------------------------------------------

    private List<Map<String, Object>> convertRecordsToMaps( List<SObject> records, MA_ListViewDescribeResult listViewDescribe ) {

        List<Map<String, Object>> maps = new List<Map<String, Object>>();

        List<String> columnNames = listViewDescribe.getColumnProperty( 'fieldNameOrPath' );

        for ( SObject record : records ) {
            maps.add( convertRecordToMap( record, columnNames ) );
        }

        return maps;
    }

    private Map<String, Object> convertRecordToMap( SObject record, List<String> columnNames ) {

        Map<String, Object> recordMap = new Map<String, Object>();

        for ( String columnName : columnNames ) {

            // column name might be field name like 'Status'
            // or might be field path like 'Owner.Alias'
            String[] fieldPaths = columnName.split( '\\.' );

            SObject value = record;

            // walk object path (e.g. record.Owner)
            for ( Integer i = 0; i < fieldPaths.size() - 1; i++ ) {
                if ( value == null ) break;
                value = value.getSObject( fieldPaths[i] );
            }

            if ( value != null ) {
                // finally, retrieve property value (e.g. 'Alias' field of 'Owner.Alias' path)
                recordMap.put( columnName, value.get( fieldPaths[fieldPaths.size() - 1] ) );
            }

        }

        return recordMap;
    }

}
/*
BSD 3-Clause License

Copyright (c) 2017, Doug Ayers, douglascayers.com
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