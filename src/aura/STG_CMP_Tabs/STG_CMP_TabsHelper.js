({
	init : function(component) {
		$A.util.addClass(component.find("afflTab"), "slds-active");

		$A.util.addClass(component.find("afflTabContent"), "slds-show");
		$A.util.addClass(component.find("relTabContent"), "slds-hide");
		$A.util.addClass(component.find("addrTabContent"), "slds-hide");
		$A.util.addClass(component.find("systemTabContent"), "slds-hide");
		
		//Retrieving hierarchy settings.
		this.getHierarchySettings(component);
	},
	
	getHierarchySettings : function(component) {
		var action = component.get("c.getSettings");
		var namespacePrefix = component.get("v.namespacePrefix");
	    action.setCallback(this, function(response) {
	    	if(response.getState() === "SUCCESS") {
	    		var settings = response.getReturnValue();
	    		if(namespacePrefix && namespacePrefix.length > 0) {
		    		var settings_no_prefix = {};
		    		//Remove package prefix from each custom field
		    		for(var key in settings) { //Iterate over each row
		    			if(key.endsWith('__c')) {
		    				var key_no_prefix = key.replace(namespacePrefix, '');
			    			settings_no_prefix[key_no_prefix] = settings[key];
		    			} else {
		    				settings_no_prefix[key] = settings[key];
		    			}
		    		}
		    		component.set("v.hierarchySettings", settings_no_prefix);
	    		} else {
	    			component.set("v.hierarchySettings", settings);
	    		}
	    	} else if(response.getState() === "ERROR") {
	    		this.displayError(response);
			}
	    });
	    $A.enqueueAction(action);
	},
	
	saveSettings : function(component) {
		var saveAction = component.get("c.saveHierarchySettings");
		saveAction.setParams({"hierarchySettings" : component.get("v.hierarchySettings")});
		saveAction.setCallback(this, function(response) {
			if(response.getState() === "SUCCESS") {
				component.set("v.isView", true);
			} else if(response.getState() === "ERROR") {
				component.set("v.isView", false);
				this.displayError(response);
			}
		});
		$A.enqueueAction(saveAction);
	},
	
	resetSettings : function(component) {
		this.getHierarchySettings(component);
	}
})