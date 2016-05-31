/**
 * This is a controller for the QueriedList component.
 *
 * @version 2013-09-09
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-09-04 - added column sorting
 * 2013-03-19 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2013-09-09 - addition of nosort, minor fixes
 */
public with sharing class EnhancedRelatedListController {
	transient private Schema.DescribeSObjectResult sobjectResult = null;
	transient private Map<String, Schema.SObjectField> sobjectFieldMap = null;

	Map<String,String> queryOrderByMap = new Map<String,String>();
	List<String> queryOrderByList = new List<String>();

	/**
	 * Standard constructor.
	 */
	public EnhancedRelatedListController() {}

	public Integer sequence {
		get;
		set {
			if(value != sequence) {
				columns = null;
				sobjectResult = null;
				sobjectFieldMap = null;
				sequence = value;
			}
		}
	}

	/**
	 * Story the object name.
	 */
	public String queryObject {
		get;
		set {
			if(queryObject != value) {
				queryObject = value;
				columns = null;
				sobjectResult = null;
				sobjectFieldMap = null;
			}
		}
	}

	/**
	 * Comma separated list of fields to query.
	 */
	public String queryFields {
		get;
		set {
			if(value != queryFields) {
				queryFields = value;
				columns = null;
			}
		}
	}

	/**
	 * This is the field name to sort on for this column.
	 */
	public String sortFieldsString {
		get;
		set {
			if(value != sortFieldsString) {
				sortFieldsString = value;
				columns = null;
			}
		}
	}

	/**
	 * If true, all column sorting is disabled.
	 */
	public Boolean noSort {
		get {
			if(noSort == null) {
				noSort = false;
			}
			return noSort;
		}
		set {
			if(value != noSort) {
				noSort = value;
				columns = null;
			}
		}
	}

	/**
	 * The conditions to use for the query.
	 */
	public String queryConditions {
		get;
		set {
			if(queryConditions != value) {
				queryConditions = value;
				controller = null;
			}
		}
	}

	String queryOrderByOverride {
		get;
		set {
			queryOrderBy = queryOrderByOverride = value;
		}
	}

	/**
	 * Order by string for the query.
	 */
	public String queryOrderBy {
		get;
		set {
			if(queryOrderByOverride != null) {
				value = queryOrderByOverride;
			}
			if(queryOrderBy != value) {
				queryOrderByMap.clear();
				queryOrderBy = '';
				if(value != null) {
					value = value.trim();
					if(! ''.equals(value)) {
						String sep = '';
						for(String v : value.split('\\s*,\\s*')) {
							String [] a = v.trim().split('\\s+',2);
							if(! queryOrderByMap.containsKey(a[0])) {
								queryOrderBy += sep + v;
								sep = ',';
								String orderValue = 'asc';
								if(a.size() == 2) {
									orderValue = a[1];
								}
								queryOrderByMap.put(a[0],orderValue);
							}
						}
					}
				}
				columns = null;
			}
		}
	}

	/**
	 * Overall limit for the query.
	 */
	public Integer queryLimit {
		get;
		set {
			if(queryLimit != value) {
				queryLimit = value;
				controller = null;
			}
		}
	}

	/**
	 * Build the query string.
	 *
	 * @return query string
	 */
	public String getQueryString() {
		String queryString = null;
		if(queryObject != null && queryFields != null) {
			queryString = 'select ';
			String sep = '';
			for(String fieldName : queryFields.trim().split('\\s*,\\s*')) {
				if(! ''.equals(fieldName) ) {
					queryString += sep + fieldName;
					sep = ',';
				}
			}
			queryString += ' from '+queryObject;
			if(queryConditions != null) {
				queryString += ' where '+queryConditions;
			}
			if(queryOrderBy != null && ! ''.equals(queryOrderBy)) {
				queryString += ' order by '+queryOrderBy;
			}
			if(queryLimit != null) {
				queryString += ' limit '+queryLimit;
			}
		}
		return queryString;
	}

	/**
	 * Number of records per page.
	 */
	public Integer pageSize {
		get;
		set;
	}

	/**
	 * Comma separated list of labels.  A blank value means we look up
	 * the label from the field description.
	 */
	public String fieldLabelListString {
		get;
		set {
			if(fieldLabelListString != value) {
				fieldLabelListString = value;
				columns = null;
			}
		}
	}

	/**
	 * Get the describe object used to lookup labels.
	 *
	 * @return describesobjectresult
	 */
	private Schema.DescribeSObjectResult getObjectResult() {
		if(sobjectResult == null && queryObject != null) {
			sobjectResult = Schema.getGlobalDescribe().get(queryObject).getDescribe();
			sobjectFieldMap = null;
		}
		return sobjectResult;
	}

	/**
	 * Get the mapping of field objects.
	 * 
	 * @return mapping
	 */
	private Map<String, Schema.SObjectField>  getObjectFieldMap() {
		if(sobjectFieldMap == null && queryObject != null) {
			sobjectFieldMap = getObjectResult().fields.getMap();
		}
		return sobjectFieldMap;
	}

	public List<ColumnInfo> columns {
		get {
			if(columns == null) {
				columns = new List<ColumnInfo>();
				List<String> labelArray = new List<String>();
				if(fieldLabelListString != null) {
					labelArray.addAll(fieldLabelListString.split('\\s*,\\s*'));
				}
				List<String> sortArray = new List<String>();
				if(sortFieldsString != null && !noSort) {
					sortArray.addAll(sortFieldsString.trim().split('\\s*,\\s*'));
				}
				if(queryFields != null) {
					for(String fieldName : queryFields.trim().split('\\s*,\\s*')) {
						String sortField = null;
						if(queryOrderByMap.containsKey(fieldName) && !noSort) {
							sortField = fieldName;
						}
						if(! sortArray.isEmpty() && !noSort) {
							sortField = sortArray.remove(0);
						}
						ColumnInfo columnInfo = new ColumnInfo(this,fieldName,sortField);
						columns.add(columnInfo);
						if(! labelArray.isEmpty()) {
							String label = labelArray.remove(0);
							if(label != null && ! ''.equals(label)) {
								columnInfo.label = label;
							}
						}
					}
				}
				for(String label : labelArray) {
					String sortField = null;
					if(! sortArray.isEmpty() && !noSort) {
						sortField = sortArray.remove(0);
					}
					ColumnInfo columnInfo = new ColumnInfo(this,null,sortField);
					columns.add(columnInfo);
					if(label != null && ! ''.equals(label)) {
						columnInfo.label = label;
					}
				}
			}
			return columns;
		}
		set {
			columns = value;
			if(value == null) {
				controller = null;
			}
		}
	}

	/**
	 * Standard Set Controller for paging results.
	 */
	public ApexPages.StandardSetController controller {
		get {
			if(controller == null) {
				controller = new ApexPages.StandardSetController(
					Database.getQueryLocator(getQueryString()) );
				if(pageSize != null) {
					controller.setPageSize(pageSize);
				}
			}
			return controller;
		}
		set;
	}

	/**
	 * List of records looked up by query in current page.
	 */
	public List<SObject> getRecords() {
		return controller.getRecords();
	}

	/**
	 * The number of pages available.
	 *
	 * @return number of pages
	 */
	public Integer getPageCount() {
		Integer rs = controller.getResultSize();
		Integer ps = controller.getPageSize();
		return (ps+rs-1)/ps;
	}


	/**
	 * Navigate to the first page.
	 * @return null
	 */
	public PageReference first() {
		controller.first();
		return null;
	}

	/**
	 * Navigate to the next page.
	 * @return null
	 */
	public PageReference next() {
		controller.next();
		return null;
	}

	/**
	 * Navigate to the previous page.
	 * @return null
	 */
	public PageReference previous() {
		controller.previous();
		return null;
	}

	/**
	 * Navigate to the last page.
	 * @return null
	 */
	public PageReference last() {
		controller.last();
		return null;
	}

	public class ColumnInfo {
		private final EnhancedRelatedListController controller;
		private final String fieldName;
		private final String sortName;

		ColumnInfo(EnhancedRelatedListController controller,String fieldName,String sortName) {
			this.controller = controller;
			if(fieldName != null) {
				fieldName = fieldName.trim();
				if(''.equals(fieldName)) {
					fieldName = null;
				}
			}
			this.fieldName = fieldName;
			this.sortName = sortName;
		}

		/** field name being viewed */
		public String getFieldName() {
			return fieldName;
		}

		/**
		 * Called to find if the sortField method will make "asc" or "desc". A null
		 * value indicates sorting is not allowed.
		 * 
		 * @return "asc" or "desc" as the field will be sorted bythe sortField method
		 */
		public String getSortTo() {
			String retval = null;
			if(sortName != null && sortName != '') {
				retval = 'asc nulls last';
				if((''+controller.queryOrderByMap.get(sortName)).toLowerCase().contains('asc')) {
					retval = 'desc nulls last';
				}
			}
			return retval;
		}

		/** Column heading */
		public String label {
			get {
				if(label == null && fieldName != null) {
					label = controller.getObjectFieldMap().get(fieldName).getDescribe().getLabel();
					if(label == null) {
						label = fieldName;
					}
				}
				return label;
			}
			set;
		}

		/**
		 * Called to sort on this column in the order indicated by the getSortTo method.
		 * 
		 * @return null
		 */
		public PageReference sortField() {
			if(sortName != null) {
				controller.queryOrderByOverride = sortName+' '+getSortTo()+','+controller.queryOrderBy;
			}
			return null;
		}
	}
}