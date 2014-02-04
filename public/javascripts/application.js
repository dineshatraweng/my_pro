$(document).ready(function(){

    /** code to add class on when dropdown is open & to remove on hover of other items**/
    $("#content-wrapper #content #main-content .jquery-selectbox .jquery-selectbox-item").hover(function(){
        $(".jquery-selectbox-list .jquery-selectbox-item.value-.item-0").removeClass("active-item");
    });
    $("#content-wrapper #content #main-content .jquery-selectbox .jquery-selectbox-moreButton").click(function(){
        $(".jquery-selectbox-list .jquery-selectbox-item.value-.item-0").addClass("active-item");
    });


    var h=$(window).height();
    if(h < 650){
        $("#login-tabs").addClass("movetop-600");
    } /* class to add when window size is less than 650*/

    if(h < 550){
        $("#login-tabs").addClass("movetop-500");
    } /* class to add when window size is less than 550*/


    $(".report-button").mouseover(function ()
    {
        $(".reports-wrap").show();
        if ( $.browser.msie ) {
            if ( $.browser.version == 7.0)
            {
                $("#content-wrapper #content").css("z-index","-1");
            }
        }
    });

    $("#report-items").mouseenter(function(){
        $(".reports-wrap").show();
        if ( $.browser.msie ) {
            if ( $.browser.version == 7.0)
            {
                $("#content-wrapper #content").css("z-index","-1");
            }
        }
    });

    $("#report-items").mouseleave(function(){
        $(".reports-wrap").hide();
        if ( $.browser.msie ) {
            if ( $.browser.version == 7.0)
            {
                $("#content-wrapper #content").css("z-index","0");
            }
        }
    });
    $(".report-button").mouseleave(function(){
        $(".reports-wrap").hide();
        if ( $.browser.msie ) {
            if ( $.browser.version == 7.0)
            {
                $("#content-wrapper #content").css("z-index","0");
            }
        }
    });
    /*------------------ show & hide nav list on hover of domain button  ------------------------*/
    $(".domain-button").mouseover(function(){
        $(".domain-items").show();
        if ( $.browser.msie ) {
            if ( $.browser.version == 7.0)
            {
                $("#content-wrapper #content").css("z-index","-1");
                $(".reports-wrapper").css("z-index","-1");
            }
        }
    });

    $(".domain-button").mouseleave(function(){
        $(".domain-items").hide();
        if ( $.browser.msie ) {
            if ( $.browser.version == 7.0)
            {
                $("#content-wrapper #content").css("z-index","0");
                $(".reports-wrapper").css("z-index","0");
            }
        }
    });

    $("#domain-items").mouseenter(function() {
        $(".domain-items").show();
        if ( $.browser.msie ) {
            if ( $.browser.version == 7.0)
            {
                $("#content-wrapper #content").css("z-index","-1");
                $(".reports-wrapper").css("z-index","-1");
            }
        }
    });

    $("#domain-items").mouseleave(function(){
        $(".domain-items").hide();
        if ( $.browser.msie ) {
            if ( $.browser.version == 7.0)
            {
                $("#content-wrapper #content").css("z-index","0");
                $(".reports-wrapper").css("z-index","0");
            }
        }
    });

    var h= $(window).height();
    pad();
    var product_list = [];
    var VAR = {
        mouse_in_container: false
    };

    var product_and_tags_list = [];


//    $('#browse .product_name').each(function(){
//        var product_name = $(this).text();
//        if($.inArray(product_name,product_list) === -1){
//            product_list.push({value: product_name, link: $(this).attr('href')});
//        };
//    });

    function fill_list(prod)
    {
        product_and_tags_list = prod
//        quickFind(prod);
    }
    $.ajax(
        {

            url:'/products/employee/fill_product_find',
            success:function(products){
                fill_list(products);

            }
        }
    );


    $("#quick-find").autocomplete({
        source: function(request, response) { response(filter(request.term ,product_and_tags_list));},
        open: function( event, ui ) {
            $("ul.ui-autocomplete").addClass("vertical-scroll");

        },
        close: function( event, ui ) {
//$("ul.ui-autocomplete" ).autocomplete( "destroy" );
            $("ul.ui-autocomplete").removeClass("vertical-scroll");
        },
        select: function(event,ui){
            window.location = ui.item.link;
        }


    });

    if ( $.browser.msie ) {                 //added code for space displayed when product has no description & docs attached (IE7 browser)
        if ( $.browser.version == 7.0)
        {
            if ($('.description').html() == ''){
                $('.description').css("padding-top","0px");
            }
        }
    }


    adjustHeight();
    search_content();
//    quickFind(product_list);
    productFormSubmit();
    productsToken();
    searchResultNavigation();
//    applyEllipsis();
    ieFixing();
    productListTree();
    folderPathAutoComplete();
    setFocusOnLoginField();
    pointCurrentLoadedProduct();
    productRatingFeedback();
    insertProductName();
    trackDocumentView();
    showFeedBackForm();
    categoryFragment();
    showalertonOFCupdate();
    tracknullserchresults();
    seeMoreRecentUpdate();
    hideSeeMoreRecentUpdate();
    addRemovable();
    hideEditable();
    versionFind();
    hideCollapseAllLink();
    fragmentChangeAjax();
    hide_add_filter_text();
    hide_and_show_scrollbar();
    if(typeof(category_id) != 'undefined')
    {
        openTree(category_id);
    }
    docNameAutocomplete();
    disableDocSubmitBtn();

    /*------------------- show tooltip onclick of arrow in documents list ----------------------------*/
    $(".tooltip-open-arrow.qtipcallback img").each(function(){
        var id = $(this).attr("id");
        var id_arr = id.split("-");
        id = id_arr[id_arr.length -1];
        var content = $("#doc-desc-" + id).text();
        $(this).qtip({
            overwrite: false,
            content:{
                text: content
            },
            position: {
                my: 'bottom right',  // Position my top left...
                at: 'top right', // at the bottom right of...
                corner: {
                    target: 'topLeft',
                    tooltip: 'bottomRight'
                },

                adjust: {
                    x: 10,
                    y: -10
                },
                effect: false
            },
            show:{
                event: 'click',
                solo: true,
                effect: false

            },
            hide: {
                event: 'click unfocus',
                solo: true
            },
            style: {
                classes: 'ui-tooltipNew',
                widget: true, // Use the jQuery UI widget classes
                def: false // Remove the default styling (usually a good idea, see below)

            },
            events: {
                show: function(event, api) {
                    var tooltip_arrow = $(".tooltip-arrow").remove();
                    api.elements.tooltip.append($("<div class='tooltip-arrow'> </div>"));

                }
            }
        });
    });

    /*----- alternate background colors to rows in documents view */
    $("ul.product-docs.listing li.ui-state-default:nth-child(2n+1)").css("background","#F4F4F4");
    $("ul.product-docs.listing li:nth-child(2n)").css("background","#d7f0fe");
});


var filter = function(user_input,elements){
    var array = [];
    var json_element =[];
    var count=0;
    //fix for IE8 since IE8 doesnt support indexOf method
    if (!Array.prototype.indexOf)
    {
        Array.prototype.indexOf = function(elt /*, from*/)
        {
            var len = this.length >>> 0;

            var from = Number(arguments[1]) || 0;
            from = (from < 0)
                ? Math.ceil(from)
                : Math.floor(from);
            if (from < 0)
                from += len;

            for (; from < len; from++)
            {
                if (from in this &&
                    this[from] === elt)
                    return from;
            }
            return -1;
        };
    }

    while(count < elements.length)
    {
        if(elements[count].value.toUpperCase().replace(/\s\s+/g, ' ').indexOf(($.trim($.trim(user_input).replace(/[-()/@™®©]/g, "").replace( /\s\s+/g, " " ).toUpperCase()))) != -1 )
        {
            if ($.trim(user_input).replace(/[^a-zA-Z0-9 ]/g, "").replace( /\s\s+/g, " " ).toUpperCase() != 0 )
            {

                if(json_element.indexOf(elements[count].name.toUpperCase()) == -1  )
                {
                    json_element.push(elements[count].name.toUpperCase());
                    array.push({"value":elements[count].name,"link":elements[count].link})
                }
            }
            else
            {
                if (elements[count].value.toUpperCase().replace(/\s\s+/g, ' ').indexOf($.trim(user_input)) != -1 && json_element.indexOf(elements[count].name.toUpperCase()) == -1 )
                {
                    json_element.push(elements[count].name.toUpperCase());
                    array.push({"value":elements[count].name,"link":elements[count].link})
                }
            }


        }
        count = count + 1
    }

    return array
} ;



function hide_and_show_scrollbar()
{
    $('div.token-input-dropdown-facebook')
        .mouseenter(function(){
            mouse_in_container = false;
        })

        .mouseleave(function(){
            mouse_in_container = true;
        }) ;


    $('li.token-input-input-token-facebook')
        .mousedown(function(){
            mouse_in_container = false
        })


}



function hide_add_filter_text()
{
    if ($(".token-input-token-facebook").length == 1 )
    {
        $(".input-tokenizer").val("");
    }
}

function pointCurrentLoadedProduct()
{
    try{
        $("#p_"+ product_id).parent().parent().addClass('selected-list');       // show an arrow on the selected product in a tree
    }
    catch(err)
    {}
}


//
//function quickFind(list){
//    $("#quick-find").autocomplete({
//        source: list,
//        select: function(event,ui){
//            window.location = ui.item.link;
//        }
//    });
//}





function versionFind(){
    var list =[];
    $('.ready .product_name').each(function(){
        var product_name = $(this).text();
        if($.inArray(product_name,list) === -1){
            list.push({value: product_name, link: $(this).attr('href'),id: $(this).attr('id'), name: $(this).attr('name')});
        };
    });
    $("#version").autocomplete({
        source: list,
        select: function(event,ui){
            $('.ready .product_name').each(function(){
                if($(this).attr('id') == ui.item.id )
                {
                    $(this).removeClass('product_name');
                }
            } );
//            var attributes = JSON.parse(ui.item.name);
            var attributes = jQuery.parseJSON(ui.item.name)
            var id = ui.item.id;
            if(attributes.version == 0)
            {
                var version = "";
            }
            else
            {
                var version = attributes.version;
            }
            $("#table1 tbody:last").append('<tr class="row-color"><td style="display: none;"><input type="text" style="display: none;" name="product[version][][id]" value = "'+ id +'"></td><td class="dragHandle"></td><td style="display:none;"> <input type="text" name="product[version][][name]" value="'+ ui.item.label +'"> </td><td>'+ui.item.label+'</td><td class="version_field" ><input type="text" name="product[version][][version_no]" value="'+version+'"></td><td><center><input class="cancel-button"type="button" value="Remove"> </center></td></tr>');
            $("#table1").tableDnD();
            versionFind();
        }
    });
}

function productFormSubmit(){
    $('#search-box form').live("submit",function(ev){
        var url = $(this).attr('action');
        var value = $("#quick-find",this).val();
        var arr = ["","Enter product name"];

        if($.inArray($.trim(value),arr) === -1)
        {
            window.location('/products/find?find[product_name]='+ value)
        }
        return false;
    });
}

function productsToken(){
    if($("#search-filter").length > 0)
    {
        var search_filter_props = {
            theme: "facebook",
            resultsLimit: 25,
            preventDuplicates: true,
            onAdd: function(item){
                var text = $('#search_filters').val();
                $('#search_filters').val(text + item.name + "|");
                $('.input-tokenizer').attr('disabled','disabled');
                $(".input-tokenizer").val("");
                $('.input-tokenizer').blur();
                $('.input-tokenizer').focus(function(){
                    $("div.token-input-dropdown-facebook").css("display","none");
                });
                $('#big-find').click(function(){
                    if ($(".token-input-token-facebook").length == 1 && $("#big-find").val() == "Search")
                    {
                        $(this).val("");
                    }


                });
                var value = $('#big-find').val();
                var arr = ["","Search"];
                if($.inArray(value,arr) === -1){
                    $('#search-box-big form').submit();
                }
            },
            onDelete: function(item){
                var arr = $('#search_filters').val().split('|');
                $('.input-tokenizer').focus(function(){
                    $("div.token-input-dropdown-facebook").css("display","block");

                });
                var index = $.inArray(item.name,arr);
                if (index != -1) {
                    arr.splice(index, 1);
                }
                $('#search_filters').val(arr.join(','));
                $('.input-tokenizer').removeAttr('disabled');
                var value = $('#big-find').val();
                var arr1 = ["","Search"];
                if($.inArray(value, arr1) === -1){
                    $('#search-box-big form').submit();
                }
            }
        };

        if(typeof(set_filters) != 'undefined')
        {
            search_filter_props.prePopulate = [];
            search_filter_props.prePopulate.push({name: set_filters});
        }
        var changed_prod_list = [];
        for(prod in prod_list)
        {
            var product = prod_list[prod];
            changed_prod_list.push({'name':product.filtered_name, 'id':product.id});
        };
        $("#search-filter").tokenInput(changed_prod_list,search_filter_props);
        if(typeof(set_search) != 'undefined')
            $('#big-find').val(set_search);
    }
}

function productListTree(){
    $('.root').treeview({control: "#tree-control"});
}

function searchResultNavigation(){
    $("#top_navigation a, #pagination a, .more-results").live('click',function(){
        var url = $(this).attr('href');
        $.ajax({url:url,success: function(data){$('#search-results-wrapper').html(data)}});
        return false;
    });
}

//function applyEllipsis(){
//    $(".ellipsis").ellipsis();
//
//    $('.ellipsis').click(function(e){
//        $(this).parent().trigger('click');
//    });
//}

function ieFixing(){
    if ( $.browser.msie ){
        $("#content #buttons").css( "position","absolute" );
    }
}

function folderPathAutoComplete(){
    initFolderPathAutoComplete();
    $('#document_doctype_input').change(function(){
        if(typeof(path_for) != 'undefined'){
            var doctype = $('input[name=document[doctype]]:radio:checked', '#document_doctype_input').val();
            var source = (path_for === "products" ? "/folder_path?path_for=products" : ("/folder_path?path_for=documents&product_id="+product_id+"&doctype="+doctype));
            $(".folder-path-field").autocomplete( "option", "source", source );
        }
    })
}

function initFolderPathAutoComplete(){
    if(typeof(path_for) != 'undefined'){
        var doctype = $('input[name=document[doctype]]:radio:checked', '#document_doctype_input').val();
        var source = (path_for === "products" ? "/folder_path?path_for=products" : ("/folder_path?path_for=documents&product_id="+product_id+"&doctype="+doctype));
        $('.folder-path-field').autocomplete({
            minLength: 0,
            source: source
        }).focus(function () {
                $(this).autocomplete("search");
            });
    }
}

function checkForIE6(){
    if($.browser.msie){
        if($.browser.version == '6.0'){

            if($('#search-results-wrapper').html() === "" || $('#search-results-wrapper .search-result').html() === "No Search Results" )
            {
                $('#content').css('height','550px');
//        $('#content').css('background-color','blue');
            }
            else
            {
                $('#content').css('height','100%');
                $('#content').css('padding-bottom','5px');
                $('#footer').css('position','relative');
                $('#footer').css('bottom','0px');
//        $('#content').css('background-color','red');
            }

            if(typeof(addcat) != "undefined"){
                $('#content').css('height','550px');
                $('#footer').css('position','absolute');
            }
        }
    }

}

function setFocusOnLoginField(){
    if($('.set-focus-here').length > 0){
        $('.set-focus-here').focus();
    }
}


function productRatingFeedback() {
    if (typeof($('#rating-star')) != 'undefined')
    {
        $('#rating-star').raty({
            half:  true,                        // it should be possible to give give a rate like 3.5, 1.5, etc
            hintList: ['','', '', '', ''],      // the hint of the star is set to null because client does not wish to see any hints
//    start: $("#productRating").val(),
            click: function(score, evt) {
                $("#productRating").val(score);
                $('#iframe_form').contents().find('#prod_rate').val(score);
                var prod_name_field = $('#iframe_form').contents().find("#product_name").val();
                var prod_url_field = $('#iframe_form').contents().find("#product_url").val();
                var prod_rating_field = $('#iframe_form').contents().find("#product_rating").val();
                var user_name_field = $('#iframe_form').contents().find("#user_name").val();
                var user_email_field = $('#iframe_form').contents().find("#user_email").val();
                var comment_field = $('#iframe_form').contents().find("#comment_input").val();
                $('#iframe_form').contents().find("#data").val('{"'+ prod_name_field +'":"'+$("#productName").val()+'","'+ prod_rating_field + '":"'+$("#productRating").val()+'","'+ prod_url_field + '":"'+window.document.URL+'","'+ user_name_field +'":" ","'+ user_email_field +'":" ","'+ comment_field +'":" "}');
                $('#iframe_form').contents().find("#formvine").submit();
                $.fn.raty.readOnly('true','#rating-star');

            }
        })
    }
}

function showFeedBackForm()
{
    $('#get-feedback').click(function(){
        $('#feedback').css("display:''");
        var star_position= $('#get-feedback').offset();
        var form_left =  star_position.left;
        var form_top = star_position.top ;   // move feedback form below the rating block
        $('#feedback').dialog({closeText: 'x',
            width: 420,
            height: 300,
            title:'Feedback Form',
            resizable: false,
            draggable: false,
            position: [form_left,form_top],
            open: function(){
                $('#iframe_form').attr('src',window.document.URL + '/feedback');
            },
            close: function()
            {
                $('#iframe_form').attr('src',window.document.URL + '/feedback');
            }
        });
    });
}
function seeMoreRecentUpdate() {

    $('.see-more').live('click',function(){
        var x = $("#recent-updates ul li.hide");
        x.slice(0,10).map(function(i,n){

            $(n).removeClass('hide').delay(800);
        });
        hideSeeMoreRecentUpdate();
        hideCollapseAllLink();
    });
    $("#see-all").live('click',function()
    {

        $("#recent-updates ul li.updates").removeClass('hide').delay(800);
        hideSeeMoreRecentUpdate();
        hideCollapseAllLink();
        $(".see-less").css("display","block");
        $("#see-all").css("display","none");
    });
    $(".see-more").live("click",function(){

        $(".see-less").css("display","block");
    });
    $(".see-less").live("click",function(){
        $("li.updates").addClass('hide');
        for(var i=0;i<=9;i++)
        {
            $("li.updates").eq(i).removeClass('hide');
        }
        $(".see-more").css("display","block");
        $(".see-less").css("display","none");
        $("#see-all").css("display","block");
    });
}

function hideSeeMoreRecentUpdate(){

    var len = $("#recent-updates ul li.hide").length;

    if (len==0)
    {
        $("#recent-updates ul li a.see-more").hide();
        $("#see-all").css("display","none");
    }
}

function insertProductName() {
    $('#iframe_form').contents().find('#prod_rate').val($("#productRating").val());
    // this js function is called onload of iframe for feedback of th particular product
    // the function sets rating field in the feedback form since it is a dynamic user dependent value.
}

function trackDocumentView()
{
    $(".document-view").click(
        function()
        {
            _gaq.push(['_trackEvent','Document-view',$(this).attr('href')]);
        });
    $(".zip-downloaded").click(
        function()
        {
            var product_name = $('#productName').val();
            _gaq.push(['_trackEvent','Download_all',product_name]);
        });
}

//function search_content()
//{
//    $('#big-find').autocomplete({
//        source: function( request, response ) {
//            $.ajax({
//                url: "/products/suggest?token=" + $('#big-find').val(),
//                success: function( data ) {
//                    response( $.map( data, function( item ) {
//                        return {
//                            value: item
//                        }
//                    }));
//                }
//            });
//        }
//    });
//}

function showalertonOFCupdate()
{

    $(".ofc").click(function()
    {
        if (confirm("Are you sure, you want to mark that this document is updated out of cycle?"))
        {
            window.location = this.name
        }
    });
}
function search_content()
{
    $('#big-find').autocomplete({
        source: function( request, response ) {
            $.ajax({
                url: "/products/suggest?token=" + $('#big-find').val(),
                success: function( data ) {
                    response( $.map( data, function( item ) {
                        return {
                            value: item
                        }
                    }));
                }
            });
        },
        select: function(event,ui){
            $('#big-find').val(ui.item.value);
            $('#search-box-gsa').submit();
        }

    });
}

function tracknullserchresults()
{

    if ( $('.search-result').text() == "No Search Results" )
    {
        var sn = "query";
        var sr = new RegExp(sn+"=[^\&]+");
        var p = document.location.pathname;
        var s = document.location.search;
        var sm = s.match(sr).toString();
        var srs = sm.split("=");
        var sre = sm.replace(sr,srs[0]+"="+srs[1]+"&cat=no-results");
        var sf = s.replace(sr,sre);
        _gaq.push(['_trackPageview',p+sf]);
    };
}

function hideEditable(){

    $("#unversioned-products").hide();
}

function addRemovable()
{

    $('.cancel-button').live("click",function()
        {
            var my_row = $(this).parent().parent().parent();
            var id_field =my_row.find("input[name='product[version][][id]']");
            var id_val = id_field.attr('value');
            $('#'+id_val).addClass('product_name');
            my_row.remove();
            versionFind();
        }
    );
}

function hideCollapseAllLink()
{
//  var all_data = $("#recent-updates ul li.updates");
//  var data_visible = [];
//  $.each(all_data,function()
//  {
//    if($.inArray('hide',this.classes) == -1){
//        data_visible.push(this);
//    }
//  });
//  var len = data_visible.length;
//  if (len==10)
//  {
//     $('.see-less').hide();
//  }
}
/////***********************************************************************************************************/////
$(".see-more").live("click",function(){
    $(".see-less").css("display","block");

});
function adjustHeight()
{

    $('#browse-tab').css('min-height',$(window).height() - $('#header').height() - $('#nav-wrapper').height() - $('#footer').height() - 20);
    $('#content-login').css('height',$(window).height() - $('#header').height() - $('#nav-wrapper').height() - $('#footer').height());
    $('#search-tab').css('min-height',$(window).height() - $('#header').height() - $('#nav-wrapper').height() - $('#footer').height());
    $(window).bind('resize',function()
    {
        $('#browse-tab').css('min-height',$(window).height() - $('#header').height() - $('#nav-wrapper').height() - $('#footer').height() - 20);
        $('#content-login').css('height',$(window).height() - $('#header').height() - $('#nav-wrapper').height() - $('#footer').height());
        $('#search-tab').css('min-height',$(window).height() - $('#header').height() - $('#nav-wrapper').height() - $('#footer').height());
    });
    $('#nav-wrapper ul li').hover(function()
    {
        $(this).addClass('hovered');
    },function()
    {
        $(this).removeClass('hovered');
    });
}




//function to move login area when window height is less than 600
function pad(){
    var h=$(window).height();
    if(h < 600){
//        if ( $.browser.msie ) {
//          if ( $.browser.version == 7.0)
//          {
//            //$("html").css("overflow-y","hidden");
//          }
//        }
//     $("#login-tabs").addClass("move-top");
    }
}

//remove the class when screen height is greater than 600
$(window).resize(function(){
    var h=$(window).height();
    /* class to add & remove */
    if(h < 650){
        $("#login-tabs").addClass("movetop-600");
    }
    else{
        $("#login-tabs").removeClass("movetop-600");
    }

    /* class to add & remove */
    if(h < 550){
        $("#login-tabs").addClass("movetop-500");
    }
    else{
        $("#login-tabs").removeClass("movetop-500");
    }
});

var docNameAutocomplete = function(){
    var cache = {};
    $( "#doc-name-field" ).autocomplete({
        minLength: 0,
        source: function( request, response ) {
            var term = request.term;
            if ( term in cache ) {
                response( cache[ term ] );
                return;
            }
            $.getJSON( "/doc_names?product_id="+ product_id, request, function( data, status, xhr ) {
                var matches = $.map( data, function(tag) {
                    if ( tag.toUpperCase().indexOf(request.term.toUpperCase()) === 0 ) {
                        return tag;
                    }
                });
                cache[ term ] = matches;
                response(matches);
            });
        },
        open: function( event, ui ) {
            $("ul.ui-autocomplete").addClass("admin-left-position-fix");
            $("ul.ui-autocomplete").addClass("vertical-scroll");
            $("ul.ui-autocomplete").css('left','462.5px');

        },
        close: function( event, ui ) {
            $("ul.ui-autocomplete").removeClass("vertical-scroll");
        }
    }).focus(function(){
            $(this).autocomplete("search");
        });
}

// disable create button on document form
var disableDocSubmitBtn=function(){
    $("#document_submit").on('click',function(){
        $(this).hide();
    })
}
