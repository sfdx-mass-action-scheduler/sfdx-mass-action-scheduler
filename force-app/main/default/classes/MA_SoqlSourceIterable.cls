/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_SoqlSourceIterable implements Iterator<Map<String, Object>>, Iterable<Map<String, Object>> {

    private Mass_Action_Configuration__c config { get; set; }

    private Boolean hasRunQuery { get ;set; }

    private Boolean hasAllData { get; set; }

    private String nextRecordsURL { get; set; }

    private Iterator<Map<String, Object>> currentPageIterator { get; set; }

    // Not to be confused with Batch Apex batch size, this is the value
    // used in the 'Sforce-Query-Options' header with REST API to chunk
    // up the amount of query records returned. This value is between 200 to 2,000.
    // https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/headers_queryoptions.htm
    private Integer queryOptionsBatchSize { get; set; }

    public MA_SoqlSourceIterable( ID configId ) {

        System.debug( 'MA_SoqlSourceIterable: configId=' + configId );

        this.config = MA_MassActionUtils.getConfiguration( configId );
        this.hasRunQuery = false;
        this.hasAllData = false;

    }

    public MA_SoqlSourceIterable( ID configId, Integer queryOptionsBatchSize ) {
        this( configId );
        this.queryOptionsBatchSize = queryOptionsBatchSize;
    }

    // ------------------------------------------------------------------------

    public Map<String, Object> next() {

        System.debug( 'MA_SoqlSourceIterable.next' );

        Map<String, Object> record = null;

        if ( hasNext() ) {
            record = this.currentPageIterator.next();
        }

        return record;
    }

    public Boolean hasNext() {

        System.debug( 'MA_SoqlSourceIterable.hasNext' );

        if ( !this.hasRunQuery || ( !this.currentPageIterator.hasNext() && !this.hasAllData ) ) {
            runQuery();
        }

        return this.currentPageIterator.hasNext();
    }

    // ------------------------------------------------------------------------

    private void runQuery() {

        System.debug( 'MA_SoqlSourceIterable.runQuery' );

        String baseURL = MA_MassActionUtils.getCalloutRestEndpointURL( this.config.Named_Credential__c );

        MA_SoqlQueryExecuteResult queryResult = new MA_SoqlQueryExecuteResult();

        if ( String.isEmpty( this.nextRecordsURL ) ) {
            queryResult = MA_MassActionUtils.executeSoqlQuery( baseURL, this.config.Source_SOQL_Query__c, this.queryOptionsBatchSize );
        } else {
            String nextRecordsId = this.nextRecordsURL.substringAfterLast( '/' );
            queryResult = MA_MassActionUtils.executeSoqlQueryNextRecords( baseURL, nextRecordsId, this.queryOptionsBatchSize );
        }

        this.hasRunQuery = true;
        this.hasAllData = queryResult.done;
        this.nextRecordsURL = queryResult.nextRecordsUrl;
        this.currentPageIterator = queryResult.records.iterator();

    }

    // ------------------------------------------------------------------------

    public Iterator<Map<String, Object>> iterator() {

        System.debug( 'MA_SoqlSourceIterable.iterator' );

        return new MA_SoqlSourceIterable( this.config.Id, this.queryOptionsBatchSize );
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