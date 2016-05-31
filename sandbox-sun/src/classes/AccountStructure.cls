/**  Copyright (c) 2008, Matthew Friend, Sales Engineering, Salesforce.com Inc.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
*  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
*  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
*  Neither the name of the salesforce.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
*  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
*  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
*  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
*  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
* To adapt this to anouther Object simply search for "Change" to go to the places 
* where the sObject and query must be changed
*
* Modified by: Bill C Riemers on 2011-10-07 to add support for field sets
* Modified by: Scott Coleman on 2012-11-19 to limit hierarchy to 1,000 account to avoid collection size limit error
*/
public with sharing class AccountStructure{

	//Declare variables
	public Account currentAccount;
	public String currentId;
	public List<ObjectStructureMap> asm ;
	public Map<String, ObjectStructureMap> masm;
	public List<Integer> maxLevel;
	public Boolean isTruncated = false;
	/**
	 * These are the field names to query.
	 */
	public Set<String> queryFields = new Set<String>{
		'Type', 'Site', 'OwnerId', 'Industry'
	};

	/**
	* Contructor
	*/
	public AccountStructure() {
		this.asm = new List<ObjectStructureMap>{};
		this.masm = new Map<String, ObjectStructureMap>{};
		this.maxLevel = new List<Integer>{};
	}

	/**
	 * Return the field Map.
	 */
	public static Map<String, Schema.SObjectField> accountFieldMap {
		get {
			if(accountFieldMap == null) {
				accountFieldMap = Schema.SObjectType.Account.fields.getMap();
			}
			return accountFieldMap;
		}
		set;
	}

	/**
	 * Allow page to set the current ID
	 */
	public void setcurrentId( String cid ){
		currentId = cid;
	}

	/**
	 * Allow the page to set the current Account.
	 */
	public Account acc {
		get {
			return acc;
		}
		set {
			acc = value;
			currentId = acc.Id;
			queryFields.clear();
			for(String fieldName : accountFieldMap.keySet()) {
				try {
					if(fieldName != 'Id' && fieldName != 'Name' && fieldName != 'Parent' && fieldName != 'ParentId') {
						System.debug('Testing fieldName='+fieldName);
						if(fieldName.endsWith('__r')) {
							Object o = acc.get(fieldName.replace('__r','__c'));
							fieldName+='.Name';
						}
						else {
							Object o = acc.get(fieldName);
							if(fieldName.endsWith('Id')) {
								fieldName = fieldName.replaceAll('Id$','.Name');
							}
						}
						queryFields.add(fieldName);
					}
				}
				catch(Exception ignored) {}
			}
			System.debug(queryFields);
		}
	}

	public List<Account> queryAccounts(Integer level,Set<Id> currentParents) {
		String query = 'select Name,ParentId';
		for(String fieldName : queryFields) {
			query+=','+fieldName;
		}
		query += ' from Account a where ';
		if(level != 0) {
			query += 'Parent';
		}
		return (List<Account>)Database.Query(query + 'Id in :CurrentParents order by Name');
	}

	/**
	* Return ObjectStructureMap to page
	* @return asm
	*/
	public List<ObjectStructureMap> getObjectStructure(){
		asm.clear();
		if ( currentId == null ) {
			currentId = System.currentPageReference().getParameters().get( 'id' );
		}
		
		System.assertNotEquals( currentId, null, 'sObject ID must be provided' );
		asm = formatObjectStructure( CurrentId );
		
		return asm;
	}

	/**
	* Return truncated to page
	* @return truncated
	*/	
	public Boolean getIsTruncated(){
		return isTruncated;
	}
	
	/**
	* Query Account from top down to build the ObjectStructureMap
	* @param currentId
	* @return asm
	*/
	public ObjectStructureMap[] formatObjectStructure( String currentId ){
	
		List<ObjectStructureMap> asm = new List<ObjectStructureMap>{};
		masm.clear();

		//Change below
		List<Account> al			= new List<Account>{};
		Set<ID> currentParent	  = new Set<ID>{};
		Map<ID, String> nodeList	= new Map<ID, String>{};
		List<String> nodeSortList   = new List<String>{};
		Map<Id,Integer> accountsMissingChildren = new Map<Id,Integer>();
		Set<ID> visibleAccounts = new Set<Id>();
		List<Boolean> levelFlag	 = new List<Boolean>{};
		List<Boolean> closeFlag	 = new List<Boolean>{};
		String nodeId			   = '0';
		String nodeType			 = 'child';
		Integer count			   = 0;
		Integer level			   = 0;
		Boolean endOfStructure	  = false;
		Boolean truncated = false;
		
		//Find highest level obejct in the structure
		currentParent.add( getTopAccountId( currentId ) );

		//Loop though all children
		while ( !endOfStructure ){
			al = (List<Account>)queryAccounts(level,currentParent);
			if( al.size() == 0 ){
				endOfStructure = true;
			}
			else{
				currentParent.clear();
				Integer s = Integer.valueOf(('1'+String.valueOf(al.size()).replaceAll('[0-9]','0')));
				for ( Integer i = 0 ; i < al.size(); i++ ){
					//Stop adding nodes when we've reached the maximum allowed collection size
					if (nodeList.size() >= 1000) {
						truncated = isTruncated = true;
					}
					//Change below
					Account a = al[i];
					nodeId = String.valueOf( i+s ).substring(1);
					if(level > 0) {
						nodeId = NodeList.get( a.ParentId )+'.'+nodeId;
					}
					masm.put( NodeID, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, a ) );
					currentParent.add( a.id );	
					nodeList.put( a.id,nodeId );				
					if (truncated) {
						Boolean visibleParentLocated = false;
						Id parentAccountId = a.ParentId;
						while (!visibleParentLocated && parentAccountId != null) {
							visibleParentLocated = visibleAccounts.contains(parentAccountId);
							if (accountsMissingChildren.containsKey(parentAccountId)) {
								Integer childCount = accountsMissingChildren.get(parentAccountId);
								accountsMissingChildren.put(parentAccountId,childCount+1);
							}
							else {
								accountsMissingChildren.put(parentAccountId,1);	
							}
							String parentNodeId = nodeList.get(parentAccountId);
							parentAccountId = masm.get(parentNodeId).account.ParentId;
						}
					}
					else {
						nodeSortList.add( nodeId );
						visibleAccounts.add (a.id);
					}
				}

				maxLevel.add( level );				
				level++;
			}
		}

		//Account structure must now be formatted
		NodeSortList.sort();

		for( Integer i = 0; i < NodeSortList.size(); i++ ){
			List<String> pnl = new List<String> {};
			List<String> cnl = new List<String> {};
			List<String> nnl = new List<String> {};

			if ( i > 0 ){
				String pn 	= NodeSortList[i-1];
				pnl 		= pn.split( '\\.', -1 );
			}

			String cn 	= NodeSortList[i];
			cnl 		= cn.split( '\\.', -1 );

			if( i < NodeSortList.size()-1 ){
				String nn = NodeSortList[i+1];
				nnl = nn.split( '\\.', -1 );
			}
			
			ObjectStructureMap tasm = masm.get( cn );
			if ( cnl.size() < nnl.size() ){
				//Parent
				tasm.nodeType = ( isLastNode( cnl ) ) ? 'parent_end' : 'parent';
			}
			else if( cnl.size() > nnl.size() ){
				tasm.nodeType 	= 'child_end';
				tasm.closeFlag 	= setcloseFlag( cnl, nnl, tasm.nodeType );
			}
			else{
				tasm.nodeType = 'child';
			}
			
			tasm.levelFlag = setlevelFlag( cnl, tasm.nodeType ); 
			
			//Change below
			if ( tasm.account.id == currentId ) {
				tasm.currentNode = true;
			}
			System.Debug('hello!');
			tasm.missingChild = accountsMissingChildren.containsKey(tasm.account.id);
			if (tasm.missingChild) {
				tasm.missingChildCount = accountsMissingChildren.get(tasm.account.id);
			}
			asm.add( tasm );
		}

		asm[0].nodeType 			= 'start';
		asm[asm.size()-1].nodeType 	= 'end';

		return asm;
	}
	
	/**
	* Determin parent elements relationship to current element
	* @return flagList
	*/
	public List<Boolean> setlevelFlag( List<String> nodeElements, String nodeType ){
		
		List<Boolean> flagList = new List<Boolean>{};
		String searchNode 	= '';
		String workNode 	= '';
		Integer cn 			= 0;
		
		for( Integer i = 0; i < nodeElements.size() - 1; i++ ){
			cn = Integer.valueOf( nodeElements[i] );
			cn++;
			searchNode 	= workNode + String.valueOf( cn );
			workNode 	= workNode + nodeElements[i] + '.';
			if ( masm.containsKey( searchNode ) ){
				flagList.add( true );
			}
			else {
				flagList.add( false );
			}
		}
		
		return flagList;
	}
	
	/**
	* Determin if the element is a closing element
	* @return flagList
	*/
	public List<Boolean> setcloseFlag( List<String> cnl, List<String> nnl, String nodeType ){
		
		List<Boolean> flagList = new List<Boolean>{};
		String searchNode 	= '';
		String workNode 	= '';
		Integer cn 			= 0;
		
		for( Integer i = nnl.size(); i < cnl.size(); i++ ){
			flagList.add( true );
		}
		
		return flagList;
	}
	
	/**
	* Determin if Element is the bottom node  
	* @return Boolean
	*/
	public Boolean isLastNode( List<String> nodeElements ){
		
		String searchNode 	= '';
		Integer cn 			= 0;
		
		for( Integer i = 0; i < nodeElements.size(); i++ ){
			if ( i == nodeElements.size()-1 ){
				cn = Integer.valueOf( nodeElements[i] );
				cn++;
				searchNode = searchNode + String.valueOf( cn );
			}
			else {
				searchNode = searchNode + nodeElements[i] + '.';
			}
		}
		if ( masm.containsKey( searchNode ) ){
			return false;
		}
		else{
			return true;
		}
	}
	
	/**
	* Find the top most element in the Account Heirarchy
	* @param accountId current Account Id
	* @return accountId
	*/
	public Id getTopAccountId( Id accountId ){
		
		Boolean top = false;
		do {
			top = true;
			//Change below
			for(Account a : [ Select Parent.Parent.Parent.Parent.Parent.Id From Account where Id = :accountId limit 1 ] ) {
				Integer i=5;
				for(;i > 0 && a.Parent != null;i--) {
					a = a.Parent;
				}
				accountId = a.Id;
				top = (i > 0);
			}
		} while(! top);
		return accountId ;
	}
	
	/**
	* Wrapper class
	*/
	public with sharing class ObjectStructureMap{

		public String nodeId;
		public Boolean[] levelFlag = new Boolean[]{};
		public Boolean[] closeFlag = new Boolean[]{};
		public String nodeType;
		public Boolean currentNode;
		public Boolean missingChild;
		public Integer missingChildCount;
		
		/**
		* @Change this to your sObject
		*/
		public Account account;
		
		public String getnodeId() { return nodeId; }
		public Boolean[] getlevelFlag() { return levelFlag; }
		public Boolean[] getcloseFlag() { return closeFlag; }
		public String getnodeType() { return nodeType; }
		public Boolean getcurrentNode() { return currentNode; }
		public Boolean getmissingChild() { return missingChild; }
		public Integer getmissingChildCount() { return missingChildCount; }


		/**
		* @Change this to your sObject
		*/
		public Account getaccount() { return account; }
		
		public void setnodeId( String n ) { this.nodeId = n; }
		public void setlevelFlag( Boolean l ) { this.levelFlag.add(l); }
		public void setlcloseFlag( Boolean l ) { this.closeFlag.add(l); }
		public void setnodeType( String nt ) { this.nodeType = nt; }
		public void setcurrentNode( Boolean cn ) { this.currentNode = cn; }
		public void setmissingChild( Boolean mc ) { this.missingChild = mc; }
		public void setmissingChildCount( Integer mcc ) { this.missingChildCount = mcc; }

		/**
		* @Change this to your sObject
		*/
		public void setaccount( Account a ) { this.account = a; }

		/**
		* @Change the parameters to your sObject
		*/
		public ObjectStructureMap( String nodeId, Boolean[] levelFlag,Boolean[] closeFlag , String nodeType, Boolean lastNode, Boolean currentNode, Account a ){
			
			this.nodeId		 = nodeId;
			this.levelFlag	  = levelFlag; 
			this.closeFlag	  = closeFlag;
			this.nodeType	   = nodeType;
			this.currentNode	= currentNode;
			this.missingChild = false;
			this.missingChildCount = 0;

			//Change this to your sObject  
			this.account = a;
		}
	}
}