
function fragmentChangeAjax(){
    $.fragmentChange(true);
    if($.browser.msie && $.inArray($.browser.version, ['6.0', '7.0']) != -1){
        $(window).hashchange(function(event,ui){
            productFragmentChange();
            categoryFragmentChange();
        });
    }
    else{
        $(document).bind("fragmentChange.product", function(event,ui){
            productFragmentChange();
        });
        $(document).bind('fragmentChange.category',function(event,ui)
        {
            categoryFragmentChange();
        });
    }
    if($.fragment().product){
        $(document).trigger("fragmentChange.product");
    }
    if($.fragment().category){
        $(document).trigger("fragmentChange.category");
    }
}

function categoryFragment(){
    $('.category').each(function(){
        $(this).click(function(){
            var category_name = $(this).attr('id');
            $.setFragment({"category" : category_name });
        });
    });
}

function categoryFragmentChange()
{
    function check_if_element_exists(el)
    {
        while ( el = el.parentNode ) if ( el === document ) return true; return false;
    }
    category = getNamedFragment();
    if (check_if_element_exists($('#'+category)))
      openTree(category);
}
function getNamedFragment()
{
    if(typeof($.fragment().category) != 'undefined'){
        var category = $.fragment().category;
        var category_name = category;
        if(!isNaN(category))
        {
            category_name = $(document).contents().find('div[name=c_'+category+']').attr('id');
            $.setFragment({"category":category_name});
        }
    }
    return category_name;
}
function productFragmentChange()
{
    if(typeof($.fragment().product) != 'undefined'){
        if(typeof($.fragment().category) != 'undefined'){
            category = getNamedFragment();
            window.location = '/products/'+ product_id+'#category='+category;
        }
        var product_id = $.fragment().product;
        window.location = '/products/'+ product_id;
    }
}


function openTree(category){
    var hitarea = $("#" + category).parent();
    var sibling_hitarea = hitarea.siblings('div.hitarea');

    if(sibling_hitarea.length > 0){
        var classes = sibling_hitarea.attr('class').split(' ');
    }
    if($.inArray('collapsable-hitarea',classes) == -1){
        var arr = new Array();
        arr.push(hitarea);

        do{
            hitarea = $(hitarea.parent().parent().siblings('span'));
            arr.splice(0,0,hitarea);
        }while(hitarea.length > 0);

        for(var i=0; i < arr.length; i++){
            var element = $(arr[i]);
            if(arr[i].length){
                element.trigger('click');
            }
        }
    }
}
