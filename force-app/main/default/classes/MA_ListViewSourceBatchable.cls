/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_ListViewSourceBatchable implements Database.Batchable<SObject>,
                                                                Database.Stateful,
                                                                Database.AllowsCallouts,
                                                                Database.RaisesPlatformEvents {

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

        this.listViewDescribe = MA_MassActionUtils.describeListView( MA_MassActionUtils.getCalloutRestEndpointURL( this.config.Named_Credential__c ), this.config.Source_List_View_ID__c );

        Database.QueryLocator queryLocator = Database.getQueryLocator( this.listViewDescribe.query );

        MA_MassActionBatchUtils.handleBatchJobStarted( this.configId, context.getJobId() );

        return queryLocator;
    }

    public void execute( Database.BatchableContext context, List<SObject> records ) {

        System.debug( 'MA_ListViewSourceBatchable.execute: ' + context + ', configId=' + this.configId );

        List<Map<String, Object>> sourceRowMaps = convertRecordsToMaps( records );

        MA_MassActionUtils.invokeTargetAction( this.config, sourceRowMaps );

        MA_MassActionBatchUtils.handleBatchJobExecution( this.configId, context.getJobId(), records.size(), JSON.serializePretty( records ) );

    }

    public void finish( Database.BatchableContext context ) {

        System.debug( 'MA_ListViewSourceBatchable.finish: ' + context + ', configId=' + this.configId );

        MA_MassActionBatchUtils.handleBatchJobFinished( this.configId, context.getJobId() );

    }

    // ------------------------------------------------------------------------

    private List<Map<String, Object>> convertRecordsToMaps( List<SObject> records ) {

        List<Map<String, Object>> maps = new List<Map<String, Object>>();

        Map<String, SObjectField> fieldsMap = records.getSObjectType().getDescribe().fields.getMap();

        for ( SObject record : records ) {
            maps.add( convertRecordToMap( record, fieldsMap ) );
        }

        return maps;
    }

    private Map<String, Object> convertRecordToMap( SObject record, Map<String, SObjectField> fieldsMap ) {

        Map<String, Object> recordMap = new Map<String, Object>();

        for ( String fieldName : fieldsMap.keySet() ) {
            // As of Winter '19, Apex does not provide a way to
            // inspect a SOQL query to know which fields were queried.
            // We can get a map of populated field values, but that map only
            // has entries for fields from the query that were non-null.
            // If the configuration record's field mappings reference a field
            // whose value is null in the query result, the map we return
            // would be lacking that map key and our validation would throw an
            // exception. Therefore, as a workaround, we iterate all the fields
            // from the sobject describe and attempt to grab the value from the queried record.
            DescribeFieldResult fieldDesc = fieldsMap.get( fieldName ).getDescribe();
            recordMap.put( fieldDesc.getName(), null );
        }

        recordMap.putAll( MA_MapUtils.visitFieldPaths( record ) );

        return recordMap;
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