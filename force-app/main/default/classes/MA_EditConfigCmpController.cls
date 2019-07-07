/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_EditConfigCmpController {

    /**
     * This method accepts the JSON serialization of the configuration and field mappings
     * because when defining the method params as the custom class type was getting internal server error.
     * I think possibly related to general serialization bugs with Lightning:
     * https://developer.salesforce.com/forums/?id=906F00000005GiwIAE
     * https://blog.texei.com/lightning-components-auraenabled-method-parameters-whats-working-and-what-s-not-83c351356104
     */
    @AuraEnabled
    public static Map<String, Object> saveConfiguration( String wrapperJson, String fieldMappingsJson ) {

        SavePoint sp = Database.setSavepoint();

        try {

            return MA_MassActionUtils.saveConfiguration( wrapperJson, fieldMappingsJson );

        } catch ( Exception e ) {

            Database.rollback( sp );

            System.debug( LoggingLevel.ERROR, 'MA_EditConfigCmpController.saveConfiguration: ' + e.getMessage() + ' : ' + e.getStackTraceString() );

            throw new AuraHandledException( e.getMessage() );

        }

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