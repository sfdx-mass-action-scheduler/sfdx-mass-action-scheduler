/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/*
 * Represents some parts of a JSON response from List View REST API.
 * "/services/data/<version>/sobjects/<sobjectName>/listviews/<listViewId>/describe"
 */
public inherited sharing class MA_ListViewDescribeResult {

    public ID id { get; set; }

    public String query { get; set; }

    public String sobjectType { get; set; }

    public List<Map<String, String>> columns { get; set; }

    public MA_ListViewDescribeResult() {
        this.columns = new List<Map<String, String>>();
    }

    /**
     * Extract a list of single property from the columns map.
     * For example, to get all of the 'fieldNameOrPath' properties.
     * Conceptually, it's like this: https://stackoverflow.com/questions/19590865/from-an-array-of-objects-extract-value-of-a-property-as-array
     */
    public List<String> getColumnProperty( String property ) {

        List<String> values = new List<String>();

        for ( Map<String, String> column : columns ) {
            values.add( column.get( property ) );
        }

        return values;
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