var StaticResources = {
  // create code which will add the sources to the page
  code : function(srcList) {
    var fragment='document.StaticResources={srcList:[';
    var sep='';
    for(var i in srcList) {
      var src = srcList[i];
      if(src) {
        if(! this[src]) {
          if(! src.match('/document.StaticResources$')) {
            if(! this[src]) {
              fragment=fragment+sep+"'"+src+"'";
              sep=',';
              this[src]=true;
            }
          }
        }
      }
    }
    return (fragment+'],count:0,load:'+this.load.toString().replace(/\s+/g,' ')+',};');
  },
  load : function() {
    var head = document.getElementsByTagName('head')[0];
    for(var i in this.srcList) {
      var src = this.srcList[i];
      var script = document.createElement('script');
      script.setAttribute('type','text/javascript');
      script.setAttribute('src',this.srcList[i]);
      head.appendChild(script);
    }
  }
};
