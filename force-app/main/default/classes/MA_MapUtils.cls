/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public inherited sharing class MA_MapUtils {

    /**
     * Returns a new map whose keys are all lowercase.
     * This is useful when need a case-insensitive way to
     * check if the map contains a key or to retrieve values.
     *
     * Because Apex does not support generics, the returned map's
     * value type is Object, so you'll need to cast the values you retrieve.
     */
    public static Map<String, Object> convertKeysToLowercase( Map<String, Object> origMap ) {

        if ( origMap == null ) {
            return origMap;
        }

        Map<String, Object> newMap = new Map<String, Object>();

        for ( String key : origMap.keySet() ) {
            newMap.put( ( key == null ) ? null : key.toLowerCase(), origMap.get( key ) );
        }

        return newMap;
    }

    // ------------------------------------------------------------------------

    /**
     * Visits each field on the given record and puts the values in
     * the given record map. The map's keys are a concatenation of
     * the given baseFieldPath and the record's field name.
     *
     * If a field's value is itself an SObject or Map then the method is
     * called again on that record. This time, passing in for the
     * baseFieldPath the value of the prior baseFieldPath + the field name.
     *
     * Ultimately, for a query like:
     *      SELECT Id, FirstName, Account.Name FROM Contact
     *
     * This method generates a map like:
     *      {
     *        "Account.Name" : "dca_mass_action: MA Test Account",
     *        "Account.Id" : "001S00000106yiiIAA",
     *        "Account" : {
     *          "attributes" : {
     *            "type" : "Account",
     *            "url" : "/services/data/v47.0/sobjects/Account/001S00000106yiiIAA"
     *          },
     *          "Id" : "001S00000106yiiIAA",
     *          "Name" : "dca_mass_action: MA Test Account"
     *        },
     *        "AccountId" : "001S00000106yiiIAA",
     *        "FirstName" : "Doug",
     *        "Id" : "003S0000018BxKOIA0"
     *      }
     *
     * @param record
     *      SObject or Map whose field values to add to the record map.
     * @param baseFieldPath
     *      Essentially, the prefix for the keys when putting values in the record map.
     * @param recordMap
     *      Map of field values from the given record.
     *      The map keys are a concatenation of `baseFieldPath + fieldName`.
     */

    public static Map<String, Object> visitFieldPaths( SObject record ) {

        Map<String, Object> recordMap = new Map<String, Object>();

        if ( record != null ) {
            visitFieldPaths( record, '', recordMap );
        }

        return recordMap;
    }

    public static Map<String, Object> visitFieldPaths( Map<String, Object> record ) {

        Map<String, Object> recordMap = new Map<String, Object>();

        if ( record != null ) {
            visitFieldPaths( record, '', recordMap );
        }

        return recordMap;
    }

    private static void visitFieldPaths( SObject record, String baseFieldPath, Map<String, Object> recordMap ) {
        if ( record != null ) {
            visitFieldPaths( record.getPopulatedFieldsAsMap(), baseFieldPath, recordMap );
        }
    }

    private static void visitFieldPaths( Map<String, Object> record, String baseFieldPath, Map<String, Object> recordMap ) {

        baseFieldPath = ( String.isBlank( baseFieldPath ) ? '' : baseFieldPath + '.' );

        Map<String, Object> populatedFieldsMap = record;

        for ( String fieldName : populatedFieldsMap.keySet() ) {

            String fieldPath = baseFieldPath + fieldName;
            Object fieldValue = populatedFieldsMap.get( fieldName );

            recordMap.put( fieldPath, fieldValue );

            if ( fieldValue instanceof SObject ) {
                visitFieldPaths( (SObject) fieldValue, fieldPath, recordMap );
            } else if ( fieldValue instanceof Map<String, Object> ) {
                visitFieldPaths( (Map<String, Object>) fieldValue, fieldPath, recordMap );
            }

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