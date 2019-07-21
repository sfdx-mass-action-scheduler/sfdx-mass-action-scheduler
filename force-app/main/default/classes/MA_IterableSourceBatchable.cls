/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_IterableSourceBatchable implements Database.Batchable<Map<String, Object>>,
                                                                Database.Stateful,
                                                                Database.AllowsCallouts,
                                                                Database.RaisesPlatformEvents {

    private ID configId { get; set; }

    private Mass_Action_Configuration__c config { get; set; }

    private Iterable<Map<String, Object>> iterable { get; set; }

    public MA_IterableSourceBatchable( ID configId, Iterable<Map<String, Object>> iterable ) {
        this.configId = configId;
        this.iterable = iterable;
    }

    // ------------------------------------------------------------------------

    public Iterable<Map<String, Object>> start( Database.BatchableContext context ) {

        System.debug( 'MA_IterableSourceBatchable.start: ' + context + ', configId=' + this.configId );

        this.config = MA_MassActionUtils.getConfiguration( this.configId );

        MA_MassActionBatchUtils.handleBatchJobStarted( this.configId, context.getJobId() );

        return this.iterable;
    }

    public void execute( Database.BatchableContext context, List<Map<String, Object>> records ) {

        System.debug( 'MA_IterableSourceBatchable.execute: ' + context + ', configId=' + this.configId );

        List<Map<String, Object>> sourceRowMaps = convertRecordsToMaps( records );

        MA_MassActionUtils.invokeTargetAction( this.config, sourceRowMaps );

        MA_MassActionBatchUtils.handleBatchJobExecution( this.configId, context.getJobId(), records.size(), JSON.serializePretty( records ) );

    }

    public void finish( Database.BatchableContext context ) {

        System.debug( 'MA_IterableSourceBatchable.finish: ' + context + ', configId=' + this.configId );

        MA_MassActionBatchUtils.handleBatchJobFinished( this.configId, context.getJobId() );

    }

    // ------------------------------------------------------------------------

    private List<Map<String, Object>> convertRecordsToMaps( List<Map<String, Object>> records ) {

        List<Map<String, Object>> maps = new List<Map<String, Object>>();

        for ( Map<String, Object> record : records ) {
            maps.add( convertRecordToMap( record ) );
        }

        return maps;
    }

    private Map<String, Object> convertRecordToMap( Map<String, Object> record ) {

        return MA_MapUtils.visitFieldPaths( record );
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