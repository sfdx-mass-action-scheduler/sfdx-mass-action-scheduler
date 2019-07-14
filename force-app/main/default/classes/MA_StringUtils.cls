/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/**
 * First try to use a method on the Apex String class before resorting to this class.
 * Inspired by https://commons.apache.org/proper/commons-lang/apidocs/org/apache/commons/lang3/StringUtils.html
 */
public inherited sharing class MA_StringUtils {

    public static String defaultIfBlank( String str, String defaultStr ) {
        return ( String.isNotBlank( str ) ? str : defaultStr );
    }

    /**
     * Returns a random string of uppercase letters with the given length.
     * Originally designed for auto-generating unique names for configuration
     * records when subscribers upgraded to the version that introduced the unique name field.
     */
    public static String getRandomLetters( Integer length ) {

        final String[] LETTERS = 'A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z'.split(',');

        String text = '';

        for ( Integer i = 0; i < length; i++ ) {
            Integer index = Math.mod( Math.abs( Crypto.getRandomInteger() ), LETTERS.size() );
            text += LETTERS[index];
        }

        return text;
    }

    /**
     * Returns an abbreviated string value no longer than max allowable length for the field.
     * If string value is empty or null then returns an empty string.
     * @see String.abbreviate
     */
    public static String abbreviateWithinFieldLength( String value, SObjectField field ) {
        return abbreviate( value, field.getDescribe().getLength() );
    }

    /**
     * Returns an abbreviated string value no longer than `maxWidth`.
     * If string value is empty or null then returns empty string.
     * @see String.abbreviate
     */
    public static String abbreviate( String value, Integer maxWidth ) {
        return ( String.isBlank( value ) ? '' : value.abbreviate( maxWidth ) );
    }

    /**
     * Determines if the input matches the regular expression.
     * @see Matcher.matches
     */
    public static Boolean matches( String input, String regex ) {
        Pattern p = Pattern.compile( regex );
        Matcher m = p.matcher( input );
        return m.matches();
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