/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public inherited sharing class MA_Exceptions {

    /**
     * Thrown by MA_MassActionUtils when encounter error
     * executing anonymous apex via SOAP API.
     */
    public inherited sharing class AnonymousApexException extends InvokeActionException {

        public String compileProblem { get; set; }

        public String exceptionMessage { get; set; }

        public String exceptionStackTrace { get; set; }

        public AnonymousApexException( HttpRequest request, HttpResponse response, String compileProblem, String exceptionMessage, String exceptionStackTrace ) {
            super( request, response );
            this.compileProblem = compileProblem;
            this.exceptionMessage = exceptionMessage;
            this.exceptionStackTrace = exceptionStackTrace;
            this.setMessage( sanitizeMessage( String.format(
                'Anonymous Apex Error:\ncompileProblem: {0}\nexceptionMessage: {1}\nexceptionStackTrace: {2}\n\n{3}',
                new Object[] { compileProblem, exceptionMessage, exceptionStackTrace, super.getMessage() }
            )));
        }

        public AnonymousApexException( HttpRequest request, HttpResponse response, String compileProblem, String exceptionMessage, String exceptionStackTrace, Exception cause ) {
            this( request, response, compileProblem, exceptionMessage, exceptionStackTrace );
            this.initCause( cause );
        }

    }

    /**
     * Thrown by MA_MassActionUtils when encounter error
     * executing a SOQL query via REST API.
     */
    public inherited sharing class SOQLQueryException extends InvokeActionException {

        public String query { get; set; }

        public String errorType { get; set; }

        public String errorMessage { get; set; }

        public SOQLQueryException( HttpRequest request, HttpResponse response, String query, String errorType, String errorMessage ) {
            super( request, response );
            this.query = query;
            this.errorType = errorType;
            this.errorMessage = errorMessage;
            this.setMessage( sanitizeMessage( String.format(
                'SOQL Query Error:\nquery: {0}\nerrorType: {1}\nerrorMessage: {2}\n\n{3}',
                new Object[] { query, errorType, errorMessage, super.getMessage() }
            )));
        }

        public SOQLQueryException( HttpRequest request, HttpResponse response, String query, String errorType, String errorMessage, Exception cause ) {
            this( request, response, query, errorType, errorMessage );
            this.initCause( cause );
        }

    }

    /**
     * Thrown by MA_MassActionBatchUtils when configuration record
     * has an unknown source type and no batch class for it.
     */
    public inherited sharing class UnsupportedSourceTypeException extends Exception {

        public ID configId { get; set; }

        public String sourceType { get; set; }

        public UnsupportedSourceTypeException( ID configId, String sourceType ) {
            this.configId = configId;
            this.sourceType = sourceType;
            this.setMessage( sanitizeMessage( String.format(
                'Error: Unsupported Source Type: {0}',
                new Object[] { sourceType }
            )));
        }

        public UnsupportedSourceTypeException( ID configId, String sourceType, Exception cause ) {
            this( configId, sourceType );
            this.initCause( cause );
        }

    }

    /**
     * Indicates that in a Mass_Action_Mapping__c record the
     * source field name was not a key in the source data map.
     */
    public inherited sharing class NoSourceFieldException extends Exception {

        public Map<String, Object> sourceData { get; set; }

        public String sourceFieldName { get; set; }

        public NoSourceFieldException( Map<String, Object> sourceData, String sourceFieldName ) {
            this.sourceData = sourceData;
            this.sourceFieldName = sourceFieldName;
            this.setMessage( sanitizeMessage( String.format(
                'Error: Field path [{0}] not found on source record [{1}]. Please review the Mass Action Mappings',
                new String [] { sourceFieldName, JSON.serialize( sourceData ) }
            )));
        }

        public NoSourceFieldException( Map<String, Object> sourceData, String sourceFieldName, Exception cause ) {
            this( sourceData, sourceFieldName );
            this.initCause( cause );
        }

    }

    /**
     * Indicates there was an error making http request to invoke action.
     * Errors that occur within Process Builder, Flow, etc. might not be
     * immediately known and thus not thrown with this exception but instead
     * reported by standard Salesforce behavior.
     */
    public inherited sharing virtual class InvokeActionException extends Exception {

        public HttpRequest request { get; set; }

        public HttpResponse response { get; set; }

        public InvokeActionException( HttpRequest request, HttpResponse response ) {
            this.request = request;
            this.response = response;
            this.setMessage( sanitizeMessage( String.format(
                'Invoke Action Error: {0}\n{1}\n\n{2}\n{3}',
                new Object[] { response.toString(), response.getBody(), request.toString(), request.getBody() }
            )));
        }

        public InvokeActionException( HttpRequest request, HttpResponse response, Exception cause ) {
            this( request, response );
            this.initCause( cause );
        }

    }

    /**
     * Indicates there was an error deploying metadata with Apex API.
     */
    public inherited sharing class MetadataDeployException extends Exception {

        public Metadata.DeployResult result { get; set; }

        public MetadataDeployException( Metadata.DeployResult result ) {
            this.result = result;
            this.setMessage( sanitizeMessage( String.format(
                'Metadata Deployment Error: {0}: {1}\n{2}',
                new Object[] { result.errorStatusCode, result.errorMessage, JSON.serializePretty( result ) }
            )));
        }

        public MetadataDeployException( Metadata.DeployResult result, Exception cause ) {
            this( result );
            this.initCause( cause );
        }

    }

    // ------------------------------------------------------------------------

    public static Exception buildException( Type t, String message ) {
        Exception ex = (Exception) t.newInstance();
        ex.setMessage( sanitizeMessage( message ) );
        return ex;
    }

    public static Exception buildException( Type t, String message, Exception cause ) {
        Exception ex = buildException( t, message );
        ex.initCause( cause );
        return ex;
    }

    /**
     * Looks for sensitive information and removes it from the message,
     * such as redacting session ids. A session id might be exposed when
     * displaying an http request's headers or body value.
     */
    public static String sanitizeMessage( String message ) {
        return message.replaceAll( '(?i)(?<=<apex:sessionId>).*(?=</apex:sessionId>)', 'SESSION_ID_REMOVED' );
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