public with sharing class NavigationInputController {

    public Communities_Navigation_Item__c navItem { get; set; }
    public List<SelectOption> tabSelectOptions { get; set; }
    public Map<String,String> tabNameToURL { get; set; }
    public Map<String, Boolean> tabNameToIsObject { get; set; }

    public boolean isObject { get; set; }

    public String selectedTab { get; set; }

    public NavigationInputController(ApexPages.StandardController sc) {

        navItem = (Communities_Navigation_Item__c)sc.getRecord();
        String navId = ((Communities_Navigation_Item__c)sc.getRecord()).Id;
        String navQuery = 'SELECT ';
        For(String s : fieldList()){
            navQuery += s+', ';
        }
        navQuery = navQuery.removeEnd(', ');
        navQuery += ' FROM Communities_Navigation_Item__c WHERE Id = :navId';

        if(navId != null && navId != ''){
            navItem = database.query(navQuery);
        }else{
            navItem = new Communities_Navigation_Item__c();
        }

        populateTabData();

        if(navItem.Tab_Name__c!=null){
            selectedTab=navItem.Tab_Name__c;
        }
    }

    public List<String> fieldList(){
        List<String> fields = new List<String>();
            fields.add('Audience__c');
            fields.add('English_Label__c');
            fields.add('Parent_Item__c');
            fields.add('Sequence__c');
            fields.add('URL__c');
            fields.add('Content_Targeting__c');
            fields.add('Tab_Name__c');
            fields.add('Name');
            fields.add('Type__c');
        return fields;
    }

    public void populateTabData(){
        List<Schema.DescribeTabSetResult> tabSet = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabs = new List<Schema.DescribeTabResult>();

        for(Schema.DescribeTabSetResult tsr : tabSet){
            if(tsr.getLabel() == 'Partner Community'){
                tabs = tsr.getTabs();
                break;
            }
        }
        tabNameToURL = new Map<String,String>();
        tabNameToIsObject = new Map<String,Boolean>();
        tabSelectOptions = new List<SelectOption>();

        Map<String,Boolean> tabLabelToIsDuplicate = new Map<String,Boolean>();
        for(Schema.DescribeTabResult tab : tabs){
            if(tabLabelToIsDuplicate.keyset().contains(tab.getLabel())){
                tabLabelToIsDuplicate.put(tab.getLabel(),true);
            }else{
                tabLabelToIsDuplicate.put(tab.getLabel(),false);
            }
        }

        for(Schema.DescribeTabResult tab : tabs){
            String tabValue;
            String tabLabel;
            if(tab.getSObjectName() == null || tab.getSObjectName() == ''){
                tabValue = 'pageTab'+tab.getLabel();
                tabNameToIsObject.put(tabValue,false);
                tabLabel = tab.getLabel();
                if(tabLabelToIsDuplicate.get(tab.getLabel())){
                    tabLabel +=  ' [Page]';
                }
            }else{
                tabValue = tab.getSObjectName();
                tabNameToIsObject.put(tabValue,true);
                tabLabel = tab.getLabel();
                if(tabLabelToIsDuplicate.get(tab.getLabel())){
                    tabLabel +=  ' [' + tab.getSObjectName() + ']';
                }
            }
            tabNameToURL.put(tabValue,tab.getURL());
            SelectOption so = new SelectOption(tabValue,tabLabel);
            tabSelectOptions.add(so);
        }

    }

    public pageReference save(){

        if(selectedTab!=null){
            navItem.Tab_Name__c = selectedTab;
            if(tabNameToIsObject.get(selectedTab)){
                navItem.URL__c = tabNameToURL.get(selectedTab).right(6);
            }else{
                navItem.URL__c = tabNameToURL.get(selectedTab).split('com/',0)[1];
            }
        }else{
            navItem.Tab_Name__c = null;
        }
        if(navItem.URL__c == null || navItem.URL__c == ''){
            navItem.URL__c = '#';
        }
        if(navItem.id==null){
            insert navItem;
        }else{
            update navItem;
        }
        PageReference navItemPage = new ApexPages.StandardController(navItem).view();
        navItemPage.setRedirect(true);
        return navItemPage;
    }

    public void clearTargetSelections(){
        selectedTab=null;
        navItem.Audience__c=null;
    }

    public void clearAll(){
        clearTargetSelections();
        navItem.Content_Targeting__c=null;
    }

    public void dummyAction(){
    }

}