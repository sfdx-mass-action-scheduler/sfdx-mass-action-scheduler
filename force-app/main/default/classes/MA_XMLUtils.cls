/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/**
 * First try to use a method on the DOM.XMLNode class before resorting to this class.
 */
public inherited sharing class MA_XMLUtils {

    /**
     * Convenience method that returns the node text from the found
     * child node. If no such child node exists, returns null.
     */
    public static String getChildNodeTextByPath( DOM.XMLNode root, String path ) {
        DOM.XMLNode child = getChildNodeByPath( root, path );
        return ( child != null ? child.getText() : null );
    }

    /**
     * Iterates child nodes to find and return the node whose name matches
     * the names in the given path.
     *
     * @param root
     *      XML node to begin the search.
     * @param path
     *      Path of child node names separated by slash (/), relative to the root node.
     */
    public static DOM.XMLNode getChildNodeByPath( DOM.XMLNode root, String path ) {

        DOM.XMLNode child = null;

        if ( root != null && String.isNotBlank( path ) ) {

            if ( path.startsWith( '/' ) ) {
                path = path.substringAfter( '/' );
            }

            String[] names = path.split( '/' );
            child = root;

            for ( String name : names ) {

                DOM.XMLNode foundNode = null;

                for ( DOM.XMLNode childNode : child.getChildElements() ) {

                    if ( String.isNotBlank( childNode.getName() ) && childNode.getName().equalsIgnoreCase( name ) ) {
                        foundNode = childNode;
                        break;
                    }

                }

                child = foundNode;

                if ( foundNode == null ) {
                    // didn't find child node, exit
                    break;
                }

            }

        }

        return child;
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