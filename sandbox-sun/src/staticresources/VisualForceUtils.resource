
function alternate(id,start,end,colors){
    if(document.getElementsByTagName){
        var table = document.getElementById(id);
        var rows = table.getElementsByTagName("tr");
        for(i = start;i < rows.length-end; i++){
            //manipulate rows
            var j=(i-start)%colors.length;
            if(colors[j])
            {
                rows[i].style.backgroundColor = colors[j];
            }
        }
    }
}

function lessThanTest(a,b)
{
    return (a<b);
}

function greaterThanTest(a,b)
{
    return (a>b);
}
