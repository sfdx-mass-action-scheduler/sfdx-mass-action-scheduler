/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_RunConfigCmpController {

    @AuraEnabled
    public static Map<String, Object> enqueueAction( ID configId ) {

        Map<String, Object> result = new Map<String, Object>();

        try {

            ID jobId = MA_MassActionBatchUtils.enqueueAction( configId );

            // We don't have lookup fields to AsyncApexJob records,
            // so standardizing on the 15 character id, least common denominator.
            // The Apex Jobs page in Setup also only displays the 15 character id.
            // So giving the user a value that they can immediately copy/paste
            // to find a job record in Setup or on the Mass Action Log records.

            result.put( 'success', true );
            result.put( 'jobId', String.valueOf( jobId ).left( 15 ) );

        } catch ( Exception e ) {

            result.put( 'success', false );
            result.put( 'message', e.getMessage() );

        }

        return result;
    }

    @AuraEnabled
    public static MA_MassActionConfigWrapper getConfiguration( ID recordId ) {

        // return json without org's namespace so our code doesn't have to worry about it
        return new MA_MassActionConfigWrapper( MA_MassActionUtils.getConfiguration( recordId ) );
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