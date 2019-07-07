/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
global with sharing class MA_RunConfigInvocable {

    @InvocableMethod(
        label = 'MAS: Run Mass Action'
        description = 'Submits background job to run a Mass Action Configuration.'
    )
    global static List<Response> execute( List<Request> requests ) {

        List<Response> responses = new List<Response>();

        Map<ID, Mass_Action_Configuration__c> configsByIdMap = getConfigurationsByIdMap( requests );
        Map<String, Mass_Action_Configuration__c> configsByUniqueNameMap = getConfigurationsByUniqueNameMap( requests );

        for ( Request req : requests ) {

            System.debug( req );

            Mass_Action_Configuration__c config = null;

            // lookup config by id
            if ( config == null && String.isNotBlank( req.configId ) ) {
                config = configsByIdMap.get( req.configId );
            }

            // lookup config by unique name
            if ( config == null && String.isNotBlank( req.configUniqueName ) ) {
                config = configsByUniqueNameMap.get( req.configUniqueName );
            }

            if ( config == null ) {
                throw MA_Exceptions.buildException( NoDataFoundException.class, 'No Mass Action Configuration record found for request: ' + req );
            }

            Response res = new Response();
            res.jobId = MA_MassActionBatchUtils.enqueueAction( config.Id );
            responses.add( res );

            System.debug( res );

        }

        return responses;
    }

    // ------------------------------------------------------------

    private static Map<ID, Mass_Action_Configuration__c> getConfigurationsByIdMap( List<Request> requests ) {

        Set<String> configIds = new Set<String>();
        for ( Request req : requests ) {
            if ( String.isNotBlank( req.configId ) ) {
                configIds.add( req.configId );
            }
        }

        Map<ID, Mass_Action_Configuration__c> configMap = new Map<ID, Mass_Action_Configuration__c>([
            SELECT Id, DeveloperName__c FROM Mass_Action_Configuration__c WHERE Id IN :configIds
        ]);

        return configMap;
    }

    private static Map<String, Mass_Action_Configuration__c> getConfigurationsByUniqueNameMap( List<Request> requests ) {

        Set<String> uniqueNames = new Set<String>();
        for ( Request req : requests ) {
            if ( String.isNotBlank( req.configUniqueName ) ) {
                uniqueNames.add( req.configUniqueName );
            }
        }

        Map<String, Mass_Action_Configuration__c> configMap = new Map<String, Mass_Action_Configuration__c>();
        for ( Mass_Action_Configuration__c config : [ SELECT Id, DeveloperName__c FROM Mass_Action_Configuration__c WHERE DeveloperName__c IN :uniqueNames ] ) {
            configMap.put( config.DeveloperName__c, config );
        }

        return configMap;
    }

    // ------------------------------------------------------------

    global inherited sharing class Request {

        @InvocableVariable(
            label = 'Configuration Unique Name'
            description = 'The unique name of the Mass Action Configuration to run. Specify this or the ID.'
            required = false
        )
        global String configUniqueName;

        @InvocableVariable(
            label = 'Configuration ID'
            description = 'The Salesforce record ID of the Mass Action Configuration to run. Specify this or the Unique Name.'
            required = false
        )
        global ID configId;

    }

    global inherited sharing class Response {

        @InvocableVariable(
            label = 'Job ID'
            description = 'The ID of the background apex job processing the Mass Action request.'
        )
        global ID jobId;

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