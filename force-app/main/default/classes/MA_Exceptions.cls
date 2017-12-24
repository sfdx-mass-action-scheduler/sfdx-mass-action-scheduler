/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public class MA_Exceptions {

    /**
     * Thrown by MA_MassActionBatchUtils when configuration record
     * has an unknown source type and no batch class for it.
     */
    public class UnsupportedSourceTypeException extends Exception {

        public ID configId { get; set; }

        public String sourceType { get; set; }

        public UnsupportedSourceTypeException( ID configId, String sourceType ) {
            this.configId = configId;
            this.sourceType = sourceType;
            this.setMessage( String.format(
                'Error: Unsupported Source Type: {0}',
                new String[] { sourceType }
            ));
        }

    }

    /**
     * Indicates that in a Mass_Action_Mapping__c record the
     * source field name was not a key in the source data map.
     */
    public class NoSourceFieldException extends Exception {

        public Map<String, Object> sourceData { get; set; }

        public String sourceFieldName { get; set; }

        public NoSourceFieldException( Map<String, Object> sourceData, String sourceFieldName ) {
            this.sourceData = sourceData;
            this.sourceFieldName = sourceFieldName;
            this.setMessage( String.format(
                'Error: Field path [{0}] not found on source record [{1}]. Please review the Mass Action Mappings',
                new String [] { sourceFieldName, JSON.serialize( sourceData ) }
            ));
        }

    }

    /**
     * Indicates there was an error making http request to invoke action.
     * Errors that occur within Process Builder, Flow, etc. might not be
     * immediately known and thus not thrown with this exception but instead
     * reported by standard Salesforce behavior.
     */
    public class InvokeActionException extends Exception {

        public HttpRequest request { get; set; }

        public HttpResponse response { get; set; }

        public InvokeActionException( HttpRequest request, HttpResponse response ) {
            this.request = request;
            this.response = response;
            this.setMessage( String.format(
                'Error: {0}\n{1}\n{2}\n{3}',
                new String[] { response.toString(), response.getBody(), request.toString(), request.getBody() }
            ));
        }

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