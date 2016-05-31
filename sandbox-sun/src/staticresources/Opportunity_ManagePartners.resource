function PartnerNodes(node,defaultRelationshipType) {
	var baseId = node.id.replace(/:[^:]*$/,':');
	this.partnerStatusIdField = baseId+'partnerStatusId';
	this.linkNode = document.getElementById(baseId+'link');
	this.searchTextNode = document.getElementById(baseId+'searchText');
	this.relationshipTypeNode = document.getElementById(baseId+'relationshipType');
	this.partnerTypeNode = document.getElementById(baseId+'partnerType');
	this.partnerSubTypeNode = document.getElementById(baseId+'partnerSubType');
	this.partnerTierNode = document.getElementById(baseId+'partnerTier');
	this.showAllRegionsNode = document.getElementById(baseId+'showAllRegions');
	this.showAllRegions = this.showAllRegionsNode.checked;
	this.relationshipType = defaultRelationshipType;
	if(this.relationshipTypeNode != null) {
		this.relationshipType = this.relationshipTypeNode.options[this.relationshipTypeNode.options.selectedIndex].value;
	}
	this.partnerTypeMap = partnerTypeMapByRelationshipType[this.relationshipType];
	if(this.partnerTypeMap == null) {
		//alert('partnerTypeMapByRelationshipType["'+this.relationshipType+'"]=null');
		this.partnerTypeMap = new Object();
	}
}

// updatePartnerTypeOptions should be called after setting the relationshipType or toggling allRegions
PartnerNodes.prototype.updatePartnerTypeOptions = function() {
	//alert('updatePartnerTypeOptions');
	var subTypeElement = this.partnerSubTypeNode;
	var typeElement = this.partnerTypeNode;
	var tierElement = this.partnerTierNode;
	var allRegions = this.showAllRegions;
	var typeId = typeElement.options[typeElement.options.selectedIndex].value;
	typeElement.options.length = 1;
	var selectedIndex = 0;
	var labelMap = new Object();
	for(var i=partnerStatusArray.length; i-- != 0;) {
		var v = partnerStatusArray[i];
		if(allRegions || v.inRegion) {
			if(partnerTierMap[v.tier] != null) {
				var partnerType = null;
				for(var id = v.type;(partnerType=this.partnerTypeMap[id]) != null;id = partnerType.parentId) {
					if(partnerType.hierarchy.length == 1) {
						labelMap[ partnerType.hierarchy[0] ] = id;
						break;
					}
				}
			}
		}
	}
	var optionLabels = new Array();
	for(var label in labelMap) {
		optionLabels.push(label);
	}
	optionLabels.sort();
	var len = optionLabels.length;
	for(var i=0;i != len;) {
		var label = optionLabels[i++];
		var id = labelMap[label];
		typeElement.options[typeElement.options.length] = new Option(label,id,false,(typeId == id));
		if(typeId == id) {
			selectedIndex = i;
		}
	}
	typeElement.options.selectedIndex = selectedIndex;
	typeElement.disabled=(typeElement.options.length == 1);
	//alert('typeElement.options.length='+typeElement.options.length);
	return typeElement.options[selectedIndex];
}

// updatePartnerTierOptions should be called after setting the relationshipType or toggling allRegions
PartnerNodes.prototype.updatePartnerTierOptions = function() {
	//alert('updatePartnerTierOptions');
	var tierElement = this.partnerTierNode;
	var allRegions = this.showAllRegions;
	var tierId = tierElement.options[tierElement.options.selectedIndex].value;
	tierElement.options.length = 1;
	var selectedIndex = 0;
	var labelMap = new Object();
	for(var i=partnerStatusArray.length; i-- != 0;) {
		var v = partnerStatusArray[i];
		if(allRegions || v.inRegion) {
			var partnerTier = partnerTierMap[v.tier];
			if(partnerTier != null) {
				var partnerType = null;
				for(var id = v.type;(partnerType=this.partnerTypeMap[id]) != null;id = partnerType.parentId) {
					if(partnerType.hierarchy.length == 1) {
						labelMap[partnerTier.hierarchy[0]]=v.tier;
						break;
					}
				}
			}
		}
	}
	var optionLabels = new Array();
	for(var label in labelMap) {
		optionLabels.push(label);
	}
	optionLabels.sort();
	var len = optionLabels.length;
	for(var i=0;i != len;) {
		var label = optionLabels[i++];
		var id = labelMap[label];
		tierElement.options[tierElement.options.length] = new Option(label,id,false,(tierId == id));
		if(tierId == id) {
			selectedIndex = i;
		}
	}
	tierElement.options.selectedIndex = selectedIndex;
	tierElement.disabled=(tierElement.options.length == 1);
	return tierElement.options[selectedIndex];
}

// updatePartnerSubTypeOptions should be called after setting the relationshipType, Tier, Type or toggling allRegions
PartnerNodes.prototype.updatePartnerSubTypeOptions = function() {
	//alert('updatePartnerSubTypeOptions');
	var subTypeElement = this.partnerSubTypeNode;
	var typeElement = this.partnerTypeNode;
	var tierElement = this.partnerTierNode;
	var allRegions = this.showAllRegions;
	var typeIndex = typeElement.options.selectedIndex;
	var typeId = typeElement.options[typeIndex].value;
	var tierIndex = tierElement.options.selectedIndex;
	var tierId = tierElement.options[tierIndex].value;
	var subTypeId = subTypeElement.options[subTypeElement.options.selectedIndex].value;
	subTypeElement.options.length = 1;
	subTypeElement.options[0].value = typeId;
	var selectedIndex = 0;
	var labelMap = new Object();
	var partnerType = this.partnerTypeMap[typeId];
	if(! (partnerType == null || partnerType.hierarchy.length != 1)) {
		for(var i=partnerStatusArray.length; i-- != 0;) {
			var v = partnerStatusArray[i];
			if(allRegions || v.inRegion) {
				if(partnerTierMap[v.tier] != null) {
					if(tierIndex == 0 || v.tier == tierId) {
						var partnerSubType = null;
						for(var id = v.type;(partnerSubType=this.partnerTypeMap[id]) != null;id = partnerType.parentId) {
							if(partnerSubType.parentId == typeId) {
								labelMap[partnerSubType.hierarchy[1]]=id;
								break;
							}
						}
					}
				}
			}
		}
	}
	var optionLabels = new Array();
	for(var label in labelMap) {
		optionLabels.push(label);
	}
	optionLabels.sort();
	var len = optionLabels.length;
	for(var i=0;i != len;) {
		var label = optionLabels[i++];
		var id = labelMap[label];
		subTypeElement.options[subTypeElement.length] = new Option(label,id,false,(subTypeId == id));
		if(subTypeId == id) {
			selectedIndex = i;
		}
	}
	subTypeElement.options.selectedIndex = selectedIndex;
	subTypeElement.disabled=(subTypeElement.options.length == 1);
	return subTypeElement.options[selectedIndex];
}

PartnerNodes.prototype.updateSearchText = function() {
	if(this.searchTextNode != null) {
		this.searchTextNode.disabled = this.partnerTypeNode.disabled;
	}
}

PartnerNodes.prototype.updateLink = function() {
	if(this.linkNode != null) {
		this.linkNode.style.display = this.partnerTypeNode.disabled?'none':'inline';
	}
}

// assignPartnerTier should be called after assigning partnerTier value
PartnerNodes.prototype.assignPartnerTier = function() {
	//alert('assignPartnerTier');
	var subTypeElement = this.partnerSubTypeNode;
	var typeElement = this.partnerTypeNode;
	var tierElement = this.partnerTierNode;
	var allRegions = this.showAllRegions;
	var typeIndex = typeElement.options.selectedIndex;
	var subTypeIndex = subTypeElement.options.selectedIndex;
	if(typeIndex != 0) {
		var tierIndex = tierElement.options.selectedIndex;
		if(tierIndex != 0) {
			var partnerTierId = tierElement.options[tierIndex].value;
			var typeId = typeElement.options[typeIndex].value;
			var partnerSubTypeId = subTypeElement.options[subTypeIndex].value;
			var hasPartnerSubTypeId = false;
			var hasPartnerTypeId = false;
			for(var i=partnerStatusArray.length; i-- != 0;) {
				var v = partnerStatusArray[i];
				if(allRegions || v.inRegion) {
					if(v.tier == partnerTierId) {
						var partnerType = null;
						for(var id = v.type;(partnerType=this.partnerTypeMap[id]) != null;id = partnerType.parentId) {
							if(id == partnerSubTypeId) {
								hasPartnerTypeId = hasPartnerSubTypeId = true;
								i=0;
								break;
							}
							if(id == typeId) {
								hasPartnerTypeId = true;
								break;
							}
						}
					}
				}
			}
			if(! hasPartnerSubTypeId) {
				subTypeElement.options.selectedIndex = 0;
				if(! hasPartnerTypeId) {
					typeElement.options.selectedIndex = 0;
				}
			}
		}
	}
	this.updatePartnerSubTypeOptions();
}

// assignPartnerType should be called after assigning partnerType value
PartnerNodes.prototype.assignPartnerType = function() {
	//alert('assignPartnerType');
	var subTypeElement = this.partnerSubTypeNode;
	var typeElement = this.partnerTypeNode;
	var tierElement = this.partnerTierNode;
	var allRegions = this.showAllRegions;
	var typeIndex = typeElement.options.selectedIndex;
	var typeId = typeElement.options[typeIndex].value;
	subTypeElement.options[0].value = typeId;
	subTypeElement.options.length = 1;
	subTypeElement.options.selectedIndex = 0;
	if(typeIndex != 0) {
		var tierIndex = tierElement.options.selectedIndex;
		var partnerTierId = tierElement.options[tierElement.options.selectedIndex].value;
		var hasPartnerTierId = false;
		for(var i=partnerStatusArray.length; i-- != 0;) {
			var v = partnerStatusArray[i];
			if(allRegions || v.inRegion) {
				if(v.tier == partnerTierId || tierIndex == 0) {
					var partnerType = null;
					for(var id = v.type;(partnerType=this.partnerTypeMap[id]) != null;id = partnerType.parentId) {
						if(id == typeId) {
							hasPartnerTierId = true;
							i=0;
							break;
						}
					}
				}
			}
		}
		if(! hasPartnerTierId) {
			tierElement.options.selectedIndex = 0;
		}
	}
	this.updatePartnerSubTypeOptions();
}

PartnerNodes.prototype.openLookupLink = function(url) {
	if(this.partnerSubTypeNode != null) {
		var partnerTypeId = this.partnerSubTypeNode.options[this.partnerSubTypeNode.options.selectedIndex].value;
		url = url.replace(/partnerTypeId=[a-zA-Z0-9]*/,'partnerTypeId='+partnerTypeId);
	}
	if(this.partnerTierNode != null) {
		var partnerTierId = this.partnerTierNode.options[this.partnerTierNode.options.selectedIndex].value;
		url = url.replace(/partnerTierId=[a-zA-Z0-9]*/,'partnerTierId='+partnerTierId);
	}
	if(this.relationshipType != null) {
		url = url.replace(/transactionRole=[^&]*/,'transactionRole='+escape(this.relationshipType));
	}
	url = url.replace(/[&]recordTypeName=[^&]*/,'');
	if(! this.showAllRegions) {
		url = url.replace(/[&]/,'&recordTypeName='+escape(PartnerNodes.recordTypeName)+'&');
	}
	if(this.searchTextNode) {
		url = url.replace(/value/g,'value ').replace('value 1',escape(this.partnerStatusIdField)).replace('value 2',escape(this.searchTextNode.id)).replace('value 3',escape(this.searchTextNode.value));
		PartnerNodes.lookup = openPopupFocus(url,'_partnerStatusLookup',1000,800,'width=1000,height=800,resizeable=yes,toolbar=no,status=no,scrollbars=yes,menubar=no,directories=yes,location=no,dependant=yes',false,false);
	}
	return false;
}

PartnerNodes.changeRelationshipType = function(node,defaultRelationshipType) {
	//alert('changeRelationshipType');
	var nodes = new PartnerNodes(node,defaultRelationshipType);
	nodes.updatePartnerTierOptions();
	nodes.updatePartnerTypeOptions();
	nodes.updatePartnerSubTypeOptions();
	nodes.updateSearchText();
	nodes.updateLink();
	return true;
}

PartnerNodes.changeShowAllRegions = function(node,defaultRelationshipType) {
	//alert('changeShowAllRegions');
	var nodes = new PartnerNodes(node,defaultRelationshipType);
	nodes.updatePartnerTierOptions();
	nodes.updatePartnerTypeOptions();
	nodes.updatePartnerSubTypeOptions();
	return true;
}

PartnerNodes.changePartnerType = function(node,defaultRelationshipType) {
	//alert('changePartnerType');
	var nodes = new PartnerNodes(node,defaultRelationshipType);
	nodes.assignPartnerType();
	return true;
}

PartnerNodes.changePartnerTier = function(node,defaultRelationshipType) {
	//alert('changePartnerTier');
	var nodes = new PartnerNodes(node,defaultRelationshipType);
	nodes.assignPartnerTier();
	return true;
}

PartnerNodes.changePartnerSubType = function(node,defaultRelationshipType) {
	//alert('changePartnerSubType');
	return true;
}

PartnerNodes.openLookupLink = function(node,url,defaultRelationshipType) {
	var nodes = new PartnerNodes(node,defaultRelationshipType);
	return nodes.openLookupLink(url);
}

PartnerNodes.setPartnerStatusId = function(node,value) {
	var partnerStatusIdField = node.id.replace(/:[^:]*$/,':partnerStatusId');
	var n = document.getElementById(partnerStatusIdField);
	if(n != null) {
		n.value = value;
	}
}

PartnerNodes.closeLookup = function() {
	try { PartnerNodes.lookup.close() } catch(e) {}
	PartnerNodes.lookup = null;
	return true;
}
