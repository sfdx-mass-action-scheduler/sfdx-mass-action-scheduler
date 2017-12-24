({
    calculateNubbinPlacement: function(component, placement){
        if(!placement) {
            var placement = component.get('v.placement');
        }
        placement = placement.replace('auto ', '');
        var nubbinPlacement;

        switch (placement){
            case 'top' : nubbinPlacement = 'slds-nubbin--bottom'; break;
            case 'bottom' : nubbinPlacement = 'slds-nubbin--top'; break;
            case 'left' : nubbinPlacement = 'slds-nubbin--right'; break;
            case 'right' : nubbinPlacement = 'slds-nubbin--left'; break;
            default : nubbinPlacement = 'slds-nubbin--bottom';
        }

        component.set('v.nubbinPlacement', nubbinPlacement);
    },
    calculateTooltipPosition: function(component) {
        var tooltipEl = component.find('tooltip').getElement();
        var tooltipBoundingBox = tooltipEl.getBoundingClientRect();
        var tooltipWidth = Math.ceil(tooltipBoundingBox.width);
        var tooltipHeight = tooltipBoundingBox.height;

        var containerEl = component.find('tooltipContainer').getElement();
        var containerBoundingBox = containerEl.getBoundingClientRect();
        var containerWidth = containerBoundingBox.width;
        var containerHeight = containerBoundingBox.height;
        var containerLeft = containerBoundingBox.left;
        var containerRight = containerBoundingBox.right;

        var placement = component.get('v.placement');

        // Check for auto placement
        if(placement.startsWith('auto ')) {

            // Remove auto placement to perform bounding checks on preferred placement
            placement = placement.replace('auto ', '');

            // Construct the window bounding box.

            // The height of the sticky global header is not accessible in any way
            // so it must be hardcoded. This may change during releases.
            // var globalHeaderHeight = 90;

            // In LEX, document.body.getBoundingClientRect() does not return the
            // correct values so we will construct a box ourselves using the
            // inner width and height of the window (viewport)
            var windowBoundingBox = {
                top: 0,
                right: window.innerWidth,
                bottom: window.innerHeight,
                left: 0
            };

            // Validate that there is space for the preferred placements. If there is
            // not, invert the placement
            if(placement === 'top' && (containerBoundingBox.top - tooltipBoundingBox.height) < windowBoundingBox.top) {
                placement = 'bottom';
            } else if(placement === 'right' && (containerBoundingBox.right + tooltipBoundingBox.width) > windowBoundingBox.right) {
                placement = 'left';
            } else if(placement === 'bottom' && (containerBoundingBox.bottom + tooltipBoundingBox.height) > windowBoundingBox.bottom) {
                placement = 'top';
            } else if(placement === 'left' && (containerBoundingBox.left - tooltipBoundingBox.width) < windowBoundingBox.left) {
                placement = 'right';
            }

            // update nubbin since placement may have changed from the last
            // display
            this.calculateNubbinPlacement(component, placement);
        }

        var tooltipYPos, tooltipXPos;
        var nubbinPadding = 14;

        var tooltipStyle = component.find('tooltipStyle').getElement();

        if (placement == 'right') {
            tooltipXPos = containerWidth + nubbinPadding;
            tooltipYPos = (containerHeight - tooltipHeight) / 2;
        } else if (placement == 'bottom') {
            tooltipXPos = (containerWidth - tooltipWidth) / 2;
            tooltipYPos = containerHeight + nubbinPadding;

            if ((containerLeft + tooltipXPos) < 4) {
                var adjustment = Math.abs(containerLeft + tooltipXPos) + 4;

                tooltipXPos += adjustment;
                tooltipStyle.innerHTML = '.st-popover_container .slds-nubbin--top:before { transform: translateX(' + -adjustment + 'px) rotate(45deg); } .st-popover_container .slds-nubbin--top:after { transform: translateX(' + -adjustment + 'px) rotate(45deg); }';
            } else if ((containerRight + Math.abs(tooltipXPos)) > (window.innerWidth - 4)) {
                var adjustment = (containerRight + Math.abs(tooltipXPos)) - (window.innerWidth - 4);

                tooltipXPos -= adjustment;
                tooltipStyle.innerHTML = '.st-popover_container .slds-nubbin--top:before { transform: translateX(' + adjustment + 'px) rotate(45deg); } .st-popover_container .slds-nubbin--top:after { transform: translateX(' + adjustment + 'px) rotate(45deg); }';
            }
        } else if (placement == 'left') {
            tooltipXPos = -tooltipWidth - nubbinPadding;
            tooltipYPos = (containerHeight - tooltipHeight) / 2;
        } else { // Top
            tooltipXPos = (containerWidth - tooltipWidth) / 2;
            tooltipYPos = -tooltipHeight - nubbinPadding;

            if ((containerLeft + tooltipXPos) < 4) {
                var adjustment = Math.abs(containerLeft + tooltipXPos) + 4;

                tooltipXPos += adjustment;
                tooltipStyle.innerHTML = '.st-popover_container .slds-nubbin--bottom:before { transform: translateX(' + -adjustment + 'px) rotate(45deg); } .st-popover_container .slds-nubbin--bottom:after { transform: translateX(' + -adjustment + 'px) rotate(45deg); }';
            } else if ((containerRight + Math.abs(tooltipXPos)) > (window.innerWidth - 4)) {
                var adjustment = (containerRight + Math.abs(tooltipXPos)) - (window.innerWidth - 4);

                tooltipXPos -= adjustment;
                tooltipStyle.innerHTML = '.st-popover_container .slds-nubbin--bottom:before { transform: translateX(' + adjustment + 'px) rotate(45deg); } .st-popover_container .slds-nubbin--bottom:after { transform: translateX(' + adjustment + 'px) rotate(45deg); }';
            }
        }

        return {
            tooltipXPos : tooltipXPos,
            tooltipYPos : tooltipYPos,
            width : tooltipWidth
        }
    }
})