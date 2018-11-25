({
    unrender: function( component, helper ) {
        this.superUnrender();
        // When component unrenders then cleanup postmate
        // resources by destroying the child and nulling out
        // the helper's cached reference to the child.
        // This ensures that the helper.handleRestRequest(..) method
        // waits appropriately for the new parent-child handshake to complete
        // when this component is re-initialized and scripts are loaded.
        if ( helper._postmate ) {
            helper._postmate.destroy();
            helper._postmate = null;
        }
    }
})